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
use vars qw($lh1 $lh2 $dir $f $f1 $f2);
# 2 language handles of the same localization subclass
eval {
    require T_L10N;
    $lh1 = T_L10N->get_handle("en");
    $lh1->bindtextdomain("test", $LOCALEDIR);
    $lh1->textdomain("test");
    $lh2 = T_L10N->get_handle("en");
    $lh2->bindtextdomain("test2", $LOCALEDIR);
    $lh2->textdomain("test2");
    $_[0] = $lh1->maketext("Hello, world!");
    $_[1] = $lh1->maketext("Every story has a happy ending.");
    $_[2] = $lh2->maketext("Hello, world!");
    $_[3] = $lh2->maketext("Every story has a happy ending.");
    $_[4] = $lh1->maketext("Hello, world!");
    $_[5] = $lh1->maketext("Every story has a happy ending.");
};
# 1
ok($@, "");
# 2
ok($_[0], "Hiya :)");
# 3
ok($_[1], "Every story has a happy ending.");
# 4
ok($_[2], "Hello, world!");
# 5
ok($_[3], "Pray it.");
# 6
ok($_[4], "Hiya :)");
# 7
ok($_[5], "Every story has a happy ending.");

# Switch between domains
eval {
    require T_L10N;
    $_ = T_L10N->get_handle("en");
    $_->bindtextdomain("test", $LOCALEDIR);
    $_->bindtextdomain("test2", $LOCALEDIR);
    $_->textdomain("test");
    $_[0] = $_->maketext("Hello, world!");
    $_[1] = $_->maketext("Every story has a happy ending.");
    $_->textdomain("test2");
    $_[2] = $_->maketext("Hello, world!");
    $_[3] = $_->maketext("Every story has a happy ending.");
    $_->textdomain("test");
    $_[4] = $_->maketext("Hello, world!");
    $_[5] = $_->maketext("Every story has a happy ending.");
};
# 8
ok($@, "");
# 9
ok($_[0], "Hiya :)");
# 10
ok($_[1], "Every story has a happy ending.");
# 11
ok($_[2], "Hello, world!");
# 12
ok($_[3], "Pray it.");
# 13
ok($_[4], "Hiya :)");
# 14
ok($_[5], "Every story has a happy ending.");

# Switch between encodings
eval {
    require T_L10N;
    $_ = T_L10N->get_handle("zh-tw");
    $_->bindtextdomain("test", $LOCALEDIR);
    $_->textdomain("test");
    $_->encoding("Big5");
    $_[0] = $_->maketext("Hello, world!");
    $_->encoding("UTF-8");
    $_[1] = $_->maketext("Hello, world!");
    $_->encoding("Big5");
    $_[2] = $_->maketext("Hello, world!");
};
# 15
ok($@, "");
# 16
ok($_[0], "¤j®a¦n¡C");
# 17
ok($_[1], "å¤§å®¶å¥½ã€‚");
# 18
ok($_[2], "¤j®a¦n¡C");

# Reload the text
eval {
    $dir = catdir($LOCALEDIR, "en", "LC_MESSAGES");
    $f = catfile($dir, "test_reload.mo");
    $f1 = catfile($dir, "test.mo");
    $f2 = catfile($dir, "test2.mo");
    unlink $f;
    link $f1, $f    or die "ERROR: $!";
    
    require T_L10N;
    $_ = T_L10N->get_handle("en");
    $_->bindtextdomain("test_reload", $LOCALEDIR);
    $_->textdomain("test_reload");
    $_[0] = $_->maketext("Hello, world!");
    $_[1] = $_->maketext("Every story has a happy ending.");
    unlink $f;
    link $f2, $f    or die "ERROR: $!";
    $_[2] = $_->maketext("Hello, world!");
    $_[3] = $_->maketext("Every story has a happy ending.");
    $_->reload_text;
    $_[4] = $_->maketext("Hello, world!");
    $_[5] = $_->maketext("Every story has a happy ending.");
    
    unlink $f;
};
# 19
ok($@, "");
# 20
ok($_[0], "Hiya :)");
# 21
ok($_[1], "Every story has a happy ending.");
# 22
ok($_[2], "Hiya :)");
# 23
ok($_[3], "Every story has a happy ending.");
# 24
ok($_[4], "Hello, world!");
# 25
ok($_[5], "Pray it.");
