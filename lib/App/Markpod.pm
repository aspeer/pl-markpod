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


sub markdown_extract {

    my ($self, $pod)=@_;
    my $md;
    if ($pod=~/^=begin markdown(?=\s*)(.*?)\n(.*?)\n*^=end markdown\s*$/gims || $pod=~/^=begin markdown(?=\s*)(.*?)\n(.*)\n*$/gims) {
        if (my $fn=$1) {
            $fn=~s/^\s*//;
            debug("suggested output filename: $fn");
            $self->{'outfile'} ||= $fn;
        }
        $md=$2;
    }
    else {
        $md='';
    }
    chomp($md);
    debug('extracted markdown %s', Dumper(\$md));
    return $md;

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
        $md.=(my $pod_md=$self->markdown_extract($pod_or->content));
        my $pod=$self->markpod_parse($pod_md);
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
        pod
        ppi_doc_or
        
    )}=(
        
        $pod_changed,
        $md,
        $pod,
        $ppi_doc_or
    );
    
    
    #  Return scalar ref of pod lines that would have changed
    #
    return \$pod_changed;
    
}


#  Getters
#
foreach my $sub (qw(markdown pod ppi_doc_or)) {

    *{sprintf("%s::${sub}", __PACKAGE__)}=sub { ref($_[0]->{$_}) ? $_[0]->{$_} : \($_[0]->{$_}) }
    
}


1;
__END__

sub ppi_doc_or {

        


    #  Check if we just want Markdown ?
    #
    if ($self->{'extract_markdown'}) {
        #my $fh=IO::File->new($self->{'outfile'}, O_WRONLY | O_TRUNC | O_CREAT) || *STDOUT;
        #print $fh $md;
        #return \undef;
        return \$md;
    }
    
    
    #  Or just want POD ?
    #
    if ($self->{'extract_pod'}) {
        #my $pod=$ppi_doc_or->serialize;
        my $pod=join($/, @pod);
        return \$pod;
    }
    
    
    #  Return PPO object
    #
    return $ppi_doc_or;
    


    #  Want POD - proceed
    #
    if (my $out_fn=$self->{'outfile'}) {
        debug("saving to file: $out_fn");
        $ppi_doc_or->save($out_fn);
    }
    elsif ($self->{'inplace'}) {
        if ($inplace_changed) {

            #  Make a backup copy
            #
            debug("inplace_changed: $inplace_changed, updating file ${fn}");
            File::Copy::copy($fn, "${fn}.bak") unless $self->{'nobackup'};

            #  Save
            #
            $ppi_doc_or->save($fn);
        }
        else {
            debug("inplace_changed: $inplace_changed, not updating ${fn}");
        }
    }
    else {
        print $ppi_doc_or->serialize;
    }


    #  Done
    #
    return \$inplace_changed;


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
    my ($md, $inplace_changed, @pod);
    foreach my $pod_or (@{$pod_or_ar}) {
        $md.=(my $pod_md=$self->markdown_extract($pod_or->content));
        my $pod=$self->markpod_parse($pod_md);
        $pod.="\n=cut\n";
        if ($inplace_changed += ($pod ne $pod_or->content())) {
            debug("pod: updating");
            $pod_or->set_content($pod);
            $self->{'pod_changed'}=$inplace_changed;
        }
        else {
            debug("pod: no change, not updating");
        }
        push @pod, $pod;
    }
    

    #  Collate processed POD
    #
    my $pod=join($/, @pod);
    

    #  Return items of interest
    #
    my %return=(

      ppi_doc_or	=> $ppi_doc_or,
      md_sr		=> \$md,
      pod_sr		=> \$pod,
      inplace_changed	=> $inplace_changed
      
    );
    return \%return;

}


sub markpod_inplace_update {


    #  Update file in place
    #
    my ($self, $fn, $ppi_doc_or, )=@_;
    $ppi_doc_or ||= $self->markpod($fn) ||
      return err();


    #  Make a backup copy if needed
    #
    debug("updating file ${fn}");
    File::Copy::copy($fn, "${fn}.bak") unless $self->{'nobackup'};


    #  Save
    #
    $ppi_doc_or->save($fn) ||
        return err("unable to save to file: $fn, $!");
        

}
    
    
    
    
    


sub markpod0 {


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
    my ($md, $inplace_changed);
    foreach my $pod_or (@{$pod_or_ar}) {
        $md.=(my $pod_md=$self->markdown_extract($pod_or->content));
        my $pod=$self->markpod_parse($pod_md);
        $pod.="\n=cut\n";
        if ($inplace_changed += ($pod ne $pod_or->content())) {
            debug("pod: updating");
            $pod_or->set_content($pod);
        }
        else {
            debug("pod: no change, not updating");
        }
    }


    #  Check if we just want Markdonw
    #
    if ($self->{'extract'}) {
        my $fh=IO::File->new($self->{'outfile'}, O_WRONLY | O_TRUNC | O_CREAT) || *STDOUT;
        print $fh $md;
        return \undef;
    }


    #  Want POD - proceed
    #
    if (my $out_fn=$self->{'outfile'}) {
        debug("saving to file: $out_fn");
        $ppi_doc_or->save($out_fn);
    }
    elsif ($self->{'inplace'}) {
        if ($inplace_changed) {

            #  Make a backup copy
            #
            debug("inplace_changed: $inplace_changed, updating file ${fn}");
            File::Copy::copy($fn, "${fn}.bak") unless $self->{'nobackup'};

            #  Save
            #
            $ppi_doc_or->save($fn);
        }
        else {
            debug("inplace_changed: $inplace_changed, not updating ${fn}");
        }
    }
    else {
        print $ppi_doc_or->serialize;
    }


    #  Done
    #
    return \$inplace_changed;


}


sub markpod_parse {

    my ($self, $md)=@_;
    my $md2pod_or=Markdown::Pod->new() ||
        return err ('unable to create new Markdown::Pod object');
    my $pod=$md2pod_or->markdown_to_pod(dialect => $self->{'dialect'}, markdown => $md);
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
    return $pod;

}

1;
__END__


=begin markdown

# NAME

markpod.pl - convert markdown formatted pod to pure pod

# SYNOPSIS

`markpod.pl filename <filename> <filename>`

# DESCRIPTION

markpod.pl scans a file for markdown formatted pod and then converts it to pure
pod and then appends it to the pod section. It allows the user to write perl
documentation in markdown format withing a pod block - and then have it
converted to "normal" pod for use with all standard utilitied that expect
pod documentation (e.g. perldoc etc.)

# OPTIONS

**--file|fn|f** input file to process

**--outfile** file to write to. If omitted will overwrite input file (i.e. inplace update)

**--dialect** which Markdown dialect to use from Markdent module. Options are Standard, GitHub (default) and Theory 

**--extract** just extract the Markdown from the input file and don't update POD. Print to STDOUT or file (using --output)

**--nobackup** don't backup input file when doing inplace update

**--help** show help synopsis

**--man** show man page

**--version** show version information

# USAGE

Create a pod section in the perl code using the markdown formatter begin
convention, e.g.

```
 =pod
 =begin markdown 

 # POD Heading
 Some **Bold** Test
 [Perl Link](http://perl.org)
 Some `code` in this section

 =end markdown 
 =cut 
```
  
Once markpod is run it would be converted to the following.

 =head1 POD Heading

 Some B\<Bold\> Test
 L\<Perl Link|http://perl.org\>
 Some C\<code\> in this section

 =cut

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


=head1 NAME

markpod.pl - convert markdown formatted pod to pure pod


=head1 SYNOPSIS

C<<< markpod.pl filename <filename> <filename> >>>


=head1 DESCRIPTION

markpod.pl scans a file for markdown formatted pod and then converts it to pure
pod and then appends it to the pod section. It allows the user to write perl
documentation in markdown format withing a pod block - and then have it
converted to "normal" pod for use with all standard utilitied that expect
pod documentation (e.g. perldoc etc.)


=head1 OPTIONS

B<--file|fn|f> input file to process

B<--outfile> file to write to. If omitted will overwrite input file (i.e. inplace update)

B<--dialect> which Markdown dialect to use from Markdent module. Options are Standard, GitHub (default) and Theory 

B<--extract> just extract the Markdown from the input file and don't update POD. Print to STDOUT or file (using --output)

B<--nobackup> don't backup input file when doing inplace update

B<--help> show help synopsis

B<--man> show man page

B<--version> show version information


=head1 USAGE

Create a pod section in the perl code using the markdown formatter begin
convention, e.g.


  =pod
  =begin markdown 
 
  # POD Heading
  Some **Bold** Test
  [Perl Link](http://perl.org)
  Some `code` in this section
 
  =end markdown 
  =cut 
Once markpod is run it would be converted to the following.

 =head1 POD Heading

 Some B<Bold> Test
 L<Perl Link|L<http://perl.org\>>
 Some C<code> in this section

 =cut


=head1 AUTHOR

Andrew Speer L<mailto:andrew.speer@isolutions.com.au>


=head1 LICENSE and COPYRIGHT

This file is part of markpod.

This software is copyright (c) 2022 by Andrew Speer L<mailto:andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

L<http://dev.perl.org/licenses/>

=cut
