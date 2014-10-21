#! /usr/bin/perl -w
# Test suite for the behavior when something went wrong
# Copyright (c) 2003 imacat. All rights reserved. This program is free
# software; you can redistribute it and/or modify it under the same terms
# as Perl itself.

use 5.008;
use strict;
use warnings;
use Test;

BEGIN { plan tests => 17 }

use FindBin;
use File::Spec::Functions qw(catdir);
use lib $FindBin::Bin;
use vars qw($LOCALEDIR);
$LOCALEDIR = catdir($FindBin::Bin, "locale");

# When something went wrong
# GNU gettext never fails!
# bindtextdomain
eval {
    require TestPkg::L10N;
    $_ = TestPkg::L10N->get_handle("en");
    $_ = $_->bindtextdomain("test");
};
# 1
ok($@, "");
# 2
ok($_, undef);

# textdomain
eval {
    require TestPkg::L10N;
    $_ = TestPkg::L10N->get_handle("en");
    $_->bindtextdomain("test", $LOCALEDIR);
    $_ = $_->textdomain;
};
# 3
ok($@, "");
# 4
ok($_, undef);

# No text domain claimed yet
eval {
    require TestPkg::L10N;
    $_ = TestPkg::L10N->get_handle("en");
    $_ = $_->maketext("Hello, world!");
};
# 5
ok($@, "");
# 6
ok($_, "Hello, world!");

# Non-existing LOCALEDIR
eval {
    require TestPkg::L10N;
    $_ = TestPkg::L10N->get_handle("en");
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
    require TestPkg::L10N;
    $_ = TestPkg::L10N->get_handle("en");
    $_->textdomain("not_registered");
    $_ = $_->maketext("Hello, world!");
};
# 9
ok($@, "");
# 10
ok($_, "Hello, world!");

# PO file not exists
eval {
    require TestPkg::L10N;
    $_ = TestPkg::L10N->get_handle("en");
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
    require TestPkg::L10N;
    $_ = TestPkg::L10N->get_handle("en");
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
    require TestPkg::L10N;
    $_ = TestPkg::L10N->get_handle("en");
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
    require TestPkg::L10N;
    $_ = TestPkg::L10N->get_handle("en");
    $_->bindtextdomain("test", $LOCALEDIR);
    $_->textdomain("test");
    $_->die_for_lookup_failures(1);
    $_ = $_->maketext("non-existing message");
};
# 17
ok($@, qr/maketext doesn't know how to say/);
