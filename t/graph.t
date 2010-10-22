#!/usr/bin/perl -w

use Test::More;
use strict;

BEGIN
   {
   plan tests => 72;
   chdir 't' if -d 't';
   use lib '../lib';
   use_ok ("Graph::Easy") or die($@);
   };

can_ok ('Graph::Easy', qw/
  new
  _init

  timeout
  strict
  output_format
  output
  seed randomize
  debug

  border_attribute
  anon_nodes
  /);

#############################################################################
my $graph = Graph::Easy->new();

is (ref($graph), 'Graph::Easy');

ok (defined $graph->{seed}, 'seed was initialized');

is ($graph->error(), '', 'no error yet');
is ($graph->output_format(), 'html', 'default output format is html');

is ($graph->timeout(), 5, '5 seconds');
is ($graph->strict(), 1, 'is strict');
is ($graph->nodes(), 0, '0 nodes');
is ($graph->edges(), 0, '0 edges');
is ($graph->border_attribute('graph'), 'none', 'graph border is none');
is ($graph->border_attribute('group'), 'dashed', 'group border is dashed 1px black');
is ($graph->border_attribute('node'), 'solid', 'node border is solid 1px black');

is (join (',', $graph->edges()), '', '0 edges');

like ($graph->output(), qr/table/, 'default output worked');

my $bonn = Graph::Easy::Node->new( name => 'Bonn' );
my $berlin = Graph::Easy::Node->new( 'Berlin' );

my $edge = $graph->add_edge ($bonn, $berlin);

is (ref($edge), 'Graph::Easy::Edge', 'add_edge() returns the new edge');

is ($graph->nodes(), 2, '2 nodes added');
is ($graph->edges(), 1, '1 edge');

is ($graph->as_txt(), "[ Bonn ] --> [ Berlin ]\n", 'as_txt for 2 nodes');

is (ref($graph->edge($bonn,$berlin)), 'Graph::Easy::Edge', 'edge from objects');
is ($graph->edge($berlin,$bonn), undef, 'berlin not connecting to bonn');

is (ref($graph->edge('Bonn', 'Berlin')), 'Graph::Easy::Edge', 'edge from names');

my @E = $graph->edges();

my $en = '';
for my $e (@E)
  {
  $en .= $e->style() . '.';
  }

is ($en, 'solid.', 'edges() in list context');

#############################################################################

my $ffm = Graph::Easy::Node->new( name => 'Frankfurt a. M.' );
# test add_edge ($n1,$n2, $label)
$graph->add_edge ($ffm, $bonn, 'train');

is ($graph->nodes (), 3, '3 nodes');
is ($graph->edges (), 2, '2 edges');

my $e = $graph->edge ($ffm,$bonn);
is ($e->label(), 'train', 'add_edge($n,$n2,"label") works');

# print $graph->as_ascii();

#############################################################################
# as_txt() (simple nodes)

is ( $graph->as_txt(), <<HERE
[ Frankfurt a. M. ] -- train --> [ Bonn ]
[ Bonn ] --> [ Berlin ]
HERE
, 'as_txt() for 3 nodes with 2 edges');

my $schweinfurt = Graph::Easy::Node->new( name => 'Schweinfurt' );
$graph->add_edge ($schweinfurt, $bonn);

is ($graph->nodes (), 4, '4 nodes');
is ($graph->edges (), 3, '3 edges');

is ( $graph->as_txt(), <<HERE
[ Frankfurt a. M. ] -- train --> [ Bonn ]
[ Schweinfurt ] --> [ Bonn ]
[ Bonn ] --> [ Berlin ]
HERE
, 'as_txt() for 4 nodes with 3 edges');

#############################################################################
# as_txt() (nodes with attributes)

$bonn->set_attribute('class', 'cities');

is ( $graph->as_txt(), <<HERE
[ Bonn ] { class: cities; }

[ Frankfurt a. M. ] -- train --> [ Bonn ]
[ Schweinfurt ] --> [ Bonn ]
[ Bonn ] --> [ Berlin ]
HERE
, 'as_txt() for 4 nodes with 3 edges and attributes');

$bonn->set_attribute('border', 'none');
$bonn->set_attribute('color', 'red');
$berlin->set_attribute('color', 'blue');

is ($bonn->attribute('borderstyle'), 'none', 'borderstyle set to none');
is ($bonn->attribute('border'), 'none', 'border set to none');
is ($bonn->border_attribute(), 'none', 'border set to none');

# border is second-to-last, class is the last attribute:

is ( $graph->as_txt(), <<HERE
[ Berlin ] { color: blue; }
[ Bonn ] { color: red; border: none; class: cities; }

[ Frankfurt a. M. ] -- train --> [ Bonn ]
[ Schweinfurt ] --> [ Bonn ]
[ Bonn ] --> [ Berlin ]
HERE
, 'as_txt() for 4 nodes with 3 edges and class attribute');


# set only 1px and dashed
$graph->set_attribute('graph', 'border', '1px dotted');
$graph->set_attribute('node', 'border', 'blue solid 2px');

# override "borderstyle"
$graph->set_attribute('graph', 'border-style', 'dashed');

is ($graph->attribute('borderstyle'), 'dashed', 'borderstyle set on graph');
is ($graph->attribute('borderwidth'), '1', 'borderwidth set on graph');
is ($graph->attribute('bordercolor'), '#000000', 'bordercolor is default black');
is ($graph->attribute('border'), 'dashed', 'border set on graph');
is ($graph->border_attribute(), 'dashed', 'border set on graph');

# the same with the class attribute for the graph
is ($graph->attribute('graph','borderstyle'), 'dashed', 'borderstyle set on class graph');
is ($graph->attribute('graph','borderwidth'), '1', 'borderwidth set on class graph');
is ($graph->attribute('graph','bordercolor'), '#000000', 'bordercolor is default black');
is ($graph->attribute('graph','border'), 'dashed', 'border set on class graph');
is ($graph->border_attribute('graph'), 'dashed', 'border set on class graph');

# the same with the class attribute for class "node"
is ($graph->attribute('node','borderstyle'), 'solid', 'borderstyle set on class node');
is ($graph->attribute('node','borderwidth'), '2', 'borderwidth set on class node');
is ($graph->attribute('node','bordercolor'), 'blue', 'borderwidth set on class node');
is ($graph->attribute('node','border'), 'solid 2px blue', 'border set on class node');
is ($graph->border_attribute('node'), 'solid 2px blue', 'border set on class node');

# graph/node/edge attributes come first

# graph "border: dashed" because "black" and "1px" are the defaults
# node "border: solid 2px blue" because these are not the defaults (color/width changed
# means we also get the style explicitely)

is ( $graph->as_txt(), <<HERE
graph { border: dashed; }
node { border: solid 2px blue; }

[ Berlin ] { color: blue; }
[ Bonn ] { color: red; border: none; class: cities; }

[ Frankfurt a. M. ] -- train --> [ Bonn ]
[ Schweinfurt ] --> [ Bonn ]
[ Bonn ] --> [ Berlin ]
HERE
, 'as_txt() for 4 nodes with 3 edges and graph/node/edge attributes');

#############################################################################
# output and output_format:

$graph = Graph::Easy->new();
is (ref($graph), 'Graph::Easy', 'new worked');

$graph->add_edge ($bonn, $berlin);

like ($graph->output(), qr/table/, 'default output worked');

$graph->set_attribute('graph', 'output', 'ascii');

is ($graph->output_format(), 'ascii', 'output format changed to ascii');
unlike ($graph->output(), qr/<table>/, 'ascii output worked');

#############################################################################
# add_group()

my $group = $graph->add_group('G');

is (ref($group), 'Graph::Easy::Group', 'add_group()');

#############################################################################
# merge_nodes() with node B in a group (fixed in v0.39)

$graph = Graph::Easy->new();

my ($A,$B) = $graph->add_edge('Bonn','Berlin','true');

$group = $graph->add_group('Cities');

is (scalar $group->nodes(), 0, 'no node in group');

$group->add_node($A);
is (scalar $group->nodes(), 1, 'one node in group');
$group->add_node($B);
is (scalar $group->nodes(), 2, 'one node in group');

is (scalar $graph->nodes(), 2, 'two nodes in graph');
is (scalar $graph->edges(), 1, 'one edge in graph');

is (scalar $group->edges(), 0, 'no edge in group');

$graph->layout();

# the edge is only added in the layout stage
is (scalar $group->edges(), 0, 'no edge leading from/to group');
is (scalar $group->edges_within(), 1, 'one edge in group');

$graph->merge_nodes($A,$B);

is (scalar $graph->edges(), 0, 'no edges in graph');
is (scalar $group->edges_within(), 0, 'no edges in group');
is (scalar $group->edges(), 0, 'no edge leading from/to group');
is (scalar $group->nodes(), 1, 'one node in group');
is (scalar $graph->nodes(), 1, 'one node in graph');

is (keys %{$A->{edges}}, 0, 'no edges in A');
is (keys %{$B->{edges}}, 0, 'no edges in B');
is ($B->{group}, undef, "B's group status got revoked");

