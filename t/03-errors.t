#! /usr/bin/perl -w
# Test suite for the behavior when something goes wrong
# Copyright (c) 2003 imacat. All rights reserved. This program is free
# software; you can redistribute it and/or modify it under the same terms
# as Perl itself.

use 5.008;
use strict;
use warnings;
use Test;

BEGIN { plan tests => 21 }

use FindBin;
use File::Spec::Functions qw(catdir);
use lib $FindBin::Bin;
use vars qw($LOCALEDIR);
$LOCALEDIR = catdir($FindBin::Bin, "locale");

# When something goes wrong
# GNU gettext never fails!
# bindtextdomain
eval {
    require T_L10N;
    $_ = T_L10N->get_handle("en");
    $_ = $_->bindtextdomain("test");
};
# 1
ok($@, "");
# 2
ok($_, undef);

# textdomain
eval {
    require T_L10N;
    $_ = T_L10N->get_handle("en");
    $_->bindtextdomain("test", $LOCALEDIR);
    $_ = $_->textdomain;
};
# 3
ok($@, "");
# 4
ok($_, undef);

# No text domain claimed yet
eval {
    require T_L10N;
    $_ = T_L10N->get_handle("en");
    $_ = $_->maketext("Hello, world!");
};
# 5
ok($@, "");
# 6
ok($_, "Hello, world!");

# Non-existing LOCALEDIR
eval {
    require T_L10N;
    $_ = T_L10N->get_handle("en");
    $_->bindtextdomain("test", "/dev/null");
    $_->textdomain("test");
    $_ = $_->maketext("Hello, world!");
};
# 7
ok($@, "");
# 8
ok($_, "Hello, world!");

# Not-registered DOMAIN
eval {
    require T_L10N;
    $_ = T_L10N->get_handle("en");
    $_->textdomain("not_registered");
    $_ = $_->maketext("Hello, world!");
};
# 9
ok($@, "");
# 10
ok($_, "Hello, world!");

# PO file not exists
eval {
    require T_L10N;
    $_ = T_L10N->get_handle("en");
    $_->bindtextdomain("no_such_domain", $LOCALEDIR);
    $_->textdomain("no_such_domain");
    $_ = $_->maketext("Hello, world!");
};
# 11
ok($@, "");
# 12
ok($_, "Hello, world!");

# PO file invalid
eval {
    require T_L10N;
    $_ = T_L10N->get_handle("en");
    $_->bindtextdomain("bad", $LOCALEDIR);
    $_->textdomain("bad");
    $_ = $_->maketext("Hello, world!");
};
# 13
ok($@, "");
# 14
ok($_, "Hello, world!");

# No such message
eval {
    require T_L10N;
    $_ = T_L10N->get_handle("en");
    $_->bindtextdomain("test", $LOCALEDIR);
    $_->textdomain("test");
    $_ = $_->maketext("non-existing message");
};
# 15
ok($@, "");
# 16
ok($_, "non-existing message");

# die_for_lookup_failures
eval {
    require T_L10N;
    $_ = T_L10N->get_handle("en");
    $_->bindtextdomain("test", $LOCALEDIR);
    $_->textdomain("test");
    $_->die_for_lookup_failures(1);
    $_ = $_->maketext("non-existing message");
};
# 17
ok($@, qr/maketext doesn't know how to say/);

# multibyte keys
eval {
    require T_L10N;
    $_ = T_L10N->get_handle("zh-tw");
    $_->bindtextdomain("test", "/dev/null");
    $_->textdomain("test");
    $_->key_encoding("Big5");
    $_ = $_->maketext("（未設定）");
};
# 18
ok($@, "");
# 19
ok($_, "（未設定）");

# Call maketext before and after binding text domain
eval {
    require T_L10N;
    $_ = T_L10N->get_handle("en");
    $_->maketext("Hello, world!");
    $_->bindtextdomain("test", $LOCALEDIR);
    $_->textdomain("test");
    $_ = $_->maketext("Hello, world!");
};
# 20
ok($@, "");
# 21
ok($_, "Hiya :)");
