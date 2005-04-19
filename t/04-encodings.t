#! /usr/bin/perl -w
# Test suite for different encodings
# Copyright (c) 2003 imacat. All rights reserved. This program is free
# software; you can redistribute it and/or modify it under the same terms
# as Perl itself.

use 5.008;
use strict;
use warnings;
use Test;

BEGIN { plan tests => 33 }

use Encode qw();
use FindBin qw();
use File::Spec::Functions qw(catdir);
use lib $FindBin::Bin;
use vars qw($LOCALEDIR);
$LOCALEDIR = catdir($FindBin::Bin, "locale");

# Different encodings
# English
# Find the default encoding
eval {
    require T_L10N;
    $_ = T_L10N->get_handle("en");
    $_->bindtextdomain("test", $LOCALEDIR);
    $_->textdomain("test");
    $_ = $_->encoding;
};
# 1
ok($@, "");
# 2
ok($_, "US-ASCII");

# Traditional Chinese
# Find the default encoding
eval {
    require T_L10N;
    $_ = T_L10N->get_handle("zh-tw");
    $_->bindtextdomain("test", $LOCALEDIR);
    $_->textdomain("test");
    $_ = $_->encoding;
};
# 3
ok($@, "");
# 4
ok($_, "Big5");

# Turn to Big5
eval {
    require T_L10N;
    $_ = T_L10N->get_handle("zh-tw");
    $_->bindtextdomain("test", $LOCALEDIR);
    $_->textdomain("test");
    $_->encoding("Big5");
    $_ = $_->maketext("Hello, world!");
};
# 5
ok($@, "");
# 6
ok($_, "¤j®a¦n¡C");

# Turn to UTF-8
eval {
    require T_L10N;
    $_ = T_L10N->get_handle("zh-tw");
    $_->bindtextdomain("test", $LOCALEDIR);
    $_->textdomain("test");
    $_->encoding("UTF-8");
    $_ = $_->maketext("Hello, world!");
};
# 7
ok($@, "");
# 8
ok($_, "å¤§å®¶å¥½ã€‚");

# Turn to UTF-16LE
eval {
    require T_L10N;
    $_ = T_L10N->get_handle("zh-tw");
    $_->bindtextdomain("test", $LOCALEDIR);
    $_->textdomain("test");
    $_->encoding("UTF-16LE");
    $_ = $_->maketext("Hello, world!");
};
# 9
ok($@, "");
# 10
ok($_, "'Y¶[}Y0");

# Find the default encoding, in UTF-8
eval {
    require T_L10N;
    $_ = T_L10N->get_handle("zh-tw");
    $_->bindtextdomain("test_utf8", $LOCALEDIR);
    $_->textdomain("test_utf8");
    $_ = $_->encoding;
};
# 11
ok($@, "");
# 12
ok($_, "UTF-8");

# Turn to UTF-8
eval {
    require T_L10N;
    $_ = T_L10N->get_handle("zh-tw");
    $_->bindtextdomain("test_utf8", $LOCALEDIR);
    $_->textdomain("test_utf8");
    $_->encoding("UTF-8");
    $_ = $_->maketext("Hello, world!");
};
# 13
ok($@, "");
# 14
ok($_, "å¤§å®¶å¥½ã€‚");

# Turn to Big5
eval {
    require T_L10N;
    $_ = T_L10N->get_handle("zh-tw");
    $_->bindtextdomain("test_utf8", $LOCALEDIR);
    $_->textdomain("test_utf8");
    $_->encoding("Big5");
    $_ = $_->maketext("Hello, world!");
};
# 15
ok($@, "");
# 16
ok($_, "¤j®a¦n¡C");

# Turn to UTF-16LE
eval {
    require T_L10N;
    $_ = T_L10N->get_handle("zh-tw");
    $_->bindtextdomain("test_utf8", $LOCALEDIR);
    $_->textdomain("test_utf8");
    $_->encoding("UTF-16LE");
    $_ = $_->maketext("Hello, world!");
};
# 17
ok($@, "");
# 18
ok($_, "'Y¶[}Y0");

# Find the default encoding
# Simplified Chinese
eval {
    require T_L10N;
    $_ = T_L10N->get_handle("zh-cn");
    $_->bindtextdomain("test_utf8", $LOCALEDIR);
    $_->textdomain("test_utf8");
    $_ = $_->encoding;
};
# 19
ok($@, "");
# 20
ok($_, "UTF-8");

# Turn to GB2312
eval {
    require T_L10N;
    $_ = T_L10N->get_handle("zh-cn");
    $_->bindtextdomain("test_utf8", $LOCALEDIR);
    $_->textdomain("test_utf8");
    $_->encoding("GB2312");
    $_ = $_->maketext("Hello, world!");
};
# 21
ok($@, "");
# 22
ok($_, "´ó¼ÒºÃ¡£");

# Encode failure
# FB_DEFAULT
eval {
    require T_L10N;
    $_ = T_L10N->get_handle("zh-tw");
    $_->bindtextdomain("test2", $LOCALEDIR);
    $_->textdomain("test2");
    $_->encoding("GB2312");
    $_ = $_->maketext("Every story has a happy ending.");
};
# 23
ok($@, "");
# 24
ok($_, "¹ÊÊÂ¶¼ÓÐÃÀ?µÄ?¾Ö¡£");

# FB_CROAK
eval {
    require T_L10N;
    $_ = T_L10N->get_handle("zh-tw");
    $_->bindtextdomain("test2", $LOCALEDIR);
    $_->textdomain("test2");
    $_->encoding("GB2312");
    $_->encode_failure(Encode::FB_CROAK);
    $_ = $_->maketext("Every story has a happy ending.");
};
# 25
ok($@, qr/does not map to/);

# FB_HTMLCREF
eval {
    require T_L10N;
    $_ = T_L10N->get_handle("zh-tw");
    $_->bindtextdomain("test2", $LOCALEDIR);
    $_->textdomain("test2");
    $_->encoding("GB2312");
    $_->encode_failure(Encode::FB_HTMLCREF);
    $_ = $_->maketext("Every story has a happy ending.");
};
# 26
ok($@, "");
# 27
ok($_, "¹ÊÊÂ¶¼ÓÐÃÀ&#40599;µÄ&#32080;¾Ö¡£");

# Return the unencoded UTF-8 text
eval {
    require T_L10N;
    $_ = T_L10N->get_handle("zh-tw");
    $_->bindtextdomain("test", $LOCALEDIR);
    $_->textdomain("test");
    $_->encoding(undef);
    $_ = $_->maketext("Hello, world!");
};
# 28
ok($@, "");
# 29
ok($_, "\x{5927}\x{5BB6}\x{597D}\x{3002}");
# 30
ok((Encode::is_utf8($_)? "utf8": "non-utf8"), "utf8");

# Return the unencoded UTF-8 text with auto lexicon
eval {
    require T_L10N;
    $_ = T_L10N->get_handle("zh-tw");
    $_->bindtextdomain("test", $LOCALEDIR);
    $_->textdomain("test");
    $_->encoding(undef);
    $_ = $_->maketext("Big watermelon");
};
# 31
ok($@, "");
# 32
ok($_, "Big watermelon");
# 33
ok((Encode::is_utf8($_)? "utf8": "non-utf8"), "utf8");
