#! /usr/bin/perl -w
require 5.008;
use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR		=> 'imacat (imacat@mail.imacat.idv.tw)',
    ABSTRACT		=> 'Bridge from gettext to Locale::Maketext',
    NAME                => 'Locale-Maketext-Gettext',
    VERSION_FROM        => 'lib/Locale/Maketext/Gettext.pm',
    PREREQ_PM		=> { },

    dist		=> {
        COMPRESS	=> 'gzip -9',
        SUFFIX		=> '.gz',
    },
);

__END__
