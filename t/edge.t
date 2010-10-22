#!/usr/bin/perl -w

use Test::More;
use strict;

BEGIN
   {
   plan tests => 43;
   chdir 't' if -d 't';
   use lib '../lib';
   use_ok qw/Graph::Easy::Edge/;
   use_ok qw/Graph::Easy::Edge::Cell/;
   }

can_ok ("Graph::Easy::Edge", qw/
  new
  error
  label
  _cells
  _add_cell
  _clear_cells
  _unplace
  attribute
  undirected
  bidirectional
  has_ports
  flip

  set_attribute
  set_attributes

  group add_to_group
  background
  edge_flow flow port

  start_port end_port
  from to start_at

  to from nodes

  as_ascii
  as_txt
  /);
  
use Graph::Easy::Edge::Cell qw/EDGE_SHORT_E/;
use Graph::Easy;

#############################################################################

# We need a graph to insert the edge into it, so that the edge gets the
# default settings from it. 
# XXX TODO: should we change the above?

my $graph = Graph::Easy->new();

my $edge = Graph::Easy::Edge->new();

$edge->{graph} = $graph;

is (ref($edge), 'Graph::Easy::Edge');

is ($edge->error(), '', 'no error yet');
is ($edge->undirected(), undef, 'not undirected');
is ($edge->bidirectional(), undef, 'not bidiriectional');
is ($edge->has_ports(), 0, 'has no port restrictions');

use_ok ('Graph::Easy::As_txt');

is ($edge->as_txt(), ' --> ', 'default is "-->"');

#############################################################################
# different styles

$edge = Graph::Easy::Edge->new( style => 'double' );
$edge->{graph} = $graph;
is ($edge->as_txt(), ' ==> ', '"==>"');

$edge = Graph::Easy::Edge->new( style => 'dotted' );
$edge->{graph} = $graph;
is ($edge->as_txt(), ' ..> ', '"..>"');

$edge = Graph::Easy::Edge->new( style => 'dashed' );
$edge->{graph} = $graph;
is ($edge->as_txt(), ' - > ', '"- >"');

$edge = Graph::Easy::Edge->new( style => 'wave' );
$edge->{graph} = $graph;
is ($edge->as_txt(), ' ~~> ', '"~~>"');

$edge = Graph::Easy::Edge->new( style => 'dot-dash' );
$edge->{graph} = $graph;
is ($edge->as_txt(), ' .-> ', '".->"');

$edge = Graph::Easy::Edge->new( style => 'double-dash' );
$edge->{graph} = $graph;
is ($edge->as_txt(), ' = > ', '"= >"');

$edge = Graph::Easy::Edge->new( style => 'dot-dot-dash' );
$edge->{graph} = $graph;
is ($edge->as_txt(), ' ..-> ', '"= >"');

$edge = Graph::Easy::Edge->new( style => 'bold' );
$edge->{graph} = $graph;
is ($edge->as_txt(), ' --> { style: bold; } ', ' --> { style: bold; }');

#############################################################################

$edge = Graph::Easy::Edge->new( label => 'train' );
$edge->{graph} = $graph;
is ($edge->as_txt(), ' -- train --> ', ' -- train -->');

#############################################################################
# cells

is (scalar $edge->_cells(), 0, 'no cells');

my $c = Graph::Easy::Edge::Cell->new (
    edge => $edge,
    type => EDGE_SHORT_E,
    x => 1, y => 1,
    after => 0,
    );
is (scalar $edge->_cells(), 1, 'one cell');
my @cells = $edge->_cells();
is ($cells[0], $c, 'added this cell');

my $c_1 = Graph::Easy::Edge::Cell->new (
    edge => $edge,
    type => EDGE_SHORT_E,
    x => 2, y => 1,
    after => $c,
    );
is (scalar $edge->_cells(), 2, 'two cells');
@cells = $edge->_cells();
is ($cells[0], $c, 'first cell stayed');
is ($cells[1], $c_1, 'added after first cell');

$edge->_clear_cells();
is (scalar $edge->_cells(), 0, 'no cells');

#############################################################################
# undirected/bidirectional

is ($edge->undirected(2), 1, 'undirected');
is ($edge->undirected(), 1, 'undirected');
is ($edge->undirected(0), 0, 'not undirected');
is ($edge->bidirectional(2), 1, 'bidiriectional');
is ($edge->bidirectional(), 1, 'bidiriectional');
is ($edge->bidirectional(0), 0, 'not bidiriectional');

#############################################################################
# has_ports()

$edge->set_attribute('start', 'south');
is ($edge->has_ports(), 1, 'has port restrictions');

$edge->set_attribute('end', 'north');
is ($edge->has_ports(), 1, 'has port restrictions');

$edge->del_attribute('start');
is ($edge->has_ports(), 1, 'has port restrictions');

$edge->del_attribute('end');
is ($edge->has_ports(), 0, 'has no port restrictions');

#############################################################################
# port()

$edge->set_attribute('start', 'south');
my @u = $edge->port('start');
is_deeply (\@u, ['south'], "port('start')");

$edge->del_attribute('end');
$edge->del_attribute('start');

#############################################################################
# background()

is ($edge->background(), 'inherit', 'background()');

$graph = Graph::Easy->new();
my ($A,$B); ($A,$B,$edge) = $graph->add_edge('A','B');

my $group = $graph->add_group('G');
$group->add_member($edge);

my $cell = Graph::Easy::Edge::Cell->new( edge => $edge, graph => $graph );

# default group background
is ($cell->background(), '#a0d0ff', 'background() for group member');

$group->set_attribute('background', 'red');
is ($cell->background(), '#a0d0ff', 'background() for group member');

# now has the fill of the group as background
$group->set_attribute('fill', 'green');
is ($cell->background(), '#008000', 'background() for group member');

#############################################################################
# flip()

my $from = $edge->from();
my $to = $edge->to();

$edge->flip();

is ($from, $edge->to(), 'from/to flipped');
is ($to, $edge->from(), 'from/to flipped');




