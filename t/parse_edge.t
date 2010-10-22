#!/usr/bin/perl -w

use Test::More;
use strict;

BEGIN
   {
   plan tests => 83;
   chdir 't' if -d 't';
   use lib '../lib';
   use_ok ("Graph::Easy::Parser") or die($@);
   };

can_ok ("Graph::Easy::Parser", qw/
  new
  from_text
  from_file
  reset
  error
  _match_edge
  _match_node
  _match_attributes
  _match_optional_attributes
  /);

#############################################################################
# create parser object

my $parser = Graph::Easy::Parser->new();

is (ref($parser), 'Graph::Easy::Parser');
is ($parser->error(), '', 'no error yet');

my $line = 0;
my $qr_edge = $parser->_match_edge();
my $qr_node = $parser->_match_node();
my $qr_oatr = $parser->_match_optional_attributes();

#my $r = '-- Label --> [ AA ]';
#$r = '--> [ AB ]';
#$r = '<--> [ AB ]';
#$r = '<- Label -> [ AB ]';
#$r = '--> { color: red; } [ AB ]';

foreach my $l (<DATA>)
  {
  chomp ($l);
  next if $l =~ /^\s*\z/;			# skip empty ones
  next if $l =~ /^#/;				# skip comments

  my ($in,$type,$style,$label) = split /\|/, $l;

  if ($type < 0)
    {
    if (!unlike ($in, qr/^$qr_edge\z/, "$in"))
      {
      $in =~ /^$qr_edge/;
      diag ("# '$1' '$2' '$3' '$4' '$5' '$6'\n");
      }
    next;
    }

  # XXX TODO check edge style and type:
  # 0 - undirected 
  # 2 - right 
  # 3 - left and right
 
  like ($in, qr/^$qr_edge\z/, "$in");

#  $in =~ /^$qr_edge\z/;
#  diag("# '$1' '$2' '$3' '$4' '$5' '$6' '$7' '$8' '$9'\n");
  }

__DATA__
# edges without arrows
--|0|--
==|0|==
..|0|..
- |-1| -
- - |0| -
---|0|--
===|0|==
...|0|..
- - |0| -
----|0|--
====|0|==
....|0|..
<->|3|--
<=>|3|==
<.>|3|..
<- >|3| -
<-->|3|--
<==>|3|==
<..>|3|..
<- - >|3| -
<--->|3|--
<===>|3|==
<...>|3|..
<- - >|3| -
->|2|--
=>|2|==
.>|2|..
- >|2| -
-->|2|--
==>|2|==
..>|2|..
~~>|2|~~
= >|2|= 
- - >|2| -
--->|2|--
===>|2|==
...>|2|..
- - >|2| -
# with labels
<- ->|3| -
- Landstrasse --|-1|--
== Autobahn ==>|2|==
.. Im Bau ..>|2|..
-  Tunnel - >|2| -
= label =>|2|==|label
<-- Landstrasse -->|3|--
<== Autobahn ==>|3|==
<.. Im Bau ..>|3|..
<-  Tunnel - >|3| -
<- Tunnel -->|-1|
<-- Tunnel -->|3|
<-- Landstrasse -->|3|--
<~~ Landstrasse ~~>|3|~~
<== Landstrasse ==>|3|==
<.- Landstrasse .->|3|.-
<..- Landstrasse ..->|3|..-
-- Landstrasse -->|2|--
~~ Landstrasse ~~>|2|~~
== Landstrasse ==>|2|==
.- Landstrasse .->|2|.-
..- Landstrasse ..->|2|..-
##################
# Failures
# no left-only edges allowed
<-|-1|--
<=|-1|==
<.|-1|..
<- |-1| -
<--|-1|--
<==|-1|==
<..|-1|..
<- -|-1| - 
<-- Landstrasse -|-1|
<== Autobahn =|-1|
<.. Im Bau .|-1|
<- - Tunnel -|-1|
<--|-1|
# mismatching pattern
<-- Landstrasse ==>|-1|
# double "<<" or ">>" are not good
<<--|-1|
<<--|-1|
<<-->>|-1|
<<. -.->>|-1|
< - Tunnel - >|-1|
