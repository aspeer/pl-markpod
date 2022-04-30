#
package App::Markpod::Constant;


#  Pragma
#
use strict qw(vars);
use vars qw($VERSION @ISA %EXPORT_TAGS @EXPORT_OK @EXPORT %Constant);


#  Version information
#
$VERSION = '0.006';


#  Get module file name and path, derive name of file to store local constants
#
use Cwd qw(abs_path);
my $local_fn = abs_path(__FILE__) . '.local';


#  Hash of constants
#
%Constant=(

    OPTION_HR => {
        dialect => 'GitHub',
        inplace => 1,
    },

    #  Local constants override anything above
    #
    %{ do($local_fn) || {} },
    %{ do(glob(sprintf('~/.%s.local', __PACKAGE__))) || {} } # || {} avoids warning

);


#  Export constants to namespace, place in export tags
#
require Exporter;
@ISA = qw(Exporter);
foreach ( keys %Constant ) { ${$_} = $Constant{$_} }
@EXPORT      = map { '$' . $_ } keys %Constant;
@EXPORT_OK   = @EXPORT;
%EXPORT_TAGS = ( all => [@EXPORT_OK] );
$_           = \%Constant;

