#!/usr/bin/perl -w

use Test::More;
use strict;

BEGIN
   {
   plan tests => 203;
   chdir 't' if -d 't';
   use lib '../lib';
   use_ok ("Graph::Easy::Node") or die($@);
   use_ok ("Graph::Easy") or die($@);
   use_ok ("Graph::Easy::As_ascii") or die($@);
   };

can_ok ("Graph::Easy::Node", qw/
  new
  as_html as_ascii
  error
  class
  dimensions
  name

  sorted_successors
  successors
  predecessors
  has_predecessors
  has_as_predecessor
  has_as_successor
  connections
  edges
  edges_to
  incoming
  outgoing

  width
  background
  height
  columns
  rows
  size
  flow
  angle

  parent
  pos
  offset
  x
  y
  class
  title
  link
  shape
  default_attribute
  del_attribute
  set_attribute
  get_attribute
  set_attributes
  attribute
  default_attribute
  color_attribute
  get_attributes
  border_attribute
  group add_to_group
  origin

  is_multicelled

  nodes_sharing_start
  nodes_sharing_end

  as_html

  _place _do_place _check_place _place_children find_grandparent
  _near_places _allowed_places
  /);

#############################################################################

my $node = Graph::Easy::Node->new();

is (ref($node), 'Graph::Easy::Node');

is ($node->error(), '', 'no error yet');

is ($node->x(), undef, 'x == undef');
is ($node->y(), undef, 'y == undef');
is ($node->label(), 'Node #0', 'label');
is ($node->name(), 'Node #0', 'name');
is ($node->class(), 'node', 'class node');
is ($node->title(), '', 'no title per default');
is (join(",", $node->pos()), "0,0", 'pos = 0,0');
is ($node->width(), undef, 'w = undef');	# no graph => thus no width yet
is ($node->height(), undef, 'h == undef');
is ($node->shape(), 'rect', 'default shape is "rect"');
is ($node->border_attribute(), '', 'border_attribute()');
is ($node->connections(), 0, 'no connections yet');
is ($node->is_multicelled(), 0, 'no multicelled');
is ($node->rows(), 1, '1 row');
is ($node->columns(), 1, '1 column');

# These are inherited:
is ($node->attribute('border'), '', 'attribute("border")');
is ($node->attribute('border-style'), 'solid', 'attribute("border-style")');

is (join(",",$node->dimensions()), "7,1", 'dimensions = (7,1)');

is ($node->origin(), undef, 'not clustered');
is (join(",",$node->offset()), '0,0', 'not clustered');

is (scalar $node->successors(), undef, 'no outgoing links');
is (scalar $node->sorted_successors(), 0, 'no outgoing links');
is (scalar $node->predecessors(), undef, 'no incoming links');
is (scalar $node->incoming(), undef, 'no incoming links');
is (scalar $node->outgoing(), undef, 'no outgoing links');

my $edge = Graph::Easy::Node->new();

$edge->set_attribute('class' => 'edge');

is ($edge->class(), 'node.edge', 'class edge');

is ($edge->border_attribute(), '', 'border_attribute()');

my $other = Graph::Easy::Node->new();

is (scalar $node->edges_to($other), undef, 'no graph, no links');
is (scalar $node->edges(), undef, 'no graph, no edges');

#############################################################################
# predecessors(), successors(), connections() and edges_to() tests

my $graph = Graph::Easy->new( );

$other = Graph::Easy::Node->new( 'Name' );

$edge = $graph->add_edge ($node, $other);

is ($node->{graph}, $graph, "node's graph points to \$graph");
is ($other->{graph}, $graph, "other's graph points to \$graph");

is ($node->successors(), 1, '1 outgoing');
is (scalar $node->sorted_successors(), 1, '1 outgoing');
is ($node->predecessors(), 0, '0 incoming');
is (scalar $node->edges_to($other), 1, '1 link to $other');
is ($node->connections(), 1, '1 connection');
is (scalar $node->edges(), 1, '1 edge');

is ($node->has_as_successor($other), 1, 'node -> other');
is ($node->has_as_successor($node), 0, '! node -> node');
is ($node->has_as_predecessor($node), 0, '! node -> node');
is ($node->has_as_predecessor($other), 0, '! node -> node');

is ($other->has_as_successor($other), 0, '! other -> node');
is ($other->has_as_successor($node), 0, '! other -> other');
is ($other->has_as_predecessor($node), 1, ' node -> other');
is ($other->has_as_predecessor($other), 0, '! other -> other');

my @E = $node->edges_to($other);

is (scalar @E, 1, '1 link to $other');
is ($E[0], $edge, 'first link to $other is $edge');

@E = $node->edges();
is ($E[0], $edge, '1 edge');

is ($other->successors(), 0, '0 outgoing');
is (scalar $other->sorted_successors(), 0, '0 outgoing');
is ($other->predecessors(), 1, '1 incoming');
is ($other->connections(), 1, '1 connection');

$graph->add_edge('First', 'Name');

@E = $node->edges_to($other);
is (scalar @E, 1, '1 link to $other');
is ($E[0], $edge, 'first link to $other is $edge');

$graph->add_edge('Name', 'Name');

#############################################################################
# as_txt/as_html

my $r = 'colspan=4 rowspan=4';

use_ok ('Graph::Easy::As_txt');

can_ok ('Graph::Easy::Node', qw/attributes_as_txt as_txt as_pure_txt/);

is ($node->as_txt(), '[ Node \#0 ]', 'as_txt');
is ($node->as_html(), " <td $r class='node'>Node #0</td>\n",
 'as_html');

# no quoting of () nec.
$node->{name} = 'Frankfurt (Oder)';

is ($node->as_txt(), '[ Frankfurt (Oder) ]', 'as_txt');
is ($node->as_html(), " <td $r class='node'>Frankfurt (Oder)</td>\n",
 'as_html');

# quoting of |
$node->{name} = 'Frankfurt |-|';

is ($node->as_txt(), '[ Frankfurt \|-\| ]', 'as_txt');
is ($node->as_html(), " <td $r class='node'>Frankfurt |-|</td>\n",
 'as_html');

# quoting of [] and {}
$node->{name} = 'Frankfurt [ { #1 } ]';

is ($node->as_txt(), '[ Frankfurt \[ \{ \#1 \} \] ]', 'as_txt');
is ($node->as_html(), " <td $r class='node'>Frankfurt [ { #1 } ]</td>\n",
 'as_html');

# quoting of &, < and >
$node->{name} = 'Frankfurt < & >';

is ($node->as_txt(), '[ Frankfurt < & > ]', 'as_txt');
is ($node->as_html(), " <td $r class='node'>Frankfurt &lt; &amp; &gt;</td>\n",
 'as_html');

#############################################################################
# as_txt with labels

$node->set_attribute('label', 'thelabel');
$node->{name} = 'name';

is ($node->as_txt(), '[ name ] { label: thelabel; }', 'as_txt');

# reset node for next tests
$node->{name} = 'Node #0';
$node->del_attribute('label');

# test setting after deletion
$node->set_attribute('label', 'my label');
is ($node->as_txt(), '[ Node \#0 ] { label: my label; }', 'as_txt');

# reset node for next tests
$node->del_attribute('label');

#############################################################################
# as_txt/as_html w/ subclass and attributes

$node->{class} = 'node.cities';

is ($node->as_txt(), '[ Node \#0 ] { class: cities; }', 'as_txt');
is ($node->as_html(), " <td $r class='node_cities'>Node #0</td>\n",
 'as_html');
is ($node->as_pure_txt(), '[ Node \#0 ]', 'as_txt_node');

$node->set_attribute ( 'color', 'blue' );
is ($node->as_txt(), '[ Node \#0 ] { color: blue; class: cities; }', 'as_txt');
is ($node->as_html(), " <td $r class='node_cities' style=\"color: #0000ff\">Node #0</td>\n",
 'as_html');
is ($node->as_pure_txt(), '[ Node \#0 ]', 'as_pure_txt');

$node->set_attributes ( { color => 'purple' } );
is ($node->as_txt(), '[ Node \#0 ] { color: purple; class: cities; }', 'as_txt');
is ($node->as_html(), " <td $r class='node_cities' style=\"color: #800080\">Node #0</td>\n",
 'as_html');
is ($node->as_pure_txt(), '[ Node \#0 ]', 'as_pure_txt');

#############################################################################
# set_attributes(class => foo)

$node->set_attributes ( { class => 'foo', color => 'orange' } );

is ($node->class(), 'node.foo', 'class set correctly');
is ($node->sub_class(), 'foo', 'class set correctly');
is ($node->attribute('color'), 'orange', 'color set correctly');

is ($node->as_txt(), '[ Node \#0 ] { color: orange; class: foo; }', 'as_txt');
is ($node->as_html(), " <td $r class='node_foo' style=\"color: #ffa500\">Node #0</td>\n",
 'as_html');

$node->set_attribute ( 'class', 'bar' );

is ($node->as_txt(), '[ Node \#0 ] { color: orange; class: bar; }', 'as_txt');
is ($node->as_html(), " <td $r class='node_bar' style=\"color: #ffa500\">Node #0</td>\n",
 'as_html');

#############################################################################
# set_attribute() with encoded entities (%3a etc) and quotation marks

foreach my $l (
  'http://bloodgate.com/',
  '"http://bloodgate.com/"',
  '"http%3a//bloodgate.com/"',
  )
  {
  $node->set_attribute('link', $l);

  is ($node->as_txt(), 
    '[ Node \#0 ] { color: orange; link: http://bloodgate.com/; class: bar; }', 'as_txt');
  is ($node->as_html(), 
    " <td $r class='node_bar'><a href='http://bloodgate.com/' style=\"color: #ffa500\">Node #0</a></td>\n",
    'as_html');
  }

foreach my $l (
  'perl/',
  '"perl/"',
  )
  {
  $node->set_attribute('link', $l);

  is ($node->as_txt(), 
    '[ Node \#0 ] { color: orange; link: perl/; class: bar; }', 'as_txt');
  is ($node->as_html(), 
    " <td $r class='node_bar'><a href='/wiki/index.php/perl/' style=\"color: #ffa500\">Node #0</a></td>\n",
    'as_html');
  }

$node->set_attribute('link', "test test&");
  is ($node->as_txt(), 
    '[ Node \#0 ] { color: orange; link: test test&; class: bar; }', 'as_txt');
  is ($node->as_html(), 
    " <td $r class='node_bar'><a href='/wiki/index.php/test+test&' style=\"color: #ffa500\">Node #0</a></td>\n",
    'as_html');

$node->set_attribute('color', "\\#801010");
  is ($node->as_txt(), 
    '[ Node \#0 ] { color: #801010; link: test test&; class: bar; }', 'as_txt');
  is ($node->as_html(), 
    " <td $r class='node_bar'><a href='/wiki/index.php/test+test&' style=\"color: #801010\">Node #0</a></td>\n",
    'as_html');

# test quotation marks in link:

$node->set_attribute('link', "test'test");
  is ($node->as_txt(), 
    '[ Node \#0 ] { color: #801010; link: test\'test; class: bar; }', 'as_txt');
  is ($node->as_html(), 
    " <td $r class='node_bar'><a href='/wiki/index.php/test%27test' style=\"color: #801010\">Node #0</a></td>\n",
    'as_html');

# quotation mark at the end (but not at the start)
$node->set_attribute('link', "test'");
  is ($node->as_txt(), 
    '[ Node \#0 ] { color: #801010; link: test\'; class: bar; }', 'as_txt');
  is ($node->as_html(), 
    " <td $r class='node_bar'><a href='/wiki/index.php/test%27' style=\"color: #801010\">Node #0</a></td>\n",
    'as_html');

#############################################################################
# multicelled nodes

is ($node->is_multicelled(), 0, 'no multicelled');
is (join (",",$node->size()), '1,1', 'size 1,1');

$node->set_attribute('size', '5,3');
$node->_calc_size();
is (join (",",$node->size()), '5,3', 'size 5,3');
is ($node->is_multicelled(), 1, 'is multicelled');
is ($node->attribute('size'), '5,3', 'attribute("size")');

$node->set_attribute('size', '1,1');
$node->_calc_size();

is ($node->{att}->{rows}, 1, 'rows still present');
is ($node->{att}->{columns}, 1, 'columns still present');
is ($node->as_txt(), "[ Node \\#0 ] { color: #801010; link: test'; class: bar; }",
  'size not in output');

$node->del_attribute('size');
is (exists $node->{att}->{rows} ? 1 : 0, 0, 'rows no longer present');
is (exists $node->{att}->{columns} ? 1 : 0, 0, 'columns no longer present');

#############################################################################
# skipping of attributes (should not appear in HTML)

$node->set_attribute('link', "test test&");
$node->set_attribute('flow','right');
$node->set_attribute('point-style','diamond');

  is ($node->as_txt(), 
    '[ Node \#0 ] { color: #801010; flow: right; link: test test&; pointstyle: diamond; class: bar; }', 'as_txt');
  is ($node->as_html(), 
    " <td $r class='node_bar'><a href='/wiki/index.php/test+test&' style=\"color: #801010\">Node #0</a></td>\n",
    'as_html');

#############################################################################
# group tests

is ($node->group(), undef, 'no groups yet');

use Graph::Easy::Group;

my $group = Graph::Easy::Group->new( { name => 'foo' } );
$node->add_to_group($group);

is ($node->group(), $group, 'group foo');
is ($node->attribute('group'), $group->{name}, 'group foo');

#############################################################################
# title tests

$node->set_attribute('title', "foo title");

is ($node->title(), 'foo title', 'foo title');

$node->del_attribute('title');

$node->set_attribute('autotitle', 'none');
is ($node->title(), '', 'no title if autotitle: none');

$node->set_attribute('autotitle', 'name');
is ($node->title(), $node->name(), 'title equals name');

$node->set_attribute('autotitle', 'label');
is ($node->title(), $node->name(), 'title equals name');

$node->set_attribute('label', 'label');
is ($node->title(), 'label', 'title equals label');

$node->set_attribute('link', '');
$node->set_attribute('autotitle', 'link');
is ($node->title(), '', 'title "" if no link');

$node->set_attribute('link', 'http://bloodgate.com/');
is ($node->title(), $node->link(), 'title eq link');

$node->set_attribute('title','my title');
is ($node->title(), 'my title', 'title will override autotitle');

#############################################################################
# invisible nodes, and nodes with shape none

$node = Graph::Easy::Node->new( { name => "anon 0", label => 'X' } );
$node->set_attribute('shape', "invisible");

is ($node->as_ascii(), "", 'invisible text node');

$node->set_attribute('shape', "none");

$node->_correct_size();

is ($node->as_ascii(), "   \n X \n   ", 'no border for shape "none"');

#############################################################################
# as_ascii() and label vs name (bug until v0.16)

$node = Graph::Easy::Node->new( { name => "Node #01234", label => 'label' } );
is ($node->label(), 'label', 'node label eq "label"');

$node->_correct_size();

is ($node->width(), '9', 'width 9 (length("label") + 2 (padding) + 2 (border)');
is ($node->height(), '3', 'height 3');

like ($node->as_ascii(), qr/label/, 'as_ascii uses label, not name');

#############################################################################
# node placement (unclustered)

$node = Graph::Easy::Node->new();

my $cells = { };
my $parent = { cells => $cells };

is ($node->_do_place(1,1,$parent), 1, 'node can be placed');

is ($cells->{"1,1"}, $node, 'node was really placed');
is (scalar keys %$cells, 1, 'one entry');

is ($node->_do_place(1,1,$parent), 0, 'node cannot be placed again');
is ($cells->{"1,1"}, $node, 'node still there placed');
is (scalar keys %$cells, 1, 'one entry');

#############################################################################
# outgoing/incoming

$graph = Graph::Easy->new();

my ($A,$B);
($A,$B, $edge) = $graph->add_edge('A','B');

is ($A->incoming(), 0, 'no incoming');
is ($B->outgoing(), 0, 'no outgoing');

is ($B->incoming(), 1, 'one incoming');
is ($A->outgoing(), 1, 'one outgoing');

my $C;

($B,$C, $edge) = $graph->add_edge('B', 'C');

is ($B->incoming(), 1, 'one incoming');
is ($C->incoming(), 1, 'one incoming');
is ($A->outgoing(), 1, 'one outgoing');
is ($B->outgoing(), 1, 'one outgoing');

$graph->add_edge('A', 'C');

is ($C->incoming(), 2, 'two incoming');
is ($A->outgoing(), 2, 'one outgoing');

$graph->add_edge('C', 'C');

is ($C->incoming(), 3, 'C -> C');
is ($C->outgoing(), 1, 'C -> C');

#############################################################################
# _allowed_places()

$graph = Graph::Easy->new();

($A,$B, $edge) = $graph->add_edge('A','B');

my @allowed = $A->_allowed_places ( [ 0,0, 0,1, 0,2, 0,3 ], [ 0,0, 0,2, 1,2 ]);
is_deeply (\@allowed, [ 0,0, 0,2 ], '_allowed_places');

@allowed = $A->_allowed_places ( [ 0,0, 0,1, 0,2, 0,3 ], [ ]);
is_deeply (\@allowed, [ ], '_allowed_places');

@allowed = $A->_allowed_places ( [ 0,0, 0,1, 0,2, 0,3 ], [ 3,1, 1,2, 0,4 ]);
is_deeply (\@allowed, [ ], '_allowed_places');

@allowed = $A->_allowed_places ( [ 0,0, 0,1, 0,2, 0,3 ], [ 3,1, 1,2, 0,3 ]);
is_deeply (\@allowed, [ 0,3 ], '_allowed_places');

#############################################################################
# _allow()

$A->{x} = 1; $A->{y} = 2;

$A->{cx} = 3; $A->{cy} = 2;

my $allow = $A->_allow('south','');
is_deeply ($allow, [ 1,4, 2,4, 3,4 ], 'south');

$allow = $A->_allow('south','0');
is_deeply ($allow, [ 1,4 ], 'south,0');

$allow = $A->_allow('south','1');
is_deeply ($allow, [ 2,4 ], 'south,1');

$allow = $A->_allow('south','2');
is_deeply ($allow, [ 3,4 ], 'south,2');

$allow = $A->_allow('south','3');
is_deeply ($allow, [ 3,4 ], 'south,3');

$allow = $A->_allow('south','-1');
is_deeply ($allow, [ 3,4 ], 'south,-1');

$allow = $A->_allow('south','-2');
is_deeply ($allow, [ 2,4 ], 'south,-2');

$allow = $A->_allow('south','-3');
is_deeply ($allow, [ 1,4 ], 'south,-3');

$allow = $A->_allow('south','-4');
is_deeply ($allow, [ 1,4 ], 'south,-4');

$allow = $A->_allow('north','');
is_deeply ($allow, [ 1,1, 2,1, 3,1 ], 'north');

$allow = $A->_allow('north','0');
is_deeply ($allow, [ 1,1 ], 'north,0');

$allow = $A->_allow('north','2');
is_deeply ($allow, [ 3,1 ], 'north,0');

$allow = $A->_allow('north','-1');
is_deeply ($allow, [ 3,1 ], 'north,0');

$allow = $A->_allow('west','');
is_deeply ($allow, [ 0,2, 0,3 ], 'west');

$allow = $A->_allow('west','0');
is_deeply ($allow, [ 0,2 ], 'west');

$allow = $A->_allow('west','1');
is_deeply ($allow, [ 0,3 ], 'west');

$allow = $A->_allow('east','');
is_deeply ($allow, [ 4,2, 4,3 ], 'east');

$allow = $A->_allow('east','1');
is_deeply ($allow, [ 4,3 ], 'east,1');

$allow = $A->_allow('east','2');
is_deeply ($allow, [ 4,3 ], 'east,2');

$allow = $A->_allow('east','-1');
is_deeply ($allow, [ 4,3 ], 'east,-1');

#############################################################################
# parent()

$graph = Graph::Easy->new();

($A,$B, $edge) = $graph->add_edge('A','B');

is ($A->parent(), $graph, 'parent is graph');

$group = $graph->add_group('Test');
$group->add_node($A);

is ($A->parent(), $group, 'parent is group');

#############################################################################
# angle()

my @angles = qw/south south front left -90 back -45 45 +45/;
my @expect = qw/180 180 90 0 0 270 45 45 135/;

is ($A->angle(), 0, 'default is 0 pointing up');
$A->set_attribute('rotate', 'south');

my $i = 0;
for my $e (@expect)
  {
  my $an = $angles[$i++];
  $A->set_attribute('rotate', $an);
  is ($A->angle(), $e, "expect $e for $an");
  }

$A->del_attribute('flow', 'south');
is ($A->{_cached_flow}, undef, 'flow uncached by set_attribute');

$A->flow();				# cache again
$A->set_attribute('flow', 'south');
is ($A->{_cached_flow}, undef, 'flow uncached by set_attribute');

@angles = qw/south south front left -90 back -45 45 +45/;
@expect = qw/180 180 180 90 90 0 135 45 225/;

$i = 0;
for my $e (@expect)
  {
  my $an = $angles[$i++];
  $A->set_attribute('rotate', $an);
  is ($A->angle(), $e, "expect $e for $an");
  }

#############################################################################
# Deleting a node should work if the node is a child node (fail untill v0.49)

$graph = Graph::Easy->new();

$A = $graph->add_node('A');
$B = $graph->add_node('B');
$B->set_attribute('origin','A');
$B->set_attribute('offset','2,2');

$graph->del_node('B');

is ($graph->as_ascii(), "+---+\n| A |\n+---+\n", 'only one node rendered');

