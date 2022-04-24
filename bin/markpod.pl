#!/usr/bin/perl

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
use strict;
use vars qw($VERSION);
use warnings;

#  Base external modules
#
use FindBin qw($RealBin $Script);
use Getopt::Long qw(GetOptionsFromArray :config auto_version auto_help);
use Pod::Usage;
use IO::File;
use File::Copy;
use Data::Dumper;
$Data::Dumper::Indent=1;
$Data::Dumper::Terse=1;


#  Other external modules
#
use PPI;
use Markdown::Pod;


#  Constantas
#
use constant {

    OPTION_AR => [

        qw(man verbose quiet),
        'dialect=s',
        'inplace|i',
        'infile_ar|file|fn|f|in=s@',
        'outfile|output|o=s',
        'extract|noconvert|md|markdown',
        'nobackup'
    ],

    OPTION_HR => {
        dialect => 'GitHub',
        inplace => 1,
        %{do(glob("~/.${Script}.option")) || {}}    # || {} avoids warning
    },

    OPTION_ENV_PREFIX => 'MARKPOD',

};


#  Version Info, must be all one line for MakeMaker, CPAN.
#
$VERSION='0.007';


#  Run main
#
exit (${&main(&getopt(\@ARGV)) || die err ()} || 0); # || 0 stops warnings


#===================================================================================================


sub main {    #no subsort

    #  Get argv array ref and bless
    #
    my $self=bless(shift());


    #  Iterate over infiles
    #
    foreach my $fn (@{$self->{'infile_ar'}}) {


        #  Sanity check on file name
        #
        unless (-f $fn) {
            return err ("file $fn not found");
        }


        #  Do it
        #
        $self->markpod($fn) ||
            return err ("unknown error processing file $fn");


    }


    #  Done
    #
    return \undef;


}


sub err {

    eval 'require Carp';
    Carp::croak sprintf(shift, @_);

}


sub getopt {


    #  ARGV usually supplied as array ref but could be anyting
    #
    my $opt_ar=shift() || \@ARGV;


    #  Base options will pass to compile. Get option defauts from ENV or Constant/options file
    #
    my %opt=(

        map {$_ => $ENV{sprintf("%s_%s", +OPTION_ENV_PREFIX, uc($_))} || +OPTION_HR->{$_}} keys %{+OPTION_HR}

    );


    #  Now import command line options.
    #
    GetOptionsFromArray($opt_ar, \%opt, @{+OPTION_AR}, '' => \${opt {'stdin'}}, '<>' => sub {push @{$opt{'infile_ar'}}, shift() . ''}) ||
        pod2usage(2);
    pod2usage(-verbose => 2) if $opt{'man'};


    #  Done
    #
    return \%opt;

}


sub markdown_extract {

    my ($self, $pod)=@_;
    my ($md)=($pod=~/^=begin markdown\s*$(.*?)^=end markdown\s*$/ms);
    chomp $md;
    return $md;

}


sub markpod {


    #  Find and replace POD in a file
    #
    my ($self, $fn)=@_;


    #  Create new PPI documents from supplied file
    #
    my $ppi_doc_or=PPI::Document->new($fn) ||
        return err ("nable to create new PPI instance on file $fn");


    #  Find Pod section and massage
    #
    my $pod_or_ar=$ppi_doc_or->find('PPI::Token::Pod');
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
    my $md2pod_or=Markdown::Pod->new;
    my $pod=$md2pod_or->markdown_to_pod(dialect => $self->{'dialect'}, markdown => $md);
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

markpod - convert markdown formatted pod to pure pod

# SYNOPSIS

`markpod.pl filename <filename> <filename>`

# DESCRIPTION

markpod.pl scans a file for markdown formatted pod and then converts it to pure
pod and then appends it to the pod section. It allows the user to write perl
documentation in markdown format within a pod block - and then have it
converted to "normal" pod for use with all standard utilities that expect
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

markpod - convert markdown formatted pod to pure pod


=head1 SYNOPSIS

C<<< markpod.pl filename <filename> <filename> >>>


=head1 DESCRIPTION

markpod.pl scans a file for markdown formatted pod and then converts it to pure
pod and then appends it to the pod section. It allows the user to write perl
documentation in markdown format within a pod block - and then have it
converted to "normal" pod for use with all standard utilities that expect
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
