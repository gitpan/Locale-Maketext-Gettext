#! /usr/bin/perl -w
# Test suite on the functional interface for the behavior when something goes wrong
# Copyright (c) 2003 imacat. All rights reserved. This program is free
# software; you can redistribute it and/or modify it under the same terms
# as Perl itself.

use 5.008;
use strict;
use warnings;
use Test;

BEGIN { plan tests => 35 }

use FindBin;
use File::Spec::Functions qw(catdir);
use lib $FindBin::Bin;
use vars qw($LOCALEDIR);
$LOCALEDIR = catdir($FindBin::Bin, "locale");

# When something goes wrong
use vars qw($dir $domain $lang $skip);
# GNU gettext never fails!
# bindtextdomain
eval {
    use Locale::Maketext::Gettext::Functions;
    $_ = bindtextdomain("test");
};
# 1
ok($@, "");
# 2
ok($_, undef);

# textdomain
eval {
    use Locale::Maketext::Gettext::Functions;
    bindtextdomain("test", $LOCALEDIR);
    $_ = textdomain;
};
# 3
ok($@, "");
# 4
ok($_, undef);

# No text domain claimed yet
eval {
    use Locale::Maketext::Gettext::Functions;
    $_ = __("Hello, world!");
};
# 5
ok($@, "");
# 6
ok($_, "Hello, world!");

# Non-existing LOCALEDIR
eval {
    use Locale::Maketext::Gettext::Functions;
    bindtextdomain("test", "/dev/null");
    textdomain("test");
    $_ = __("Hello, world!");
};
# 7
ok($@, "");
# 8
ok($_, "Hello, world!");

# Not-registered DOMAIN
eval {
    use Locale::Maketext::Gettext::Functions;
    textdomain("not_registered");
    $_ = __("Hello, world!");
};
# 9
ok($@, "");
# 10
ok($_, "Hello, world!");

# PO file not exists
eval {
    use Locale::Maketext::Gettext::Functions;
    bindtextdomain("no_such_domain", $LOCALEDIR);
    textdomain("no_such_domain");
    $_ = __("Hello, world!");
};
# 11
ok($@, "");
# 12
ok($_, "Hello, world!");

# PO file invalid
eval {
    use Locale::Maketext::Gettext::Functions;
    bindtextdomain("bad", $LOCALEDIR);
    textdomain("bad");
    $_ = __("Hello, world!");
};
# 13
ok($@, "");
# 14
ok($_, "Hello, world!");

# No such message
eval {
    use Locale::Maketext::Gettext::Functions;
    bindtextdomain("test", $LOCALEDIR);
    textdomain("test");
    get_handle("en");
    $_ = __("non-existing message");
};
# 15
ok($@, "");
# 16
ok($_, "non-existing message");

# get_handle before textdomain
eval {
    use Locale::Maketext::Gettext::Functions;
    get_handle("en");
    bindtextdomain("test", $LOCALEDIR);
    textdomain("test");
    $_ = __("Hello, world!");
};
# 17
ok($@, "");
# 18
ok($_, "Hiya :)");

# bindtextdomain after textdomain
eval {
    use Locale::Maketext::Gettext::Functions;
    get_handle("en");
    textdomain("test2");
    bindtextdomain("test2", $LOCALEDIR);
    $_ = __("Every story has a happy ending.");
};
# 19
ok($@, "");
# 20
ok($_, "Pray it.");

# multibyte keys
eval {
    use Locale::Maketext::Gettext::Functions;
    bindtextdomain("test", $LOCALEDIR);
    textdomain("test");
    get_handle("zh-tw");
    key_encoding("Big5");
    $_ = maketext("（未設定）");
    undef $Locale::Maketext::Gettext::Functions::KEY_ENCODING;
};
# 21
ok($@, "");
# 22
ok($_, "（未設定）");

eval {
    use Locale::Maketext::Gettext::Functions;
    bindtextdomain("test", "/dev/null");
    textdomain("test");
    get_handle("zh-tw");
    key_encoding("Big5");
    $_ = maketext("（未設定）");
    undef $Locale::Maketext::Gettext::Functions::KEY_ENCODING;
};
# 23
ok($@, "");
# 24
ok($_, "（未設定）");

# Maketext before and after binding text domain
eval {
    use Locale::Maketext::Gettext::Functions;
    __("Hello, world!");
    bindtextdomain("test", $LOCALEDIR);
    textdomain("test");
    get_handle("en");
    $_ = __("Hello, world!");
};
# 25
ok($@, "");
# 26
ok($_, "Hiya :)");

# Switch to a domain that is not binded yet
eval {
    use Locale::Maketext::Gettext::Functions;
    get_handle("en");
    bindtextdomain("test", $LOCALEDIR);
    textdomain("test");
    textdomain("test2");
    $_ = __("Hello, world!");
};
# 27
ok($@, "");
# 28
ok($_, "Hello, world!");

# N_: different context - string to array
eval {
    use Locale::Maketext::Gettext::Functions;
    bindtextdomain("test", $LOCALEDIR);
    textdomain("test");
    get_handle("en");
    @_ = N_("Hello, world!");
};
# 29
ok($@, "");
# 30
ok($_[0], "Hello, world!");
# 31
ok($_[1], undef);

# N_: different context - array to string
eval {
    use Locale::Maketext::Gettext::Functions;
    bindtextdomain("test", $LOCALEDIR);
    textdomain("test");
    get_handle("en");
    $_ = N_("Hello, world!", "Cool!", "Big watermelon");
};
# 32
ok($@, "");
# 33
ok($_, "Hello, world!");

# Search system locale directories
use Locale::Maketext::Gettext::Functions;
undef $domain;
foreach $dir (@Locale::Maketext::Gettext::Functions::SYSTEM_LOCALEDIRS) {
    next unless -d $dir;
    @_ = glob "$dir/*/LC_MESSAGES/*.mo";
    next if scalar(@_) == 0;
    $_ = $_[0];
    /^\Q$dir\E\/(.+?)\/LC_MESSAGES\/(.+?)\.mo$/;
    ($domain, $lang) = ($2, $1);
    $lang = lc $lang;
    $lang =~ s/_/-/g;
    last;
}
$skip = defined $domain? 0: 1;
if (!$skip) {
    eval {
        use Locale::Maketext::Gettext::Functions;
        textdomain($domain);
        get_handle($lang);
        $_ = maketext("");
    };
}
# 34
skip($skip, $@, "");
# 35
skip($skip, $_, qr/Project-Id-Version:/);
