#!/usr/bin/perl -w

# test layouts after setting attributes
use Test::More;
use strict;

BEGIN
   {
   plan tests => 12;
   chdir 't' if -d 't';
   use lib '../lib';
   use_ok ("Graph::Easy") or die($@);
   };

can_ok ('Graph::Easy', qw/
  new
  /);

#############################################################################
# setup a graph

my $graph = Graph::Easy->new();

is (ref($graph), 'Graph::Easy');

is ($graph->error(), '', 'no error yet');

my ($bonn,$berlin,$edge) = $graph->add_edge('Bonn','Berlin');

#############################################################################
# lay out as ascii

my $ascii = $graph->as_ascii();

is ($ascii, <<EOF
+------+     +--------+
| Bonn | --> | Berlin |
+------+     +--------+
EOF
, 'as_ascii');

#############################################################################
# change label of Bonn to be longer

$bonn->set_attribute('label', 'Frankfurt a. Main');

$ascii = $graph->as_ascii();

is ($ascii, <<EOF
+-------------------+     +--------+
| Frankfurt a. Main | --> | Berlin |
+-------------------+     +--------+
EOF
, 'as_ascii');

$bonn->set_attribute('label', 'Frankfurt\n(a. Main)');
$ascii = $graph->as_ascii();

is ($ascii, <<EOF
+-----------+     +--------+
| Frankfurt |     | Berlin |
| (a. Main) | --> |        |
+-----------+     +--------+
EOF
, 'as_ascii');

# Change label of Bonn to be shorter (and one line high, this also tests
# resetting the height of Berlin even though we did not change an attribute
# on Berlin itself:

$bonn->set_attribute('label', 'Frankfurt');

$ascii = $graph->as_ascii();

is ($ascii, <<EOF
+-----------+     +--------+
| Frankfurt | --> | Berlin |
+-----------+     +--------+
EOF
, 'as_ascii');

is ($bonn->{w}, 13, 'w is 13');
is ($bonn->{h}, 3, 'h is 2');

#############################################################################
# change edge label

$edge->set_attribute('label', 'Test');

$ascii = $graph->as_ascii();

is ($ascii, <<EOF
+-----------+  Test   +--------+
| Frankfurt | ------> | Berlin |
+-----------+         +--------+
EOF
, 'as_ascii');

$edge->set_attribute('label', 'Testtest');

$ascii = $graph->as_ascii();

is ($ascii, <<EOF
+-----------+  Testtest   +--------+
| Frankfurt | ----------> | Berlin |
+-----------+             +--------+
EOF
, 'as_ascii');

#############################################################################


