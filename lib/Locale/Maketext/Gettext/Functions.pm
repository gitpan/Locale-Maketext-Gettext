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
$VERSION = 0.03;
@EXPORT = qw(bindtextdomain textdomain get_handle maketext __ N_ dmaketext reload_text read_mo);
@EXPORT_OK = @EXPORT;

use File::Spec::Functions qw(catdir catfile);
use Locale::Maketext::Gettext qw(read_mo);
use vars qw(%LOCALEDIRS %CLASSES %DOMAINS);
use vars qw(%LHS $_AUTO $LH $DOMAIN $CATEGORY $CLASSBASE);
%LHS = qw();
# The internal auto lexicon from Locale::Maketext::Gettext
$_AUTO = $Locale::Maketext::Gettext::_AUTO;
# The category is always LC_MESSAGES
$CATEGORY = "LC_MESSAGES";
$CLASSBASE = "Locale::Maketext::Gettext::_runtime";
use vars qw(@LANGS);
@LANGS = qw();

# bindtextdomain: Bind a text domain to a locale directory
sub bindtextdomain {
    local ($_, %_);
    my ($domain, $LOCALEDIR);
    ($domain, $LOCALEDIR) = @_;
    # Return the current registry
    return (exists $LOCALEDIRS{$domain}? $LOCALEDIRS{$domain}: undef)
        if !defined $LOCALEDIR;
    # Register and return the locale directory
    return ($LOCALEDIRS{$domain} = $LOCALEDIR);
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
    # Initialize this text domain
    _init_textdomain($DOMAIN);
    # Reset the language handle
    _get_handle($DOMAIN, @LANGS);
    return $DOMAIN;
}

# get_handle: Get a language handle
sub get_handle {
    local ($_, %_);
    # Register the current get_handle arguments
    @LANGS = @_;
    # Reset the language handle
    _get_handle($DOMAIN, @LANGS);
    return;
}

# maketext: Maketext
sub maketext {
    local ($_, %_);
    my ($key, @param);
    ($key, @param) = @_;
    # Reset the language handle if it is not set yet
    _get_handle($DOMAIN, @LANGS) if !defined $LH;
    return $LH->maketext($key, @param);
}

# __: A shortcut synonym to maketext
sub __ {
    return maketext(@_);
}

# N_: Return the original text untouched, so that it can be catched
#     with xgettext
sub N_ {
    # Watch out for this perl magic! :p
    return $_[0] unless wantarray;
    return @_;
}

# dmaketext: Maketext in another text domain temporarily,
#            an equivalent to dgettext.
sub dmaketext {
    local ($_, %_);
    my ($domain, $key, @param, $lh0, $text);
    ($domain, $key, @param) = @_;
    # Initialize this text domain
    _init_textdomain($domain);
    # Preserve the current language handle
    $lh0 = $LH;
    # Set the current language handle
    _get_handle($domain, @LANGS);
    # Maketext
    $text = $LH->maketext($key, @param);
    # Return the current language handle
    $LH = $lh0;
    # Return the "made text"
    return $text;
}

# reload_text: Purge the lexicon cache
sub reload_text {
    # reload_text is static.  It can even be called this way.
    Locale::Maketext::Gettext::reload_text;
}

# encoding: Set the output encoding
sub encoding {
    local ($_, %_);
}

# key_encoding: Set the encoding of the original text
sub key_encoding {
    local ($_, %_);
}

# _reg_class: Declare and register a class
sub _reg_class {
    local ($_, %_);
    $_ = $_[0];
    # Return if it is declared
    return if exists $CLASSES{$_};
    # Declare it
    eval << "EOT";
package $_;
use strict;
use warnings;
use base qw(Locale::Maketext::Gettext);
use vars qw(\@ISA %Lexicon);
EOT
    # Register it
    $CLASSES{$_} = 1;
    return;
}

# _catclass: Catenate the class name
sub _catclass {
    return join("::", @_);;
}

# _init_textdomain: Initialize a text domain
sub _init_textdomain {
    local ($_, %_);
    my ($domain, $DH, $locale, $MOfile);
    $domain = $_[0];
    
    # Return if this domain was not binded yet
    return if !exists $LOCALEDIRS{$domain};
    
    # Return if this domain is initialized before
    return if exists $DOMAINS{$domain};
    
    # Declaire and register the localization class
    _reg_class(_catclass($CLASSBASE, $domain));
    # Get the available locales
    opendir $DH, $LOCALEDIRS{$domain}   or return;
    while (defined($locale = readdir $DH)) {
        # Skip hidden entries
        next if $locale =~ /^\./;
        # Skip non-directories
        next unless -d catdir($LOCALEDIRS{$domain}, $locale);
        # Skip locales with dot "." (encoding)
        next if $locale =~ /\./;
        # Get the MO file name
        $MOfile = catfile($LOCALEDIRS{$domain}, $locale,
            $CATEGORY, "$domain.mo");
        # Skip if MO file is not available for this locale
        next if ! -f $MOfile && ! -r $MOfile;
        # Map C to i_default
        $locale = "i_default" if $locale eq "C";
        # Declaire and register the language subclass
        _reg_class(_catclass($CLASSBASE, $domain, lc $locale));
    }
    closedir $DH                        or return;
    
    # Record it
    $DOMAINS{$domain} = 1;
    
    return;
}

# _get_handle: Set the language handle
sub _get_handle {
    local ($_, %_);
    my ($domain, @langs, $class, $lang, $key);
    ($domain, @langs) = @_;
    # Domain not set or locale directory not registered yet
    if (!defined $domain || !exists $LOCALEDIRS{$domain}) {
        # Use the auto lexicon
        $LH = $_AUTO;
    } else {
        # Get the localization class name
        $class = _catclass($CLASSBASE, $domain);
        no strict qw(refs);
        # Get the handle
        $LH = $class->get_handle(@langs);
        # Success
        if (defined $LH) {
            $lang = scalar($LH);
            $lang =~ s/^.*:://;
            $key = join("\n", $domain, $lang);
            # Registered before
            if (exists $LHS{$key}) {
                # Use the existing language handle whenever possible, to
                # reduce the initialization overhead
                $LH = $LHS{$key};
            # Not registered before
            } else {
                # Initialize it
                $LH->bindtextdomain($domain, $LOCALEDIRS{$domain});
                $LH->textdomain($domain);
                # Register it
                $LHS{$key} = $LH;
            }
        # Failed
        } else {
            # Use the auto lexicon as a fallback
            $LH = $_AUTO;
        }
    }
    return;
}

# _reset: Initialize everything
sub _reset {
    local ($_, %_);
    %LOCALEDIRS = qw();
    %LHS = qw();
    $_AUTO = $Locale::Maketext::Gettext::_AUTO;
    %DOMAINS = qw();
    undef $LH;
    undef $DOMAIN;
    @LANGS = qw();
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
  get_handle();
  print __("Hello, world!\n");

=head1 DESCRIPTION

Locale::Maketext::Gettext::Functions is a functional
interface to
L<Locale::Maketext::Gettext(3)|Locale::Maketext::Gettext/3> (and
L<Locale::Maketext(3)|Locale::Maketext/3>).  It works exactly the GNU
gettext way.  It plays magic to
L<Locale::Maketext(3)|Locale::Maketext/3> for you.  No more
localization class/subclasses and language handles are required at
all.

The C<maketext> and C<dmaketext> functions attempt to translate a
text string into the user's native language, by looking up the
translation in a message catalog.

=head1 FUNCTIONS

=over

=item bindtextdomain(DOMAIN, LOCALEDIR);

Register a text domain with a locale directory.  Returns C<LOCALEDIR>
itself.  If C<LOCALEDIR> is omitted, the registered locale directory
of C<DOMAIN> is returned.  This method always success.

=item textdomain(DOMAIN);

Set the current text domain.  Returns the C<DOMAIN> itself.  if
C<DOMAIN> is omitted, the current text domain is returned.  This
method always success.

=item get_handle(@languages);

Set the user's language.  It searches for an available language in
the provided @languages list.  If @languages was not provided, it
looks checks environment variable LANG, and HTTP_ACCEPT_LANGUAGE
when running as CGI.  Refer to
L<Locale::Maketext(3)|Locale::Maketext/3> for the magic of the
C<get_handle>.

=item $message = maketext($key, @param...);

Attempts to translate a text string into the user's native language,
by looking up the translation in a message catalog.  Refer to
L<Locale::Maketext(3)|Locale::Maketext/3> for the C<maketext> plural
grammer.

=item $message = __($key, @param...);

A synonym to C<maketext()>.  This is a shortcut to C<maketext()> so
that it is cleaner when you employ maketext to your existing project.

=item ($key, @param...) = N_($key, @param...);

Returns the original text untouched.  This is to enable the text be
catched with xgettext.

=item reload_text();

Purges the MO text cache.  By default MO files are cached after they
are read and parse from the disk, to reduce I/O and parsing overhead
on busy sites.  reload_text() purges this cache.  The next time
C<maketext> is called, the MO file will be read and parse from the
disk again.  This is used when your MO file is updated, but you
cannot shutdown and restart the application.  For example, when you
are a co-hoster on a mod_perl-enabled Apache, or when your
mod_perl-enabled Apache is too vital to be restarted for every
update of your MO file, or if you are running a vital daemon, such
as an X display server.

=item %Lexicon = read_mo($MOfile);

Read and parse the MO file.  Returns the read %Lexicon.  The returned
lexicon is in its original encoding.

If you need the meta infomation of your MO file, parse the entry
C<$Lexicon{""}>.  For example:

  /^Content-Type: text\/plain; charset=(.*)$/im;
  $encoding = $1;

=back

=head1 NOTES

B<WARNING:>  Due to the design of perl itself, run-time removal of a
locale from your package does not work.
L<Locale::Maketext(3)|Locale::Maketext/3> finds a language handle by
looking for a valid subclass package, and run-time unloading of a
package is not available to perl.  You always have to restart your
application if you remove an MO file.  This includes restarting a
mod_perl-enabled Apache.

For the same reason, rebinding of a text domain to another locale
directory may not work as you expected.  Declared subclass packages
cannot be taken back.  Solutions may be possible, though.  

=head1 STORY

The idea is that:  I finally realized that, no matter how hard I try,
I<I can never get a never-failure C<maketext>.>  A common wrapper
like:

  sub __ { return $LH->maketext(@_) };

always fails if $LH is not initialized yet.  For this reason, 
C<maketext> can hardly be employed in error handlers to output
graceful error messages in the natural language of the user.  So,
I have to write something like this:

  sub __ {
      $LH = MyPkg::L10N->get_handle if !defined $LH;
      return $LH->maketext(@_);
  }

But what if C<get_handle> itself fails?  So, this becomes:

  sub __ {
      $LH = MyPkg::L10N->get_handle if !defined $LH;
      $LH = _AUTO->get_handle if !defined $LH;
      return $LH->maketext(@_);
  }
  package _AUTO;
  use base qw(Locale::Maketext);
  package _AUTO::i_default;
  use base qw(Locale::Maketext);
  %Lexicon = ( "_AUTO" => 1 );

Ya, this works.  But, if I have always have to do this in my every
application, why shouldn't I make a solution to the localization
framework itself?  This is a common problem to every localization
projects.  It should be solved at the localization framework level,
but not at the application level.

Another reason is that:  I<Programmers should be able to use
C<maketext> without the knowledge of object-oriented programming.>
A localization framework should be neat and simple.  It should lower
down its barrier, be friendly to the beginners, in order to
encourage the use of localization and globalization.  Apparently
the current practice of L<Locale::Maketext(3)|Locale::Maketext/3>
doesn't satisfy this request.

The third reason is:  Since 
L<Locale::Maketext::Gettext(3)|Locale::Maketext::Gettext/3> imports
the lexicon from foreign sources, the class source file is left
empty.  It exists only to help the C<get_handle> method looking for
a proper language handle.  Then, why not make it disappear, and be
generated whenever needed?  Why bother the programmers to put
an empty class source file there?

How neat can we be?

imacat, 2003-04-29

=head1 BUGS

=over

=item encoding not supported yet

Source text encoding and output encoding is not supported yet.
Locale::Maketext::Gettext::Functions is still not multibyte-safe.
Solutions or suggestions are welcome.

=item lookup failure control not supported yet

Solutions or suggestions are welcome.

=back

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
