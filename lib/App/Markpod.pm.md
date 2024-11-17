
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

**new()** 

Create a new App::Markpod reference. Usage:

`my $markpod_or=App::Markpod->new(\%opt)`

See OPTIONS section for options that can be supplied to creator

**markpod_process( filename )** 

Process the named file. Will return number of POD lines changed from any existing in file as scalar reference

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

