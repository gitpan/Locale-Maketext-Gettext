#! /usr/bin/perl -w
# Test suite on the functional interface for switching between different settings
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

# Switching between different settings
# dmaketext
$_ = fork_and_test << "EOT";
    use Locale::Maketext::Gettext::Functions;
    get_handle("en");
    \$_ = "";
    bindtextdomain("test", \$LOCALEDIR);
    bindtextdomain("test2", \$LOCALEDIR);
    textdomain("test");
    \$_ .= __("Hello, world!")."\n";
    \$_ .= __("Every story has a happy ending.")."\n";
    \$_ .= dmaketext("test2", "Hello, world!")."\n";
    \$_ .= dmaketext("test2", "Every story has a happy ending.")."\n";
    \$_ .= __("Hello, world!")."\n";
    \$_ .= __("Every story has a happy ending.")."\n";
EOT
@_ = split /\n/, $_;
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
$_ = fork_and_test << "EOT";
    use Locale::Maketext::Gettext::Functions;
    bindtextdomain("test", \$LOCALEDIR);
    bindtextdomain("test2", \$LOCALEDIR);
    get_handle("en");
    \$_ = "";
    textdomain("test");
    \$_ .= maketext("Hello, world!")."\n";
    \$_ .= maketext("Every story has a happy ending.")."\n";
    textdomain("test2");
    \$_ .= maketext("Hello, world!")."\n";
    \$_ .= maketext("Every story has a happy ending.")."\n";
    textdomain("test");
    \$_ .= maketext("Hello, world!")."\n";
    \$_ .= maketext("Every story has a happy ending.")."\n";
EOT
@_ = split /\n/, $_;
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

# Switch between languages
$_ = fork_and_test << "EOT";
    use Locale::Maketext::Gettext::Functions;
    bindtextdomain("test", \$LOCALEDIR);
    textdomain("test");
    \$_ = "";
    get_handle("en");
    \$_ .= maketext("Hello, world!")."\n";
    get_handle("zh-tw");
    \$_ .= maketext("Hello, world!")."\n";
    get_handle("zh-cn");
    \$_ .= maketext("Hello, world!")."\n";
EOT
@_ = split /\n/, $_;
# 15
ok($@, "");
# 16
ok($_[0], "Hiya :)");
# 17
ok($_[1], "¤j®a¦n¡C");
# 18
ok($_[2], "´ó¼ÒºÃ¡£");

# Reload the text
$_ = fork_and_test << "EOT";
    use vars qw(\$dir \$f \$f1 \$f2);
    \$dir = catdir(\$LOCALEDIR, "en", "LC_MESSAGES");
    \$f = catfile(\$dir, "test_reload.mo");
    \$f1 = catfile(\$dir, "test.mo");
    \$f2 = catfile(\$dir, "test2.mo");
    unlink \$f if -f \$f;
    link \$f1, \$f    or die "ERROR: \$!";
    \$_ = "";
    use Locale::Maketext::Gettext::Functions;
    bindtextdomain("test_reload", \$LOCALEDIR);
    textdomain("test_reload");
    get_handle("en");
    \$_ .= maketext("Hello, world!")."\n";
    \$_ .= maketext("Every story has a happy ending.")."\n";
    unlink \$f;
    link \$f2, \$f    or die "ERROR: \$!";
    \$_ .= maketext("Hello, world!")."\n";
    \$_ .= maketext("Every story has a happy ending.")."\n";
    reload_text;
    \$_ .= maketext("Hello, world!")."\n";
    \$_ .= maketext("Every story has a happy ending.")."\n";
    unlink \$f;
EOT
@_ = split /\n/, $_;
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
