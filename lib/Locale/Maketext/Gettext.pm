# Locale::Maketext::Gettext - bridge gettext to Locale::Maketext

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
$VERSION = 0.02;
@EXPORT = qw(readmo);
@EXPORT_OK = @EXPORT;

use Encode qw(encode decode FB_CROAK);
use File::Spec::Functions qw(catfile);
no strict qw(refs);

use vars qw(%Lexicons %ENCODINGS $REREAD_MO $MOFILE $DIE_FOR_LOOKUP_FAILURES);
$REREAD_MO = 0;
$MOFILE = "";

# encoding: Set or retrieve the encoding
sub encoding {
    local ($_, %_);
    my ($self, $new_enc, $pkg);
    ($self, $new_enc) = @_;
    
    # Return the current encoding
    return $self->{"CUR_ENC"} if !defined $new_enc;
    
    # Set the current encoding
    return ($self->{"CUR_ENC"} = $new_enc);
}

# Sorry for Sean... :p
sub new {
    my ($self, $pkg);
    # Nothing fancy!
    $pkg = ref($_[0]) || $_[0];
    $self = bless {}, $pkg;
    
    # Initialize the LOCALEDIRS registry
    $self->{"LOCALEDIRS"} = { };
    # Initialize the MO timestamp
    $self->{"REREAD_MO"} = $REREAD_MO;
    # Initialize the DIE_FOR_LOOKUP_FAILURES value
    $self->{"DIE_FOR_LOOKUP_FAILURES"} = 0;
    ${"$pkg\::Lexicon"}{"_AUTO"} = 1;
    # Initialize the MOFILE value of this instance
    $self->{"MOFILE"} = "";
    ${"$pkg\::MOFILE"} = "" if !defined ${"$pkg\::MOFILE"};
    
    $self->init;
    return $self;
}

# bindtextdomain: Bind a text domain to a locale directory
sub bindtextdomain {
    local ($_, %_);
    my ($self, $DOMAIN, $LOCALEDIR, $pkg);
    ($self, $DOMAIN, $LOCALEDIR) = @_;
    
    # Initialize the registry
    $self->{"LOCALEDIRS"} = { } if !defined $self->{"LOCALEDIRS"};
    
    # Return null for this rare case
    return if   !defined $LOCALEDIR
                && !exists ${$self->{"LOCALEDIRS"}}{$DOMAIN};
    
    ${$self->{"LOCALEDIRS"}}{$DOMAIN} = $LOCALEDIR if defined $LOCALEDIR;
    return ${$self->{"LOCALEDIRS"}}{$DOMAIN};
}

# textdomain: Set the current text domain
sub textdomain {
    local ($_, %_);
    my ($self, $DOMAIN, $pkg, $file, %lex);
    ($self, $DOMAIN) = @_;
    
    # Find the caller package name
    $pkg = ref($self);
    
    # Return the current domain
    return $self->{"CUR_DOMAIN"} if !defined $DOMAIN;
    
    # Set the timestamp of this read in this instance
    $self->{"REREAD_MO"} = $REREAD_MO;
    
    # Set the current domain
    $self->{"CUR_DOMAIN"} = $DOMAIN;
    
    # Find the locale name, for this subclass
    if (!defined $self->{"LOCALE"}) {
        $self->{"LOCALE"} = $pkg;
        $self->{"LOCALE"} =~ s/^.*:://;
        $self->{"LOCALE"} =~ s/(_)(.*)$/$1 . uc $2/e;
    }
    
    # Clear it
    $self->{"Lexicon"} = {};
    %{"$pkg\::Lexicon"} = qw();
    ${"$pkg\::Lexicon"}{"_AUTO"} = 1 unless $self->{"DIE_FOR_LOOKUP_FAILURES"};
    
    # Return if this domain was not binded yet
    return $DOMAIN if !exists ${$self->{"LOCALEDIRS"}}{$DOMAIN};
    
    # import the PO files
    # The format is "{LOCALEDIR}/{LANG}/LC_MESSAGES/{DOMAIN}.mo"
    # The category is always LC_MESSAGES.  I'm not planning to change it
    $file = catfile(${$self->{"LOCALEDIRS"}}{$DOMAIN}, $self->{"LOCALE"}, "LC_MESSAGES", "$DOMAIN.mo");
    # Record it
    ${"$pkg\::MOFILE"} = $file;
    $self->{"MOFILE"} = $file;
    # Avoid avoid being stupid
    return $DOMAIN unless -f $file;
    
    # Read the MO file
    ($_, %_) = readmo($file);
    # Keep the current encoding
    $self->{"CUR_ENC"} = $_ if !defined $self->{"CUR_ENC"};
    $self->{"Lexicon"} = \%_;
    %{"$pkg\::Lexicon"} = %_;
    ${"$pkg\::Lexicon"}{"_AUTO"} = 1 unless $self->{"DIE_FOR_LOOKUP_FAILURES"};
    
    return $DOMAIN;
}

# maketext: Encode after maketext
sub maketext {
    local ($_, %_);
    my ($self, $key, @param, $pkg);
    ($self, $key, @param) = @_;
    
    # Find the caller package name
    $pkg = ref($self);
    
    # MO file should be ret-read
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
    #   This is not changable.
    if (${"$pkg\::MOFILE"} ne $self->{"MOFILE"}) {
        ${"$pkg\::MOFILE"} = $self->{"MOFILE"};
        %{"$pkg\::Lexicon"} = %{$self->{"Lexicon"}};
        ${"$pkg\::Lexicon"}{"_AUTO"} = 1
            unless $self->{"DIE_FOR_LOOKUP_FAILURES"};
    }
    
    # Strange that I have to do this.  If maketext is called before
    # setting textdomain, all the following maketext calls fails
    exists ${"$pkg\::Lexicon"}{$key};
    $_ = $self->SUPER::maketext($key, @param);
    $_ = encode($self->{"CUR_ENC"}, $_, FB_CROAK)
        if defined $self->{"CUR_ENC"};
    
    return $_;
}

# readmo: Subroutine to read the MO file
#         Refer to gettext documentation section 8.3
sub readmo {
    local ($_, %_);
    my ($MOfile, $len, $FH, $content, $tmpl, $enc);
    $MOfile = $_[0];
    
    # Read before -- return the cached result
    return ($ENCODINGS{$MOfile}, %{$Lexicons{$MOfile}})
        if exists $ENCODINGS{$MOfile} && exists $Lexicons{$MOfile};
    
    # Read the MO file
    $len = (stat $MOfile)[7];
    open $FH, $MOfile   or return;  # GNU gettext never get wrong! ^_*'
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
    
    # Decode it
    # Find the encoding of that MO file
    $_{""} =~ /^Content-Type: text\/plain; charset=(.*)$/im;
    $enc = $1;
    # Set the current encoding to the encoding of the MO file
    $_{$_} = decode($enc, $_{$_}, FB_CROAK) foreach keys %_;
    
    # Cache them
    $Lexicons{$MOfile} = \%_;
    $ENCODINGS{$MOfile} = $enc;
    
    return ($enc, %_);
}

# reload_text: Method to purge the lexicon cache
sub reload_text {
    local ($_, %_);
    my ($self);
    $self = $_[0];
    
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
    my ($self, $is_die, $pkg);
    ($self, $is_die) = @_;
    
    # Find the caller package name
    $pkg = ref($self);
    
    # Return the current setting
    return $self->{"DIE_FOR_LOOKUP_FAILURES"} if !defined $is_die;
    
    $self->{"LOCALE"} = $pkg;
    # Set to yes
    if ($is_die) {
        delete ${"$pkg\::Lexicon"}{"_AUTO"};
        return ($self->{"DIE_FOR_LOOKUP_FAILURES"} = 1);
    # Set to no.  GNU gettext never fails.
    } else {
        ${"$pkg\::Lexicon"}{"_AUTO"} = 1;
        return ($self->{"DIE_FOR_LOOKUP_FAILURES"} = 0);
    }
}

return 1;

__END__

=head1 NAME

Locale::Maketext::Gettext - brings gettext and Maketext together

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
whether this C<LOCALEDIR> exists, nor if C<DOMAIN> really sit in this
C<LOCALEDIR>.  Returns C<LOCALEDIR> itself.  If C<LOCALEDIR> is
omitted, the registered locale directory of C<DOMAIN> is returned.
If C<DOMAIN> is not even registered yet, returns C<undef>.  This
method always success.

Don't do $LH-E<gt>bindtextdomain(DOMAIN, $LH-E<gt>bindtextdomain) on
an unregistered domain.  This is an infinite loop, and I'm not
planning to fix it, in order to conform to the GNU gettext behavior.
You should always use

defined($_ = $LH-E<gt>bindtextdomain(DOMAIN)) and $LH-E<gt>bindtextdomain(DOMAIN, $_)

instead.

=item $LH->textdomain(DOMAIN)

Set the current text domain.  It reads the corresponding MO file
and replaces the %Lexicon with this new lexicon.  If anything goes
wrong, for example, MO file not found, unreadable, NFS
disconnection, etc., it returns immediatly and the your lexicon
becomes empty.  Returns the C<DOMAIN> itself.  If C<DOMAIN> is
omitted, the current text domain is returned.  If the current text
domain is not even set yet, returns C<undef>.  This method always
success.

Don't do $LH-E<gt>textdomain($LH-E<gt>textdomain) before your text
domain is set.  This is an infinite loop, and I'm not planning to fix
it, in order to conform to the GNU gettext behavior.  You should
always use

defined($_ = $LH-E<gt>textdomain(DOMAIN)) and $LH-E<gt>textdomain(DOMAIN, $_)

instead.

=item $LH->language_tag

Retrieve the output encoding.  This is the same method in
L<Locale::Maketext(3)|Locale::Maketext/3>.  It is readonly.

=item $LH->encoding(ENCODING)

Set or retrieve the output encoding.  The default is the same
encoding as the gettext MO file.  You should not override this method
in your localization subclasses, as contract to the current
practice of L<Locale::Maketext(3)|Locale::Maketext/3>.

B<WARNING:>  You should always trust the encoding in the gettext
MO file.  GNU gettext C<msgfmt> will check the illegal characters for
you when you compile your MO file fro your PO file.  If you try to
output to an wrong encoding, C<maketext> will C<die> for illegal
characters in your text.  For example, try to turn Chinese text into
US-ASCII.  If you DO need to output to a different encoding, use the
value of this method and C<from_to> from L<Encode(3)|Encode/3> to do
your job.  I'm not planning to supply an option for this C<die>.
So, change the output encoding at your own risk.

If you need the behavior of auto Traditional Chinese/Simplfied
Chinese conversion, as GNU gettext smartly does, do it yourself with
the L<Encode::HanExtra(3)|Encode::HanExtra/3>, too.  There may be a
solution for this in the future, but not now.

=item $text = $LH->maketext($key, @param...)

The same method in L<Locale::Maketext(3)|Locale::Maketext/3>, with
a wrapper that return the text string C<encode>d according to the
current C<encoding>.

=item $LH->die_for_lookup_failures(SHOULD_I_DIE)

Maketext dies for lookup failures, but GNU gettext never fails.
By default Lexicon::Maketext::Gettext follows the GNU gettext
behavior.  But if you are old-styled, or if you want a better
control over the failures, set this to 1.  Returns the current
setting.

=item $LH->reload_text

Purge the MO text cache.  It purges the MO text cache from the base
class Locale::Maketext::Gettext.  The next time C<maketext> is
called, the MO file will be read and parse from the disk again.  This
is used whenever your MO file is updated, but you cannot shutdown and
restart the application.  For example, you are a co-hoster on a
mod_perl-enabled Apache, or your mod_perl-enabled Apache is too
vital to be restarted for every update of your MO file, or if you
are running a vital daemon, such as an X display server.

=back

=head1 FUNCTIONS

=over

=item ($encoding, %Lexicon) = readmo($MOfile);

Read and parse the MO file and return a suggested default encoding
and %Lexicon.  The suggested encoding is the encoding of the MO file
itself.  This subroutine is called by the C<textdomain> method to
retrieve the current %Lexicon.  The result is cached, to reduce the
file I/O and parsing overhead.  This is essential to C<mod_perl>
where C<textdomain> asks for %Lexicon for each request.  This is
the same way GNU gettext works.  If you DO need to re-read the
modified MO file, call the C<reload_text> method above.

C<readmo()> is exported by default.

=back

=head1 NOTES

B<WARNING:> Don't try to put any lexicon in your language subclass.
When the C<textdomain> method is called, the current lexicon will be
B<replaced>, but not appended.  This is to accommodate the way
C<textdomain> works.  Messages from the previous text domain should
not stay in the current text domain.

An essential benefit of this Locale::Maketext::Gettext over the
original L<Locale::Maketext(3)|Locale::Maketext/3> is that: 
I<GNU gettext is multibyte safe,> but perl code is not.  GNU gettext
is safe to Big5 characters like \xa5\x5c (Gong1).  You always have to
escape bytes like \x5c, \x40, \x5b, etc, and your non-technical
translators and reviewers will be presented with a mess, the
so-called "Luan4Ma3".  Sorry to say this, but it is, in fact, weird
for a localization framework to be not multibyte-safe.  But, well,
here comes Locale::Maketext::Gettext to rescue.  With
Locale::Maketext::Gettext, you can sit back and leave all these mess
to the excellent GNU gettext from now on. ^_*'

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
ability to handle the encoding in
L<Locale::Maketext(3)|Locale::Maketext/3>.  I implement this since
this is what GNU gettext does.  When %Lexicon is read from MO files
by C<readmo()>, the encoding tagged in gettext MO files is used to
C<decode> the text into perl's internal encoding.  Then, when
extracted by C<maketext>, it is C<encode>d by the current
C<encoding> value.  The C<encoding> can be changed at run time, so
that you can run a daemon and output to different encoding
according to the language settings of individual users, without
having to restart the application.  This is an improvement to the
L<Locale::Maketext(3)|Locale::Maketext/3>, and is essential to
daemons and C<mod_perl> applications.

C<dgettext> and C<dcgettext> in GNU gettext are not implemented.
It's not possible to temporarily change the current text domain in
the current design of Locale::Maketext::Gettext.  Besides, it's
meaningless.  Locale::Maketext is object-oriented.  You can always
raise a new language handle for another text domain.  This is
different from the situation of GNU gettext.  Also, the category
is always C<LC_MESSAGES>.  It's meaningless to change it.

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

All the problems I have noticed have been fixed.  You are welcome
to submit new ones. ^_*'  Maybe a long-winded docmuentation is a
bug, too. :p

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
