#! /usr/bin/perl -w
# Test suite on the functional interface for different encodings
# Copyright (c) 2003 imacat. All rights reserved. This program is free
# software; you can redistribute it and/or modify it under the same terms
# as Perl itself.

use 5.008;
use strict;
use warnings;
use Test;

BEGIN { plan tests => 33 }

use Encode qw();
use FindBin;
use File::Spec::Functions qw(catdir);
use lib $FindBin::Bin;
use vars qw($LOCALEDIR);
$LOCALEDIR = catdir($FindBin::Bin, "locale");

# Different encodings
# English
# Find the default encoding
eval {
    use Locale::Maketext::Gettext::Functions;
    bindtextdomain("test", $LOCALEDIR);
    textdomain("test");
    get_handle("en");
    $_ = encoding();
};
# 1
ok($@, "");
# 2
ok($_, "US-ASCII");

# Traditional Chinese
# Find the default encoding
eval {
    use Locale::Maketext::Gettext::Functions;
    bindtextdomain("test", $LOCALEDIR);
    textdomain("test");
    get_handle("zh-tw");
    $_ = encoding;
};
# 3
ok($@, "");
# 4
ok($_, "Big5");

# Turn to Big5
eval {
    use Locale::Maketext::Gettext::Functions;
    bindtextdomain("test", $LOCALEDIR);
    textdomain("test");
    get_handle("zh-tw");
    encoding("Big5");
    $_ = maketext("Hello, world!");
    delete $Locale::Maketext::Gettext::Functions::VARS{"ENCODING"};
};
# 5
ok($@, "");
# 6
ok($_, "¤j®a¦n¡C");

# Turn to UTF-8
eval {
    use Locale::Maketext::Gettext::Functions;
    bindtextdomain("test", $LOCALEDIR);
    textdomain("test");
    get_handle("zh-tw");
    encoding("UTF-8");
    $_ = maketext("Hello, world!");
    delete $Locale::Maketext::Gettext::Functions::VARS{"ENCODING"};
};
# 7
ok($@, "");
# 8
ok($_, "å¤§å®¶å¥½ã€‚");

# Turn to UTF-16LE
eval {
    use Locale::Maketext::Gettext::Functions;
    bindtextdomain("test", $LOCALEDIR);
    textdomain("test");
    get_handle("zh-tw");
    encoding("UTF-16LE");
    $_ = maketext("Hello, world!");
    delete $Locale::Maketext::Gettext::Functions::VARS{"ENCODING"};
};
# 9
ok($@, "");
# 10
ok($_, "'Y¶[}Y0");

# Find the default encoding, in UTF-8
eval {
    use Locale::Maketext::Gettext::Functions;
    bindtextdomain("test_utf8", $LOCALEDIR);
    textdomain("test_utf8");
    get_handle("zh-tw");
    $_ = encoding;
};
# 11
ok($@, "");
# 12
ok($_, "UTF-8");

# Turn to UTF-8
eval {
    use Locale::Maketext::Gettext::Functions;
    bindtextdomain("test_utf8", $LOCALEDIR);
    textdomain("test_utf8");
    get_handle("zh-tw");
    encoding("UTF-8");
    $_ = maketext("Hello, world!");
    delete $Locale::Maketext::Gettext::Functions::VARS{"ENCODING"};
};
# 13
ok($@, "");
# 14
ok($_, "å¤§å®¶å¥½ã€‚");

# Turn to Big5
eval {
    use Locale::Maketext::Gettext::Functions;
    bindtextdomain("test_utf8", $LOCALEDIR);
    textdomain("test_utf8");
    get_handle("zh-tw");
    encoding("Big5");
    $_ = maketext("Hello, world!");
    delete $Locale::Maketext::Gettext::Functions::VARS{"ENCODING"};
};
# 15
ok($@, "");
# 16
ok($_, "¤j®a¦n¡C");

# Turn to UTF-16LE
eval {
    use Locale::Maketext::Gettext::Functions;
    bindtextdomain("test_utf8", $LOCALEDIR);
    textdomain("test_utf8");
    get_handle("zh-tw");
    encoding("UTF-16LE");
    $_ = maketext("Hello, world!");
    delete $Locale::Maketext::Gettext::Functions::VARS{"ENCODING"};
};
# 17
ok($@, "");
# 18
ok($_, "'Y¶[}Y0");

# Find the default encoding
# Simplified Chinese
eval {
    use Locale::Maketext::Gettext::Functions;
    bindtextdomain("test_utf8", $LOCALEDIR);
    textdomain("test_utf8");
    get_handle("zh-cn");
    $_ = encoding();
};
# 19
ok($@, "");
# 20
ok($_, "UTF-8");

# Turn to GB2312
eval {
    use Locale::Maketext::Gettext::Functions;
    bindtextdomain("test_utf8", $LOCALEDIR);
    textdomain("test_utf8");
    get_handle("zh-cn");
    encoding("GB2312");
    $_ = maketext("Hello, world!");
    delete $Locale::Maketext::Gettext::Functions::VARS{"ENCODING"};
};
# 21
ok($@, "");
# 22
ok($_, "´ó¼ÒºÃ¡£");

# Encode failure
# FB_DEFAULT
eval {
    use Locale::Maketext::Gettext::Functions;
    bindtextdomain("test2", $LOCALEDIR);
    textdomain("test2");
    get_handle("zh-tw");
    encoding("GB2312");
    $_ = maketext("Every story has a happy ending.");
    delete $Locale::Maketext::Gettext::Functions::VARS{"ENCODING"};
};
# 23
ok($@, "");
# 24
ok($_, "¹ÊÊÂ¶¼ÓÐÃÀ?µÄ?¾Ö¡£");

# FB_CROAK
eval {
    use Locale::Maketext::Gettext::Functions;
    bindtextdomain("test2", $LOCALEDIR);
    textdomain("test2");
    get_handle("zh-tw");
    encoding("GB2312");
    encode_failure(Encode::FB_CROAK);
    $_ = maketext("Every story has a happy ending.");
    delete $Locale::Maketext::Gettext::Functions::VARS{"ENCODING"};
    undef $Locale::Maketext::Gettext::Functions::ENCODE_FAILURE;
};
# 25
ok($@, qr/does not map to/);

# FB_HTMLCREF
eval {
    use Locale::Maketext::Gettext::Functions;
    bindtextdomain("test2", $LOCALEDIR);
    textdomain("test2");
    get_handle("zh-tw");
    encoding("GB2312");
    encode_failure(Encode::FB_HTMLCREF);
    $_ = maketext("Every story has a happy ending.");
    delete $Locale::Maketext::Gettext::Functions::VARS{"ENCODING"};
    undef $Locale::Maketext::Gettext::Functions::ENCODE_FAILURE;
};
# 26
ok($@, "");
# 27
ok($_, "¹ÊÊÂ¶¼ÓÐÃÀ&#40599;µÄ&#32080;¾Ö¡£");

# Return the unencoded UTF-8 text
eval {
    use Locale::Maketext::Gettext::Functions;
    bindtextdomain("test", $LOCALEDIR);
    textdomain("test");
    get_handle("zh-tw");
    encoding(undef);
    $_ = maketext("Hello, world!");
    delete $Locale::Maketext::Gettext::Functions::VARS{"ENCODING"};
    undef $Locale::Maketext::Gettext::Functions::ENCODE_FAILURE;
};
# 28
ok($@, "");
# 29
ok($_, "\x{5927}\x{5BB6}\x{597D}\x{3002}");
# 30
ok((Encode::is_utf8($_)? "utf8": "non-utf8"), "utf8");

# Return the unencoded UTF-8 text with auto lexicon
eval {
    use Locale::Maketext::Gettext::Functions;
    bindtextdomain("test", $LOCALEDIR);
    textdomain("test");
    get_handle("zh-tw");
    encoding(undef);
    $_ = maketext("Big watermelon");
    delete $Locale::Maketext::Gettext::Functions::VARS{"ENCODING"};
    undef $Locale::Maketext::Gettext::Functions::ENCODE_FAILURE;
};
# 31
ok($@, "");
# 32
ok($_, "Big watermelon");
# 33
ok((Encode::is_utf8($_)? "utf8": "non-utf8"), "utf8");
