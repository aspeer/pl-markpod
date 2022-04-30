#
#  This file is part of markpod.
#
#  This software is copyright (c) 2022 by Andrew Speer <andrew.speer@isolutions.com.au>.
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
$VERSION='0.008';


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
        %{$opt_hr}
    );
    debug('final option hash %s', Dumper(\%opt));
    
    
    #  Done
    #
    return bless(\%opt, $class);
    
}


sub markdown_extract {

    my ($self, $pod)=@_;
    my ($md)=($pod=~/^=begin markdown\s*$(.*?)^=end markdown\s*$/ms);
    chomp $md;
    debug('extracted markdown %s', Dumper(\$md));
    return $md;

}


sub markpod {


    #  Find and replace POD in a file
    #
    my ($self, $fn)=@_;
    debug("processing file $fn");


    #  Create new PPI documents from supplied file
    #
    my $ppi_doc_or=PPI::Document->new($fn) ||
        return err ("nable to create new PPI instance on file $fn");


    #  Find Pod section and massage
    #
    my $pod_or_ar=$ppi_doc_or->find('PPI::Token::Pod');
    debug('pod_or_ar: %s', Dumper($pod_or_ar));
    my $md;
    foreach my $pod_or (@{$pod_or_ar}) {
        $md.=(my $pod_md=$self->markdown_extract($pod_or->content));
        my $pod=$self->markpod_parse($pod_md);
        $pod.="\n=cut\n";
        $pod_or->set_content($pod);
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
        $ppi_doc_or->save($out_fn);
    }
    elsif ($self->{'inplace'}) {
        File::Copy::copy($fn, "${fn}.bak") unless $self->{'nobackup'};

        #  Backup and save
        #
        $ppi_doc_or->save($fn);
    }
    else {
        print $ppi_doc_or->serialize;
    }


    #  Done
    #
    return \undef;


}


sub markpod_parse {

    my ($self, $md)=@_;
    my $md2pod_or=Markdown::Pod->new() ||
        return err('unable to create new Markdown::Pod object');
    my $pod=$md2pod_or->markdown_to_pod(dialect => $self->{'dialect'}, markdown => $md);
    debug('created pod %s', Dumper(\$pod));
    $pod=join(
        "\n",
        '=begin markdown',
        $md,
        '=end markdown',
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

This software is copyright (c) 2022 by Andrew Speer <andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Terms of the Perl programming language system itself

a) the GNU General Public License as published by the Free
   Software Foundation; either version 1, or (at your option) any
   later version, or
b) the "Artistic License"


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

This software is copyright (c) 2022 by Andrew Speer <andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:
L<http://dev.perl.org/licenses/>

=cut
