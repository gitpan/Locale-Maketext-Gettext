#! /usr/bin/perl -w
# Basic test suite for the functional interface
# Copyright (c) 2003 imacat. All rights reserved. This program is free
# software; you can redistribute it and/or modify it under the same terms
# as Perl itself.

use 5.008;
use strict;
use warnings;
use Test;

BEGIN { plan tests => 17 }

use FindBin;
use File::Spec::Functions qw(catdir catfile);
use lib $FindBin::Bin;
use vars qw($LOCALEDIR);
$LOCALEDIR = catdir($FindBin::Bin, "locale");

# fork_and_test: Use fork to test, to avoid polluting the package space
sub fork_and_test {
    local ($_, %_);
    my ($CODE, $PW, $PE, $CR, $CE, $pid, $len);
    $CODE = $_[0];
    pipe $CR, $PW;
    pipe $CE, $PE;
    # Systems that does not support fork
    defined($pid = fork) or return;
    # Test in the child process
    if ($pid == 0) {
        eval $CODE;
        print $PE "" . (length $@) . "\n";
        print $PE $@;
        $_ = defined $_? $_: "(undef)";
        print $PW "" . (length $_) . "\n";
        print $PW $_;
        exit 0;
    # Read the result in the parent process
    } else {
        $len = <$CE>;
        chomp $len;
        read $CE, $@, $len;
        $len = <$CR>;
        chomp $len;
        read $CR, $_, $len;
    }
    return $_;
}

# Basic test suite
# bindtextdomain
$_ = fork_and_test << "EOT";
    use Locale::Maketext::Gettext::Functions;
    \$_ = bindtextdomain("test", \$LOCALEDIR);
EOT
# 1
ok($@, "");
# 2
ok($_, $LOCALEDIR);

# textdomain
$_ = fork_and_test << "EOT";
    use Locale::Maketext::Gettext::Functions;
    bindtextdomain("test", \$LOCALEDIR);
    \$_ = textdomain("test");
EOT
# 3
ok($@, "");
# 4
ok($_, "test");

# get_handle
$_ = fork_and_test << "EOT";
    use Locale::Maketext::Gettext::Functions;
    bindtextdomain("test", \$LOCALEDIR);
    textdomain("test");
    get_handle("en");
EOT
# 5
ok($@, "");

# maketext
$_ = fork_and_test << "EOT";
    use Locale::Maketext::Gettext::Functions;
    bindtextdomain("test", \$LOCALEDIR);
    textdomain("test");
    get_handle("en");
    \$_ = maketext("Hello, world!");
EOT
# 6
ok($@, "");
# 7
ok($_, "Hiya :)");

# __ (shortcut to maketext)
$_ = fork_and_test << "EOT";
    use Locale::Maketext::Gettext::Functions;
    bindtextdomain("test", \$LOCALEDIR);
    textdomain("test");
    get_handle("en");
    \$_ = __("Hello, world!");
EOT
# 8
ok($@, "");
# 9
ok($_, "Hiya :)");

# N_ (do nothing)
$_ = fork_and_test << "EOT";
    use Locale::Maketext::Gettext::Functions;
    bindtextdomain("test", \$LOCALEDIR);
    textdomain("test");
    get_handle("en");
    \$_ = N_("Hello, world!");
EOT
# 10
ok($@, "");
# 11
ok($_, "Hello, world!");

# maketext
# English
$_ = fork_and_test << "EOT";
    use Locale::Maketext::Gettext::Functions;
    bindtextdomain("test", \$LOCALEDIR);
    textdomain("test");
    get_handle("en");
    \$_ = __("Hello, world!");
EOT
# 12
ok($@, "");
# 13
ok($_, "Hiya :)");

# Traditional Chinese
$_ = fork_and_test << "EOT";
    use Locale::Maketext::Gettext::Functions;
    bindtextdomain("test", \$LOCALEDIR);
    textdomain("test");
    get_handle("zh-tw");
    \$_ = __("Hello, world!");
EOT
# 14
ok($@, "");
# 14
ok($_, "¤j®a¦n¡C");

# Simplified Chinese
$_ = fork_and_test << "EOT";
    use Locale::Maketext::Gettext::Functions;
    bindtextdomain("test", \$LOCALEDIR);
    textdomain("test");
    get_handle("zh-cn");
    \$_ = __("Hello, world!");
EOT
# 16
ok($@, "");
# 17
ok($_, "´ó¼ÒºÃ¡£");
