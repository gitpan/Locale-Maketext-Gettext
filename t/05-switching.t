#! /usr/bin/perl -w
# Test suite for switching between different settings
# Copyright (c) 2003 imacat. All rights reserved. This program is free
# software; you can redistribute it and/or modify it under the same terms
# as Perl itself.

use 5.008;
use strict;
use warnings;
use Test;

BEGIN { plan tests => 25 }

use FindBin;
use File::Spec::Functions qw(catdir catfile);
use lib $FindBin::Bin;
use vars qw($LOCALEDIR);
$LOCALEDIR = catdir($FindBin::Bin, "locale");

# Switching between different settings
use vars qw($lh1 $lh2 $t1 $t2 $t3 $t4 $t5 $t6 $dir $f $f1 $f2);
# 2 language handles of the same localization subclass
eval {
    require T_L10N;
    $lh1 = T_L10N->get_handle("en");
    $lh1->bindtextdomain("test", $LOCALEDIR);
    $lh1->textdomain("test");
    $lh2 = T_L10N->get_handle("en");
    $lh2->bindtextdomain("test2", $LOCALEDIR);
    $lh2->textdomain("test2");
    $t1 = $lh1->maketext("Hello, world!");
    $t2 = $lh1->maketext("Every story has a happy ending.");
    $t3 = $lh2->maketext("Hello, world!");
    $t4 = $lh2->maketext("Every story has a happy ending.");
    $t5 = $lh1->maketext("Hello, world!");
    $t6 = $lh1->maketext("Every story has a happy ending.");
};
# 1
ok($@, "");
# 2
ok($t1, "Hiya :)");
# 3
ok($t2, "Every story has a happy ending.");
# 4
ok($t3, "Hello, world!");
# 5
ok($t4, "Pray it.");
# 6
ok($t5, "Hiya :)");
# 7
ok($t6, "Every story has a happy ending.");

# Switch between domains
eval {
    require T_L10N;
    $_ = T_L10N->get_handle("en");
    $_->bindtextdomain("test", $LOCALEDIR);
    $_->bindtextdomain("test2", $LOCALEDIR);
    $_->textdomain("test");
    $t1 = $_->maketext("Hello, world!");
    $t2 = $_->maketext("Every story has a happy ending.");
    $_->textdomain("test2");
    $t3 = $_->maketext("Hello, world!");
    $t4 = $_->maketext("Every story has a happy ending.");
    $_->textdomain("test");
    $t5 = $_->maketext("Hello, world!");
    $t6 = $_->maketext("Every story has a happy ending.");
};
# 8
ok($@, "");
# 9
ok($t1, "Hiya :)");
# 10
ok($t2, "Every story has a happy ending.");
# 11
ok($t3, "Hello, world!");
# 12
ok($t4, "Pray it.");
# 13
ok($t5, "Hiya :)");
# 14
ok($t6, "Every story has a happy ending.");

# Switch between encodings
eval {
    require T_L10N;
    $_ = T_L10N->get_handle("zh-tw");
    $_->bindtextdomain("test", $LOCALEDIR);
    $_->textdomain("test");
    $_->encoding("Big5");
    $t1 = $_->maketext("Hello, world!");
    $_->encoding("UTF-8");
    $t2 = $_->maketext("Hello, world!");
    $_->encoding("Big5");
    $t3 = $_->maketext("Hello, world!");
};
# 15
ok($@, "");
# 16
ok($t1, "¤j®a¦n¡C");
# 17
ok($t2, "å¤§å®¶å¥½ã€‚");
# 18
ok($t3, "¤j®a¦n¡C");

# Reload the text
eval {
    $dir = catdir($LOCALEDIR, "en", "LC_MESSAGES");
    $f = catfile($dir, "test_reload.mo");
    $f1 = catfile($dir, "test.mo");
    $f2 = catfile($dir, "test2.mo");
    unlink $f if -f $f;
    link $f1, $f    or die "ERROR: $!";
    
    require T_L10N;
    $_ = T_L10N->get_handle("en");
    $_->bindtextdomain("test_reload", $LOCALEDIR);
    $_->textdomain("test_reload");
    $t1 = $_->maketext("Hello, world!");
    $t2 = $_->maketext("Every story has a happy ending.");
    unlink $f;
    link $f2, $f    or die "ERROR: $!";
    $t3 = $_->maketext("Hello, world!");
    $t4 = $_->maketext("Every story has a happy ending.");
    $_->reload_text;
    $t5 = $_->maketext("Hello, world!");
    $t6 = $_->maketext("Every story has a happy ending.");
    
    unlink $f;
};
# 19
ok($@, "");
# 20
ok($t1, "Hiya :)");
# 21
ok($t2, "Every story has a happy ending.");
# 22
ok($t3, "Hiya :)");
# 23
ok($t4, "Every story has a happy ending.");
# 24
ok($t5, "Hello, world!");
# 25
ok($t6, "Pray it.");
