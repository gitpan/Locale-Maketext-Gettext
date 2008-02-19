#! /usr/bin/perl -w
# Test suite for the behavior when something goes wrong
# Copyright (c) 2003-2008 imacat. All rights reserved. This program is free
# software; you can redistribute it and/or modify it under the same terms
# as Perl itself.

use 5.008;
use strict;
use warnings;
use Test;

BEGIN { plan tests => 29 }

use FindBin;
use File::Spec::Functions qw(catdir);
use lib $FindBin::Bin;
use vars qw($LOCALEDIR $r);
$LOCALEDIR = catdir($FindBin::Bin, "locale");

# When something goes wrong
use vars qw($dir $domain $lang $skip);
# GNU gettext never fails!
# bindtextdomain
$r = eval {
    require T_L10N;
    $_ = T_L10N->get_handle("en");
    $_ = $_->bindtextdomain("test");
    return 1;
};
# 1
ok($r, 1);
# 2
ok($_, undef);

# textdomain
$r = eval {
    require T_L10N;
    $_ = T_L10N->get_handle("en");
    $_->bindtextdomain("test", $LOCALEDIR);
    $_ = $_->textdomain;
    return 1;
};
# 3
ok($r, 1);
# 4
ok($_, undef);

# No text domain claimed yet
$r = eval {
    require T_L10N;
    $_ = T_L10N->get_handle("en");
    $_ = $_->maketext("Hello, world!");
    return 1;
};
# 5
ok($r, 1);
# 6
ok($_, "Hello, world!");

# Non-existing LOCALEDIR
$r = eval {
    require T_L10N;
    $_ = T_L10N->get_handle("en");
    $_->bindtextdomain("test", "/dev/null");
    $_->textdomain("test");
    $_ = $_->maketext("Hello, world!");
    return 1;
};
# 7
ok($r, 1);
# 8
ok($_, "Hello, world!");

# Not-registered DOMAIN
$r = eval {
    require T_L10N;
    $_ = T_L10N->get_handle("en");
    $_->textdomain("not_registered");
    $_ = $_->maketext("Hello, world!");
    return 1;
};
# 9
ok($r, 1);
# 10
ok($_, "Hello, world!");

# PO file not exists
$r = eval {
    require T_L10N;
    $_ = T_L10N->get_handle("en");
    $_->bindtextdomain("no_such_domain", $LOCALEDIR);
    $_->textdomain("no_such_domain");
    $_ = $_->maketext("Hello, world!");
    return 1;
};
# 11
ok($r, 1);
# 12
ok($_, "Hello, world!");

# PO file invalid
$r = eval {
    require T_L10N;
    $_ = T_L10N->get_handle("en");
    $_->bindtextdomain("bad", $LOCALEDIR);
    $_->textdomain("bad");
    $_ = $_->maketext("Hello, world!");
    return 1;
};
# 13
ok($r, 1);
# 14
ok($_, "Hello, world!");

# No such message
$r = eval {
    require T_L10N;
    @_ = qw();
    $_ = T_L10N->get_handle("en");
    $_->bindtextdomain("test", $LOCALEDIR);
    $_->textdomain("test");
    $_[0] = $_->maketext("[*,_1,non-existing message,non-existing messages]", 1);
    $_[1] = $_->maketext("[*,_1,non-existing message,non-existing messages]", 3);
    $_[2] = $_->pmaketext("Menu|View|", "[*,_1,non-existing message,non-existing messages]", 1);
    $_[3] = $_->pmaketext("Menu|View|", "[*,_1,non-existing message,non-existing messages]", 3);
    $_[4] = $_->pmaketext("Menu|None|", "Hello, world!");
    return 1;
};
# 15
ok($r, 1);
# 16
ok($_[0], "1 non-existing message");
# 17
ok($_[1], "3 non-existing messages");
# 18
ok($_[2], "1 non-existing message");
# 19
ok($_[3], "3 non-existing messages");
# 20
ok($_[4], "Hello, world!");

# die_for_lookup_failures
$r = eval {
    require T_L10N;
    $_ = T_L10N->get_handle("en");
    $_->bindtextdomain("test", $LOCALEDIR);
    $_->textdomain("test");
    $_->die_for_lookup_failures(1);
    $_ = $_->maketext("non-existing message");
    return 1;
};
# To be refined - to know that we failed at maketext()
# was ok($@, qr/maketext doesn't know how to say/);
# 21
ok($r, undef);

# multibyte keys
$r = eval {
    require T_L10N;
    $_ = T_L10N->get_handle("zh-tw");
    $_->bindtextdomain("test", $LOCALEDIR);
    $_->textdomain("test");
    $_->key_encoding("Big5");
    $_ = $_->maketext("（未設定）");
    return 1;
};
# 22
ok($r, 1);
# 23
ok($_, "（未設定）");

$r = eval {
    require T_L10N;
    $_ = T_L10N->get_handle("zh-tw");
    $_->bindtextdomain("test", "/dev/null");
    $_->textdomain("test");
    $_->key_encoding("Big5");
    $_ = $_->maketext("（未設定）");
    return 1;
};
# 24
ok($r, 1);
# 25
ok($_, "（未設定）");

# Call maketext before and after binding text domain
$r = eval {
    require T_L10N;
    $_ = T_L10N->get_handle("en");
    $_->maketext("Hello, world!");
    $_->bindtextdomain("test", $LOCALEDIR);
    $_->textdomain("test");
    $_ = $_->maketext("Hello, world!");
    return 1;
};
# 26
ok($r, 1);
# 27
ok($_, "Hiya :)");

# Search system locale directories
use Locale::Maketext::Gettext;
undef $domain;
foreach $dir (@Locale::Maketext::Gettext::SYSTEM_LOCALEDIRS) {
    next unless -d $dir;
    # Only valid in the language range of T_L10N
    if (scalar(@_) == 0) {
        @_ = glob "$dir/zh_TW/LC_MESSAGES/*.mo";
        @_ = grep /\/[^\/\.]+\/LC_MESSAGES\//, @_;
    }
    if (scalar(@_) == 0) {
        @_ = glob "$dir/zh_CN/LC_MESSAGES/*.mo" if scalar(@_) == 0;
        @_ = grep /\/[^\/\.]+\/LC_MESSAGES\//, @_;
    }
    next if scalar(@_) == 0;
    $_ = $_[0];
    /^\Q$dir\E\/(.+?)\/LC_MESSAGES\/(.+?)\.mo$/;
    ($domain, $lang) = ($2, $1);
    $lang = lc $lang;
    $lang =~ s/_/-/g;
    $lang = "i-default" if $lang eq "c";
    last;
}
$skip = defined $domain? 0: 1;
if (!$skip) {
    $r = eval {
        require T_L10N;
        $_ = T_L10N->get_handle($lang);
        $_->textdomain($domain);
        $_ = $_->maketext("");
        # Skip if $Lexicon{""} does not exists
        $skip = 1 if $_ eq "";
        return 1;
    };
}
# 28
skip($skip, $r, 1);
# 29
skip($skip, $_, qr/Project-Id-Version:/);
