#!perl
use strict;
use warnings;

use File::Which qw(which);
use autodie qw(:all);

my ($version) = @ARGV;

die "Must specify a VERSION" unless defined $version;

die "VERSION does not match X.YY or X.YY_ZZ format"
  unless $version =~ /\A\d\.\d\d(|_\d\d)\z/;

die "No perl-reversion in PATH, please install Perl::Version"
  unless which('perl-reversion');

system( 'perl-reversion', '-set', $version );

## NOTE: This logic fixes a self-coherence check in t/

{
    my $test_file = './t/20pre560.t';

    warn "Scanning $test_file\n";

    my $test_content = do {
        open my $fh, '<', $test_file;
        local $/;
        <$fh>;
    };

    my $fixed_version = $version;
    $fixed_version =~ tr/_//d;

    warn "Setting check version to $fixed_version\n";
    $test_content =~ s{
      ^(if\s*\(\$Carp::Clan::VERSION\s+eq\s+')[^']+(')
    }{$1$fixed_version$2}xm;

    warn "Saving $test_file\n";
    open my $fh, '>', $test_file;
    print {$fh} $test_content;
    close $fh;
}
{
    my $changes_file = 'Changes';
    warn "Scanning $changes_file\n";

    my $changes_content = do {
        open my $fh, '<', $changes_file;
        local $/;
        <$fh>;
    };

    if ( $changes_content !~ /^Version $version/m ) {
        warn "Adding Version $version to $changes_file\n";
        my ( $d, $m, $y ) = ( gmtime() )[ 3, 4, 5 ];
        my $date = sprintf "%02d.%02d.%04d", $d, $m + 1, $y + 1900;
        $changes_content =~ s{
          (Version\s*history:\n-+\n\n)
        }{$1Version $version  $date\n\n}mx;

        warn "Saving $changes_file\n";
        open my $fh, '>', $changes_file;
        print {$fh} $changes_content;
        close $fh;
    }

}
