#! /usr/bin/perl -w
# Basic test suite
# Copyright (c) 2003-2007 imacat. All rights reserved. This program is free
# software; you can redistribute it and/or modify it under the same terms
# as Perl itself.

use 5.008;
use strict;
use warnings;
use Test;

BEGIN { plan tests => 16 }

use FindBin;
use File::Spec::Functions qw(catdir catfile);
use lib $FindBin::Bin;
use vars qw($LOCALEDIR $r);
$LOCALEDIR = catdir($FindBin::Bin, "locale");

# Basic test suite
use Encode qw(decode);
use vars qw($META $n $k1 $k2 $s1 $s2);

# bindtextdomain
$r = eval {
    require T_L10N;
    $_ = T_L10N->get_handle("en");
    $_->bindtextdomain("test", $LOCALEDIR);
    $_ = $_->bindtextdomain("test");
    return 1;
};
# 1
ok($r, 1);
# 2
ok($_, "$LOCALEDIR");

# textdomain
$r = eval {
    require T_L10N;
    $_ = T_L10N->get_handle("en");
    $_->bindtextdomain("test", $LOCALEDIR);
    $_->textdomain("test");
    $_ = $_->textdomain;
    return 1;
};
# 3
ok($r, 1);
# 4
ok($_, "test");

# read_mo
$META = << "EOT";
Project-Id-Version: test 1.0
POT-Creation-Date: 2003-04-24 21:52+0800
PO-Revision-Date: 2003-04-24 21:52+0800
Last-Translator: imacat <imacat\@mail.imacat.idv.tw>
Language-Team: English <imacat\@mail.imacat.idv.tw>
MIME-Version: 1.0
Content-Type: text/plain; charset=US-ASCII
Content-Transfer-Encoding: 7bit
Plural-Forms: nplurals=2; plural=n != 1;
EOT
$r = eval {
    use Locale::Maketext::Gettext;
    $_ = catfile($LOCALEDIR, "en", "LC_MESSAGES", "test.mo");
    %_ = read_mo($_);
    @_ = sort keys %_;
    $n = scalar(@_);
    $k1 = $_[0];
    $k2 = $_[1];
    $s1 = $_{$k1};
    $s2 = $_{$k2};
    return 1;
};
# 5
ok($r, 1);
# 6
ok($n, 2);
# 7
ok($k1, "");
# 8
ok($k2, "Hello, world!");
# 9
ok($s1, $META);
# 10
ok($s2, "Hiya :)");

# English
$r = eval {
    require T_L10N;
    $_ = T_L10N->get_handle("en");
    $_->bindtextdomain("test", $LOCALEDIR);
    $_->textdomain("test");
    $_ = $_->maketext("Hello, world!");
    return 1;
};
# 11
ok($r, 1);
# 12
ok($_, "Hiya :)");

# Traditional Chinese
$r = eval {
    require T_L10N;
    $_ = T_L10N->get_handle("zh-tw");
    $_->bindtextdomain("test", $LOCALEDIR);
    $_->textdomain("test");
    $_ = $_->maketext("Hello, world!");
    return 1;
};
# 13
ok($r, 1);
# 14
ok($_, "�j�a�n�C");

# Simplified Chinese
$r = eval {
    require T_L10N;
    $_ = T_L10N->get_handle("zh-cn");
    $_->bindtextdomain("test", $LOCALEDIR);
    $_->textdomain("test");
    $_ = $_->maketext("Hello, world!");
    return 1;
};
# 15
ok($r, 1);
# 16
ok($_, "��Һá�");
