# Locale::Maketext::Gettext - bridge gettext to Locale::Maketext

# Copyright (c) 2003 imacat. All rights reserved. This program is free
# software; you can redistribute it and/or modify it under the same terms
# as Perl itself.
# First written: 2003-04-23

package Locale::Maketext::Gettext;
use 5.008;
use strict;
use warnings;
use base qw(Locale::Maketext);
use vars qw($VERSION @ISA %Lexicon);
$VERSION = 0.01;
use vars qw(%Lexicons $LOCALE %LOCALEDIRS $CUR_DOMAIN $CUR_ENC %DEF_ENC);
use constant LAST_DEF_ENC => "utf-8";
%DEF_ENC = (
    "zh-tw" => "big5",
    "zh-hk" => "big5-hkscs",
    "zh-cn" => "gb2312",
    "zh-sg" => "gb2312",
    "zh"    => "big5",      # :p
    "ja"    => "shift-jis",
    "ko"    => "euc-kr",
    "en-us" => "us-ascii",
    "en"    => "us-ascii",
    "de"    => "iso-8859-1",
);

use Encode qw(encode decode FB_CROAK);
use Fcntl qw(:flock);
use File::Spec::Functions qw(catfile);
no strict qw(refs);

# encoding: Set or retrieve the encoding
sub encoding {
    local ($_, %_);
    my ($self, $new_enc, $pkg);
    ($self, $new_enc) = @_;
    
    # Find the caller package name
    $pkg = ref($self);
    
    # Set the current encoding
    return (${"$pkg\::CUR_ENC"} = $new_enc) if defined $new_enc;
    
    # Return the current encoding
    return ${"$pkg\::CUR_ENC"} if defined ${"$pkg\::CUR_ENC"};
    
    # Check the default encoding
    $_ = $self->language_tag;
    return (${"$pkg\::CUR_ENC"} = $DEF_ENC{$_})
        if exists $DEF_ENC{$_};
    
    # Return the last default encoding encoding
    return (${"$pkg\::CUR_ENC"} = LAST_DEF_ENC);
}

# Override the new method to initialize the encoding
#   Sorry, Sean :p
sub new {
  # Nothing fancy!
  my $class = ref($_[0]) || $_[0];
  my $handle = bless {}, $class;
  # Initialize the encoding
  $handle->encoding;
  $handle->init;
  return $handle;
}

# bindtextdomain: Bind a text domain to a locale directory
sub bindtextdomain {
    local ($_, %_);
    my ($self, $DOMAIN, $LOCALEDIR);
    ($self, $DOMAIN, $LOCALEDIR) = @_;
    
    # Return null for this rare case
    return if !defined $LOCALEDIR && !exists $LOCALEDIRS{$DOMAIN};
    
    $LOCALEDIRS{$DOMAIN} = $LOCALEDIR if defined $LOCALEDIR;
    return $LOCALEDIRS{$DOMAIN};
}

# textdomain: Set the current text domain
sub textdomain {
    local ($_, %_);
    my ($self, $DOMAIN, $pkg, $locale, $file, %lex);
    ($self, $DOMAIN) = @_;
    
    # Return the current domain
    return $CUR_DOMAIN if !defined $DOMAIN;
    
    # Set the current domain
    $CUR_DOMAIN = $DOMAIN;
    
    # Find the caller package name
    $pkg = ref($self);
    
    # Find the locale name, for once only
    if (!defined ${"$pkg\::LOCALE"}) {
        ${"$pkg\::LOCALE"} = $self->language_tag;
        ${"$pkg\::LOCALE"} =~ s/-/_/g;
        ${"$pkg\::LOCALE"} =~ s/(_)(.*)$/$1 . uc $2/e;
    }
    
    # Clear it
    %{"$pkg\::Lexicon"} = qw();
    
    # Return if this domain was not binded yet
    return $DOMAIN if !exists $LOCALEDIRS{$DOMAIN};
    
    # import the PO files
    # The format is "{LOCALEDIR}/{LANG}/LC_MESSAGES/{DOMAIN}.mo"
    # The category is always LC_MESSAGES.  I'm not planning to change it
    $file = catfile($LOCALEDIRS{$DOMAIN}, ${"$pkg\::LOCALE"}, "LC_MESSAGES", "$DOMAIN.mo");
    # Avoid avoid being stupid
    return $DOMAIN unless -f $file;
    
    # Read the MO file
    %{"$pkg\::Lexicon"} = readmo($file);
    
    return $DOMAIN;
}

# maketext: Encode after maketext
sub maketext {
    local ($_, %_);
    my ($self, $key, @param);
    ($self, $key, @param) = @_;
    
    $_ = $self->SUPER::maketext($key, @param);
    $_ = encode($self->encoding, $_, FB_CROAK);
    
    return $_;
}

# readmo: Subroutine to read the MO file
#         Refer to gettext documentation section 8.3
sub readmo {
    local ($_, %_);
    my ($mo, $FH, $content, $len);
    $mo = $_[0];
    
    # Read before -- return the cached result
    return %{$Lexicons{$mo}} if exists $Lexicons{$mo};
    
    # Read the MO file
    $len = (stat $mo)[7];
    open $FH, $mo       or return;  # GNU gettext never get wrong! ^_*'
    binmode $FH;
    defined($_ = read $FH, $content, $len)
                        or return;
    close $FH           or return;
    
    # Sanity checks
    # If this is a MO file
    $_ = substr($content, 0, 4);
    return unless $_ eq "\x95\x04\x12\xde" || $_ eq "\xde\x12\x04\x95";
    # If this is in a right MO revision number
    $_ = unpack "L", substr($content, 4, 4);
    return unless $_ == 0;
    
    my ($num, $offo, $offt);
    # Number of strings
    $num = unpack "L", substr($content, 8, 4);
    # Offset to the beginning of the original strings
    $offo = unpack "L", substr($content, 12, 4);
    # Offset to the beginning of the translated strings
    $offt = unpack "L", substr($content, 16, 4);
    %_ = qw();
    for ($_ = 0; $_ < $num; $_++) {
        my ($len, $off, $stro, $strt);
        # The first word is the length of the string
        $len = unpack "L", substr($content, $offo+$_*8, 4);
        # The second word is the offset of the string
        $off = unpack "L", substr($content, $offo+$_*8+4, 4);
        # Original string
        $stro = substr($content, $off, $len);
        
        # The first word is the length of the string
        $len = unpack "L", substr($content, $offt+$_*8, 4);
        # The second word is the offset of the string
        $off = unpack "L", substr($content, $offt+$_*8+4, 4);
        # Translated string
        $strt = substr($content, $off, $len);
        
        # Hash it
        $_{$stro} = $strt;
    }
    
    # Decode it
    # Find the encoding of that MO file
    $_{""} =~ /^Content-Type: text\/plain; charset=(.*)$/im;
    my $enc = $1;
    $_{$_} = decode($enc, $_{$_}, FB_CROAK) foreach keys %_;
    
    # Cache it
    $Lexicons{$mo} = \%_;
    
    return %_;
}

return 1;

__END__

=head1 NAME

Locale::Maketext::Gettext - bring Maketext and gettext together

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

=head1 DESCRIPTION

Locale::Maketext::Gettext brings GNU gettext and Maketext together.
It is a subclass of L<Locale::Maketext(3)|Locale::Maketext/3> that
follows the way GNU gettext works.  It works seamlessly, I<both in
the sense of GNU gettext and Maketext>.

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
registration.  Nothing really happens here.  No check is ever made
whether this LOCALEDIR exists, nor if DOMAIN really sit in this
LOCALEDIR.  Returns LOCALEDIR itself.  If LOCALEDIR is omitted, the
registered locale directory of DOMAIN is returned.  If DOMAIN is not
even registered yet, return undef.  This method always success.

=item $LH->textdomain(DOMAIN)

Set the current text domain.  It reads the corresponding MO file
and replaces the %Lexicon with this new lexicon.  If anything went
wrong, for example, MO file not found, unreadable, NFS
disconnection, etc., it returns immediatly and the your lexicon
becomes empty.  Returns the DOMAIN itself.  If DOMAIN is omitted, the
current text domain is returned.  If the current text domain is not
even set yet, return undef.  This method always success.

=item $LH->language_tag

Retrieve the output encoding.  This is the same method in
L<Locale::Maketext(3)|Locale::Maketext/3>.  It is readonly.

=item $LH->encoding(ENCODING)

Set or retrieve the output encoding.  The default is UTF-8 for the
whole bunch of languages I do not know. :p  You should check this
ans set it according to the current language tag and your
requirement.  You can access the current language tag by the
$LH->language_tag method above.

B<WARNING:>  If you set this to an incorrect encoding, C<maketext>
may die for illegal characters in that encoding.  For example, try
to encode Chinese text into US-ASCII.  You can trap this failure in
an C<eval {}>, or alternatively you can set the encoding to UTF-8
and post-process the returned UTF-8 text by yourself.

=item $text = $LH->maketext($key, @param...)

The same method in L<Locale::Maketext(3)|Locale::Maketext/3>, with
a wrapper that return the text string C<encode>d according to the
current C<encoding>.

=back

=head1 FUNCTIONS

=over

=item %Lexicon = Locale::Maketext::Gettext::readmo($MOfile);

Read and parse the MO file and return the %Lexicon.  This subroutine
is called by the C<textdomain> method to retrieve the current
%Lexicon.  The result is cached, to reduce the overhead of file
reading and parsing again and again, especially in C<mod_perl> where
C<textdomain> may ask for %Lexicon for every connection.  This is
exactly the same way GNU gettext works.  I'm not planning to change
it.  If you DO need to re-read the modified MO file, clear
the hash %Locale::Maketext::Gettext::Lexicons.

C<readmo()> recognizes the MO file format revision number, and refuses
to parse unrecognized MO file formats.  Currently there is only one MO
file format: revision 0.

C<readmo()> is not automatically exported.

=back

=head1 NOTES

B<WARNING:> Don't try to put any lexicon in your language subclass.
When the C<textdomain> method is called, the current lexicon will be
B<replaced>, but not appended.  This is to accommodate the way
C<textdomain> works.  Messages from the previous text domain should
not stay in the current text domain.

The idea of Locale::Maketext::Getttext came from
L<Locale::Maketext::Lexicon(3)|Locale::Maketext::Lexicon/3>, a great
work by autrijus.  But it is simply not finished yet and not
practically usable.  So I decide to write a replacement.

The part of calling F<msgunfmt> is removed.  The gettext MO file
format is officially documented, so I decided to parse it by myself.
It is not hard.  It reduces the overhead to raising a subshell.  It
benefits from the fact that reading and parsing MO binary files is
much faster then PO text files, since regular expression is not
involved.  Also, after all, F<msgunfmt> is not portable on non-GNU
systems.

Locale::Maketext::Gettext also solved the problem of lack of the
ability to handle the encoding in L<Locale::Maketext(3)|Locale::Maketext/3>.
When %Lexicon is read from MO files by C<readmo()>, the encoding
tagged in gettext MO files is used to C<decode> the text into
perl's internal encoding.  Then, when extracted by C<maketext>, it is
C<encode>d by the current C<encoding> value.  The C<encoding> can
be changed at run time, so that you can run a daemon and output to
different encoding according to the language settings of individual
users, without having to restart the application.  This is an
improvement to the L<Locale::Maketext(3)|Locale::Maketext/3>, and is
essential to daemons and C<mod_perl> applications.

Another benefit of this C<encode/decode> is described below:  In some
multi-byte encodings, like Big5, the Maketext magic characters C<[>
and C<]> are part of some multibyte characters.  It will raise the
error of "Unterminated bracket group" to Locale::Maketext, even
though it is most natural to the native language speakers.  It isn't
right to insert an escape character before that magic character,
since this breaks the whole multibyte character into halves, and the
text will become unreadable to the translators and reviewers.  A
C<decode> wrapper solves this problem.  The internal encoding of
perl is, utill now, Maketext-safe.

=head1 BUGS

=over

=item The default encodings of all the languages

The default encoding for all languages should not be UTF-8.  It's the
last thing to do.  I tries to tell the default encoding of all
possible language I know, including zh-tw, zh-cn, zh-hk, zh-sg, zh,
ja, ko, en-us, en.  Please tell me the proper default encoding of
your language so that I can add it into this list.  Thank you. ^_*'

And I'll be mostly appreciated if someone can solve this in another
module, like in I18N::LangTags (or if someone can show me a table so
that I can create something like I18N::LangTags::Encodings).
Deciding the default encoding should not be the job of
Locale::Maketext::Gettext.

The reason for a "default encoding" is clear:  I<GNU gettext never
fails.>  It works when if you set your locale to zh_TW, but not
zh_TW.Big5.  That's the right thing to do.

=item Error handler when encode failed

There should be an option to decide what to do when encode failed.
The only 2 reasonble choices for me are C<FB_CROAK> and
C<FB_HTMLCREF>.  I choose C<FB_CROAK>, since C<FB_HTMLCREF> is
certainly not a good choice as a default behavior.  But C<FB_CROAK>
is not a good choice, too.  I should implement some way to set this
at run time.  It's not hard.  It's just that I didn't do it yet.

I think the other thing may be necessary, too:  A method to check
if this current encoding works.  That is, C<encode/decode> every text
strings using the current encoding and see if everyone smiles.
This should only be used in the development stage, for example, to
check if the returning text from the translators/reviewers contains
any illegal characters in their PO/MO files.

=item A method to clear the current MO text cache

Is this necessary?  I don't know.  It is not hard, after all.  It
might be necessary for a C<mod_perl> application, to update the
text translation without having to restart Apache.

=back

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
