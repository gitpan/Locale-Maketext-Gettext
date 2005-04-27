#! /usr/bin/perl -w
require 5.008;
use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR		=> 'imacat <imacat@mail.imacat.idv.tw>',
    ABSTRACT		=> 'Joins gettext and Maketext frameworks',
    NAME                => 'Locale-Maketext-Gettext',
    VERSION             => '1.16',
    PREREQ_PM		=> { },
    
    EXE_FILES		=> [ "bin/maketext" ],
    dist		=> {
        COMPRESS	=> 'gzip -9',
        SUFFIX		=> '.gz',
    },
);

__END__
