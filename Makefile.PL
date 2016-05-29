#!perl

use strict;
use ExtUtils::MakeMaker;

my %make_conf = (
    NAME           => 'Carp::Clan',
    AUTHOR         => 'Steffen Beyer <STBEY@cpan.org>',
    LICENSE        => 'perl',
    VERSION_FROM   => 'lib/Carp/Clan.pm',
    ABSTRACT_FROM  => 'lib/Carp/Clan.pod',
    PREREQ_PM      => {},
    BUILD_REQUIRES => {},
    TEST_REQUIRES  => { 'Test::Exception' => 0 },
    dist           => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    clean => { FILES => 'Carp-Clan-*' },
    test  => { TESTS => 't/*.t' }
);

my %meta_merge = ( 'meta-spec' => { 'version' => 2 }, );

BEGIN {
    *author_mode = -f 'META.json' ? sub () { 0 } : sub () { 1 };
}

if (author_mode) {
    ExtUtils::MakeMaker->VERSION(6.63_03);
    $make_conf{META_MERGE} = \%meta_merge;
}
else {
    # have to do this since old EUMM dev releases miss the eval $VERSION line
    my $eumm_version = eval $ExtUtils::MakeMaker::VERSION;

    _merge_requirements( $make_conf{BUILD_REQUIRES}, $make_conf{TEST_REQUIRES} )
      if $eumm_version < 6.63_03;
    _merge_requirements( $make_conf{PREREQ_PM}, $make_conf{BUILD_REQUIRES} )
      if $eumm_version < 6.55_01;

    for my $key (qw( PREREQ_PM BUILD_REQUIRES TEST_REQUIRES )) {
        delete $make_conf{$key}
          if exists $make_conf{$key} and not keys %{ $make_conf{$key} || {} };
    }
}

WriteMakefile(%make_conf);

sub _merge_requirements {
    my ( $into, $source ) = @_;
    for my $module ( keys %{$source} ) {
        my $version = delete $source->{$module};
        if ( not exists $into->{$module}
            or ( $into->{$module} || '0' ) < $version )
        {
            $into->{$module} = $version;
        }
    }
}

__END__

