#! /usr/bin/perl -w
require 5.008;
use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME        => "Locale-Maketext-Gettext",
    VERSION     => "1.20",
    ABSTRACT    => "Joins gettext and Maketext frameworks",
    AUTHOR      => "imacat <imacat\@mail.imacat.idv.tw>",
    PREREQ_PM   => { },
    SIGN        => 1,
    
    EXE_FILES   => [ "bin/maketext" ],
    dist        => {
        COMPRESS    => "gzip -9",
        SUFFIX      => ".gz",
    },
);

__END__
