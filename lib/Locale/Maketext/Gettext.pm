# Locale::Maketext::Gettext - Joins the gettext and Maketext frameworks

# Copyright (c) 2003 imacat. All rights reserved. This program is free
# software; you can redistribute it and/or modify it under the same terms
# as Perl itself.
# First written: 2003-04-23

package Locale::Maketext::Gettext;
use 5.008;
use strict;
use warnings;
use base qw(Locale::Maketext Exporter);
use vars qw($VERSION @ISA %Lexicon @EXPORT @EXPORT_OK);
$VERSION = 0.06;
@EXPORT = qw(read_mo readmo);
@EXPORT_OK = @EXPORT;

use Encode qw(encode decode FB_DEFAULT);
use File::Spec::Functions qw(catfile);
no strict qw(refs);

use vars qw(%Lexicons %ENCODINGS $REREAD_MO $MOFILE $_AUTO @SYSTEM_LOCALEDIRS);
$REREAD_MO = 0;
$MOFILE = "";
$_AUTO = Locale::Maketext::Gettext::_AUTO::L10N->get_handle;
@SYSTEM_LOCALEDIRS = qw(/usr/share/locale /usr/lib/locale
    /usr/local/share/locale /usr/local/lib/locale);

# encoding: Set or retrieve the encoding
sub encoding {
    local ($_, %_);
    my ($self, $new_enc);
    ($self, $new_enc) = @_;
    
    # This is not a static method
    return if ref($self) eq "";
    
    # Return the current encoding
    return $self->{"ENCODING"} if !defined $new_enc;
    
    # Set the current encoding
    return ($self->{"ENCODING"} = $new_enc);
}

# key_encoding: Specify the encoding used in the keys
sub key_encoding {
    local ($_, %_);
    my ($self, $KEY_ENCODING);
    ($self, $KEY_ENCODING) = @_;
    
    # This is not a static method
    return if ref($self) eq "";
    
    # Specify the encoding used in the keys
    $self->{"KEY_ENCODING"} = $KEY_ENCODING if defined $KEY_ENCODING;
    
    # Return the encoding
    return $self->{"KEY_ENCODING"};
}

# Sorry for Sean... :p  I have to initialize several variables
sub new {
    my ($self, $class);
    # Nothing fancy!
    $class = ref($_[0]) || $_[0];
    $self = bless {}, $class;
    
    # Initialize the instance lexicon
    $self->{"Lexicon"} = {};
    # Initialize the LOCALEDIRS registry
    $self->{"LOCALEDIRS"} = {};
    # Initialize the MO timestamp
    $self->{"REREAD_MO"} = $REREAD_MO;
    # Initialize the DIE_FOR_LOOKUP_FAILURES setting
    $self->{"DIE_FOR_LOOKUP_FAILURES"} = 0;
    # Initialize the ENCODE_FAILURE setting
    $self->{"ENCODE_FAILURE"} = FB_DEFAULT;
    # Initialize the MOFILE value of this instance
    $self->{"MOFILE"} = "";
    ${"$class\::MOFILE"} = "" if !defined ${"$class\::MOFILE"};
    # Find the locale name, for this subclass
    $self->{"LOCALE"} = $class;
    $self->{"LOCALE"} =~ s/^.*:://;
    $self->{"LOCALE"} =~ s/(_)(.*)$/$1 . uc $2/e;
    # Set the category.  Currently this is always LC_MESSAGES
    $self->{"CATEGORY"} = "LC_MESSAGES";
    
    $self->init;
    return $self;
}

# bindtextdomain: Bind a text domain to a locale directory
sub bindtextdomain {
    local ($_, %_);
    my ($self, $DOMAIN, $LOCALEDIR);
    ($self, $DOMAIN, $LOCALEDIR) = @_;
    
    # This is not a static method
    return if ref($self) eq "";
    
    # Return null for this rare case
    return if   !defined $LOCALEDIR
                && !exists ${$self->{"LOCALEDIRS"}}{$DOMAIN};
    
    # Register the DOMAIN and its LOCALEDIR
    ${$self->{"LOCALEDIRS"}}{$DOMAIN} = $LOCALEDIR if defined $LOCALEDIR;
    
    # Return the registry
    return ${$self->{"LOCALEDIRS"}}{$DOMAIN};
}

# textdomain: Set the current text domain
sub textdomain {
    local ($_, %_);
    my ($self, $class, $DOMAIN, $LOCALEDIR, $MOfile);
    ($self, $DOMAIN) = @_;
    
    # This is not a static method
    return if ref($self) eq "";
    # Find the class name
    $class = ref($self);
    
    # Return the current domain
    return $self->{"DOMAIN"} if !defined $DOMAIN;
    
    # Set the timestamp of this read in this instance
    $self->{"REREAD_MO"} = $REREAD_MO;
    # Set the current domain
    $self->{"DOMAIN"} = $DOMAIN;
    
    # Clear it
    $self->{"Lexicon"} = {};
    %{"$class\::Lexicon"} = qw();
    $self->{"MOFILE"} = "";
    ${"$class\::MOFILE"} = "";
    
    # The format is "{LOCALEDIR}/{LOCALE}/{CATEGORY}/{DOMAIN}.mo"
    # Search the system locale directories if the domain was not
    # registered yet
    if (!exists ${$self->{"LOCALEDIRS"}}{$DOMAIN}) {
        undef $MOfile;
        foreach $LOCALEDIR (@SYSTEM_LOCALEDIRS) {
            $_ = catfile($LOCALEDIR, $self->{"LOCALE"},
                $self->{"CATEGORY"}, "$DOMAIN.mo");
            if (-f $_ && -r $_) {
                $MOfile = $_;
                last;
            }
        }
        # Not found at last
        return $DOMAIN if !defined $MOfile;
    
    # This domain was registered
    } else {
        $MOfile = catfile(${$self->{"LOCALEDIRS"}}{$DOMAIN},
            $self->{"LOCALE"}, $self->{"CATEGORY"}, "$DOMAIN.mo");
    }
    
    # Record it
    ${"$class\::MOFILE"} = $MOfile;
    $self->{"MOFILE"} = $MOfile;
    
    # Read the MO file
    # Cached
    if (!exists $ENCODINGS{$MOfile} || !exists $Lexicons{$MOfile}) {
        my $enc;
        # Read it
        %_ = read_mo($MOfile);
        
        # Successfully read
        if (scalar(keys %_) > 0) {
            # Decode it
            # Find the encoding of that MO file
            $_{""} =~ /^Content-Type: text\/plain; charset=(.*)$/im;
            $enc = $1;
            # Set the current encoding to the encoding of the MO file
            $_{$_} = decode($enc, $_{$_}) foreach keys %_;
        }
        # Cache them
        $Lexicons{$MOfile} = \%_;
        $ENCODINGS{$MOfile} = $enc;
    }
    
    # Respect the existing output encoding setting
    $self->{"ENCODING"} = $ENCODINGS{$MOfile}
        if !defined $self->{"ENCODING"};
    $self->{"Lexicon"} = $Lexicons{$MOfile};
    %{"$class\::Lexicon"} = %{$Lexicons{$MOfile}};
    
    return $DOMAIN;
}

# maketext: Encode after maketext
sub maketext {
    local ($_, %_);
    my ($self, $key, @param, $class);
    ($self, $key, @param) = @_;
    
    # This is not a static method -- NOW
    # Sorry to Sean for this
    return if ref($self) eq "";
    # Find the class name
    $class = ref($self);
    
    # MO file should be re-read
    if ($self->{"REREAD_MO"} < $REREAD_MO) {
        $self->{"REREAD_MO"} = $REREAD_MO;
        defined($_ = $self->textdomain) and $self->textdomain($_);
    }
    
    # If the instance lexicon is changed.
    # Maketext uses a class lexicon.  We have to copy the instance
    #   lexicon into the class lexicon.
    # This is slow and stupid.  Mass memory copy sucks.  Avoid create
    #   several objects for a single localization subclass whenever
    #   possible.
    # Maketext uses class lexicon in order to track the inheritance.
    #   It is hard to change it.
    if (${"$class\::MOFILE"} ne $self->{"MOFILE"}) {
        ${"$class\::MOFILE"} = $self->{"MOFILE"};
        %{"$class\::Lexicon"} = %{$self->{"Lexicon"}};
    }
    
    # Decode the _AUTO lexicon first, in order for the _AUTO lexicon
    #   to be multibyte-safe as possible.
    $key = decode($self->{"KEY_ENCODING"}, $key, $self->{"ENCODE_FAILURE"})
        if  !exists ${$self->{"Lexicon"}}{$key} &&
            defined $self->{"KEY_ENCODING"};
    
    # Process with the _AUTO lexicon for lookup failures
    if (    !exists ${$self->{"Lexicon"}}{$key}
            && !$self->{"DIE_FOR_LOOKUP_FAILURES"}) {
        $_ = $_AUTO->maketext($key, @param);
    # Process with the ordinary maketext
    } else {
        $_ = $self->SUPER::maketext($key, @param);
    }
    # Encode with the output encoding
    $_ = encode($self->{"ENCODING"}, $_, $self->{"ENCODE_FAILURE"})
        if defined $self->{"ENCODING"};
    
    return $_;
}

# readmo: Deprecated.  Please use read_mo() instead.
sub readmo {
    local ($_, %_);
    my ($MOfile, $enc);
    $MOfile = $_[0];
    
    # Deprecated
    print STDERR "The use of readmo() is deprecated.  Use read_mo() instead.\n";
    
    # Read it
    %_ = read_mo($MOfile);
    
    # Successfully read
    if (scalar(keys %_) > 0) {
        # Decode it
        # Find the encoding of that MO file
        $_{""} =~ /^Content-Type: text\/plain; charset=(.*)$/im;
        $enc = $1;
        # Set the output encoding to the encoding of the MO file
        $_{$_} = decode($enc, $_{$_}) foreach keys %_;
    }
    
    return ($enc, %_);
}

# read_mo: Subroutine to read and parse the MO file
#          Refer to gettext documentation section 8.3
sub read_mo {
    local ($_, %_);
    my ($MOfile, $len, $FH, $content, $tmpl);
    $MOfile = $_[0];
    
    # Avild being stupid
    return unless -f $MOfile && -r $MOfile;
    # Read the MO file
    $len = (stat $MOfile)[7];
    open $FH, $MOfile   or return;  # GNU gettext never fails! ^_*'
    binmode $FH;
    defined($_ = read $FH, $content, $len)
                        or return;
    close $FH           or return;
    
    # Find the byte order of the MO file creator
    $_ = substr($content, 0, 4);
    # Little endian
    if ($_ eq "\xde\x12\x04\x95") {
    	$tmpl = "V";
    # Big endian
    } elsif ($_ eq "\x95\x04\x12\xde") {
        $tmpl = "N";
    # Wrong magic number.  Not a valid MO file.
    } else {
        return;
    }
    
    # Check the MO format revision number
    $_ = unpack $tmpl, substr($content, 4, 4);
    # There is only one revision now: revision 0.
    return if $_ > 0;
    
    my ($num, $offo, $offt);
    # Number of strings
    $num = unpack $tmpl, substr($content, 8, 4);
    # Offset to the beginning of the original strings
    $offo = unpack $tmpl, substr($content, 12, 4);
    # Offset to the beginning of the translated strings
    $offt = unpack $tmpl, substr($content, 16, 4);
    %_ = qw();
    for ($_ = 0; $_ < $num; $_++) {
        my ($len, $off, $stro, $strt);
        # The first word is the length of the string
        $len = unpack $tmpl, substr($content, $offo+$_*8, 4);
        # The second word is the offset of the string
        $off = unpack $tmpl, substr($content, $offo+$_*8+4, 4);
        # Original string
        $stro = substr($content, $off, $len);
        
        # The first word is the length of the string
        $len = unpack $tmpl, substr($content, $offt+$_*8, 4);
        # The second word is the offset of the string
        $off = unpack $tmpl, substr($content, $offt+$_*8+4, 4);
        # Translated string
        $strt = substr($content, $off, $len);
        
        # Hash it
        $_{$stro} = $strt;
    }
    
    return %_;
}

# reload_text: Method to purge the lexicon cache
sub reload_text {
    local ($_, %_);
    
    # Purge the text cache
    %Lexicons = qw();
    %ENCODINGS = qw();
    $REREAD_MO = time;
    
    return;
}

# die_for_lookup_failures: Whether we should die for lookup failure
# The default is no.  GNU gettext never fails.
sub die_for_lookup_failures {
    local ($_, %_);
    my ($self, $is_die, $class);
    ($self, $is_die) = @_;
    
    # This is not a static method
    return if ref($self) eq "";
    # Find the class name
    $class = ref($self);
    
    # Return the current setting
    return $self->{"DIE_FOR_LOOKUP_FAILURES"} if !defined $is_die;
    
    # Set and return
    return ($self->{"DIE_FOR_LOOKUP_FAILURES"} = ($is_die? 1: 0));
}

# encode_failure: What to do if the text is out of your output encoding
#   Refer to Encode on possible values of this check
sub encode_failure {
    local ($_, %_);
    my ($self, $CHECK);
    ($self, $CHECK) = @_;
    
    # This is not a static method
    return if ref($self) eq "";
    
    # Specify the action used in the keys
    $self->{"ENCODE_FAILURE"} = $CHECK if defined $CHECK;
    
    # Returns the encoding
    return $self->{"ENCODE_FAILURE"};
}

# Public _AUTO lexicon -- process auto lexicon with it, but not the _AUTO
#   lexicon entry, so that the compiled cache of %Lexicon can be preserved
#   and reduce the memory-copy and compilation overhead
package Locale::Maketext::Gettext::_AUTO::L10N;
use strict;
use warnings;
use base qw(Locale::Maketext);
use vars qw(@ISA %Lexicon);

package Locale::Maketext::Gettext::_AUTO::L10N::i_default;
use strict;
use warnings;
use base qw(Locale::Maketext);
use vars qw(@ISA %Lexicon);
%Lexicon = ( "_AUTO" => 1 );

return 1;

__END__

=head1 NAME

Locale::Maketext::Gettext - Joins the gettext and Maketext frameworks

=head1 SYNOPSIS

In your localization class:

  package MyPackage::L10N;
  use base qw(Locale::Maketext::Gettext);
  return 1;

In your application:

  use MyPackage::L10N;
  $LH = MyPackage::L10N->get_handle or die "What language?";
  $LH->bindtextdomain("mypackage", "/home/user/locale");
  $LH->textdomain("mypackage");
  $LH->maketext("Hello, world!!");

If you want to have more control to the detail:

  # Change the output encoding
  $LH->encoding("UTF-8");
  # Stick with the Maketext behavior on lookup failures
  $LH->die_for_lookup_failures(1);
  # Flush the MO file cache and re-read your updated MO files
  $LH->reload_text;
  # Set the encoding of your maketext keys, if not in English
  $LH->key_encoding("Big5");
  # Set the action when encode fails
  $LH->encode_failure(Encode::FB_HTMLCREF);

Use Locale::Maketext::Gettext to read and parse the MO file:

  use Locale::Maketext::Gettext;
  %Lexicon = read_mo($MOfile);

=head1 DESCRIPTION

Locale::Maketext::Gettext joins the GNU gettext and Maketext
frameworks.  It is a subclass of L<Locale::Maketext(3)|Locale::Maketext/3>
that follows the way GNU gettext works.  It works seamlessly, I<both
in the sense of GNU gettext and Maketext>.  As a result, you I<enjoy
both their advantages, and get rid of both their problems, too.>

You start as an usual GNU gettext localization project:  Work on
PO files with the help of translators, reviewers and Emacs.  Turn
them into MO files with F<msgfmt>.  Copy them into the appropriate
locale directory, such as
F</usr/share/locale/de/LC_MESSAGES/myapp.mo>.

Then, build your Maketext localization class, with your base class
changed from L<Locale::Maketext(3)|Locale::Maketext/3> to
Locale::Maketext::Gettext.  That's all. ^_*'

=head1 METHODS

=over

=item $LH->bindtextdomain(DOMAIN, LOCALEDIR)

Register a text domain with a locale directory.  It is only a
registration.  Nothing really happens.  No check is ever made to
whether this C<LOCALEDIR> exists, nor if that C<DOMAIN> really sits
in this C<LOCALEDIR>.  Returns C<LOCALEDIR> itself.  If C<LOCALEDIR>
is omitted, the registered locale directory of C<DOMAIN> is returned.
If C<DOMAIN> is not even registered yet, returns C<undef>.  This
method always success.

=item $LH->textdomain(DOMAIN)

Set the current text domain.  If C<DOMAIN> was not registered with
C<bindtextdomain> before, search the system locale directories for
the corresponding MO file.  Then, it reads the MO file and replaces
your current %Lexicon with this new lexicon.  If anything goes wrong,
for example, MO file not found, unreadable, NFS disconnection, etc.,
it returns immediatly and the your lexicon becomes empty.  Returns
the C<DOMAIN> itself.  If C<DOMAIN> is omitted, the current text
domain is returned.  If the current text domain is not even set yet,
returns C<undef>.  This method always success.

The current system locale directory search order is:
/usr/share/locale, /usr/lib/locale, /usr/local/share/locale,
/usr/local/lib/locale.  Suggestions for this search order are
welcome.

=item $LH->language_tag

Retrieve the language tag.  This is the same method in
L<Locale::Maketext(3)|Locale::Maketext/3>.  It is readonly.

=item $LH->encoding(ENCODING)

Set or retrieve the output encoding.  The default is the same
encoding as the gettext MO file.  You should not override this
method, as contract to the current practice of
L<Locale::Maketext(3)|Locale::Maketext/3>.

=item $LH->encode_failure(CHECK)

Set the action when encode fails.  This happens when the output text
is out of the scope of your output encoding.  For exmaple, output
Chinese into US-ASCII.  Refer to L<Encode(3)|Encode/3> for the
possible values of this C<CHECK>.  The default is C<FB_DEFAULT>,
which is a safe choice that never fails.  But part of your text may
be lost, since that is what C<FB_DEFAULT> does.  Returns the current
setting.

=item $LH->key_encoding(ENCODING)

Specify the encoding used in your original text.  The C<maketext>
method itself isn't multibyte-safe to the _AUTO lexicon.  If you are
using your native non-English language as your original text and you
are having troubles like:

Unterminated bracket group, in:

Then, specify the C<key_encoding> to the encoding of your original
text.  Returns the current setting.

This is a workaround, not a solution.  There is no solution to this
problem yet.  You should avoid using non-English language as your
original text.  You'll get yourself into trouble if you mix several
original text encodings, for example, joining several pieces of code
from programmers all around the world.  Solution suggestions are
welcome.

=item $text = $LH->maketext($key, @param...)

The same method in L<Locale::Maketext(3)|Locale::Maketext/3>, with
a wrapper that return the text string C<encode>d according to the
current C<encoding>.  Refer to
L<Locale::Maketext(3)|Locale::Maketext/3> for its details.

B<NOTICE:> I<MyPackage::L10N::en-E<gt>maketext(...) is not available
anymore,> as the C<maketext> method is no more static.  That is a
sure result, as %Lexicon is imported from foreign sources
dynamically, but not statically hardcoded in perl sources.  But the
documentation of L<Locale::Maketext(3)|Locale::Maketext/3> does not
say that you can use it as a static method anyway.  Maybe you were
practicing this before.  You had better check your existing code for
this.  If you try to invoke it statically, it returns C<undef>.

=item $LH->die_for_lookup_failures(SHOULD_I_DIE)

Maketext dies for lookup failures, but GNU gettext never fails.
By default Lexicon::Maketext::Gettext follows the GNU gettext
behavior.  But if you are Maketext-styled, or if you need a better
control over the failures (like me :p), set this to 1.  Returns the
current setting.

=item $LH->reload_text

Purge the MO text cache.  It purges the MO text cache from the base
class Locale::Maketext::Gettext.  The next time C<maketext> is
called, the MO file will be read and parse from the disk again.  This
is used when your MO file is updated, but you cannot shutdown and
restart the application.  For example, when you are a co-hoster on a
mod_perl-enabled Apache, or when your mod_perl-enabled Apache is too
vital to be restarted for every update of your MO file, or if you
are running a vital daemon, such as an X display server.

=back

=head1 FUNCTIONS

=over

=item %Lexicon = read_mo($MOfile);

Read and parse the MO file.  Returns the read %Lexicon.  The returned
lexicon is in its original encoding.

If you need the meta infomation of your MO file, parse the entry
C<$Lexicon{""}>.  For example:

  /^Content-Type: text\/plain; charset=(.*)$/im;
  $encoding = $1;

C<read_mo()> is exported by default, but you need to C<use
Locale::Maketext::Gettext> in order to use it.  It is not exported
from your localization class, but from the Locale::Maketext::Gettext
package.

=item ($encoding, %Lexicon) = readmo($MOfile);

(deprecated) Read and parse the MO file.  Returns a suggested default
encoding and %Lexicon.  The suggested encoding is the encoding of the
MO file itself.  The %Lexicon is returned in perl's internal
encoding.

This method is deprecated and will be removed in the future.  use
C<read_mo()> instead.  There are far too many meta infomation to be
returned other than its C<encoding>.  It's not possible to change the
API for each new requirement.  See C<read_mo()> above for how to
parse the meta infomation by yourself.

=back

=head1 NOTES

B<WARNING:> Don't try to put any lexicon in your language subclass.
When the C<textdomain> method is called, the current lexicon will be
B<replaced>, but not appended.  This is to accommodate the way
C<textdomain> works.  Messages from the previous text domain should
not stay in the current text domain.

An essential benefit of this Locale::Maketext::Gettext over the
original L<Locale::Maketext(3)|Locale::Maketext/3> is that: 
I<GNU gettext is multibyte safe,> but perl source isn't.  GNU gettext
is safe to Big5 characters like \xa5\x5c (Gong1).  But if you follow
the current L<Locale::Maketext(3)|Locale::Maketext/3> document and
put your lexicon as a hash in the source of a localization subclass,
you have to escape bytes like \x5c, \x40, \x5b, etc., in the middle
of some natural multibyte characters.  This breaks these characters
in halves.  Your non-technical translators and reviewers will be
presented with unreadable mess, "Luan4Ma3".  Sorry to say this, but
it is weird for a localization framework to be not multibyte-safe.
But, well, here comes Locale::Maketext::Gettext to rescue.  With
Locale::Maketext::Gettext, you can sit back and relax now, leaving
all this mess to the excellent GNU gettext framework. ^_*'

The idea of Locale::Maketext::Getttext came from
L<Locale::Maketext::Lexicon(3)|Locale::Maketext::Lexicon/3>, a great
work by Autrijus.  But it has several problems at that time (version
0.16).  I was first trying to write a wrapper to fix it, but finally
I dropped it and decided to make a solution towards
L<Locale::Maketext(3)|Locale::Maketext/3> itself.
L<Locale::Maketext::Lexicon(3)|Locale::Maketext::Lexicon/3> should be
fine now if you obtain a version newer than 0.16.

Locale::Maketext::Gettext also solved the problem of lack of the
ability to handle the encoding in
L<Locale::Maketext(3)|Locale::Maketext/3>.  I implement this since
this is what GNU gettext does.  When %Lexicon is read from MO files
by C<read_mo()>, the encoding tagged in gettext MO files is used to
C<decode> the text into perl's internal encoding.  Then, when
extracted by C<maketext>, it is C<encode>d by the current
C<encoding> value.  The C<encoding> can be set at run time, so
that you can run a daemon and output to different encoding
according to the language settings of individual users, without
having to restart the application.  This is an improvement to the
L<Locale::Maketext(3)|Locale::Maketext/3>, and is essential to
daemons and C<mod_perl> applications.

You should trust the encoding of your gettext MO file.  GNU gettext
C<msgfmt> checks the illegal characters for you when you compile your
MO file from your PO file.  The encoding form your MO files are
always good.  If you try to output to a wrong encoding, part of your
text may be lost, as C<FB_DEFAULT> does.  If you don't like this
C<FB_DEFAULT>, change the failure behavior with the method
C<encode_failure>.

If you need the behavior of auto Traditional Chinese/Simplfied
Chinese conversion, as GNU gettext smartly does, do it yourself with
L<Encode::HanExtra(3)|Encode::HanExtra/3>, too.  There may be a
solution for this in the future, but not now.

C<dgettext> and C<dcgettext> in GNU gettext are not implemented.
It's not possible to temporarily change the current text domain in
the current design of Locale::Maketext::Gettext.  Besides, it's
meaningless.  Locale::Maketext is object-oriented.  You can always
raise a new language handle for another text domain.  This is
different from the situation of GNU gettext.  Also, the category
is always C<LC_MESSAGES>.  Of course it is.  We are gettext and
Maketext. ^_*'

Avoid creating different language handles with different
textdomain on the same localization subclass.  This currently
works, but it violates the basic design of 
L<Locale::Maketext(3)|Locale::Maketext/3>.  In
L<Locale::Maketext(3)|Locale::Maketext/3>, %Lexicon is saved as a
class variable, in order for the lexicon inheritance system to work.
So, multiple language handles to a same localization subclass shares
a same lexicon space.  Their lexicon space clash.  I tried to avoid
this problem by saving a copy of the current lexicon as an instance
variable, and replacing the class lexicon with the current instance
lexicon whenever it is changed by another language handle instance.
But this involves large scaled memory copy, which affects the
proformance seriously.  This is discouraged.  You are adviced to use
a single textdomain for a single localization class.

=head1 BUGS

GNU gettext never fails.  I tries to achieve it as long as possible.
The only reason that maketext may die unexpectedly now is
"Unterminated bracket group".  I cannot get a better solution to it
currently.  Suggestions are welcome.

You are welcome to fix my English.  I have done my best to this
documentation, but I'm not a native English speaker after all. ^^;

=head1 SEE ALSO

L<Locale::Maketext(3)|Locale::Maketext/3>,
L<Locale::Maketext::TPJ13(3)|Locale::Maketext::TPJ13/3>,
L<Locale::Maketext::Lexicon(3)|Locale::Maketext::Lexicon/3>,
L<Encode(3)|Encode/3>, L<bindtextdomain(3)|bindtextdomain/3>,
L<textdomain(3)|textdomain/3>.  Also, please refer to the official GNU
gettext manual at L<http://www.gnu.org/manual/gettext/>.

=head1 AUTHOR

imacat <imacat@mail.imacat.idv.tw>

=head1 COPYRIGHT

Copyright (c) 2003 imacat. All rights reserved. This program is free
software; you can redistribute it and/or modify it under the same terms
as Perl itself.

=cut
