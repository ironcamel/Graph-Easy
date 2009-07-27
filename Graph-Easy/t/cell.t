#!/usr/bin/perl -w

# Test Graph::Easy::Node::Cell

use Test::More;
use strict;

BEGIN
   {
   plan tests => 28;
   chdir 't' if -d 't';
   use lib '../lib';
   use_ok ("Graph::Easy::Node::Cell") or die($@);
   use_ok ("Graph::Easy") or die($@);
   use_ok ("Graph::Easy::As_ascii") or die($@);
   };

can_ok ("Graph::Easy::Node::Cell", qw/
  new
  as_ascii as_html
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
  title
  del_attribute
  set_attribute
  set_attributes
  attribute
  group add_to_group
  /);

#############################################################################

my $cell = Graph::Easy::Node::Cell->new();

is (ref($cell), 'Graph::Easy::Node::Cell');

is ($cell->error(), '', 'no error yet');

is ($cell->x(), 0, 'x == 0');
is ($cell->y(), 0, 'x == 0');
is ($cell->label(), '', 'label');
is ($cell->name(), '', 'name');
is ($cell->title(), '', 'no title per default');
is (join(",", $cell->pos()), "0,0", 'pos = 0,0');
is ($cell->width(),  undef, 'w == undef');
is ($cell->height(), undef, 'h == undef');

is ($cell->class(), '', 'no class');

#############################################################################
# as_ascii/as_html

is ($cell->as_ascii(), '', 'as_ascii');
is ($cell->as_html(), '', 'as_html');

$cell->_correct_size();

is ($cell->width(),  0, 'w = 0');
is ($cell->height(), 0, 'h = 0');

#############################################################################
# group tests

use Graph::Easy::Group;

my $group = Graph::Easy::Group->new( { name => 'foo' } );

# fake that the cell belongs as filler to a node
my $node = Graph::Easy::Node->new( 'foo' );
$cell->{node} = $node;

is ($cell->node(), $node, 'node for cell');
is ($cell->group(), undef, 'no group yet');

$node->add_to_group($group);

is ($cell->node(), $node, 'node for cell');
is ($cell->group(), $group, 'group foo');

#############################################################################
# title tests

$cell->set_attribute('title', "foo title");

is ($cell->title(), 'foo title', 'foo title');

$cell->del_attribute('title');
$cell->set_attribute('autotitle', 'name');

is ($cell->title(), $cell->name(), 'title equals name');

#############################################################################
# invisible nodes

$node = Graph::Easy::Node->new( { name => "anon 0", label => 'X' } );
$node->set_attribute('shape', "invisible");

is ($node->as_ascii(), "", 'invisible text node');

#############################################################################
# as_txt()

use_ok ('Graph::Easy::As_txt');

can_ok ("Graph::Easy::Node::Cell", qw/
  attributes_as_txt
  as_txt
  as_pure_txt
  /);


