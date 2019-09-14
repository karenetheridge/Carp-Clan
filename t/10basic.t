#!perl -w

BEGIN
{
    eval { require Test::More; Test::More->import(); };
    if ($@) { print "1..0 # skip Test::More is not available on this platform\n"; exit 0; }
}

use strict;

plan tests => 2;

use_ok( 'Carp::Clan', 'Use Carp::Clan' );

eval {
    Carp::Clan->import(qw(^Carp\\b));
};

is($@, '', 'No errors importing');

__END__

