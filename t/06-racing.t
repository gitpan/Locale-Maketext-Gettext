#! /usr/bin/perl -w
# Test suite for the hybrid racing condition
# Copyright (c) 2003 imacat. All rights reserved. This program is free
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
use vars qw($LOCALEDIR);
$LOCALEDIR = catdir($FindBin::Bin, "locale");

# Hybrid racing conditionr
use vars qw($lh1 $lh2);
eval {
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
};
# 1
ok($@, "");

# Once
eval {
    $_ = $lh1->maketext("Hello, world!");
};
# 2
ok($_, "¤j®a¦n¡C");
eval {
    $_ = $lh1->maketext("Every story has a happy ending.");
};
# 3
ok($_, "Every story has a happy ending.");
eval {
    $_ = $lh2->maketext("Hello, world!");
};
# 4
ok($@, qr/maketext doesn't know how to say/);
eval {
    $_ = $lh2->maketext("Every story has a happy ending.");
};
# 5
ok($_, "æ•…äº‹éƒ½æœ‰ç¾Žéº—çš„çµå±€ã€‚");

# Again
eval {
    $_ = $lh1->maketext("Hello, world!");
};
# 6
ok($_, "¤j®a¦n¡C");
eval {
    $_ = $lh1->maketext("Every story has a happy ending.");
};
# 7
ok($_, "Every story has a happy ending.");
eval {
    $_ = $lh2->maketext("Hello, world!");
};
# 8
ok($@, qr/maketext doesn't know how to say/);
eval {
    $_ = $lh2->maketext("Every story has a happy ending.");
};
# 9
ok($_, "æ•…äº‹éƒ½æœ‰ç¾Žéº—çš„çµå±€ã€‚");

# Exchange everything!
eval {
    $lh1->bindtextdomain("test2", $LOCALEDIR);
    $lh1->textdomain("test2");
    $lh1->encoding("UTF-8");
    $lh1->die_for_lookup_failures(1);
    
    $lh2->bindtextdomain("test", $LOCALEDIR);
    $lh2->textdomain("test");
    $lh2->encoding("Big5");
    $lh2->die_for_lookup_failures(0);
};

# 10
ok($@, "");
eval {
    $_ = $lh1->maketext("Hello, world!");
};
# 11
ok($@, qr/maketext doesn't know how to say/);
eval {
    $_ = $lh1->maketext("Every story has a happy ending.");
};
# 12
ok($_, "æ•…äº‹éƒ½æœ‰ç¾Žéº—çš„çµå±€ã€‚");
eval {
    $_ = $lh2->maketext("Hello, world!");
};
# 13
ok($_, "¤j®a¦n¡C");
eval {
    $_ = $lh2->maketext("Every story has a happy ending.");
};
# 14
ok($_, "Every story has a happy ending.");

# Exchange the text domains
eval {
    $lh1->textdomain("test");
    $lh2->textdomain("test2");
};
# 15
ok($@, "");
eval {
    $_ = $lh1->maketext("Hello, world!");
};
# 16
ok($_, "å¤§å®¶å¥½ã€‚");
eval {
    $_ = $lh1->maketext("Every story has a happy ending.");
};
# 17
ok($@, qr/maketext doesn't know how to say/);
eval {
    $_ = $lh2->maketext("Hello, world!");
};
# 18
ok($_, "Hello, world!");
eval {
    $_ = $lh2->maketext("Every story has a happy ending.");
};
# 19
ok($_, "¬G¨Æ³£¦³¬üÄRªºµ²§½¡C");

# Exchange encodings
eval {
    $lh1->encoding("Big5");
    $lh2->encoding("UTF-8");
};
# 20
ok($@, "");
eval {
    $_ = $lh1->maketext("Hello, world!");
};
# 21
ok($_, "¤j®a¦n¡C");
eval {
    $_ = $lh1->maketext("Every story has a happy ending.");
};
# 22
ok($@, qr/maketext doesn't know how to say/);
eval {
    $_ = $lh2->maketext("Hello, world!");
};
# 23
ok($_, "Hello, world!");
eval {
    $_ = $lh2->maketext("Every story has a happy ending.");
};
# 24
ok($_, "æ•…äº‹éƒ½æœ‰ç¾Žéº—çš„çµå±€ã€‚");

# Exchange lookup-failure behaviors
eval {
    $lh1->die_for_lookup_failures(0);
    $lh2->die_for_lookup_failures(1);
};
# 25
ok($@, "");
eval {
    $_ = $lh1->maketext("Hello, world!");
};
# 26
ok($_, "¤j®a¦n¡C");
eval {
    $_ = $lh1->maketext("Every story has a happy ending.");
};
# 27
ok($_, "Every story has a happy ending.");
eval {
    $_ = $lh2->maketext("Hello, world!");
};
# 28
ok($@, qr/maketext doesn't know how to say/);
eval {
    $_ = $lh2->maketext("Every story has a happy ending.");
};
# 29
ok($_, "æ•…äº‹éƒ½æœ‰ç¾Žéº—çš„çµå±€ã€‚");

# Switch to an non-existing domain
eval {
    $lh1->textdomain("Big5");
    $lh2->textdomain("GB2312");
};
# 30
ok($@, "");
eval {
    $_ = $lh1->maketext("Hello, world!");
};
# 31
ok($_, "Hello, world!");
eval {
    $_ = $lh1->maketext("Every story has a happy ending.");
};
# 32
ok($_, "Every story has a happy ending.");
eval {
    $_ = $lh2->maketext("Hello, world!");
};
# 33
ok($@, qr/maketext doesn't know how to say/);
eval {
    $_ = $lh2->maketext("Every story has a happy ending.");
};
# 34
ok($@, qr/maketext doesn't know how to say/);
