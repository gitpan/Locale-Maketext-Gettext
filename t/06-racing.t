#! /usr/bin/perl -w
# Test suite for the hybrid racing condition
# Copyright (c) 2003-2007 imacat. All rights reserved. This program is free
# software; you can redistribute it and/or modify it under the same terms
# as Perl itself.

use 5.008;
use strict;
use warnings;
use Test;

BEGIN { plan tests => 34 }

use FindBin;
use File::Spec::Functions qw(catdir catfile);
use lib $FindBin::Bin;
use vars qw($LOCALEDIR $r);
$LOCALEDIR = catdir($FindBin::Bin, "locale");

# Hybrid racing conditionr
use vars qw($lh1 $lh2);
$r = eval {
    require T_L10N;
    
    $lh1 = T_L10N->get_handle("zh-tw");
    $lh1->bindtextdomain("test", $LOCALEDIR);
    $lh1->textdomain("test");
    $lh1->encoding("Big5");
    $lh1->die_for_lookup_failures(0);
    
    $lh2 = T_L10N->get_handle("zh-tw");
    $lh2->bindtextdomain("test2", $LOCALEDIR);
    $lh2->textdomain("test2");
    $lh2->encoding("UTF-8");
    $lh2->die_for_lookup_failures(1);
    return 1;
};
# 1
ok($r, 1);

# Once
$r = eval {
    $_ = $lh1->maketext("Hello, world!");
    return 1;
};
# 2
ok($_, "¤j®a¦n¡C");
$r = eval {
    $_ = $lh1->maketext("Every story has a happy ending.");
    return 1;
};
# 3
ok($_, "Every story has a happy ending.");
$r = eval {
    $_ = $lh2->maketext("Hello, world!");
    return 1;
};
# To be refined - to know that we failed at maketext()
# was ok($@, qr/maketext doesn't know how to say/);
# 4
ok($r, undef);
$r = eval {
    $_ = $lh2->maketext("Every story has a happy ending.");
    return 1;
};
# 5
ok($_, "æ•…äº‹éƒ½æœ‰ç¾Žéº—çš„çµå±€ã€‚");

# Again
$r = eval {
    $_ = $lh1->maketext("Hello, world!");
    return 1;
};
# 6
ok($_, "¤j®a¦n¡C");
$r = eval {
    $_ = $lh1->maketext("Every story has a happy ending.");
    return 1;
};
# 7
ok($_, "Every story has a happy ending.");
$r = eval {
    $_ = $lh2->maketext("Hello, world!");
    return 1;
};
# To be refined - to know that we failed at maketext()
# was ok($@, qr/maketext doesn't know how to say/);
# 8
ok($r, undef);
$r = eval {
    $_ = $lh2->maketext("Every story has a happy ending.");
    return 1;
};
# 9
ok($_, "æ•…äº‹éƒ½æœ‰ç¾Žéº—çš„çµå±€ã€‚");

# Exchange everything!
$r = eval {
    $lh1->bindtextdomain("test2", $LOCALEDIR);
    $lh1->textdomain("test2");
    $lh1->encoding("UTF-8");
    $lh1->die_for_lookup_failures(1);
    
    $lh2->bindtextdomain("test", $LOCALEDIR);
    $lh2->textdomain("test");
    $lh2->encoding("Big5");
    $lh2->die_for_lookup_failures(0);
    return 1;
};
# 10
ok($r, 1);

$r = eval {
    $_ = $lh1->maketext("Hello, world!");
    return 1;
};
# To be refined - to know that we failed at maketext()
# was ok($@, qr/maketext doesn't know how to say/);
# 11
ok($r, undef);
$r = eval {
    $_ = $lh1->maketext("Every story has a happy ending.");
    return 1;
};
# 12
ok($_, "æ•…äº‹éƒ½æœ‰ç¾Žéº—çš„çµå±€ã€‚");
$r = eval {
    $_ = $lh2->maketext("Hello, world!");
    return 1;
};
# 13
ok($_, "¤j®a¦n¡C");
$r = eval {
    $_ = $lh2->maketext("Every story has a happy ending.");
    return 1;
};
# 14
ok($_, "Every story has a happy ending.");

# Exchange the text domains
$r = eval {
    $lh1->textdomain("test");
    $lh2->textdomain("test2");
    return 1;
};
# 15
ok($r, 1);
$r = eval {
    $_ = $lh1->maketext("Hello, world!");
    return 1;
};
# 16
ok($_, "å¤§å®¶å¥½ã€‚");
$r = eval {
    $_ = $lh1->maketext("Every story has a happy ending.");
    return 1;
};
# To be refined - to know that we failed at maketext()
# was ok($@, qr/maketext doesn't know how to say/);
# 17
ok($r, undef);
$r = eval {
    $_ = $lh2->maketext("Hello, world!");
    return 1;
};
# 18
ok($_, "Hello, world!");
$r = eval {
    $_ = $lh2->maketext("Every story has a happy ending.");
    return 1;
};
# 19
ok($_, "¬G¨Æ³£¦³¬üÄRªºµ²§½¡C");

# Exchange encodings
$r = eval {
    $lh1->encoding("Big5");
    $lh2->encoding("UTF-8");
    return 1;
};
# 20
ok($r, 1);
$r = eval {
    $_ = $lh1->maketext("Hello, world!");
    return 1;
};
# 21
ok($_, "¤j®a¦n¡C");
$r = eval {
    $_ = $lh1->maketext("Every story has a happy ending.");
    return 1;
};
# To be refined - to know that we failed at maketext()
# was ok($@, qr/maketext doesn't know how to say/);
# 22
ok($r, undef);
$r = eval {
    $_ = $lh2->maketext("Hello, world!");
    return 1;
};
# 23
ok($_, "Hello, world!");
$r = eval {
    $_ = $lh2->maketext("Every story has a happy ending.");
    return 1;
};
# 24
ok($_, "æ•…äº‹éƒ½æœ‰ç¾Žéº—çš„çµå±€ã€‚");

# Exchange lookup-failure behaviors
$r = eval {
    $lh1->die_for_lookup_failures(0);
    $lh2->die_for_lookup_failures(1);
    return 1;
};
# 25
ok($r, 1);
$r = eval {
    $_ = $lh1->maketext("Hello, world!");
    return 1;
};
# 26
ok($_, "¤j®a¦n¡C");
$r = eval {
    $_ = $lh1->maketext("Every story has a happy ending.");
    return 1;
};
# 27
ok($_, "Every story has a happy ending.");
$r = eval {
    $_ = $lh2->maketext("Hello, world!");
    return 1;
};
# To be refined - to know that we failed at maketext()
# was ok($@, qr/maketext doesn't know how to say/);
# 28
ok($r, undef);
$r = eval {
    $_ = $lh2->maketext("Every story has a happy ending.");
    return 1;
};
# 29
ok($_, "æ•…äº‹éƒ½æœ‰ç¾Žéº—çš„çµå±€ã€‚");

# Switch to an non-existing domain
$r = eval {
    $lh1->textdomain("Big5");
    $lh2->textdomain("GB2312");
    return 1;
};
# 30
ok($r, 1);
$r = eval {
    $_ = $lh1->maketext("Hello, world!");
    return 1;
};
# 31
ok($_, "Hello, world!");
$r = eval {
    $_ = $lh1->maketext("Every story has a happy ending.");
    return 1;
};
# 32
ok($_, "Every story has a happy ending.");
$r = eval {
    $_ = $lh2->maketext("Hello, world!");
    return 1;
};
# To be refined - to know that we failed at maketext()
# was ok($@, qr/maketext doesn't know how to say/);
# 33
ok($r, undef);
$r = eval {
    $_ = $lh2->maketext("Every story has a happy ending.");
    return 1;
};
# To be refined - to know that we failed at maketext()
# was ok($@, qr/maketext doesn't know how to say/);
# 34
ok($r, undef);
