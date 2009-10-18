#!perl -w

###############################################################################
##                                                                           ##
##    Copyright (c) 2001 - 2004 by Steffen Beyer.                            ##
##    All rights reserved.                                                   ##
##                                                                           ##
##    This package is free software; you can redistribute it                 ##
##    and/or modify it under the same terms as Perl itself.                  ##
##                                                                           ##
###############################################################################

use strict;

use ExtUtils::MakeMaker;

use Config;

WriteMakefile(
    'NAME'              => 'Carp::Clan',
    'AUTHOR'            => 'Steffen Beyer <STBEY@cpan.org>',
    'VERSION_FROM'      => 'Clan.pm',
    'ABSTRACT_FROM'     => 'Clan.pod',
    'dist'              => { COMPRESS => 'gzip -9', SUFFIX => 'gz', },
#   for ActivePerl:
    ($] >= 5.005 && $^O eq 'MSWin32' && $Config::Config{'archname'} =~ /-object\b/i ?
        ('CAPI'         => 'TRUE') : ())
);

__END__

