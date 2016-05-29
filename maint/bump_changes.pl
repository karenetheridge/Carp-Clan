#!perl
use strict;
use warnings;

# This merely makes sure various files with changes are "Up to date"

use autodie qw(:all);
use Term::ANSIColor qw( colored );
use constant HAS_GIT => eval { require Git::Wrapper; -e '.git' and -d '.git' };

my $year = ( gmtime() )[5] + 1900;

my $changes_content;

{
    my $changes_file = 'Changes';
    warn "Scanning $changes_file\n";

    $changes_content = do {
        open my $fh, '<', $changes_file;
        local $/;
        <$fh>;
    };

    warn "Updating date in $changes_file\n";
    my ( $d, $m, $y ) = ( gmtime() )[ 3, 4, 5 ];
    my $date = sprintf "%02d.%02d.%04d", $d, $m + 1, $y + 1900;

    $changes_content =~ s{
          (Version\s*history:\n-+\n\nVersion\s*\S+\s*)\d+.\d+.\d+\n
    }{$1$date\n}mx;

    warn "Updating Copyrights in $changes_file\n";
    $changes_content =~ s/\b(\d{4}-)\d{4}/$1$year/mg;

    warn "Saving $changes_file\n";
    open my $fh, '>', $changes_file;
    print {$fh} $changes_content;
    close $fh;
}
{
    warn "Extracting last change";
    my $change;
    if (
        $changes_content =~ qr{
         Version\s*history:\n-+\n\n(Version\s*\S+\s*\d+.\d+.\d+\n
         .*?)
         \nVersion\s*\S+\s*
    }msx
      )
    {
        $change = $1;
        warn "Last change:\n$change\n";
    }
    if ($change) {

        $change =~ s/\n+\z/\n\n/ms;

        my $readme = 'README';
        warn "Reading $readme\n";
        my $readme_content = do {
            open my $fh, '<', $readme;
            local $/;
            <$fh>;
        };
        warn "Updating new-release data in $readme\n";
        $readme_content =~ s{
      (What's\s+new\s+in\s+this\s+release:\s*\n-+\n\n)
      .*?
      (Copyright\s+&\s+License:\s*\n)
    }{$1$change$2}msx;

        warn "Updating Copyrights in $readme\n";
        $readme_content =~ s/\b(\d{4}-)\d{4}/$1$year/mg;

        warn "Writing $readme\n";
        open my $fh, '>', $readme;
        print {$fh} $readme_content;
        close $fh;
    }
}
update_mm: {
    my $main_module = 'lib/Carp/Clan.pm';
    unless (HAS_GIT) {
        #<<<
        warn colored( ['red'], '**' ) . "Git::Wrapper should be installed and this should be run in a git checkout\n"
           . colored( ['red'], '**' ) . "Skipping Last-Modified update in Carp/Clan.pm.\n";
        #>>>
        last update_mm;
    }

    warn "Determining last modifier of $main_module from git\n";
    my $git = Git::Wrapper->new('.');

    # TODO: Determine how far back to look, but this is an optimization
    # HEAD~10 to HEAD seems fine, but might not be.
    my (@commits) = do {

      # This is basically how you get dates/times in UTC.
      # A) using "local" usurps the default ( which is specified in the commit )
      # B) Setting TZ then defines what "local" is.
        local $ENV{LC_ALL} = 'C';
        local $ENV{TZ}     = 'UTC';
        $git->log( '--date=format-local:%d-%b-%Y|%T@%z', '--', $main_module );
    };
    my ( $author, $author_date, $change_id );

    # This little block of code expressly tries to make sure
    # that updating the "Last Modified by" line doesn't
    # turn into some iterative self-dependency
    # where every time you update the line with a commit, you change
    # when the last modified time was, resulting in needing to update
    # "last modified" as result of updating "Last modified".
  find_noteworthy_change: while (@commits) {
        if ( @commits < 2 ) {
            $author      = $commits[0]->author;
            $author_date = $commits[0]->date;
            $change_id   = $commits[0]->id;
            last;
        }
        my ( $tip, $succ ) = @commits[ 0, 1 ];
        my (@lines) = $git->diff( $succ->id, $tip->id, '--', $main_module );
        for my $line (@lines) {
            next if $line =~ /^[-+]{3} [a|b]/;
            next if $line !~ /^\+/;
            next if $line =~ /^\+##\s+Last\s+modified/;
            $author      = $tip->author;
            $author_date = $tip->date;
            $change_id   = $tip->id;
            last find_noteworthy_change;
        }
        shift @commits;
    }
    warn
      "$main_module Last modified by $author on $author_date ( $change_id )\n";
    for
      my $line ( $git->diff( "$change_id~1", $change_id, '--', $main_module ) )
    {
        # Tidy Guard
        #<<<
        print STDERR $line =~ /^\+/              ? colored( ['green'], $line )
                   : $line =~ /^-/               ? colored( ['red'  ], $line )
                   : $line =~ /^(\@|diff|index)/ ? colored( ['cyan' ], $line )
                   :                                                   $line ;
        #>>>
        print STDERR "\n";
    }
    my $modified_date = $author_date;
    $modified_date =~ s/\|.*\z//s;
    my $modifier = $author;
    $modifier =~ s/\<.*\z//s;

    warn "Reading $main_module\n";

    my $content = do {
        open my $fh, '<', $main_module;
        local $/;
        <$fh>;
    };

    warn "Updating ${main_module}'s contents\n";

    $content =~ s{
      ^
      (\#\#\s*Last\s+modified\s+)
      \d+-\w+?-\d+
      (\s+by\s+)
      [^.]+
      (\.)
    }{$1$modified_date$2$modifier$3}msx;

    warn "Writing $main_module\n";
    open my $fh, '>', $main_module;
    print {$fh} $content;
    close $fh;

}
