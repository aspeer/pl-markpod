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


#  Base External modules
#
use App::Markpod;
use App::Markpod::Util;
use App::Markpod::Constant;


#  Other external modules
#
use Pod::Usage;
use FindBin qw($RealBin $Script);
use Getopt::Long qw(GetOptionsFromArray :config auto_version auto_help);


#  Constantas
#
use constant {


    #  Command line options in Getopt::Long format
    #
    OPTION_AR => [

        qw(man verbose quiet),
        'dialect=s',
        'inplace|i',
        'infile_ar|file|fn|f|in=s@',
        'outfile|output|o=s',
        'extract|noconvert|md|markdown',
        'nobackup'
    ],


    #  Option defaults
    #
    OPTION_HR => {
        %{$OPTION_HR},                              # From App::Markpod::Constant;
        %{do(glob("~/.${Script}.option")) || {}}    # || {} avoids warning
    },


    #  Environment prefix which will override option, e.g. MARKPOD_NOBACKUP=1
    #
    OPTION_ENV_PREFIX => 'MARKPOD',

};


#  Version Info, must be all one line for MakeMaker, CPAN.
#
$VERSION='0.009_263630434';


#  Run main
#
exit(${&main(&getopt(\@ARGV)) || die err ()} || 0);    # || 0 stops warnings


#===================================================================================================


sub main {    #no subsort


    #  Get base object blassed with options as first arg.
    #
    my $self=App::Markpod->new(shift());


    #  Iterate over infiles
    #
    foreach my $fn (@{$self->{'infile_ar'}}) {


        #  Sanity check on file name
        #
        debug("processing file: $fn");
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


sub getopt {


    #  ARGV usually supplied as array ref but could be anyting
    #
    my $opt_ar=shift() || \@ARGV;


    #  Base options will pass to compile. Get option defauts from ENV or Constant/options file
    #
    my %opt=(

        map {
            $_ => do {my $key=sprintf("%s_%s", +OPTION_ENV_PREFIX, uc($_)); defined $ENV{$key} ? $ENV{$key} : +OPTION_HR->{$_}}
        } keys %{+OPTION_HR}

    );
    debug('opt stage 1: %s', Dumper(\%opt));


    #  Now import command line options.
    #
    GetOptionsFromArray($opt_ar, \%opt, @{+OPTION_AR}, '' => \${opt {'stdin'}}, '<>' => sub {push @{$opt{'infile_ar'}}, shift() . ''}) ||
        pod2usage(2);
    debug('opt stage 2: %s', Dumper(\%opt));
    pod2usage(-verbose => 2) if $opt{'man'};


    #  Done
    #
    return \%opt;

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
