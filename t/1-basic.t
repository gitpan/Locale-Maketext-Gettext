#! /usr/bin/perl -w
# Basic test suite
# Copyright (c) 2003 imacat. All rights reserved. This program is free
# software; you can redistribute it and/or modify it under the same terms
# as Perl itself.

use 5.008;
use strict;
use warnings;
use Test;

BEGIN { plan tests => 14 }

use FindBin;
use File::Spec::Functions qw(catdir catfile);
use lib $FindBin::Bin;
use vars qw($LOCALEDIR);
$LOCALEDIR = catdir($FindBin::Bin, "locale");

# Basic checks
use Encode qw(decode);

# bindtextdomain
eval {
    require TestPkg::L10N;
    $_ = TestPkg::L10N->get_handle("en");
    $_->bindtextdomain("test", $LOCALEDIR);
    $_ = $_->bindtextdomain("test");
};
# 1
ok($@, "");
# 2
ok($_, "$LOCALEDIR");

# textdomain
eval {
    require TestPkg::L10N;
    $_ = TestPkg::L10N->get_handle("en");
    $_->bindtextdomain("test", $LOCALEDIR);
    $_->textdomain("test");
    $_ = $_->textdomain;
};
# 3
ok($@, "");
# 4
ok($_, "test");

# readmo
eval {
    use Locale::Maketext::Gettext;
    $_ = catfile($LOCALEDIR, "zh_TW", "LC_MESSAGES", "test.mo");
    ($_, %_) = readmo($_);
};
# 5
ok($@, "");
# 6
ok($_, "Big5");
# 7
ok(scalar(keys %_), 2);
# 8
ok($_{"Hello, world!"}, decode("Big5", "大家好。"));

# English
eval {
    require TestPkg::L10N;
    $_ = TestPkg::L10N->get_handle("en");
    $_->bindtextdomain("test", $LOCALEDIR);
    $_->textdomain("test");
    $_ = $_->maketext("Hello, world!");
};
# 9
ok($@, "");
# 10
ok($_, "Hiya :)");

# Traditional Chinese
eval {
    require TestPkg::L10N;
    $_ = TestPkg::L10N->get_handle("zh-tw");
    $_->bindtextdomain("test", $LOCALEDIR);
    $_->textdomain("test");
    $_ = $_->maketext("Hello, world!");
};
# 11
ok($@, "");
# 12
ok($_, "大家好。");

# Simplified Chinese
eval {
    require TestPkg::L10N;
    $_ = TestPkg::L10N->get_handle("zh-cn");
    $_->bindtextdomain("test", $LOCALEDIR);
    $_->textdomain("test");
    $_ = $_->maketext("Hello, world!");
};
# 13
ok($@, "");
# 14
ok($_, "湮模疑﹝");
