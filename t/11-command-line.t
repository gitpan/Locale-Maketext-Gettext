#! /usr/bin/perl -w
# Test suite on the maketext script
# Copyright (c) 2003 imacat. All rights reserved. This program is free
# software; you can redistribute it and/or modify it under the same terms
# as Perl itself.

use 5.008;
use strict;
use warnings;
use Test;

BEGIN { plan tests => 10 }

use FindBin;
use File::Spec::Functions qw(catdir catfile updir);
use lib $FindBin::Bin;
use vars qw($LOCALEDIR $maketext);
$LOCALEDIR = catdir($FindBin::Bin, "locale");
$maketext = catdir($FindBin::Bin, updir, "blib", "script", "maketext");

# The maketext script
# Ordinary text unchanged
eval {
    delete $ENV{"LANG"};
    delete $ENV{"LANGUAGE"};
    delete $ENV{"TEXTDOMAINDIR"};
    delete $ENV{"TEXTDOMAIN"};
    @_ = `$maketext "Hello, world!"`;
};
# 1
ok($@, "");
# 2
ok($_[0], "Hello, world!");

# Specify the text domain by the -d argument
# English
eval {
    $ENV{"LANG"} = "C";
    $ENV{"LANGUAGE"} = "C";
    $ENV{"TEXTDOMAINDIR"} = $LOCALEDIR;
    delete $ENV{"TEXTDOMAIN"};
    @_ = `$maketext -d test "Hello, world!"`;
};
# 3
ok($@, "");
# 4
ok($_[0], "Hiya :)");

# Specify the text domain by the environment variable
# English
eval {
    $ENV{"LANG"} = "C";
    $ENV{"LANGUAGE"} = "C";
    $ENV{"TEXTDOMAINDIR"} = $LOCALEDIR;
    $ENV{"TEXTDOMAIN"} = "test";
    @_ = `$maketext "Hello, world!"`;
};
# 5
ok($@, "");
# 6
ok($_[0], "Hiya :)");

# The -s argument
eval {
    $ENV{"LANG"} = "C";
    $ENV{"LANGUAGE"} = "C";
    $ENV{"TEXTDOMAINDIR"} = $LOCALEDIR;
    $ENV{"TEXTDOMAIN"} = "test";
    @_ = `$maketext -s "Hello, world!"`;
};
# 7
ok($@, "");
# 8
ok($_[0], "Hiya :)\n");

# Maketext
eval {
    $ENV{"LANG"} = "C";
    $ENV{"LANGUAGE"} = "C";
    $ENV{"TEXTDOMAINDIR"} = $LOCALEDIR;
    $ENV{"TEXTDOMAIN"} = "test";
    @_ = `$maketext -s "[*,_1,directory,directories]" 5`;
};
# 9
ok($@, "");
# 10
ok($_[0], "5 directories\n");
