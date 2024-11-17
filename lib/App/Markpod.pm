#
#  This file is part of markpod.
#
#  This software is copyright (c) 2024 by Andrew Speer <andrew.speer@isolutions.com.au>.
#
#  This is free software; you can redistribute it and/or modify it under
#  the same terms as the Perl 5 programming language system itself.
#
#  Full license text is available at:
#
#  <http://dev.perl.org/licenses/>
#


#  Compiler pragma
#
package App::Markpod;
use strict;
use warnings;
use vars qw($VERSION @EXPORT_OK);


#  Base Packages
#
use App::Markpod::Util;
use App::Markpod::Constant;


#  Base external modules
#
use IO::File;
use File::Copy;


#  Other external modules
#
use PPI;
use Markdown::Pod;


#  Version Info, must be all one line for MakeMaker, CPAN.
#
$VERSION='0.013';


#  Done
#
1;

#===================================================================================================


sub new {

    #  Bless self ref and retun
    #
    my ($class, $opt_hr)=@_;
    debug("instantiating new $class object with supplied options %s", Dumper($opt_hr));


    #  Get default options and overrides
    #
    my %opt=(
        %{$OPTION_HR},
        $opt_hr ? %{$opt_hr} : ()
    );
    debug('final option hash %s', Dumper(\%opt));


    #  Done
    #
    return bless({opt=>\%opt}, $class);

}


sub markpod_process {


    #  Find and replace POD in a file
    #
    my ($self, $fn)=@_;
    debug("processing file: $fn");


    #  Create new PPI documents from supplied file
    #
    my $ppi_doc_or=PPI::Document->new($fn) ||
        return err ("nable to create new PPI instance on file $fn");


    #  Find Pod section and massage. Return early if nothing to do (no POD)
    #
    my $pod_or_ar=$ppi_doc_or->find('PPI::Token::Pod') || do {
        msg("no POD section found in file: $fn, skipping");
        return \undef;
    };
    debug('pod_or_ar: %s', Dumper($pod_or_ar));
    my ($md, $pod_changed, @pod);
    foreach my $pod_or (@{$pod_or_ar}) {
        $md.=(my $pod_md=${
            $self->markpod_markdown_extract($pod_or->content) ||
                return err();
        });
        my $pod=${
            $self->markpod_pod_merge($pod_md) ||
                return err();
        };
        $pod.="\n=cut\n";
        if ($pod_changed += ($pod ne $pod_or->content())) {
            debug("pod: updating");
            $pod_or->set_content($pod);
        }
        else {
            debug("pod: no change, not updating");
        }
        push @pod, $pod;
    }
    
    
    #  Join POD
    #
    my $pod=join($/, @pod);
    
    
    #  Store results
    #
    @{$self}{qw(

        pod_changed
        markdown
        ppi_doc_or
        
    )}=(
        
        $pod_changed,
        $md,
        $ppi_doc_or
    );
    
    
    #  Return scalar ref of pod lines that would have changed
    #
    return \$pod_changed;
    
}



sub markpod_inplace_update {


    #  Update file in place
    #
    #my ($self, $fn, $ppi_doc_or, )=@_;
    #$ppi_doc_or ||= $self->markpod($fn) ||
    #  return err();
    my ($self, $fn)=@_;
    my $ppi_doc_or=$self->ppi_doc_or()
        || return err();


    #  Make a backup copy if needed
    #
    debug("updating file ${fn}");
    File::Copy::copy($fn, "${fn}.bak") unless $self->{'opt'}{'nobackup'};


    #  Save
    #
    $ppi_doc_or->save($fn) ||
        return err("unable to save to file: $fn, $!");
        

}


sub markpod_markdown_extract {

    my ($self, $pod)=@_;
    my $md;
    if ($pod=~/^=begin markdown(?=\s*)(.*?)\n(.*?)\n*^=end markdown\s*$/gims || $pod=~/^=begin markdown(?=\s*)(.*?)\n(.*)\n*$/gims) {
        if (my $fn=$1) {
            $fn=~s/^\s*//;
            debug("suggested output filename: $fn");
            $self->{'opt'}{'outfile'} ||= $fn;
        }
        $md=$2;
    }
    else {
        $md='';
    }
    chomp($md);
    debug('extracted markdown %s', Dumper(\$md));
    return \$md;

}


sub markpod_pod_merge {

    my ($self, $md)=@_;
    my $md2pod_or=Markdown::Pod->new() ||
        return err ('unable to create new Markdown::Pod object');
    my $pod=$md2pod_or->markdown_to_pod(dialect => $self->{'opt'}{'dialect'}, markdown => $md);
    #  Make a note of raw POD for getter function
    $self->{'pod'}=$pod;
    debug('created pod %s', Dumper(\$pod));
    $pod=join(
        "\n",
        '=begin markdown',
        $md,
        '',
        '=end markdown',
        '',
        $pod
    );
    #  This is markdown merged with created POD
    return \$pod;

}


sub outfile {


    #  Save output to a file or send to STDOUT
    #
    my ($self, $output_sr, $fn)=@_;


    #  Send to STDOUT or selected output file
    #
    my $fh=$fn ? do {
        IO::File->new($fn, O_CREAT|O_TRUNC|O_WRONLY) ||
            return err("unable to open output file $fn, $!");
        } : *STDOUT;
    print $fh ${$output_sr};
    

}    


#  Getters
#
foreach my $sub (qw(markdown pod ppi_doc_or)) {

    no strict qw(refs);
    *{sprintf("%s::${sub}", __PACKAGE__)}=sub { ref($_[0]->{$sub}) ? $_[0]->{$sub} : \($_[0]->{$sub}) }
    
}


1;
__END__

=pod
=begin markdown

# NAME

App::Markpod - convert markdown formatted pod to pure pod

# SYNOPSIS

```perl

use App::Markpod
my $markpod_or=App::Markpod ->new()
$markpod_or->markpod_process('foo.pl');
my $pod_sr=$markpod_or->pod()
print ${$pod_sr}
```

# DESCRIPTION

Helper module for the markpod utility that can also be used independently. 


# METHODS

**new()** Create a new App::Markpod reference. Usage:

`my $markpod_or=App::Markpod->new(\%opt)`

See OPTIONS section for options that can be supplied to creator

**markpod_process( filename )** Process the named file. Will return number of POD lines changed from any existing in file as scalar reference

```perl
my $lines_changed_sr=$markpod_or->markpod_process('foo.pl');
print "lines changed: ", ${$lines_changed_sr}, "\n";
```

# AUTHOR

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE and COPYRIGHT

This file is part of markpod.

This software is copyright (c) 2024 by Andrew Speer <andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

<http://dev.perl.org/licenses/>

=end markdown
