# Locale::Maketext::Gettext::Functions - Functional interface to Locale::Maketext::Gettext

# Copyright (c) 2003 imacat. All rights reserved. This program is free
# software; you can redistribute it and/or modify it under the same terms
# as Perl itself.
# First written: 2003-04-23

package Locale::Maketext::Gettext::Functions;
use 5.008;
use strict;
use warnings;
use base qw(Exporter);
use vars qw($VERSION @EXPORT @EXPORT_OK);
$VERSION = 0.01;
@EXPORT = qw(bindtextdomain textdomain get_handle maketext dmaketext);
@EXPORT_OK = @EXPORT;

use File::Spec::Functions qw(catdir catfile);
use vars qw(%LOCALEDIRS %CLASSES $LH $DOMAIN $CATEGORY $CLASSBASE);
# The category is always LC_MESSAGES
$CATEGORY = "LC_MESSAGES";
$CLASSBASE = "Locale::Maketext::Gettext::_runtime";

# bindtextdomain: Bind a text domain to a locale directory
sub bindtextdomain {
    local ($_, %_);
    my ($DOMAIN, $LOCALEDIR);
    ($DOMAIN, $LOCALEDIR) = @_;
    # Return the current registry
    return (exists $LOCALEDIRS{$DOMAIN}? $LOCALEDIRS{$DOMAIN}: undef)
        if !defined $LOCALEDIR;
    # Register and return the locale directory
    return ($LOCALEDIRS{$DOMAIN} = $LOCALEDIR);
}

# textdomain: Set the current text domain
sub textdomain {
    local ($_, %_);
    my ($new_domain);
    $new_domain = $_[0];
    # Return the current text domain
    return $DOMAIN if !defined $new_domain;
    # Set the current text domain
    $DOMAIN = $new_domain;
    # Return if this domain was not binded yet
    return $DOMAIN if !exists $LOCALEDIRS{$DOMAIN};
    # Initialize a text domain
    _init_textdomain($DOMAIN);
    return $DOMAIN;
}

# get_handle: Get a language handle, an equivalent to setlocale
sub get_handle {
    local ($_, %_);
    my (@langs, $class, $lh, $ln);
    @langs = @_;
    # Get the localization class name
    # TODO: when text domain is not set yet
    $class = _catclass($CLASSBASE, $DOMAIN);
    # Get a language handle
    $LH = $class->get_handle(@langs);
    $LH->bindtextdomain($DOMAIN, $LOCALEDIRS{$DOMAIN});
    $LH->textdomain($DOMAIN);
    return;
}

# maketext: Maketext
sub maketext {
    local ($_, %_);
    my ($key, @param);
    ($key, @param) = @_;
    return $LH->maketext($key, @param);
}

# __: An synonym to maketext
sub __ {
    return maketext(@_);
}

# N_: Return the original text untouched, so that it can be catched
#     with xgettext
sub N_ {
    return @_;
}

# _reg_class: Declare and register a class
sub _reg_class {
    local ($_, %_);
    $_ = $_[0];
    # Check if a domain is registered
    if (!exists $CLASSES{$_}) {
        eval << "EOT";
package $_;
use strict;
use warnings;
use base qw(Locale::Maketext::Gettext);
use vars qw(\@ISA %Lexicon);
EOT
        $CLASSES{$_} = 1;
    }
    return;
}

# _catclass: Catenate the class name
sub _catclass {
    return join("::", @_);;
}

# _init_textdomain: Initialize a text domain
sub _init_textdomain {
    local ($_, %_);
    my ($DOMAIN, $DH, $locale, $MOfile);
    $DOMAIN = $_[0];
    
    # Declaire and register the localization class
    _reg_class(_catclass($CLASSBASE, $DOMAIN));
    # Get the available locales
    opendir $DH, $LOCALEDIRS{$DOMAIN}   or return;
    while (defined($locale = readdir $DH)) {
        # Skip hidden entries
        next if $locale =~ /^\./;
        # Skip non-directories
        next unless -d catdir($LOCALEDIRS{$DOMAIN}, $locale);
        # Skip locales with dot "." (encoding)
        next if $locale =~ /\./;
        # Get the MO file name
        $MOfile = catfile($LOCALEDIRS{$DOMAIN}, $locale,
            $CATEGORY, "$DOMAIN.mo");
        # Skip if no MO file is available for this locale
        next if ! -f $MOfile && ! -r $MOfile;
        # Declaire and register the language subclass
        _reg_class(_catclass($CLASSBASE, $DOMAIN, lc $locale));
    }
    closedir $DH                        or return;
    
    return;
}

return 1;

__END__

=head1 NAME

Locale::Maketext::Gettext::Functions - Functional interface to Locale::Maketext::Gettext

=head1 SYNOPSIS

  use Locale::Maketext::Gettext::Functions;
  bindtextdomain(DOMAIN, LOCALEDIR);
  textdomain(DOMAIN);
  print __("Hello, world!");

=head1 DESCRIPTION

B<WARNING>:  This is still experimental.  Use at your own risk.
Tests and suggestions are welcome.

This is the functional interface to Locale::Maketext::Gettext (and
Locale::Maketext).

The C<maketext> function attempts to translate a text string into
the user's native language, by looking up the translation in a
message catalog.

=head1 FUNCTIONS

=over

=item bindtextdomain(DOMAIN, LOCALEDIR)

Register a text domain with a locale directory.  Returns C<LOCALEDIR>
itself.  If C<LOCALEDIR> is omitted, the registered locale directory
of C<DOMAIN> is returned.  This method always success.

=item textdomain(DOMAIN)

Set the current text domain.  Returns the C<DOMAIN> itself.  if
C<DOMAIN> is omitted, the current text domain is returned.  This
method always success.

=item maketext($key, @param...)

Attempts to translate a text string into the user's native language,
by looking up the translation in a message catalog.  Refer to
L<Locale::Maketext(3)|Locale::Maketext/3> for the details on
its c<maketext> method.

=item __($key, @param...)

An synonym to C<maketext()>.  This is a shortcut to C<maketext()> so
that it is neater when you employ maketext to your existing project.

=item N_($key, @param...)

Return the original text untouched.  This is to enable the text be
catched with xgettext.

=back

=head1 STORY

The idea is that:  I finally realized that, no matter how hard I try,
I<I can never get a never-failure C<maketext>.>  A wrapper like:

  sub __ { return $LH->maketext(@_) };

always fails if $LH is not initialized yet.  For this reason, 
C<maketext> can hardly be employed in error handlers to output
graceful error messages in the natural language of the user.  So,
I have to write something like this:

  sub __ {
      $LH->MyPkg::L10N->get_handle if !defined $LH;
      return $LH->maketext(@_);
  }

But what if C<get_handle> itself fails?  So, this becomes:

  sub __ {
      $LH->MyPkg::L10N->get_handle if !defined $LH;
      $LH->_AUTO->get_handle if !defined $LH;
      return $LH->maketext(@_);
  }
  package _AUTO;
  use base qw(Locale::Maketext);
  package _AUTO::i_default;
  use base qw(Locale::Maketext);
  %Lexicon = ( "_AUTO" );

Ya, this works.  But, if I have always have to do this in my every
application, why shouldn't I make a solution to the localization
framework itself?  This is a common problem to every localization
projects.  It should be solved at the localization framework level,
but not at the applications level.

Another reason is that:  I<Programmers should be able to use
C<maketext> without the knowledge of object programming.>  A
localization network should be neat and simple.  It should lower down
its barrier, be friendly to the beginners, in order to encourage
localization and globalization.  Apparently the current practice
of C<Locale::Maketext> doesn't satisfy this request.

The third reason is:  Since 
L<Locale::Maketext::Gettext(3)|Locale::Maketext::Gettext/3> imports
the lexicon from foreign sources, the class source file is left
empty.  It exists only to help the C<get_handle> method looking for
a proper language handle.  Then, why not make it disappear, and be
generated whenever needed?  Why bother the programmers to put
an empty class source file there?

How neat can we be?

imacat, 2003-04-29

=head1 SEE ALSO

L<Locale::Maketext(3)|Locale::Maketext/3>,
L<Locale::Maketext::TPJ13(3)|Locale::Maketext::TPJ13/3>,
L<Locale::Maketext::Gettext(3)|Locale::Maketext::Gettext/3>,
L<bindtextdomain(3)|bindtextdomain/3>, L<textdomain(3)|textdomain/3>.
Also, please refer to the official GNU gettext manual at
L<http://www.gnu.org/manual/gettext/>.

=head1 AUTHOR

imacat <imacat@mail.imacat.idv.tw>

=head1 COPYRIGHT

Copyright (c) 2003 imacat. All rights reserved. This program is free
software; you can redistribute it and/or modify it under the same terms
as Perl itself.

=cut
