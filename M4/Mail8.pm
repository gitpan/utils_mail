#!/usr/bin/perl -w
# Copyright (c) 2007 celmorlauren limited. All rights reserved. 
# This program is free software; you can redistribute it and/or modify it under
# the same terms as Perl itself.

package Sendmail::M4::Mail8;
require Exporter;
use vars qw(@ISA @EXPORT $VERSION);
use strict;

@ISA    = qw(Exporter);
@EXPORT = ();
$VERSION= 0.2;

use Sendmail::M4::Utils;

=head1 NAME

Sendmail::M4::Mail8 - Stop fake MX and most spammers, sendmail M4 hack file

=head1 STATUS

Version 0.2 (early Beta)
Very much a work in progress.

=head1 SYNOPSIS

SPAM consitutes the bulk of e-mail on the internet, many methods exist to fight this scurge, some better than others. However we think that this module is the simplest, quickest and most efective, relying as it does on the basic power of B<sendmail> macros for most of its methods.

As all systems have an IP address and most have some sought of domain-name, it is possible to base the protection on wether the IP ties up with whom they claim to be at the <helo> stage. You can set B<sendmail> to be picky about this. But many peoples IP address does not resolve to what they would like, its easy to setup domain to IP via people like B<network associates>, but the other way round needs a friendy ISP. 
So as this is a common problem, base the protection on the B<helo> resolving to their IP.

Next check that their domain does not contain their IP encoded somehow, people who are not real MXs tend to have numeric user addresses, this has tuning to control how strict this is.

Keep a record of whom the system has sent mail to, so that we have a chance of spotting spammers using fake bounces to fill up a users email box, at the most paranoid this refuses all bounces. That causes some problems with some systems who use fake bounces to check wether you are an MX, some even come from a completly different domain to the one being talked to at the time!??! Stupid or what?

Next check that the B<From> address is not pretending to be one of your own hosted domains, ie the IP is external and is not known to you as an outside user.

After that noraml B<sendmail> DB files will do the rest, use the B<cookbook>, all you need to know is there.

Sendmail::M4::Utils does most of the work for this module, all this does is format the B<rule>s and supply a default name for the hack. Various tuning methods exist, and of course you can add your own B<rule>s to this.


This module is non OO, and exports the methods descriped under EXPORTS.

=head1 AUTHOR

Ian McNulty, celmorlauren limited (registered in England & Wales 5418604). 

email E<lt>development@celmorlauren.comE<gt>

=head1 USES

 Sendmail::M4::Utils    the module created to make testing this easier

=head1 EXPORTS

=cut

=head2 HASH REF = mail8_setup(@_)   Sendmail::M4::Utils::setup HASH REF

=over 4

This configures this module, and is allways required first.

Expected/Allowed values allways as a (hash value pairing), see C<Sendmail::M4::Utils> for hash=>value pairings it expects, the list bellow are either default values or additional for use by this.

    file    SCALAR with default value of "mail8-stop-fake-mx.m4",
    build   SCALAR with default value of 1
    install SCALAR with default value of 1
    test    SCALAR with default value of 1

    paranoid
            SCALAR see heading below for values

=over 12

=over 4

=item 0 

not paranoid at all, has local users and is content to accept bounces and "callback verify" sudo bounces.

Standard sendmail rules and databases will handle user and bounce requests.
This just verifys that the sending host appears to be legimate.
Assuming that the hit rate on the system is not too great, use sendmail "milters" as well to take care of "spam" and "viruses"

=item 1 

slightly paranoid, has local users and is content to accept "callback verify" sudo bounces, but will refuse any bounce request that really is a bounce, that is a bounce with data.

=item 2

mildly paranoid, is a relay host with no local users, will say OK to all "callback verify" requests that refer to hosted domains, regardless of wether the user exits or not!
Refuses all real bounces.

=item 3

paranoid, is a hassled relay host, will just say OK to any "callback verify" request, regardless of wether it relays for that domain or not! Refuses all real bounces.

=item 4

fairly paranoid, is a really hasseled relay host, and has no time for any type of bounce, all refused. Most e-mail and even more bounces are bogus.

=back

=back


=cut
push @EXPORT, "mail8_setup";
my $mail8_setup;
sub mail8_setup
{
    $mail8_setup = setup   file=>"mail8-stop-fake-mx.m4", 
                           build=>1, 
                           install=>1, 
                           test=>1, 
                           @_;
    return $mail8_setup;
}


=head2 copyright(@_)

=over 4

copyright message to list at the start of the B<hack>, anything supplied will replace the first two lines below.

Copyright (c) 2007 celmorlauren Limited England
Author: Ian McNulty       <development\@celmorlauren.com>

this should live in /usr/share/sendmail/hack/

some settings that are advised
  FEATURE(`access_db',	`hash -TE<lt>TMPFE<gt> -o /etc/mail/access.db')
  FEATURE(`greet_pause',	`2000')
  define(`confPRIVACY_FLAGS', `goaway')

=back

=cut
push @EXPORT, "copyright";
sub copyright
{
    my @cr = (scalar @_)
        ?(@_)
        :(  "Copyright (c) 2007 celmorlauren Limited England",
            "Author: Ian McNulty       <development\@celmorlauren.com>");
    dnl @cr, <<DNL;

this should live in /usr/share/sendmail/hack/

some settings that are advised
  FEATURE(`access_db',	`hash -T<TMPF> -o /etc/mail/access.db')
  FEATURE(`greet_pause',	`2000')
  define(`confPRIVACY_FLAGS', `goaway')
DNL

}

=head2 version_id

=over 4

This is really a reminder to use B<VERSIONID> with your own value, or just use this to use the default

VERSIONID "ANTI SPAM & FAKE MX"

=back

=cut
push @EXPORT, "version_id";
sub version_id
{
    VERSIONID "ANTI SPAM & FAKE MX";
}

=head2 local_config

=over 4

Required statement, this inserts required statements into the hack file.

This inserts required statements before and after B<LOCAL_CONFIG>, you may add more statements that belong here.

Main items
    "-"                 added to confOPERATORS
    KRlookup            for DNS check on HELO host name
    H*: $>+ScreenHeader to check received headers
    KMath arith         to join the IP address together into a single token

    KZombie program -t /etc/mail/mail8_zombie.pl
                        this is included in the script regardless 
                        of wether it is installed or not
                        and will be uploaded as part of this
                        as soon as possible.

=back

=cut
push @EXPORT, "local_config";
sub local_config
{
    dnl <<DNL;

SPAM checking additions --------------------------
'-' added to trap DSL faked domain names

DNL
    echo <<ECHO;
define(`confOPERATORS',`.:@!^/[]-')
ECHO

    LOCAL_CONFIG;

    echo <<ECHO;
KRlookup dns -RA -a.FOUND -d5s -r4
KMath arith
KZombie program -t /etc/mail/mail8_zombie.pl
ECHO

# we can do some checking with HEADER lines
    echo "H*: £>+ScreenHeader";

}

=head2 PerlHelpers

=over 4

This enables the use of the additional Perl scripts to identify and block bogus e-mail hosts, especialy when the site is being bombed by an abusive system.

None of the scripts are currently available on CPAN, and there is no current intention of releasing them at this time, this is mostly due to the extra system setup required, such as interfaces to the B<iptables> firewall script bring used!

If you would like to use these, contact celmorlauren for help.

=back

=cut
push @EXPORT, "PerlHelpers";
sub PerlHelpers
{
# perl scripts, last resort due to high overhead in starting
    $mail8_setup->{'PerlHelpers'} = 1;
    echo <<ECHO;
dnl perl programs, used as last resort
Kmail8 program /etc/mail/mail8/mail8.pl
Kmail8b program /etc/mail/mail8/mail8block.pl
Kmail9b program /etc/mail/mail8/mail9block.pl
ECHO
}

=head2 mail8_db(SCALAR test)

=over 4

These are configured automatically by the above B<PerlHelpers>, however they can be setup by hand, so are still useable even if you do not use B<PerlHelpers>.

use B<vi ###; makemap hash ###.db E<lt>###> where ### is the database source.

    /etc/mail/mail8/mail9.db        ip (address port 25) to TarPit
                                    in firewall rules
    /etc/mail/mail8/mail8.db        refuse connect to SPAMMER
                                    access.db also does this and more
    /etc/mail/mail8/mail4.db        allow, OK this host would fail tests
    /etc/mail/mail8/mail3.db        single shot, allow, like mail4
    /etc/mail/mail8/mail2.db        relays hosted domains
                                    $=R, $=w, & ${VirtHost} also does this
    /etc/mail/mail8/mail1.db        relays internal hosts by IP
                                    192.168.#.#     assummed local
                                    172.16.#.#      assummed local
                                    10.#.#.#        assummed local


B<NOTE> This files are all optional, so this can be specified even if none of these exist.

The single useable argument if SCALAR will place the DataBases in /var/tmp/mail8, which enables you to test with alternate files to the running version.

=back

=cut
push @EXPORT, "mail8_db";
sub mail8_db
{
    my ($testmode) = @_; 
# black and white lists
    $mail8_setup->{'mail8_db'} = 1;
    my $mail8_base = (scalar $testmode)?("/var/tmp"):("/etc/mail/mail8");
    echo <<ECHO;
dnl black list (firewall) should also be in mail8
Kmail9db hash -o -a.FOUND $mail8_base/mail9.db
dnl black list
Kmail8db hash -o -a.FOUND $mail8_base/mail8.db
dnl white list
Kmail4db hash -o -a.FOUND $mail8_base/mail4.db
dnl one off white list
Kmail3db hash -o -a.FOUND $mail8_base/mail3.db
dnl our own domains, stops people claiming to be us!
Kmail2db hash -o -a.FOUND $mail8_base/mail2.db
dnl our own IP's, this is mostly to by pass these routines, but also traps some spammers
Kmail1db hash -o -a.FOUND $mail8_base/mail1.db
ECHO
}

=head2 local_rulesets

=over 4

Required statement, this inserts required statements into the hack file.

This inserts required statements before and after B<LOCAL_RULESETS>, you may add more statements that belong here.

Main items
    D{Paranoid}"%setup{paranoid}"           paranoid level set above
    D{mail8yhabr}"YOU HAVE ALREADY BEEN REFUSED!"
    D{mail8ctboood}"SPAMMER CLAIMED TO BE ONE OF OUR DOMAINS!"
    D{mail3tt}"ONLY MAIL TO SUPPLIED Trouble Ticket ACCEPTED"

=back

=cut
push @EXPORT, "local_rulesets";
sub local_rulesets
{
# some error messages
    echo <<ECHO;
D{Paranoid}"$mail8_setup->{'paranoid'}" 
D{mail8yhabr}"YOU HAVE ALREADY BEEN REFUSED!"
D{mail8ctboood}"SPAMMER CLAIMED TO BE ONE OF OUR DOMAINS!"
D{mail3tt}"ONLY MAIL TO SUPPLIED Trouble Ticket ACCEPTED"
ECHO

# this is the start of the real code
    LOCAL_RULESETS;
}

##############################################################################
# CODE is INLINED where possible, and declared before use.
# why does sendmail have such small limits on "named  rulsets"???

##############################################################################
##############################################################################
##############################################################################
##############################################################################
#TODO
##############################################################################
##############################################################################
##############################################################################
##############################################################################

=head2 screen_domain    GLOBAL B

=over 4

HELO DOMAIN NAME CHECKING

Most SPAMMERS use ZOMBIE PC's to send their spam, most if not all have completly numeric DNS names.

=over 4

=item *

Most have their IP address in simple dotted or dashed notation, often all 4 parts of their IP address, we will not let any who have 2 or more parts of their address as their name through.

We are considering a tuning element to vary this, maybe to just one, however a lot of real senders with several servers use the last part of the IP address in their name.

=item *

Some unhelpfull ISP's string the IP's together as a single number.

=item *

Some very unhelpfull ISP's encode the numbers in HEX.

=item *

And finally totally random strings of numbers and letters, which have led us in the past to completly block the entire domain in the standard B<access.db> file, this is often the best thing to do with hard to otherwise stop SPAMMER domains.

=back


=cut
push @EXPORT, "screen_domain";
sub screen_domain
{

=pod

As much as possible of the code is INLINED to reduce the "B<named rulesets>" total, as inlined code must be defined before use, macros are in reverse order.

=cut

=pod

[Pad,Hex,PadHex]Number convert single digits to what the name sugests.

=cut

# must be a better way of doing this

# IP's are often encoded in DNS names, sometimes with leading zeros
    rule "SPadNumber", "GLOBAL D", "INLINE NOMASH", "NOTEST AUTO", map { sprintf "R %u    £: %.3u",$_,$_ } (0..99); 
# alternativly maybe coded in hexidecimal
    rule "SHexNumber", "GLOBAL D", "INLINE NOMASH", "NOTEST AUTO", map { sprintf "R %u    £: %x",$_,$_ } (10..255); 
# padded, normally coded with leading zero for values under F
    rule "SPadHexNumber",
        "GLOBAL D",  
        "INLINE NOMASH",
        "NOTEST AUTO", 
        (map { sprintf "R %u    £: %.2x",$_,$_ } (0..15)),
        (map { sprintf "R %x    £: %.2x",$_,$_ } (10..15));


=pod

(Pad,Hex,PadHex)IpNumber 

=over 4

convert four digit IP address to what the name sugests.

=back

=cut
    foreach ( qw(Pad Hex PadHex ) )
    {
        my $S = "S".$_."IpNumber";
        my $M = $_."Number";
        rule <<RULE;
$S
GLOBAL C
INLINE
NOTEST AUTO
R £-.£-.£-.£-       £: £1
R £*                £: £>$M £1
R £*                £: £(SelfMacro {MashStack1} £@ £1 £) £1        Padded digit 1
R £*                £: £&{MashSelf}
R £-.£-.£-.£-       £: £2
R £*                £: £>$M £1
R £*                £: £(SelfMacro {MashStack2} £@ £1 £) £1        Padded digit 2
R £*                £: £&{MashSelf}
R £-.£-.£-.£-       £: £3
R £*                £: £>$M £1
R £*                £: £(SelfMacro {MashStack3} £@ £1 £) £1        Padded digit 3
R £*                £: £&{MashSelf}
R £-.£-.£-.£-       £: £4
R £*                £: £>$M £1
R £*                £: £(SelfMacro {MashStack4} £@ £1 £) £1        Padded digit 4
R £*                £: £&{MashStack1}.£&{MashStack2}.£&{MashStack3}.£&{MashStack4}
RULE
    }


=pod

ScreenMash     

=over 4

The worker, matchs supplied patten with $s (HELLO).

However Hello must be clearly tokenised.

=back

=cut

    rule <<RULE;
SScreenMash
GLOBAL F
INLINE MASH
dnl if not clearly tokenised then will not work
TEST D(see123456789.local.bogus) V(123456789)
TEST D(see123456789s.local.bogus) V(123456789)
TEST D(s123456789s.local.bogus) V(123456789)
TEST D(see.123456789s.local.bogus) V(123456789)
TEST D(sff.ee.123456789s.local.bogus) V(123456789)
TEST D(sqq.ff.ee.123456789s.local.bogus) V(123456789)
TEST D(see.qq.ff.ee.123456789s.local.bogus) V(123456789)
dnl token match works on these below
TEST D(s123456789.local.bogus) E(123456789)
TEST D(see.123456789.local.bogus) E(123456789)
TEST D(sff.ee.123456789.local.bogus) E(123456789)
TEST D(sqq.ff.ee.123456789.local.bogus) E(123456789)
TEST D(see.qq.ff.ee.123456789.local.bogus) E(123456789)
R £*                    £: £&s                                  Get Helo name
R £&{MashSelf}.£+       £#error £@ 5.1.8 £: "550 I am not your MX, go away! (S.<" £&{MashSelf} ">)"
R £&{MashSelf}£+        £#error £@ 5.1.8 £: "550 I am not your MX, go away! (SJ.<" £&{MashSelf} ">)"
R £+.£&{MashSelf}.£+    £#error £@ 5.1.8 £: "550 I am not your MX, go away! (L.<" £&{MashSelf} ">)"
R £+£&{MashSelf}.£+     £#error £@ 5.1.8 £: "550 I am not your MX, go away! (LJ.<" £&{MashSelf} ">)"
R £+£&{MashSelf}£+      £#error £@ 5.1.8 £: "550 I am not your MX, go away! (MJ.<" £&{MashSelf} ">)"
RULE


=pod

Splice          used by ScreenIP

=over 4

There must be a better way to do this, however as far as decimal numerics goes this works, nothing todate (lots of time spent trying) works for HEX.

celmorlauren will continue to use the original Perl helpers for now.

=back

=cut
    rule <<RULE;
SSplice
GLOBAL E
INLINE
NOTEST AUTO
R £-.£-.£-.£-       £: £(Math * £@ £1 £@ 1000000000 £: ERR £)       must not resolv to 0
R £*                £: £(SelfMacro {MashStack1} £@ £1 £) £1         digit 1
R £*                £: £&{MashSelf}
R £-.£-.£-.£-       £: £(Math * £@ £2 £@ 1000000 £: ERR £)          however following digits can be 0
R £*                £: £(SelfMacro {MashStack2} £@ £1 £) £1         digit 2
R £*                £: £&{MashSelf}
R £-.£-.£-.£-       £: £(Math * £@ £3 £@ 1000 £: ERR £)
R £*                £: £(SelfMacro {MashStack3} £@ £1 £) £1         digit 3
R £*                £: £&{MashSelf}
R £-.£-.£-.£-       £: £(SelfMacro {MashStack4} £@ £4 £) £1         digit 4
dnl now add the parts dnl
R £*                £: £(Math + £@ £&{MashStack1} £@ £&{MashStack2} £: ERR £)
R £*                £: £(SelfMacro {MashStack12} £@ £1 £) £1       1 and 2
R £*                £: £(Math + £@ £&{MashStack3} £@ £&{MashStack4} £: ERR £)
R £*                £: £(SelfMacro {MashStack34} £@ £1 £) £1       3 and 4
R £*                £: £(Math + £@ £&{MashStack12} £@ £&{MashStack34} £: ERR £)
R 0                 £: £&{MashSelf}                                 a value of zero means nothing worked
RULE

=pod

ScreenIpPatten      used by above, trys patten dotted then dashed

=cut
    rule <<RULE;
SScreenIpPatten
GLOBAL E
INLINE MASH
NOTEST AUTO
R £*                £: £>ScreenMash £1                      Got IP or part
R £-.£-.£-.£-       £: £1-£2-£3-£4                          dash it
R £-.£-.£-          £: £1-£2-£3
R £-.£-             £: £1-£2
R £*                £: £>ScreenMash £1
RULE

=pod

ScreenIP    

=over 4

used by above, trims IP address from 4 then 3 then 2, also trys re-arranging and all 4 parts spliced together as a single token

=back

=cut
    rule <<RULE;
SScreenIP
GLOBAL D
INLINE MASH
NOTEST AUTO
R £*                £: £>ScreenIpPatten £1              Check 4 part address
R £-.£-.£-.£-       £: £2.£3.£4
R £*                £: £>ScreenIpPatten £1              Check 3 part address
R £-.£-.£-          £: £2.£3
R £*                £: £>ScreenIpPatten £1              Check 2 part address
dnl restore and try again
R £*                £: £&{MashSelf}                     Restore Original
R £-.£-.£-.£-       £: £1.£2.£3                         OK try other end trimmed
R £*                £: £>ScreenIpPatten £1              Check 3 part address
R £-.£-.£-          £: £1.£2
R £*                £: £>ScreenIpPatten £1              Check 2 part address
dnl restore and try again
R £*                £: £&{MashSelf}                     Restore Original
R £*                £: £>Splice £1                      ok lets join the IP parts together
R £*                £: £>ScreenMash £1                  try the joined-up ip
RULE


=pod

ScreenDomainIP   small often used macro, re-arranges IP to check

=cut
    rule <<RULE;
SScreenDomainIP
GLOBAL C
INLINE MASH
NOTEST AUTO
    R £*                £: £>ScreenIP £1            Check normal IP direction
    R £-.£-.£-.£-       £: £4.£3.£2.£1              Reverse 
    R £*                £: £>ScreenIP £1            Check reverse IP direction
    R £*                £: £&{MashSelf}             restore
    R £-.£-.£-.£-       £: £4.£1.£2.£3              lead with trailing ip
    R £*                £: £>ScreenIP £1            try pattern
    R £*                £: £&{MashSelf}             restore
    R £-.£-.£-.£-       £: £3.£4.£1.£2              lead with trailing 2 ip
    R £*                £: £>ScreenIP £1            try pattern
RULE

#TODO
# now this should only be stated if the Perl Helpers are defined.
# But as we have failed to incorperate all the testing we wanted,
# we will re-write one of the current helpers without stuff that 
# will not work on systems that we have not installed ourselves.
    my $ZOMBIE = <<ZOMBIE;
    R £*        £: MACRO{ £1
        INLINE NOMASH
        dnl these tests will only work with the Perl Helper installed
        TEST D(sLEAD.c0a97b8c.DOMAIN) V(192.169.123.140)
        TEST D(sLEAD.C0A97B8C.DOMAIN) V(192.169.123.140)
        dnl            hello, connected ip,
        R £*        £: £&s £&{client_addr}
        R £*        £: £(Zombie £1 £)
        R ERR.£*    £#error £@ 5.1.8 £: "550 I am not your MX, go away! ERR=" £1
    }MACRO
ZOMBIE

    rule <<RULE;
SScreenDomain
GLOBAL B
TEST D(sLEAD.192.168.0.14.DOMAIN) E(192.168.0.14)
TEST D(sLEAD192.168.0.14.DOMAIN)  E(192.168.0.14)
TEST D(sLEAD168.0.14.DOMAIN)      E(192.168.0.14)
TEST D(sLEAD.0.14.DOMAIN)         E(192.168.0.14)
TEST D(sLEAD.192.168.0.DOMAIN)    E(192.168.0.14)
TEST D(sLEAD.192.168.DOMAIN)      E(192.168.0.14)
TEST D(sLEAD.192168000014.DOMAIN) E(192.168.0.14)
# should be noted that run together IP's dont work, except when padded 
TEST D(sLEAD.192168014.DOMAIN)    V(192.168.0.14)
# HELLO host with IP with leading ZEROS
TEST D(sLEAD.192.168.000.014.DOMAIN) E(192.168.0.14)
TEST D(sLEAD192.168.000.014.DOMAIN)  E(192.168.0.14)
TEST D(sLEAD168.000.014.DOMAIN)      E(192.168.0.14)
TEST D(sLEAD.000.014.DOMAIN)         E(192.168.0.14)
TEST D(sLEAD.192.168.000.DOMAIN )    E(192.168.0.14)
TEST D(sLEAD.192.168.DOMAIN)         E(192.168.0.14)
# now  for HEX hosts that should fail
TEST D(sLEAD.c0.a8.0.e.DOMAIN)    E(192.168.0.14)
TEST D(sLEAD.C0.A8.0.E.DOMAIN)    E(192.168.0.14)
TEST D(sLEAD.C0.A9.7B.8C.DOMAIN)  E(192.169.123.140)
TEST D(sLEAD.c0.a9.7b.8c.DOMAIN)  E(192.169.123.140)
TEST D(sLEAD.C0.A9.7B.8C.DOMAIN)  E(192.169.123.140)
TEST D(sLEAD.A.B.C.9.DOMAIN)      E(10.11.12.9)
TEST D(sLEAD.0A.0B.0C.09.DOMAIN)  E(10.11.12.9)
# this can not cope with run together HEX encoding
TEST D(sLEAD.c0a97b8c.DOMAIN) V(192.169.123.140)
TEST D(sLEAD.C0A97B8C.DOMAIN) V(192.169.123.140)
R £*    £: MACRO{ £1    # should have been supplied with HELO host IP
    INLINE MASH
    dnl HELLO host with IP encoded directly within it
    TEST D(sLEAD.192.168.0.14.DOMAIN) E(192.168.0.14)
    TEST D(sLEAD192.168.0.14.DOMAIN)  E(192.168.0.14)
    TEST D(sLEAD168.0.14.DOMAIN)      E(192.168.0.14)
    TEST D(sLEAD.0.14.DOMAIN)         E(192.168.0.14)
    TEST D(sLEAD.192.168.0.DOMAIN)    E(192.168.0.14)
    TEST D(sLEAD.192.168.DOMAIN)      E(192.168.0.14)
    TEST D(sLEAD.192168000014.DOMAIN) E(192.168.0.14)
    dnl should be noted that run together IP's dont work, except when padded 
    TEST D(sLEAD.192168014.DOMAIN)    V(192.168.0.14)
    dnl now to for hosts that should pass this, but will fail later
    TEST D(sLEAD.c0.a8.0.e.DOMAIN)    V(192.168.0.14)
    TEST D(sLEAD.C0.A8.0.E.DOMAIN)    V(192.168.0.14)
    TEST D(sLEAD.C0.A9.7B.8C.DOMAIN)  V(192.169.123.140)
    R £*                £: £>ScreenDomainIP £1
}MACRO
R £*    £: MACRO{ £1    # still here, maybe the HELO address has padded IP?
    INLINE MASH
    dnl HELLO host with IP with leading ZEROS
    TEST D(sLEAD.192.168.000.014.DOMAIN) E(192.168.0.14)
    TEST D(sLEAD192.168.000.014.DOMAIN)  E(192.168.0.14)
    TEST D(sLEAD168.000.014.DOMAIN)      E(192.168.0.14)
    TEST D(sLEAD.000.014.DOMAIN)         E(192.168.0.14)
    TEST D(sLEAD.192.168.000.DOMAIN )    E(192.168.0.14)
    TEST D(sLEAD.192.168.DOMAIN)         E(192.168.0.14)
    dnl hum below is caught by the preceeding check, but fails here as leading ZEROs 
    dnl cause arith to assume the number is something other than decimal
    TEST D(sLEAD.192168000014.DOMAIN)    V(192.168.0.14)
    dnl now to for hosts that should pass this, but will fail later
    TEST D(sLEAD.c0.a8.0.e.DOMAIN)    V(192.168.0.14)
    TEST D(sLEAD.C0.A8.0.E.DOMAIN)    V(192.168.0.14)
    TEST D(sLEAD.C0.A9.7B.8C.DOMAIN)  V(192.169.123.140)
    TEST D(sLEAD.c0.a9.7b.8c.DOMAIN)  V(192.169.123.140)
    TEST D(sLEAD.C0.A9.7B.8C.DOMAIN)  V(192.169.123.140)
    TEST D(sLEAD.A.B.C.9.DOMAIN)      V(10.11.12.9)
    TEST D(sLEAD.0A.0B.0C.09.DOMAIN)  V(10.11.12.9)
    R £*                £: £>PadIpNumber £1         OK now pad number and try again
    R £*                £: £>ScreenDomainIP £1
}MACRO
R £*    £: MACRO{ £1    # still here, maybe the HELO address has HEX coded IP?
    INLINE MASH
    dnl this would have failed above, but are included here to check that they pass here
    TEST D(sLEAD.192.168.000.014.DOMAIN) V(192.168.0.14)
    TEST D(sLEAD192.168.000.014.DOMAIN)  V(192.168.0.14)
    TEST D(sLEAD168.000.014.DOMAIN)      V(192.168.0.14)
    TEST D(sLEAD.000.014.DOMAIN)         V(192.168.0.14)
    TEST D(sLEAD.192.168.000.DOMAIN )    V(192.168.0.14)
    TEST D(sLEAD.192.168.DOMAIN)         V(192.168.0.14)
    TEST D(sLEAD.192168000014.DOMAIN)    V(192.168.0.14)
    dnl now to for hosts that should fail
    TEST D(sLEAD.c0.a8.0.e.DOMAIN)    E(192.168.0.14)
    TEST D(sLEAD.C0.A8.0.E.DOMAIN)    E(192.168.0.14)
    TEST D(sLEAD.C0.A9.7B.8C.DOMAIN)  E(192.169.123.140)
    TEST D(sLEAD.c0.a9.7b.8c.DOMAIN)  E(192.169.123.140)
    TEST D(sLEAD.C0.A9.7B.8C.DOMAIN)  E(192.169.123.140)
    TEST D(sLEAD.A.B.C.9.DOMAIN)      E(10.11.12.9)
    TEST D(sLEAD.0A.0B.0C.09.DOMAIN)  E(10.11.12.9)
    dnl this can not cope with run together HEX encoding
    TEST D(sLEAD.c0a97b8c.DOMAIN) V(192.169.123.140)
    TEST D(sLEAD.C0A97B8C.DOMAIN) V(192.169.123.140)
    R £*                £: £>HexIpNumber £1         OK now Hex number and try again
    R £*                £: £>ScreenDomainIP £1
    dnl still here, maybe the HELO address has padded HEX coded IP? dnl
    R £*                £: £>PadHexIpNumber £1         OK now Hex number and try again
    R £*                £: £>ScreenDomainIP £1
    dnl nothing for it, must use an external program to do the last ditch testing dnl
    dnl at least most ZOMBIES will have been stopped by the above rules dnl
    $ZOMBIE
}MACRO
RULE
}
##############################################################################
##############################################################################
##############################################################################
#TODO
##############################################################################
##############################################################################
##############################################################################

=head2 local_check_relay        GLOBAL A

=over 4

CONTACT

This bit arrived at on first contact, and so permissions based on IP can be set

Local_check_relay standard rule, to check incoming connection against mail8 databases and of course standard local ip addresses, further rules are based on what happens here.

=cut
push @EXPORT, "local_check_relay";
sub local_check_relay
{
    echo <<ECHO;

dnl this bit is for mail8, intial contact and flood checking?
dnl bit below checked, see p288 sendmail 3rd edition
ECHO

    sane <<SANE;
GoodRelay
{GoodRelay}this.one.FOUND, {BadRelay}this.one.FOUND
{client_resolve}OK
SANE
    sane <<SANE;
BadRelay
{BadRelay}this.one.FOUND
{GoodRelay}notset.clear
SANE
    sane <<SANE;
Local_check_relay
{GoodRelay}notset.clear, {BadRelay}notset.clear
SANE
    rule <<RULE;
SLocal_check_relay
GLOBAL A
HINT This bit arrived at on first contact, and so permissions based on IP can be set
TEST SANE(Local_check_relay) T(Translate) AUTO(D; OUR; {client_resolve} RESOLVE, V OUR DOMAIN IP)     
TEST SANE(Local_check_relay) T(Translate) F(localhost 127.0.0.1)
TEST D({client_resolve}OK)
TEST SANE(Local_check_relay) T(Translate) F(pc1.local 192.168.0.1, pc2.local 172.16.4.1, serv1.local 10.0.0.1) V(uknown.bogus.bogus 987.654.321.0)
TEST D({client_resolve}FAIL)
TEST SANE(Local_check_relay) T(Translate) V(bogus.bogus 721.0.0.1)
R £*            £: MACRO{ £1    # mail8 DB, check both name and IP
    NOTEST AUTO Local_check_relay wraps this entirely, mail8 will block access
    R £* £| £*      £: £(SelfMacro {RelayName} £@ £1 £) £1 £| £2
    R £* £| £*      £: £(SelfMacro {RelayIP} £@ £2 £) £1 £| £2
    dnl sendmail's own tables wrap IP in square brackets dnl
    R £*            £: £&{RelayIP}                          try IP
    R £*            £: [ £1 ]                               wrap with brackets
    R £*            £: £>Screen_bad_relay £1
    R £+.FOUND      £@ £1.FOUND                             found IP
    dnl now try IP as is, may be found in mail8 db? dnl
    R £*            £: £>Screen_bad_relay £&{RelayIP}       try IP
    R £+.FOUND      £@ £1.FOUND                             found IP
    dnl now try domain name
    R £*            £: £&{client_resolve}                   try name if it resolved
    R OK            £@ £>Screen_bad_relay £&{RelayName}     found it?
}MACRO
RULE

=pod

uses Macro B<Screem_bad_relay> (GLOBAL B) to do the main checking

{GoodRelay} and {BadRelay} both contain result of check, such values as (where # is checked value).
    
    #.Local.FOUND       $w                                  {GoodRelay}
    #.VirtHost.FOUND    ${VirtHost}                         {GoodRelay}
    #.RelayDomain.FOUND $R                                  {GoodRelay}
    #.mail1.FOUND       mail1.db                            {GoodRelay}
    #.Private.FOUND     192.168.#.# 172.16.#.# 10.#.#.#     {GoodRelay}
    #.mail4.FOUND
    #.mail3.FOUND

mail8 amd mail9 checks result im $#error

Being found does not mean that the host is a BadRelay, just that it will need handling differently to other hosts.
Hosts recorded as being GoodRelay are also in BadRelay.

=back

=cut

    rule <<RULE;
SScreen_bad_relay
GLOBAL B
HINT Called by 'Local_check_relay' with IP then domain name
TEST F(localhost, 127.0.0.1, 192.168.0.1, 172.16.0.1, 10.0.0.1)
TEST V(bogus.bogus, 987.6.5.4, 321.123.321.123)
R £*    £: MACRO{ £1    # check for local systems
    TEST F(localhost, [127.0.0.1], 127.0.0.1, 192.168.254.200, 172.16.34.5, 10.4.5.6)
    TEST V(BOGUS.BOGUS, 987.64.34.1)
    dnl standard sendmail tables first dnl
    R £=w               £@ £1.Local.FOUND
    R £={VirtHost}      £@ £1.VirtHost.FOUND
    R £=R               £@ £1.RelayDomain.FOUND
    dnl mail8 database checks, some duplicate standard databases dnl
    dnl now for mail1 table, IP's in preference to names dnl
    R £*                £: £(mail1db £1 £: £1 £)          mail1 DB, our domain IP's check
    R £+.FOUND          £@ £1.mail1.FOUND
    dnl  standard private domains are assumed to be ok dnl
    R 192.168.£+        £@ £&{MashSelf}.Private.FOUND
    R 172.16.£+         £@ £&{MashSelf}.Private.FOUND
    R 10.£+             £@ £&{MashSelf}.Private.FOUND
    R 127.£+            £@ £&{MashSelf}.Private.FOUND
}MACRO
FOUND GoodRelay     found? then is one of our domains
FOUND BadRelay      found? then save here as well
R £+.FOUND      £@ £1.FOUND    ok one of our domains
# now for systems that are not local
R £*    £: MACRO{ £1    # check for systems that may have problems
    HINT This checks mail8's DataBases for IP's or domain names?
    dnl mail8 database checks  dnl
    R £*            £: £(mail4db £1 £: £1 £)          mail4 DB, poorly configured systems, that will fail tests
    R £+.FOUND      £@ £1.mail4.FOUND
    R £*            £: £(mail3db £1 £: £1 £)          mail3 DB, single shot white list
    R £+.FOUND      £@ £1.mail3.FOUND
    R £*            £: £(mail8db £1 £: £1 £)          mail8 DB, spammer check
    R £+.FOUND      £#error £@ 5.1.8 £: "550 SPAMMER, GO AWAY!"
    dnl if firewall interface is working should never get here dnl
    R £*            £: £(mail9db £1 £: £1 £)          mail9 DB, spammer check
    R £+.FOUND      £#error £@ 5.1.8 £: "550 SPAMMER, GO AWAY!"
}MACRO
FOUND BadRelay      found? then save here
R £+.FOUND      £@ £1.FOUND    ok then may be OK?
RULE
}


=head2 local_check_mail     GLOBAL A

=over 4

HELO & FROM

After intial HELO and every FROM following

This insists that the HELO host name must either be the same as the {client_name} or resolve to an address that is the same as the {client_name}.

This also handles empty FROM's which are normally bounces of some kind, or the un-helpfull B<callback verify> sudo bounce, which often originates from poorly configured e-mail systems that blindly B<bounce> back to B<Forged FROM> addresses.

{Bounce} records that a empty FROM has been recieved, these are accepted according to the value of {Paranoid}.

{Refused} and {RefusedAgain} record that the connection has been refused, only spammers will cause {RefusedAgain} to be generated, also if the B<Perl Helpers> are installed these will attempt to ammend both sendmail databases and the firewall rules.

Refers to 

=over 4

=item ScreenMail8blocker    GLOBAL B

this is called regardless of wether the B<PerlHelpers> have been installed.

=item ScreenMail9blocker    GLOBAL B

this is called regardless of wether the B<PerlHelpers> have been installed.

=item ScreenDomain          GLOBAL B

this checks the HELO host for being highly numeric, and having its IP encoded in the name.

=back

=back

=cut
push @EXPORT, "local_check_mail";
sub local_check_mail
{
    sane <<SANE;
Local_check_mail
{Refused}ok.clear
{AlreadyRefused}ok.clear
{Bounce}ok.clear
SANE

    rule <<RULE;
SLocal_check_mail
GLOBAL A
# reset globals that are set in above rules
TEST SANE(Local_check_relay)
# also use lowest sensible value for paranoid
TEST D({Paranoid}1)
# 1st check normal legal external senders who have no special rights or needs
TEST SANE(Local_check_mail) AUTO(D; OK; s HELO; {client_name} DOMAIN; {client_addr} IP; {client_resolve} RESOLVE, F OK FROM)     
# retest assuming sudo bounce (callback verify) which we have to tollarate to some degree
TEST SANE(Local_check_mail) F(<>) AUTO(D; OK; s HELO; {client_name} DOMAIN; {client_addr} IP; {client_resolve} RESOLVE)     
# 2nd check senders who failed with the last release, and should still fail
TEST SANE(Local_check_mail) AUTO(D; BAD; s HELO; {client_name} DOMAIN; {client_addr} IP; {client_resolve} RESOLVE;, E BAD FROM)     
# 3rd check our domain who should be able to do anthing
TEST SANE(GoodRelay)
TEST SANE(Local_check_mail) AUTO(D; OUR; s HELO; {client_name} DOMAIN; {client_addr} IP; {client_resolve} RESOLVE;, F OUR FROM)     
# retest assuming sudo bounce (callback verify) which we have to tollarate to some degree
TEST SANE(Local_check_mail) F(<>) AUTO(D; OUR; s HELO; {client_name} DOMAIN; {client_addr} IP; {client_resolve} RESOLVE)     
R £*            £: £&{Refused}      has this host already been refused?
R £+.FOUND      £@ MACRO{ £1
    TEST D({Refused}991.2.3.4) E(991.2.3.4, blah.blah)
    TEST D({AlreadyRefused}994.3.2.1.FOUND) E(994.3.2.1)
    R £*            £: £&{AlreadyRefused}     refused more than once?
    R £+.FOUND      £: MACRO{
        TEST E(nogin.the.nog)
        dnl even if the perl helpers are not installed  dnl
        R £*        £: £>ScreenMail9blocker £{mail8yhabr}       already has been warned, attempt to drop IP
        dnl should not get here, however put something in logs to get sys-admin to do the blocking dnl
        R £*        £#error £@ 5.1.8 £: "550 SPAMMER, GO AWAY! " £{mail8yhabr} " SYSTEM ADMIN ATTN"
    }MACRO
    dnl record that this system is trying again dnl
    ALREADYREFUSED £#error £@ 5.1.8 £: "550 SPAMMER, GO AWAY! " £{mail8yhabr} " Next time you will be dropped!"
}MACRO
dnl restore original value dnl
R £*            £: £&{MashSelf}
R £*            £: MACRO{ £1
    TEST SANE(Local_check_mail, BadRelay) E(you\@localhost)
    TEST SANE(Local_check_mail) D({Paranoid}1) V(<>)
    TEST SANE(Local_check_mail) D({Paranoid}2) V(<>)
    TEST SANE(Local_check_mail) D({Paranoid}3) V(<>)
    TEST SANE(Local_check_mail) D({Paranoid}4) E(<>)
    R £+ @ £+       £@ MACRO{ £2    # check HOST part of FROM address
        TEST SANE(Local_check_relay)
        TEST SANE(Local_check_mail) E(localhost, host.localhost, any.host.localhost)
        TEST SANE(GoodRelay)
        TEST SANE(Local_check_mail) F(localhost, host.localhost, any.host.localhost)
        TEST SANE(Local_check_relay)
        dnl NOTE: sendmail already checks that the HOST part of the domain name makes sense dnl
        IS FOUND GoodRelay £@ £1    our own systems are presumed OK
        R £*            £: MACRO{ £1 # check claimed host name against local names
            TEST F(home.localhost, this.is.home.localhost)
            R £* £=w               £@ £1.Local.FOUND
            R £* £={VirtHost}      £@ £1.VirtHost.FOUND
            R £* £=R               £@ £1.RelayDomain.FOUND
            R £*                £: £(mail2db £1 £: £1 £)          mail2 DB
            R £+.FOUND          £@ £1.mail2.FOUND
        }MACRO
        dnl is system claiming to be us? dnl
        IS THISFOUND AND REFUSED £#error £@ 5.1.8 £: "550 SPAMMER, GO AWAY! " £{mail8ctboood}
        dnl OK system does not claim to be sending from us dnl
    }MACRO
    #
    dnl record attempt at bounce, we will need this to check at RCPT and DATA checking routines dnl
    dnl local systems are allowed to bounce dnl
    IS FOUND GoodRelay £@ £1
    dnl other systems have limited permissions dnl
    IS FOUND Bounce AND REFUSED £#error £@ 5.1.8 £: "553 Multiple BOUNCES are not allowed, GO AWAY, (Empty From <> address): " £&s
    dnl OK have not bounced before dnl
    R £*                £: £1.FOUND
    R £*                £: £(SelfMacro {Bounce} £@ £1 £) £1
    dnl empty address, either a "callback verify" or a real bounce dnl
    R £*    £: £&{Paranoid}
    R 0     £@ 0       Not paranoid
    R 1     £@ 1       slighty
    R 2     £@ 2       mildly
    R 3     £@ 3       paranoid
    dnl any bounce at this level of paranoid must be refused, refuse any further attempts dnl
    REFUSED £#error £@ 5.1.8 £: "553 Domain Mail Probes are not allowed, GO AWAY, (Empty From <> address): " £&s
}MACRO
#
#
dnl now we know FROM sort of makes sense check sender dnl
R £*        £: MACRO{ £1    # checking HELO
    TEST SANE(Local_check_relay)
    TEST SANE(Local_check_mail)
    TEST D(smail.bogus.bogus) E(NA)
    TEST D(slocalhost) E(NA)
    TEST D(s80.176.153.184, {client_addr}80.176.153.184) E(NA)
    IS FOUND GoodRelay £@ £1    our own systems are presumed OK
    IS FOUND BadRelay £@ £1     other known systems are presummed OK
    #
    dnl now for everybody else
    R £*            £: £&s      HELO name requires checking
    R £*            £: MACRO{ £1 # Check helo
        TEST F(home.localhost, this.is.home.localhost)
        TEST F(80.176.153.184) D({client_addr}80.176.153.184)
        dnl some just use their IP? no way can these be legal? dnl
        R £&{client_addr}   £@ £&{client_addr}.IP.FOUND
        dnl others claiming to be us? dnl
        R £* £=w               £@ £1.Local.FOUND
        R £* £={VirtHost}      £@ £1.VirtHost.FOUND
        R £* £=R               £@ £1.RelayDomain.FOUND
        R £*                £: £(mail2db £1 £: £1 £)          mail2 DB
        R £+.FOUND          £@ £1.mail2.FOUND
        R £*                £: £(mail1db £1 £: £1 £)          mail1 DB
        R £+.FOUND          £@ £1.mail1.FOUND
        dnl  standard private domains are assumed to be not ok dnl
        R 192.168.£+        £@ £&{MashSelf}.Private.FOUND
        R 172.16.£+         £@ £&{MashSelf}.Private.FOUND
        R 10.£+             £@ £&{MashSelf}.Private.FOUND
    }MACRO
    IS THISFOUND AND REFUSED £#error £@ 5.1.8 £: "550 SPAMMER, GO AWAY! " £{mail8ctboood}
    #
    dnl does the senders HELO resolve? dnl
    R £*            £: MACRO{ £1  # check HELO with client_name and then DNS
        TEST D({client_resolve}OK, {client_name}bogus.host.bogus, sbogus.host.bogus) F(bogus.host.bogus)
        TEST D({client_resolve}FAIL, {client_addr}192.168.0.1, swww.celmorlauren.com) E(www.celmorlauren.com)
        TEST D({client_resolve}TEMP, {client_addr}192.168.0.1, swww.celmorlauren.com) E(www.celmorlauren.com)
        TEST D({client_resolve}FORGED, {client_addr}192.168.0.1, swww.celmorlauren.com) E(www.celmorlauren.com)
        R £*                    £: £&{client_resolve}
        R OK                    £: OK.£&{MashSelf}
        # HELO could be same as client_name
        R OK.£&{client_name}    £@ £&{MashSelf}.FOUND       already known, no need to look up
        #
        R £*            £: £(Rlookup £&{MashSelf} £)      HELO host, DNS lookup needed
        R £+.FOUND      £@ MACRO{ £1    #  HELO resolves
            TEST D({client_addr}192.168.0.1, {client_name}NA.192.168.0.1.NA, sNA.NA) F(192.168.0.1) E(10.0.0.1)
            R £&{client_addr}   £@ £&{MashSelf}.FOUND
            REFUSED £#error £@ 5.1.8 £: "550 SPAMMER claimed to be: " £&s "with address:" £&{MashSelf}
        }MACRO
        #
        # HELO Failed to verify
        #
        REFUSED
        #
        R £*            £: £&{client_resolve}
        R TEMP          £#error £@ 4.1.8 £: "450 cannot resolve HELO host: " £&{MashSelf}
        R £*            £#error £@ 5.1.8 £: "550 cannot resolve HELO host: " £&{MashSelf} "From: " £1 " Address"
    }MACRO
    R £+.FOUND      £: £>ScreenDomain £1
}MACRO
RULE


    if ( scalar $mail8_setup->{'PerlHelpers'} )
    {
        dnl <<DNL;
The Blocker, for abusive senders, mail bombers etc
Even if the demon is not running (the demon that writes the files and blocks the IP) this will slow the atack down
DNL

        rule <<RULE;
SScreenMail8blocker
GLOBAL B
TEST D({client_addr}999.888.777.666) E(error message)
REFUSED
dnl Perl Helper args = connected-as, claiming-to-be, optional-error-message
dnl helper will also remove connected-as from mail3 and mail4 databases
R £*        £: £&{client_addr} £&s £&{MashSelf}
R £*        £: £(mail8b £1 £)
R £*        £#error £@ 5.1.8 £: "550 SPAMMER, GO AWAY!" £1
RULE
        rule <<RULE;
SScreenMail9blocker
GLOBAL B
TEST D({client_addr}999.888.777.666) E(error message)
dnl Perl Helper args = connected-as, claiming-to-be, optional-error-message
R £*        £: £&{client_addr} £&s £&{MashSelf}
R £*        £: £(mail9b £1 £)
R £*        £#error £@ 5.1.8 £: "550 SPAMMER, GO AWAY!" £1
RULE
    }
    else
    {
        rule <<RULE;
SScreenMail8blocker
GLOBAL B
TEST D({client_addr}999.888.777.666) E(error message)
REFUSED  £#error £@ 5.1.8 £: "550 SPAMMER, GO AWAY!" £&{MashSelf}
RULE
        rule <<RULE;
SScreenMail9blocker
GLOBAL B
TEST E(error message)
R £*        £#error £@ 5.1.8 £: "550 SPAMMER, GO AWAY!" £1
RULE
    }
}

=head2 local_check_rcpt     GLOBAL A

=over 4

RCPT

standard sendmail rules do most of the work, however depending on the value {Paranoid} responses will vary in responce to {Bounce} requests.

=back

=cut
push @EXPORT, "local_check_rcpt";
sub local_check_rcpt
{
    dnl <<DNL;
RCPT
normal rules do most of the work, however mail3.db is for one shot bad boys
DNL
    rule <<RULE;
SLocal_check_rcpt
GLOBAL A
TEST SANE(Local_check_relay, Local_check_mail)
R £*            £: MACRO{ £1 # first check wether sender is local
    TEST D({GoodRelay}localhost.FOUND) F(na\@localhost)
    TEST SANE(Local_check_relay)
    TEST D({BadRelay}tt\@localhost.mail3.FOUND,{rcpt_addr}tt\@localhost) V(NA)
    TEST D({BadRelay}tt\@localhost.mail3.FOUND,{rcpt_addr}nott\@localhost) E(NA)
    TEST SANE(Local_check_relay)
    TEST D({Bounce}is.FOUND)
    TEST D({rcpt_host}localhost, {Paranoid}2) O(na\@localhost)
    TEST D({rcpt_host}notlocalhost, {Paranoid}2) E(na\@localhost)
    TEST D({rcpt_host}notlocalhost, {Paranoid}3) O(na\@localhost)
    TEST SANE(Local_check_relay, Local_check_mail)
    R £*            £: £&{GoodRelay}        local domains are OK
    R £+.FOUND      £@ £1.FOUND
    R £*            £: £&{BadRelay}         relays with problems, more checking needed
    R £+.FOUND      £@ MACRO{ £1
        TEST D({rcpt_addr}match.this) V(match.this.mail3) E(not.this.mail3)
        R £*.mail3      £@ MACRO{ £1 # Trouble Ticket user
            TEST D({rcpt_addr}bingo.local) V(bingo.local) E(bad.nothing)
            R £&{rcpt_addr}     £@ £&{MashSelf}
            R £*                £@ £>ScreenMail8blocker £{mail3tt}
        }MACRO
    }MACRO
    R £*            £: £&{Bounce}
    R £+.FOUND      £@ MACRO{ £1
        TEST D({Paranoid}2, {rcpt_host}localhost) O(localhost)
        TEST D({Paranoid}2, {rcpt_host}not.such.host) E(not.such.host)
        TEST D({Paranoid}3, {rcpt_host}localhost) O(localhost)
        TEST D({Paranoid}3, {rcpt_host}not.such.host) O(not.such.host)
        TEST D({Paranoid}1, {rcpt_host}not.such.host) V(not.such.host)
        R £*            £: £&{Paranoid}
        R 2             £: OK2.£&{rcpt_host}
        R OK2.£+        £@ MACRO{ £1
            TEST D({rcpt_host}na.auto.na)
            TEST O(localhost)
            TEST AUTO(O OUR HELO, E BAD HELO)
            R £* £=w               £# OK
            R £* £={VirtHost}      £# OK
            R £* £=R               £# OK
            R £*                £: £(mail2db £1 £: £1 £)          mail2 DB
            R £+.FOUND          £# OK
            REFUSED £#error £@ 5.1.8 £: "550 SPAMMER, GO AWAY! MAIL REFUSED FOR HOST" £&{rcpt_host}
        }MACRO
        dnl bogus bounces deserve to be treated with bogus replys dnl
        R 3             £# OK
    }MACRO
}MACRO
RULE
}

=head2 check_data       GLOBAL A

=over 4

DATA

This bit is for checking for B<callback verify> requests which are a B<fake bounce> with no B<DATA>, action depends on setting of {Paranoid} and {Bounce}

For all values of {Paranoid} other than 0, this will not accept any B<bounces> from any unknown systems.

{Bounce} will not be defined if mail is from permitted systems.

=back

=cut
push @EXPORT, "check_data";
sub check_data
{
    rule <<RULE;
Scheck_data
GLOBAL A
TEST SANE(Local_check_relay, Local_check_mail)
TEST V(NA)
TEST D({Bounce}is.FOUND) 
TEST D({Paranoid}1) E(na)
TEST D({GoodRelay}is.FOUND) F(na)
TEST SANE(Local_check_relay, Local_check_mail)
TEST D({Paranoid}0)
R £*            £: £&{Bounce}
R £+.FOUND      £: MACRO{ £1
    TEST D({Paranoid}0, {GoodRelay}is.FOUND) V(NA)
    TEST D({Paranoid}1, {GoodRelay}is.FOUND) F(NA)
    TEST D({Paranoid}0, {GoodRelay}is.not) V(NA)
    TEST D({Paranoid}1, {GoodRelay}is.not) E(NA)
    R £*            £: £&{Paranoid}
    R 0             £@ 0
    IS FOUND GoodRelay £@ £&{GoodRelay}
    dnl all other values for Paranoid will not accept bounces from strangers dnl
    REFUSED £#error £@ 5.1.8 £: "550 SPAM BOUNCES ARE REFUSED, WE DO NOT KNOW YOU, GO AWAY"
}MACRO
RULE
}

=head2 screen_header(@_)        GLOBAL A

=over 4

HEADER LINES

All this does at the moment is check the B<Received> header statment, some spammers pass other tests but show themselves by pretending to send from one of our domains! Other tests are possible. But on balance we think that these should be left to a 2nd level e-mail system that can take a closer look with both B<anti virus> and something like B<SpamAssassin>, it should be noted that these systems tend to be rather slow, so should never be run on a busy front line e-mail system under constant attack.
If you wish additional rules may be supplied, these will be tacked on the end of the B<SScreenHeader> definition.

=back

=cut
push @EXPORT, "screen_header";
sub screen_header
{
    my $tail = <<RULE;
}MACRO
RULE
    my @extra = (scalar @_)?((@_,$tail)):(($tail));
    my $screen_header = <<RULE;
GLOBAL A
TEST SANE(Local_check_relay,Local_check_mail)
R £*    £: MACRO{ £1
    TEST D({hdr_name}NotReceived:) V(NA)
    TEST D({hdr_name}Received:,{currHeader}na by localhost na) V(NA)
    TEST D({hdr_name}Received:,{currHeader}na by your.localhost na) V(NA)
    R £*            £: £&{GoodRelay}        local domains are OK
    R £+.FOUND      £@ £1.FOUND
    dnl others will need checking dnl
    R £*            £: £&{hdr_name}
    R Received:     £@ MACRO{ £&{currHeader}
        TEST V(anon did not find this,bog standard mailer)
        R £+by £+ £+        £: MACRO{ £2 # claiming to be one of our domains?
            TEST AUTO(E OUR HELO, V OK HELO)
            dnl localhost is to be expected, most liky as the first server? dnl
            R localhost         £@ £&{MashSelf}
            dnl  standard private domains are assumed to be ok dnl
            R 192.168.£+        £@ £&{MashSelf}
            R 172.16.£+         £@ £&{MashSelf}
            R 10.£+             £@ £&{MashSelf}
            dnl now check for our systems
            R £* £=w               £#error £@ 5.1.1 £: "553 SPAM mailing loop?" £1
            R £* £={VirtHost}      £#error £@ 5.1.1 £: "553 SPAM mailing loop?" £1
            R £* £=R               £#error £@ 5.1.1 £: "553 SPAM mailing loop?" £1
            R £*                £: £(mail2db £1 £: £1 £)          mail2 DB
            R £+.FOUND          £#error £@ 5.1.1 £: "553 SPAM mailing loop?" £1
            R £*                £: £(mail1db £1 £: £1 £)          mail1 DB
            R £+.FOUND          £#error £@ 5.1.1 £: "553 SPAM mailing loop?" £1
        }MACRO
    }MACRO
RULE

    rule "SScreenHeader", $screen_header,@extra;
}



1;
