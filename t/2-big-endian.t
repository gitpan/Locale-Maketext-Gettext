#! /usr/bin/perl -w
# Test the big endian MO files
# Copyright (c) 2003 imacat. All rights reserved. This program is free
# software; you can redistribute it and/or modify it under the same terms
# as Perl itself.

use 5.008;
use strict;
use warnings;
use Test;

BEGIN { plan tests => 6 }

use FindBin;
use File::Spec::Functions qw(catdir);
use lib $FindBin::Bin;
use vars qw($LOCALEDIR);
$LOCALEDIR = catdir($FindBin::Bin, "locale");

# Check reading big-endian PO files
# English
eval {
    require TestPkg::L10N;
    $_ = TestPkg::L10N->get_handle("en");
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
    require TestPkg::L10N;
    $_ = TestPkg::L10N->get_handle("zh-tw");
    $_->bindtextdomain("test_be", $LOCALEDIR);
    $_->textdomain("test_be");
    $_ = $_->maketext("Hello, world!");
};
# 3
ok($@, "");
# 4
ok($_, "�j�a�n�C");

# Simplified Chinese
eval {
    require TestPkg::L10N;
    $_ = TestPkg::L10N->get_handle("zh-cn");
    $_->bindtextdomain("test_be", $LOCALEDIR);
    $_->textdomain("test_be");
    $_ = $_->maketext("Hello, world!");
};
# 5
ok($@, "");
# 6
ok($_, "��Һá�");
