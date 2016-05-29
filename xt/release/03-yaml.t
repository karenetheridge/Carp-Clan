#!perl

use strict;
use warnings;
use Test::More;
use YAML qw( LoadFile );
plan tests => 1;
ok( LoadFile("META.yml") );

__END__

