#!/usr/bin/perl -w

# Test Graph::Easy::Group and Graph::Easy::Group::Cell

use Test::More;
use strict;

BEGIN
   {
   plan tests => 72;
   chdir 't' if -d 't';
   use lib '../lib';
   use_ok ("Graph::Easy::Group") or die($@);
   use_ok ("Graph::Easy::Group::Cell") or die($@);
   use_ok ("Graph::Easy") or die($@);
   };

can_ok ("Graph::Easy::Group", qw/
  new
  error
  name
  add_node
  add_nodes
  add_member
  has_as_successor
  has_as_predecessor
  successors
  predecessors

  nodes
  edges

  _add_cell _del_cell _cells _clear_cells

  del_node
  del_edge
  del_member

  /);

can_ok ("Graph::Easy::Group::Cell", qw/
  _set_type
  class
  /);

#############################################################################

my $group = Graph::Easy::Group->new();

is (ref($group), 'Graph::Easy::Group');

is ($group->error(), '', 'no error yet');

my $graph = Graph::Easy->new();

use_ok ('Graph::Easy::As_txt');

# "insert" into a graph to get default attributes
$group->{graph} = $graph;

is ($group->as_txt(), "( Group \\#0 )\n\n", 'as_txt (empty group)');
is (scalar $group->nodes(), 0, 'no nodes in group');
is (scalar $group->edges(), 0, 'no edges in group');
is ($group->name(), 'Group #0', 'name()');

my $first = Graph::Easy::Node->new( name => 'first' );
my $second = Graph::Easy::Node->new( name => 'second' );

$group->add_node($first);
is (scalar $group->nodes(), 1, 'one node in group');
is ($first->attribute('group'), $group->name(), 'node has group attribute set');

$group->add_nodes($first, $second);
is (scalar $group->nodes(), 2, 'two nodes in group');
is ($second->attribute('group'), $group->name(), 'node has group attribute set');
is ($second->{group}, $group, 'add_nodes() worked');

is ($group->as_txt(), <<HERE
( Group \\#0
  [ first ]
  [ second ]
)

HERE
, 'as_txt (group with two nodes)');

#############################################################################
# attribute nodeclass

$group = Graph::Easy::Group->new();
$group->set_attributes ( { 'nodeclass' => 'city', } );

is ($first->class(),'node', 'class is "node"');

$group->add_node($first);

is ($first->class(),'node.city', 'class is now "node.city"');

#############################################################################
# Group::Cells

my $c = '_cells';

my $cell = Graph::Easy::Group::Cell->new( group => $group, x => 0, y => 0, );
is (scalar keys %{$group->{$c}}, 1, 'one cell');

my $cells = { '0,0' => $cell };

$cell->_set_type( $cells );

is ($cell->class(), 'group ga', 'group ga');

is ($cell->group( $group->{name} ), $group, "group()");

my $cell2 = Graph::Easy::Group::Cell->new( group => $group, x => 1, y => 0 );
is (scalar keys %{$group->{$c}}, 2, 'one more cell');
$cells->{'1,0'} = $cell2;

my $cell3 = Graph::Easy::Group::Cell->new( group => $group, x => 0, y => -1 );
is (scalar keys %{$group->{$c}}, 3, 'one more cell');
$cells->{'0,-1'} = $cell3;

my $cell4 = Graph::Easy::Group::Cell->new( group => $group, x => 0, y => 1 );
is (scalar keys %{$group->{$c}}, 4, 'one more cell');
$cells->{'0,1'} = $cell4;

is ($cell2->group( $group->{name} ), $group, "group()");

$cell->_set_type( $cells );
is ($cell->class(), 'group gl', 'group gl');

#############################################################################
# attributes on cells

# The default attributes are returned by attribute():

is ($group->attribute('border-style'), 'dashed', 'group border');
is ($group->attribute('borderstyle'), 'dashed', 'group border');
is ($cell->attribute('border'), '', 'default border on this cell');
is ($cell->attribute('border-style'), 'dashed', 'default border on this cell');

is ($group->default_attribute('border-style'), 'dashed', 'group is dashed');
is ($cell->default_attribute('border'), 'dashed 1px #000000', 'dashed border on this cell');
is ($cell->default_attribute('border-style'), 'dashed', 'dashed border on this cell');

is ($group->default_attribute('fill'), '#a0d0ff', 'fill on group');
is ($group->attribute('fill'), '#a0d0ff', 'fill on group');
is ($cell->default_attribute('fill'), '#a0d0ff', 'fill on group cell');
is ($cell->attribute('fill'), '#a0d0ff', 'fill on group cell');

#############################################################################
# del_cell();

#print join (" ", keys %{$group->{cells}}),"\n";

is (scalar keys %{$group->{$c}}, 4, 'one less');
$group->_del_cell($cell);

is (scalar keys %{$group->{$c}}, 3, 'one less');
is ($cell->group(), undef, "no group() on deleted cell");

#############################################################################
# del_node() & del_edge(), when node/edge are in a group (bug until 0.39)

$graph = Graph::Easy->new();

$group = $graph->add_group('group');

my ($A,$B,$E) = $graph->add_edge('A','B','E');

for my $m ($A,$B,$E)
  {
  $group->add_member($m);
  }

is ($group->nodes(), 2, '2 nodes in group');
is ($group->edges(), 0, '0 edges going from/to group');
is ($group->edges_within(), 1, '1 edge in group');

is ($A->attribute('group'), $group->name(), 'group attribute got added');
$graph->del_node($A);

is ($A->attribute('group'), '', 'group attribute got deleted');
is ($group->nodes(), 1, '1 node in group');
is ($group->edges(), 0, '0 edges in group');

($A,$B,$E) = $graph->add_edge('A','B','E');

$group->add_member($A);
$group->add_member($E);

is ($group->nodes(), 2, '2 nodes in group');
is ($group->edges(), 0, '0 edges going from/to group');
is ($group->edges_within(), 1, '1 edge in group');

$graph->del_edge($E);

is ($group->nodes(), 2, '2 nodes in group');
is ($group->edges(), 0, '0 edges in group');
is ($group->edges_within(), 0, '0 edges in group');

#############################################################################
# successors and predecessors

$graph = Graph::Easy->new();

$group = $graph->add_group('group');

my ($g1,$bonn) = $graph->add_edge($group, 'Bonn');
my ($berlin,$g2) = $graph->add_edge('Berlin', $group);

is ($group->has_as_successor($bonn), 1, 'group -> bonn');
is ($group->has_as_successor($berlin), 0, '! group -> berlin');
is ($group->has_as_predecessor($berlin), 1, 'berlin -> group');
is ($group->has_as_predecessor($bonn), 0, '! bonn -> group');

is ($bonn->has_as_successor($group), 0, '! group -> bonn');
is ($berlin->has_as_predecessor($group), 0, 'group -> berlin');
is ($bonn->has_as_predecessor($group), 1, 'bonn -> group');

my @suc = $group->successors();

is (scalar @suc, 1, 'one successor');
is ($suc[0], $bonn, 'group => bonn');

#############################################################################
# add_node('Bonn'), add_member('Bonn','Berlin') etc.

$graph = Graph::Easy->new();

$group = $graph->add_group('group');
$bonn = $group->add_node('Bonn');

is (ref($bonn), 'Graph::Easy::Node', "add_node('Bonn') works for groups");

($bonn,$berlin) = $group->add_nodes('Bonn','Berlin');

is (ref($bonn), 'Graph::Easy::Node', "add_nodes('Bonn') works for groups");
is ($bonn->name(), 'Bonn', "add_nodes('Bonn') works for groups");
is (ref($berlin), 'Graph::Easy::Node', "add_nodes('Berlin') works for groups");
is ($berlin->name(), 'Berlin', "add_nodes('Berlin') works for groups");

# add_edge()
my $edge = $group->add_edge('Bonn','Kassel');

my $kassel = $graph->node('Kassel');

is (ref($kassel), 'Graph::Easy::Node', "add_edge('Bonn','Kassel') works for groups");

# add_edge_once()

$edge = $group->add_edge_once('Bonn','Kassel');

my @edges = $graph->edges('Bonn','Kassel');
is (scalar @edges, 1, 'one edge from Bonn => Kassel');

# add_edge() twice

$edge = $group->add_edge('Bonn','Kassel');

@edges = $graph->edges('Bonn','Kassel');
is (scalar @edges, 2, 'two edges from Bonn => Kassel');

