#! /usr/bin/perl -w
# Basic test suite for the functional interface
# Copyright (c) 2003-2005 imacat. All rights reserved. This program is free
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
use vars qw($LOCALEDIR);
$LOCALEDIR = catdir($FindBin::Bin, "locale");
delete $ENV{$_}
    foreach qw(LANGUAGE LC_ALL LC_CTYPE LC_COLLATE LC_MESSAGES LC_NUMERIC
                LC_MONETARY LC_TIME LANG);

# Basic test suite
# bindtextdomain
eval {
    use Locale::Maketext::Gettext::Functions;
    Locale::Maketext::Gettext::Functions::_reset();
    $_ = bindtextdomain("test", $LOCALEDIR);
};
# 1
ok($@, "");
# 2
ok($_, $LOCALEDIR);

# textdomain
eval {
    use Locale::Maketext::Gettext::Functions;
    Locale::Maketext::Gettext::Functions::_reset();
    bindtextdomain("test", $LOCALEDIR);
    $_ = textdomain("test");
};
# 3
ok($@, "");
# 4
ok($_, "test");

# get_handle
eval {
    use Locale::Maketext::Gettext::Functions;
    Locale::Maketext::Gettext::Functions::_reset();
    bindtextdomain("test", $LOCALEDIR);
    textdomain("test");
    get_handle("en");
};
# 5
ok($@, "");

# maketext
eval {
    use Locale::Maketext::Gettext::Functions;
    Locale::Maketext::Gettext::Functions::_reset();
    bindtextdomain("test", $LOCALEDIR);
    textdomain("test");
    get_handle("en");
    $_ = maketext("Hello, world!");
};
# 6
ok($@, "");
# 7
ok($_, "Hiya :)");

# __ (shortcut to maketext)
eval {
    use Locale::Maketext::Gettext::Functions;
    Locale::Maketext::Gettext::Functions::_reset();
    bindtextdomain("test", $LOCALEDIR);
    textdomain("test");
    get_handle("en");
    $_ = __("Hello, world!");
};
# 8
ok($@, "");
# 9
ok($_, "Hiya :)");

# N_ (do nothing)
eval {
    use Locale::Maketext::Gettext::Functions;
    Locale::Maketext::Gettext::Functions::_reset();
    bindtextdomain("test", $LOCALEDIR);
    textdomain("test");
    get_handle("en");
    $_ = N_("Hello, world!");
};
# 10
ok($@, "");
# 11
ok($_, "Hello, world!");

# N_ (do nothing)
eval {
    use Locale::Maketext::Gettext::Functions;
    Locale::Maketext::Gettext::Functions::_reset();
    bindtextdomain("test", $LOCALEDIR);
    textdomain("test");
    get_handle("en");
    # ゅ硂采﹁ナ :p From: 芖臨艵
    @_ = N_("Hello, world!", "Cool!", "Big watermelon");
};
# 12
ok($@, "");
# 13
ok($_[0], "Hello, world!");
# 14
ok($_[1], "Cool!");
# 15
ok($_[2], "Big watermelon");

eval {
    use Locale::Maketext::Gettext::Functions;
    Locale::Maketext::Gettext::Functions::_reset();
    bindtextdomain("test", $LOCALEDIR);
    textdomain("test");
    get_handle("en");
    $_ = N_("Hello, world!");
};
# 16
ok($@, "");
# 17
ok($_, "Hello, world!");

# maketext
# English
eval {
    use Locale::Maketext::Gettext::Functions;
    Locale::Maketext::Gettext::Functions::_reset();
    bindtextdomain("test", $LOCALEDIR);
    textdomain("test");
    get_handle("en");
    $_ = __("Hello, world!");
};
# 18
ok($@, "");
# 19
ok($_, "Hiya :)");

# Traditional Chinese
eval {
    use Locale::Maketext::Gettext::Functions;
    Locale::Maketext::Gettext::Functions::_reset();
    bindtextdomain("test", $LOCALEDIR);
    textdomain("test");
    get_handle("zh-tw");
    $_ = __("Hello, world!");
};
# 20
ok($@, "");
# 21
ok($_, "產");

# Simplified Chinese
eval {
    use Locale::Maketext::Gettext::Functions;
    Locale::Maketext::Gettext::Functions::_reset();
    bindtextdomain("test", $LOCALEDIR);
    textdomain("test");
    get_handle("zh-cn");
    $_ = __("Hello, world!");
};
# 22
ok($@, "");
# 23
ok($_, "大家好。");

# maketext - by environment
# English
eval {
    use Locale::Maketext::Gettext::Functions;
    Locale::Maketext::Gettext::Functions::_reset();
    bindtextdomain("test", $LOCALEDIR);
    textdomain("test");
    $ENV{"LANG"} = "en";
    get_handle();
    $_ = __("Hello, world!");
};
# 24
ok($@, "");
# 25
ok($_, "Hiya :)");

# Traditional Chinese
eval {
    use Locale::Maketext::Gettext::Functions;
    Locale::Maketext::Gettext::Functions::_reset();
    bindtextdomain("test", $LOCALEDIR);
    textdomain("test");
    $ENV{"LANG"} = "zh-tw";
    get_handle();
    $_ = __("Hello, world!");
};
# 26
ok($@, "");
# 27
ok($_, "產");

# Simplified Chinese
eval {
    use Locale::Maketext::Gettext::Functions;
    Locale::Maketext::Gettext::Functions::_reset();
    bindtextdomain("test", $LOCALEDIR);
    textdomain("test");
    $ENV{"LANG"} = "zh-cn";
    get_handle();
    $_ = __("Hello, world!");
};
# 28
ok($@, "");
# 29
ok($_, "大家好。");
