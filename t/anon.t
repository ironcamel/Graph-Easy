#!/usr/bin/perl -w

# test anonymous nodes

use Test::More;
use strict;

BEGIN
   {
   plan tests => 31;
   chdir 't' if -d 't';
   use lib '../lib';
   use_ok ("Graph::Easy::Node::Anon") or die($@);
   use_ok ("Graph::Easy") or die($@);
   use_ok ("Graph::Easy::As_txt") or die($@);
   require_ok ("Graph::Easy::As_ascii") or die($@);
   };

can_ok ("Graph::Easy::Node::Anon", qw/
  new
  as_txt as_html
  error
  class
  name
  successors
  predecessors
  width
  height
  pos
  x
  y
  class
  del_attribute
  set_attribute
  set_attributes
  attribute
  attributes_as_txt
  as_pure_txt
  group add_to_group
  /);

#############################################################################

my $node = Graph::Easy::Node::Anon->new();

is (ref($node), 'Graph::Easy::Node::Anon');

is ($node->error(), '', 'no error yet');

is ($node->x(), undef, 'x == undef');
is ($node->y(), undef, 'y == undef');
is ($node->width(), undef, 'w == undef');
is ($node->height(), undef, 'h == undef');
is ($node->label(), ' ', 'label');
is ($node->name(), '#0', 'name');
is ($node->title(), '', 'no title per default');
is (join(",", $node->pos()), "0,0", 'pos = 0,0');

is ($node->{graph}, undef, 'no graph');
is (scalar $node->successors(), undef, 'no outgoing links');
is (scalar $node->predecessors(), undef, 'no incoming links');
is ($node->{graph}, undef, 'successors/predecssors leave graph alone');

$node->_correct_size();

is ($node->width(), 3, 'w == 3');
is ($node->height(), 3, 'h == 3');

#############################################################################
# as_txt/as_html

my $graph = Graph::Easy->new();

$graph->add_node($node);

is ($node->as_txt(), '[ ]', 'anon as_txt');
is ($node->as_html(), " <td colspan=4 rowspan=4 class='node_anon'></td>\n",
 'as_html');
is ($node->as_ascii(), "   \n   \n   ", 'anon as_ascii');

require Graph::Easy::As_graphviz;
is ($node->as_graphviz_txt(), '"#0"', 'anon as_graphviz');

#############################################################################
# anon node as_graphviz

my $grviz = $graph->as_graphviz();

my $match = quotemeta('"#0" [ color="#ffffff", label=" ", style=filled ]');

like ($grviz, qr/$match/, 'anon node');

#############################################################################
# with border attribute

$node->set_attribute('border-style', 'dotted');

is ($node->as_txt(), '[ ] { border: dotted; }', 'anon as_txt');

is ($node->as_html(), " <td colspan=4 rowspan=4 class='node_anon' style=\"border: dotted 1px #000000\"></td>\n",
 'as_html');

$grviz = $graph->as_graphviz();
$match = quotemeta('"#0" [ label=" ", style="filled,dotted" ]');
like ($grviz, qr/$match/, 'anon node as graphviz');

#############################################################################
# with fill attribute

$node->set_attribute('fill', 'orange');

is ($node->as_txt(), '[ ] { fill: orange; border: dotted; }', 'anon as_txt');

is ($node->as_html(), " <td colspan=4 rowspan=4 class='node_anon' style=\"background: #ffa500; border: dotted 1px #000000\"></td>\n",
 'as_html');

