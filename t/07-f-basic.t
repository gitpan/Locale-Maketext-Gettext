#! /usr/bin/perl -w
# Basic test suite for the functional interface
# Copyright (c) 2003-2007 imacat. All rights reserved. This program is free
# software; you can redistribute it and/or modify it under the same terms
# as Perl itself.

use 5.008;
use strict;
use warnings;
use Test;

BEGIN { plan tests => 29 }

use FindBin;
use File::Spec::Functions qw(catdir catfile);
use lib $FindBin::Bin;
use vars qw($LOCALEDIR $r);
$LOCALEDIR = catdir($FindBin::Bin, "locale");
delete $ENV{$_}
    foreach qw(LANGUAGE LC_ALL LC_CTYPE LC_COLLATE LC_MESSAGES LC_NUMERIC
                LC_MONETARY LC_TIME LANG);

# Basic test suite
# bindtextdomain
$r = eval {
    use Locale::Maketext::Gettext::Functions;
    $_ = bindtextdomain("test", $LOCALEDIR);
    Locale::Maketext::Gettext::Functions::_reset();
    return 1;
};
# 1
ok($r, 1);
# 2
ok($_, $LOCALEDIR);

# textdomain
$r = eval {
    use Locale::Maketext::Gettext::Functions;
    bindtextdomain("test", $LOCALEDIR);
    $_ = textdomain("test");
    Locale::Maketext::Gettext::Functions::_reset();
    return 1;
};
# 3
ok($r, 1);
# 4
ok($_, "test");

# get_handle
$r = eval {
    use Locale::Maketext::Gettext::Functions;
    bindtextdomain("test", $LOCALEDIR);
    textdomain("test");
    get_handle("en");
    Locale::Maketext::Gettext::Functions::_reset();
    return 1;
};
# 5
ok($r, 1);

# maketext
$r = eval {
    use Locale::Maketext::Gettext::Functions;
    bindtextdomain("test", $LOCALEDIR);
    textdomain("test");
    get_handle("en");
    $_ = maketext("Hello, world!");
    Locale::Maketext::Gettext::Functions::_reset();
    return 1;
};
# 6
ok($r, 1);
# 7
ok($_, "Hiya :)");

# __ (shortcut to maketext)
$r = eval {
    use Locale::Maketext::Gettext::Functions;
    bindtextdomain("test", $LOCALEDIR);
    textdomain("test");
    get_handle("en");
    $_ = __("Hello, world!");
    Locale::Maketext::Gettext::Functions::_reset();
    return 1;
};
# 8
ok($r, 1);
# 9
ok($_, "Hiya :)");

# N_ (do nothing)
$r = eval {
    use Locale::Maketext::Gettext::Functions;
    bindtextdomain("test", $LOCALEDIR);
    textdomain("test");
    get_handle("en");
    $_ = N_("Hello, world!");
    Locale::Maketext::Gettext::Functions::_reset();
    return 1;
};
# 10
ok($r, 1);
# 11
ok($_, "Hello, world!");

# N_ (do nothing)
$r = eval {
    use Locale::Maketext::Gettext::Functions;
    bindtextdomain("test", $LOCALEDIR);
    textdomain("test");
    get_handle("en");
    # ゅ硂采﹁ナ :p From: 芖臨艵
    @_ = N_("Hello, world!", "Cool!", "Big watermelon");
    Locale::Maketext::Gettext::Functions::_reset();
    return 1;
};
# 12
ok($r, 1);
# 13
ok($_[0], "Hello, world!");
# 14
ok($_[1], "Cool!");
# 15
ok($_[2], "Big watermelon");

$r = eval {
    use Locale::Maketext::Gettext::Functions;
    bindtextdomain("test", $LOCALEDIR);
    textdomain("test");
    get_handle("en");
    $_ = N_("Hello, world!");
    Locale::Maketext::Gettext::Functions::_reset();
    return 1;
};
# 16
ok($r, 1);
# 17
ok($_, "Hello, world!");

# maketext
# English
$r = eval {
    use Locale::Maketext::Gettext::Functions;
    bindtextdomain("test", $LOCALEDIR);
    textdomain("test");
    get_handle("en");
    $_ = __("Hello, world!");
    Locale::Maketext::Gettext::Functions::_reset();
    return 1;
};
# 18
ok($r, 1);
# 19
ok($_, "Hiya :)");

# Traditional Chinese
$r = eval {
    use Locale::Maketext::Gettext::Functions;
    bindtextdomain("test", $LOCALEDIR);
    textdomain("test");
    get_handle("zh-tw");
    $_ = __("Hello, world!");
    Locale::Maketext::Gettext::Functions::_reset();
    return 1;
};
# 20
ok($r, 1);
# 21
ok($_, "產");

# Simplified Chinese
$r = eval {
    use Locale::Maketext::Gettext::Functions;
    bindtextdomain("test", $LOCALEDIR);
    textdomain("test");
    get_handle("zh-cn");
    $_ = __("Hello, world!");
    Locale::Maketext::Gettext::Functions::_reset();
    return 1;
};
# 22
ok($r, 1);
# 23
ok($_, "大家好。");

# maketext - by environment
# English
$r = eval {
    use Locale::Maketext::Gettext::Functions;
    bindtextdomain("test", $LOCALEDIR);
    textdomain("test");
    $ENV{"LANG"} = "en";
    get_handle();
    $_ = __("Hello, world!");
    Locale::Maketext::Gettext::Functions::_reset();
    return 1;
};
# 24
ok($r, 1);
# 25
ok($_, "Hiya :)");

# Traditional Chinese
$r = eval {
    use Locale::Maketext::Gettext::Functions;
    bindtextdomain("test", $LOCALEDIR);
    textdomain("test");
    $ENV{"LANG"} = "zh-tw";
    get_handle();
    $_ = __("Hello, world!");
    Locale::Maketext::Gettext::Functions::_reset();
    return 1;
};
# 26
ok($r, 1);
# 27
ok($_, "產");

# Simplified Chinese
$r = eval {
    use Locale::Maketext::Gettext::Functions;
    bindtextdomain("test", $LOCALEDIR);
    textdomain("test");
    $ENV{"LANG"} = "zh-cn";
    get_handle();
    $_ = __("Hello, world!");
    Locale::Maketext::Gettext::Functions::_reset();
    return 1;
};
# 28
ok($r, 1);
# 29
ok($_, "大家好。");
