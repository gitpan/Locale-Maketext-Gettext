#! /usr/bin/perl -w
# Test suite on the functional interface for the behavior when something went wrong
# Copyright (c) 2003 imacat. All rights reserved. This program is free
# software; you can redistribute it and/or modify it under the same terms
# as Perl itself.

use 5.008;
use strict;
use warnings;
use Test;

BEGIN { plan tests => 21 }

use FindBin;
use File::Spec::Functions qw(catdir);
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

# When something went wrong
# GNU gettext never fails!
# bindtextdomain
$_ = fork_and_test << "EOT";
    use Locale::Maketext::Gettext::Functions;
    \$_ = bindtextdomain("test");
EOT
# 1
ok($@, "");
# 2
ok($_, "(undef)");

# textdomain
$_ = fork_and_test << "EOT";
    use Locale::Maketext::Gettext::Functions;
    bindtextdomain("test", \$LOCALEDIR);
    \$_ = textdomain;
EOT
# 3
ok($@, "");
# 4
ok($_, "(undef)");

# No text domain claimed yet
$_ = fork_and_test << "EOT";
    use Locale::Maketext::Gettext::Functions;
    \$_ = __("Hello, world!");
EOT
# 5
ok($@, "");
# 6
ok($_, "Hello, world!");

# Non-existing LOCALEDIR
$_ = << "EOT";
    use Locale::Maketext::Gettext::Functions;
    bindtextdomain("test", "/dev/null");
    textdomain("test");
    \$_ = __("Hello, world!");
EOT
$_ = fork_and_test($_);
# 7
ok($@, "");
# 8
ok($_, "Hello, world!");

# Not-registered DOMAIN
$_ = fork_and_test << "EOT";
    use Locale::Maketext::Gettext::Functions;
    textdomain("not_registered");
    \$_ = __("Hello, world!");
EOT
# 9
ok($@, "");
# 10
ok($_, "Hello, world!");

# PO file not exists
$_ = fork_and_test << "EOT";
    use Locale::Maketext::Gettext::Functions;
    bindtextdomain("no_such_domain", \$LOCALEDIR);
    textdomain("no_such_domain");
    \$_ = __("Hello, world!");
EOT
# 11
ok($@, "");
# 12
ok($_, "Hello, world!");

# PO file invalid
$_ = fork_and_test << "EOT";
    use Locale::Maketext::Gettext::Functions;
    bindtextdomain("bad", \$LOCALEDIR);
    textdomain("bad");
    \$_ = __("Hello, world!");
EOT
# 13
ok($@, "");
# 14
ok($_, "Hello, world!");

# No such message
$_ = fork_and_test << "EOT";
    use Locale::Maketext::Gettext::Functions;
    bindtextdomain("test", \$LOCALEDIR);
    textdomain("test");
    get_handle("en");
    \$_ = __("non-existing message");
EOT
# 15
ok($@, "");
# 16
ok($_, "non-existing message");

# get_handle before textdomain
$_ = fork_and_test << "EOT";
    use Locale::Maketext::Gettext::Functions;
    get_handle("en");
    bindtextdomain("test", \$LOCALEDIR);
    textdomain("test");
    \$_ = __("Hello, world!");
EOT
# 17
ok($@, "");
# 18
ok($_, "Hiya :)");

# Maketext before and after binding text domain
$_ = fork_and_test << "EOT";
    use Locale::Maketext::Gettext::Functions;
    %Locale::Maketext::tried = qw();
    __("Hello, world!");
    bindtextdomain("test", \$LOCALEDIR);
    textdomain("test");
    get_handle("en");
    \$_ = __("Hello, world!");
EOT
# 19
ok($@, "");
# 20
ok($_, "Hiya :)");

# Switch to a domain that is not binded yet
$_ = fork_and_test << "EOT";
    use Locale::Maketext::Gettext::Functions;
    get_handle("en");
    bindtextdomain("test", \$LOCALEDIR);
    textdomain("test");
    textdomain("test2");
    \$_ = __("Hello, world!");
EOT
# 21
ok($_, "Hello, world!");
