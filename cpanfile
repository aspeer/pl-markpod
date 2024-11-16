requires 'App::Markpod';
requires 'App::Markpod::Constant';
requires 'App::Markpod::Util';
requires 'FindBin';
requires 'Getopt::Long';
requires 'Markdown::Pod';
requires 'PPI';
requires 'Pod::Usage';
requires 'constant';
requires 'strict';
requires 'vars';
requires 'warnings';
requires 'with';

on configure => sub {
    requires 'perl', '5.006';
};

on test => sub {
    requires 'Test::More';
};
