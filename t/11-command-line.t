#! /usr/bin/perl -w
# Test suite on the maketext script
# Copyright (c) 2003 imacat. All rights reserved. This program is free
# software; you can redistribute it and/or modify it under the same terms
# as Perl itself.

use 5.008;
use strict;
use warnings;
use Test;

BEGIN { plan tests => 18 }

use FindBin;
use File::Spec::Functions qw(catdir catfile updir);
use lib $FindBin::Bin;
use vars qw($LOCALEDIR $maketext);
$LOCALEDIR = catdir($FindBin::Bin, "locale");
$maketext = catdir($FindBin::Bin, updir, "bin", "maketext");

# The maketext script
# Ordinary text unchanged
eval {
    delete $ENV{"LANG"};
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
    $ENV{"LANG"} = "en";
    $ENV{"TEXTDOMAINDIR"} = $LOCALEDIR;
    delete $ENV{"TEXTDOMAIN"};
    @_ = `$maketext -d test "Hello, world!"`;
};
# 3
ok($@, "");
# 4
ok($_[0], "Hiya :)");

# Traditional Chinese
eval {
    $ENV{"LANG"} = "zh-tw";
    $ENV{"TEXTDOMAINDIR"} = $LOCALEDIR;
    delete $ENV{"TEXTDOMAIN"};
    @_ = `$maketext -d test "Hello, world!"`;
};
# 5
ok($@, "");
# 6
ok($_[0], "產");

# Simplified Chinese
eval {
    $ENV{"LANG"} = "zh-cn";
    $ENV{"TEXTDOMAINDIR"} = $LOCALEDIR;
    delete $ENV{"TEXTDOMAIN"};
    @_ = `$maketext -d test "Hello, world!"`;
};
# 7
ok($@, "");
# 8
ok($_[0], "大家好。");

# Specify the text domain by the environment variable
# English
eval {
    $ENV{"LANG"} = "en";
    $ENV{"TEXTDOMAINDIR"} = $LOCALEDIR;
    $ENV{"TEXTDOMAIN"} = "test";
    @_ = `$maketext "Hello, world!"`;
};
# 9
ok($@, "");
# 10
ok($_[0], "Hiya :)");

# Traditional Chinese
eval {
    $ENV{"LANG"} = "zh-tw";
    $ENV{"TEXTDOMAINDIR"} = $LOCALEDIR;
    $ENV{"TEXTDOMAIN"} = "test";
    @_ = `$maketext "Hello, world!"`;
};
# 11
ok($@, "");
# 12
ok($_[0], "產");

# Simplified Chinese
eval {
    $ENV{"LANG"} = "zh-cn";
    $ENV{"TEXTDOMAINDIR"} = $LOCALEDIR;
    $ENV{"TEXTDOMAIN"} = "test";
    @_ = `$maketext "Hello, world!"`;
};
# 13
ok($@, "");
# 14
ok($_[0], "大家好。");

# The -s argument
eval {
    $ENV{"LANG"} = "en";
    $ENV{"TEXTDOMAINDIR"} = $LOCALEDIR;
    $ENV{"TEXTDOMAIN"} = "test";
    @_ = `$maketext -s "Hello, world!"`;
};
# 15
ok($@, "");
# 16
ok($_[0], "Hiya :)\n");

# Maketext
eval {
    $ENV{"LANG"} = "en";
    $ENV{"TEXTDOMAINDIR"} = $LOCALEDIR;
    $ENV{"TEXTDOMAIN"} = "test";
    @_ = `$maketext -s "[*,_1,directory,directories]" 5`;
};
# 17
ok($@, "");
# 18
ok($_[0], "5 directories\n");
