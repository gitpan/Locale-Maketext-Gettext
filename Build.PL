#! /usr/bin/perl -w
use strict;
use Module::Build;

my $build = Module::Build->new(
    dist_name       => "Locale-Maketext-Gettext",
    dist_version    => "1.20",
    dist_abstract   => "Joins gettext and Maketext frameworks",
    dist_author     => "imacat <imacat\@mail.imacat.idv.tw>",
    license         => "perl",
    sign            => 1,
    
    script_files    => [ "bin/maketext" ],
    requires        => {
        "perl"          => "5.8.0",
    },
);

$build->create_build_script;

__END__
