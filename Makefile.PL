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

my %author_test_requires = (
    'Test::More' => '0.89',
    'Test::Pod'  => '1.14',
);
my %release_test_requires = (
    'Test::More' => '0.89',
    'YAML'       => '0',
);

my %meta_merge = (
    'meta-spec' => { 'version' => 2 },
    'resources' => {
        'repository' => {
            'type' => 'git',
            'url'  => 'https://github.com/kentnl/Carp-Clan',
            'web'  => 'https://github.com/kentnl/Carp-Clan',
        },
    },
    'prereqs' => {
        'x_author_test'  => { 'requires' => {%author_test_requires} },
        'x_release_test' => { 'requires' => {%author_test_requires} },
    },
);

BEGIN {
    *author_mode = -f 'META.json' ? sub () { 0 } : sub () { 1 };
}

#NB: It is important PREREQ_PM is not changed in author mode
#    or it will leak into META.* and turn up in the release.
if ( $ENV{AUTOMATED_TESTING} or $ENV{AUTHOR_TESTING} ) {
    warn "* Author Tests Enabled\n";
    $make_conf{test}{TESTS} .= " xt/author/*.t";
    _merge_requirements( $make_conf{TEST_REQUIRES}, \%author_test_requires )
      unless author_mode;
}

if ( $ENV{AUTOMATED_TESTING} or $ENV{RELEASE_TESTING} ) {
    warn "* Release Tests Enabled\n";
    $make_conf{test}{TESTS} .= " xt/release/*.t";
    _merge_requirements( $make_conf{TEST_REQUIRES}, \%release_test_requires )
      unless author_mode;
}

#if ( $ENV{AUTOMATED_TESTING} ) {
#    $make_conf{test}{TESTS} .= " xt/smoke/*.t";
#}

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

