# Locale::Maketext::Gettext::Functions - Functional interface to Locale::Maketext::Gettext

# Copyright (c) 2003 imacat. All rights reserved. This program is free
# software; you can redistribute it and/or modify it under the same terms
# as Perl itself.
# First written: 2003-04-28

package Locale::Maketext::Gettext::Functions;
use 5.008;
use strict;
use warnings;
use base qw(Exporter);
use vars qw($VERSION @EXPORT @EXPORT_OK);
$VERSION = 0.06;
@EXPORT = qw();
push @EXPORT, qw(bindtextdomain textdomain get_handle maketext __ N_ dmaketext);
push @EXPORT, qw(reload_text read_mo encoding key_encoding encode_failure);
@EXPORT_OK = @EXPORT;

use Encode qw(encode decode from_to FB_DEFAULT);
use File::Spec::Functions qw(catdir catfile);
use Locale::Maketext::Gettext qw(read_mo);
use vars qw(%LOCALEDIRS %RIDS %CLASSES %LANGS);
use vars qw(%LHS $_AUTO $_EMPTY $LH $FLH $DOMAIN $CATEGORY $CLASSBASE @LANGS);
use vars qw(@SYSTEM_LOCALEDIRS);
use vars qw($ENCODING $KEY_ENCODING $ENCODE_FAILURE $DIE_FOR_LOOKUP_FAILURES);
%LHS = qw();
# The internal auto/empty lexicons from Locale::Maketext::Gettext
$_AUTO = $Locale::Maketext::Gettext::_AUTO;
$_EMPTY = $Locale::Maketext::Gettext::_EMPTY;
$FLH = $_AUTO;
# The category is always LC_MESSAGES
$CATEGORY = "LC_MESSAGES";
$CLASSBASE = "Locale::Maketext::Gettext::_runtime";
# Current language parameters
@LANGS = qw();
@SYSTEM_LOCALEDIRS = @Locale::Maketext::Gettext::SYSTEM_LOCALEDIRS;
$ENCODE_FAILURE = FB_DEFAULT;
$DIE_FOR_LOOKUP_FAILURES = 0;
# Parameters for random class IDs
use vars qw($RID_LEN @RID_CHARS);
$RID_LEN = 8;
@RID_CHARS = split //,
    "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";

# bindtextdomain: Bind a text domain to a locale directory
sub bindtextdomain {
    local ($_, %_);
    my ($domain, $LOCALEDIR);
    ($domain, $LOCALEDIR) = @_;
    # Return the current registry
    return (exists $LOCALEDIRS{$domain}? $LOCALEDIRS{$domain}: undef)
        if !defined $LOCALEDIR;
    # Register the locale directory
    $LOCALEDIRS{$domain} = $LOCALEDIR;
    # Reinitialize the text domain
    _init_textdomain($domain);
    # Reset the current language handle
    _get_handle() if defined $DOMAIN && $domain eq $DOMAIN;
    # Return the locale directory
    return $LOCALEDIR;
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
    # Reinitialize the text domain
    _init_textdomain($DOMAIN);
    # Reset the current language handle
    _get_handle();
    return $DOMAIN;
}

# get_handle: Get a language handle
sub get_handle {
    local ($_, %_);
    # Register the current get_handle arguments
    @LANGS = @_;
    # Reset and return the current language handle
    return _get_handle();
}

# maketext: Maketext, in its long name
sub maketext {
    return __(@_);
}

# __: Maketext, in its shortcut name
sub __ {
    local ($_, %_);
    my ($key, @param, $msg, $encoding, $lh_encoding, $key_encoding);
    ($key, @param) = @_;
    # Encode the source text
    $key = decode($KEY_ENCODING, $key, $ENCODE_FAILURE)
        if defined $KEY_ENCODING;
    # Reset the current language handle if it is not set yet
    _get_handle() if !defined $LH;
    
    # Lookup failures.  Let the fail handler take over
    if (!exists ${$LH->{"Lexicon"}}{$key}) {
        $msg = $FLH->maketext($key, @param);
        # Wrap the output encoding
        if (defined $ENCODING) {
            $msg = encode($ENCODING, $msg, $ENCODE_FAILURE);
        # Turn back to the encoding of the source text
        } elsif (defined $KEY_ENCODING) {
            $msg = encode($KEY_ENCODING, $msg, $ENCODE_FAILURE);
        }
    # Process with the ordinary maketext
    } else {
        $msg = $LH->maketext($key, @param);
        # Wrap the output encoding
        from_to($msg, $LH->encoding, $ENCODING, $ENCODE_FAILURE)
            if defined $ENCODING;
    }
    
    return $msg;
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
    my ($domain, $key, @param, $lh0, $domain0, $text);
    ($domain, $key, @param) = @_;
    # Preserve the current status
    ($lh0, $domain0) = ($LH, $DOMAIN);
    # Reinitialize the text domain
    textdomain($domain);
    # Maketext
    $text = maketext($key, @param);
    # Return the current status
    ($LH, $DOMAIN) = ($lh0, $domain0);
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
    my ($new_encoding);
    $new_encoding = $_[0];
    # Return the current encoding
    if (!defined $new_encoding) {
        return $ENCODING if defined $ENCODING;
        return if !defined $LH;
        return $LH->encoding;
    }
    # Set and return the current output encoding
    return ($ENCODING = $new_encoding);
}

# key_encoding: Set the encoding of the original text
sub key_encoding {
    local ($_, %_);
    my ($new_key_encoding);
    $new_key_encoding = $_[0];
    # Return the current key encoding
    return $KEY_ENCODING if !defined $new_key_encoding;
    # Set and return the current output encoding
    return ($KEY_ENCODING = $new_key_encoding);
}

# encode_failure: What to do if the text is out of your output encoding
#   Refer to Encode on possible values of this check
sub encode_failure {
    local ($_, %_);
    my ($CHECK);
    $CHECK = $_[0];
    # Return the current setting
    return $ENCODE_FAILURE if !defined $CHECK;
    # Set and return the current setting
    return ($ENCODE_FAILURE = $CHECK);
}

# die_for_lookup_failures: Whether we should die for lookup failure
#   The default is no.  GNU gettext never fails.
sub die_for_lookup_failures {
    local ($_, %_);
    my $is_die;
    $is_die = $_[0];
    # Return the current setting
    return $DIE_FOR_LOOKUP_FAILURES if !defined $is_die;
    # Set the current setting
    if ($is_die) {
        $FLH = $_EMPTY;
        $DIE_FOR_LOOKUP_FAILURES = 1;
    } else {
        $FLH = $_AUTO;
        $DIE_FOR_LOOKUP_FAILURES = 0;
    }
    # Resetting the current language handle is not required
    # Lookup failures are handled by the fail handler directly
    return $DIE_FOR_LOOKUP_FAILURES;
}

# _declare_class: Declare a class
sub _declare_class {
    eval << "EOT";
package $_[0];
use base qw(Locale::Maketext::Gettext);
use vars qw(\@ISA %Lexicon);
EOT
}

# _catclass: Catenate the class name
sub _catclass {
    return join("::", @_);;
}

# _init_textdomain: Initialize a text domain
sub _init_textdomain {
    local ($_, %_);
    my ($domain, $k, @langs, $langs);
    $domain = $_[0];
    
    # Return if text domain not specified yet
    return if !defined $domain;
    
    # Obtain the available locales
    # A binded domain
    if (exists $LOCALEDIRS{$domain}) {
        @langs = _get_langs($LOCALEDIRS{$domain}, $domain);
    # Not binded
    } else {
        @langs = qw();
        # Search the system locale directories
        foreach (@SYSTEM_LOCALEDIRS) {
            @langs = _get_langs($_, $domain);
            # Domain not found in this directory
            next if scalar(@langs) == 0;
            $LOCALEDIRS{$domain} = $_;
            last;
        }
        # Not found at last
        return if !exists $LOCALEDIRS{$domain};
    }
    $langs = join ",", sort @langs;
    
    # Obtain the registry key
    $k = _k($domain);
    
    # Available language list remains for this domain
    return if exists $LANGS{$k} && $LANGS{$k} eq $langs;
    # Register this new language list
    $LANGS{$k} = $langs;
    
    my ($rid, $class);
    # Garbage collection - drop abandoned language handles
    if (exists $CLASSES{$k}) {
        delete $LHS{$_} foreach grep /^$CLASSES{$k}/, keys %LHS;
    }
    # Get a new class ID
    $rid = _new_rid();
    # Obtain the class name
    $class = _catclass($CLASSBASE, $rid);
    # Register the domain with this class
    $CLASSES{$k} = $class;
    # Declare this class
    _declare_class($class);
    # Declare its language subclasses
    _declare_class(_catclass($class, $_))
        foreach @langs;
    
    return;
}

# _get_langs: Search a locale directory and return the available languages
sub _get_langs {
    local ($_, %_);
    my ($dir, $domain, $DH, $entry, $MOfile);
    ($dir, $domain) = @_;
    
    @_ = qw();
    {
        opendir $DH, $dir   or last;
        while (defined($entry = readdir $DH)) {
            # Skip hidden entries
            next if $entry =~ /^\./;
            # Skip non-directories
            next unless -d catdir($dir, $entry);
            # Skip locales with dot "." (trailing encoding)
            next if $entry =~ /\./;
            # Get the MO file name
            $MOfile = catfile($dir, $entry, $CATEGORY, "$domain.mo");
            # Skip if MO file is not available for this locale
            next if ! -f $MOfile && ! -r $MOfile;
            # Map C to i_default
            $entry = "i_default" if $entry eq "C";
            # Add this language
            push @_, lc $entry;
        }
        close $DH           or last;
    }
    return @_;
}

# _get_handle: Set the language handle with the current DOMAIN and @LANGS
sub _get_handle {
    local ($_, %_);
    my ($k, $class, $subclass);
    
    # Use the auto lexicon if text domain not specified, or not binded yet
    return _lang($LH = $FLH)
        if !defined $DOMAIN || !exists $LOCALEDIRS{$DOMAIN};
    # Obtain the registry key
    $k = _k($DOMAIN);
    # Use the auto lexicon if text domain was not properly set yet
    return _lang($LH = $FLH) if !exists $CLASSES{$k};
    
    # Get the localization class name
    $class = $CLASSES{$k};
    # Get the language handle
    $LH = $class->get_handle(@LANGS);
    # Fallback to the auto lexicon if failed get_handle
    return _lang($LH = $FLH) if !defined $LH;
    
    # Obtain the subclass name of the got language handle
    $subclass = ref($LH);
    # Use the existing language handle whenever possible, to reduce
    # the initialization overhead
    return _lang($LH = $LHS{$subclass}) if exists $LHS{$subclass};
    
    # Initialize it
    $LH->bindtextdomain($DOMAIN, $LOCALEDIRS{$DOMAIN});
    $LH->textdomain($DOMAIN);
    # Register it
    $LHS{$subclass} = $LH;
    
    return _lang($LH);
}

# _reset: Initialize everything
sub _reset {
    local ($_, %_);
    
    %LOCALEDIRS = qw();
    undef $LH;
    undef $DOMAIN;
    @LANGS = qw();
    undef $ENCODING;
    undef $KEY_ENCODING;
    $ENCODE_FAILURE = FB_DEFAULT;
    
    return;
}

# _new_rid: Generate a new random ID
sub _new_rid {
    local ($_, %_);
    my ($id);
    
    do {
        for ($id = "", $_ = 0; $_ < $RID_LEN; $_++) {
            $id .= $RID_CHARS[int rand scalar @RID_CHARS];
        }
    } while exists $RIDS{$id};
    $RIDS{$id} = 1;
    
    return $id;
}

# _k: Build the key for the domain registry
sub _k {
    return join "\n", $LOCALEDIRS{$_[0]}, $CATEGORY, $_[0];
}

# _lang: The langage from a language handle.  language_tag isn't quite sane.
sub _lang {
    local ($_, %_);
    $_ = $_[0];
    $_ = ref($_);
    s/^.+:://;
    s/_/-/g;
    return $_;
}

return 1;

__END__

=head1 NAME

Locale::Maketext::Gettext::Functions - Functional interface to Locale::Maketext::Gettext

=head1 SYNOPSIS

  use Locale::Maketext::Gettext::Functions;
  bindtextdomain(DOMAIN, LOCALEDIR);
  textdomain(DOMAIN);
  get_handle("de");
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
translation in an MO lexicon file.

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

=item get_handle(@languages)

Set the user's language.  It searches for an available language in
the provided @languages list.  If @languages was not provided, it
looks checks environment variable LANG, and HTTP_ACCEPT_LANGUAGE
when running as CGI.  Refer to
L<Locale::Maketext(3)|Locale::Maketext/3> for the magic of the
C<get_handle>.

=item $message = maketext($key, @param...)

Attempts to translate a text string into the user's native language,
by looking up the translation in an MO lexicon file.  Refer to
L<Locale::Maketext(3)|Locale::Maketext/3> for the C<maketext> plural
grammer.

=item $message = __($key, @param...)

A synonym to C<maketext()>.  This is a shortcut to C<maketext()> so
that it is cleaner when you employ maketext to your existing project.

=item ($key, @param...) = N_($key, @param...)

Returns the original text untouched.  This is to enable the text be
catched with xgettext.

=item $message = dmaketext($domain, $key, @param...)

Temporarily switch to another text domain and attempts to translate
a text string into the user's native language in that text domain.

=item encoding(ENCODING)

Set or retrieve the output encoding.  The default is the same
encoding as the gettext MO file.

=item key_encoding(ENCODING)

Specify the encoding used in your original text.  The C<maketext>
method itself isn't multibyte-safe to the _AUTO lexicon.  If you are
using your native non-English language as your original text and you
are having troubles like:

Unterminated bracket group, in:

Then, specify the C<key_encoding> to the encoding of your original
text.  Returns the current setting.

=item encode_failure(CHECK)

Set the action when encode fails.  This happens when the output text
is out of the scope of your output encoding.  For exmaple, output
Chinese into US-ASCII.  Refer to L<Encode(3)|Encode/3> for the
possible values of this C<CHECK>.  The default is C<FB_DEFAULT>,
which is a safe choice that never fails.  But part of your text may
be lost, since that is what C<FB_DEFAULT> does.  Returns the current
setting.

=item die_for_lookup_failures(SHOULD_I_DIE)

Maketext dies for lookup failures, but GNU gettext never fails.
By default Lexicon::Maketext::Gettext follows the GNU gettext
behavior.  But if you are Maketext-styled, or if you need a better
control over the failures (like me :p), set this to 1.  Returns the
current setting.

=item reload_text()

Purges the MO text cache.  By default MO files are cached after they
are read and parsed from the disk, to reduce I/O and parsing overhead
on busy sites.  reload_text() purges this cache, so that updated MO
files can take effect at run-time.  This is used when your MO file is
updated, but you cannot shutdown and restart the application.  for
example, when you are a co-hoster on a mod_perl-enabled Apache, or
when your mod_perl-enabled Apache is too vital to be restarted for
every update of your MO file, or if you are running a vital daemon,
such as an X display server.

=item %Lexicon = read_mo($MOfile)

Read and parse the MO file.  Returns the read %Lexicon.  The returned
lexicon is in its original encoding.

If you need the meta infomation of your MO file, parse the entry
C<$Lexicon{""}>.  For example:

  /^Content-Type: text\/plain; charset=(.*)$/im;
  $encoding = $1;

=back

=head1 NOTES

B<NOTE:> Since localization classes are generated at run-time, it is
not possible to override the Maketext language functions, like
C<quant> or C<numerate>.  If that is your concern, use
L<Locale::Maketext::Gettext(3)|Locale::Maketext::Gettext/3> instead.
Suggestions are welcome.

You can now add/remove languages/MO files at run-time.  This is a
major improvement over the original
L<Locale::Maketext::Gettext(3)|Locale::Maketext::Gettext/3> (and
L<Locale::Maketext(3)|Locale::Maketext/3>). ^_*'  This is done by
registering localization classes with random IDs, so that the same
text domain can be re-declared infinitely, whenever needed (language
list changes, LOCALEDIR changes, etc.)  This is not possible to the
object-interface of
L<Locale::Maketext::Gettext(3)|Locale::Maketext::Gettext/3> (and
L<Locale::Maketext(3)|Locale::Maketext/3>).

Language addition/removal takes effect only after C<bindtextdomain>
or C<textdomain> is called.  It has no effect on C<maketext> calls.
This keeps a basic sanity in the lifetime of a running script.

If you set C<textdomain> to a domain that is not C<bindtextdomain> to
specific a locale directory yet, it will try search system locale
directories.  The current system locale directory search order is:
/usr/share/locale, /usr/lib/locale, /usr/local/share/locale,
/usr/local/lib/locale.  Suggestions are welcome.

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

Ya, this works.  But, if I always have to do this in my every
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

Since maketext localization classes are generated at run time,
Maketext language function override, like C<quant> or C<numerate>, is
not available here.  Suggestions are welcome.

C<encoding>, C<key_encoding>, C<encode_failure> and
C<die_for_lookup_failures> are not mod_perl-safe.  These settings
affect the whole process, including the following scripts it is
going to run.  This is the same as C<setlocale> in
L<POSIX(3)|POSIX/3>.  Always set them at the very beginning of your
script if you are running under mod_perl.  If you don't like it,
use the object-oriented
L<Locale::Maketext::Gettext(3)|Locale::Maketext::Gettext/3> instead.
Suggestions are welcome.

Smart translation between Traditional Chinese/Simplified Chinese,
like what GNU gettext does, is not available yet.  Suggestions are
welcome.

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
