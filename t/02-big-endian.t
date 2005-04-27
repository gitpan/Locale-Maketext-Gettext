#! /usr/bin/perl -w
# Test the big endian MO files
# Copyright (c) 2003 imacat. All rights reserved. This program is free
# software; you can redistribute it and/or modify it under the same terms
# as Perl itself.

use 5.008;
use strict;
use warnings;
use Test;

BEGIN { plan tests => 8 }

use FindBin;
use File::Spec::Functions qw(catdir catfile);
use lib $FindBin::Bin;
use vars qw($LOCALEDIR);
$LOCALEDIR = catdir($FindBin::Bin, "locale");

# Check reading big-endian PO files
use vars qw($skip $POfile $MOfile);
# English
eval {
    require T_L10N;
    $_ = T_L10N->get_handle("en");
    $_->bindtextdomain("test_be", $LOCALEDIR);
    $_->textdomain("test_be");
    $_ = $_->maketext("Hello, world!");
};
# 1
ok($@, "");
# 2
ok($_, "Hiya :)");

# Traditional Chinese
eval {
    require T_L10N;
    $_ = T_L10N->get_handle("zh-tw");
    $_->bindtextdomain("test_be", $LOCALEDIR);
    $_->textdomain("test_be");
    $_ = $_->maketext("Hello, world!");
};
# 3
ok($@, "");
# 4
ok($_, "¤j®a¦n¡C");

# Simplified Chinese
eval {
    require T_L10N;
    $_ = T_L10N->get_handle("zh-cn");
    $_->bindtextdomain("test_be", $LOCALEDIR);
    $_->textdomain("test_be");
    $_ = $_->maketext("Hello, world!");
};
# 5
ok($@, "");
# 6
ok($_, "´ó¼ÒºÃ¡£");

# Native-built MO file
{
$skip = 1;
$_ = join "", `msgfmt --version 2>&1`;
last unless $? == 0;
last unless /GNU gettext/;
$POfile = catfile($FindBin::Bin, "test_native.po");
$MOfile = catfile($LOCALEDIR, "en", "LC_MESSAGES", "test_native.mo");
`msgfmt -o "$MOfile" "$POfile"`;
last unless $? == 0;
$skip = 0;
eval {
    require T_L10N;
    $_ = T_L10N->get_handle("en");
    $_->bindtextdomain("test_native", $LOCALEDIR);
    $_->textdomain("test_native");
    $_ = $_->maketext("Hello, world!");
};
}
# 7
skip($skip, $@, "");
# 8
skip($skip, $_, "Hiya :)");

# Garbage collection
unlink catfile($LOCALEDIR, "en", "LC_MESSAGES", "test_native.mo");
