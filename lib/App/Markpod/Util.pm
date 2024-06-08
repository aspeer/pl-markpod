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

package App::Markpod::Util;


#  Pragma
#
use strict;
use vars qw($VERSION $DEBUG @EXPORT);
use warnings;


#  External modules
#
use FindBin qw($RealBin $Script);
FindBin::again();
use Data::Dumper;
$Data::Dumper::Indent=1;
$Data::Dumper::Terse=1;


#  Export functions
#
use base 'Exporter';
@EXPORT=qw(err msg arg debug Dumper);


#  Version information in a format suitable for CPAN etc. Must be
#  all on one line
#
$VERSION='0.013';


#  Debugging on ?
#
$Script=~s/\.pl$//;
($Carp::Verbose=++$DEBUG) if $ENV{uc("${Script}_DEBUG")};


#  Done
#
1;

#==================================================================================================


sub debug {

    #  Debug
    #
    goto &msg if $DEBUG;

}


sub err {

    #  Quit on errors
    #
    my $msg=&fmt('error: %s', @_);
    CORE::print STDERR $msg, "\n";
    eval {require Carp; 1};
    Carp::croak;

}


sub fmt {

    #  Format message nicely. Always called by err or msg so caller=2
    #
    my $message=sprintf(shift(), @_);
    chomp($message);
    my $caller=(caller(2))[3] || 'main';
    $caller=~s/^_?!(_)//;
    my $format='@<<<<<<<<<<<<<<<<<<<<<< @<';
    local $^A='';
    formline $format, "[${caller}]", '';
    $message=$^A . $message; $^A=undef;
    return $message;

}


sub msg {

    #  Print message
    #
    return CORE::print &fmt(@_), "\n";

}
