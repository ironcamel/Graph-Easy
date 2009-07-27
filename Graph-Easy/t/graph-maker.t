#!/usr/bin/perl -w

# test interface being compatible to Graph.pm so that Graph::Maker works:
use Test::More;
use strict;

BEGIN
   {
   plan tests => 15;
   chdir 't' if -d 't';
   use lib '../lib';
   use_ok ("Graph::Easy") or die($@);
   };

can_ok ('Graph::Easy', qw/
  new

  add_vertex
  add_vertices
  has_edge
  vertices
  add_path
  add_cycle
  /);

#############################################################################
my $graph = Graph::Easy->new();

is (ref($graph), 'Graph::Easy');

is ($graph->error(), '', 'no error yet');

$graph->add_vertex('A');
my $A = $graph->node('A');

is (scalar $graph->vertices(), 1, '1 vertex');
my @nodes = $graph->vertices();
is ($nodes[0], $A, '1 vertex');

my $edge = $graph->add_edge ('A', 'B');

is ($graph->has_edge('A','B'), 1, 'has_edge()');
is ($graph->has_edge($A,'B'),  1, 'has_edge()');
is ($graph->has_edge('C','B'), 0, 'has_edge()');

$graph->add_vertices('A','B','C');
is (scalar $graph->vertices(), 3, '3 vertices');

$graph->set_vertex_attribute('A','fill','#deadff');

my $atr = $graph->get_vertex_attribute('A','fill');

is ($atr, $A->attribute('fill'), 'attribute got set');

#############################################################################
## add_cycle and add_path
#

$graph = Graph::Easy->new();
$graph->add_path('A','B','C');
is (scalar $graph->vertices(), 3, '3 vertices');
is (scalar $graph->edges(), 2, '2 vertices');

$graph = Graph::Easy->new();
$graph->add_cycle('A','B','C');
is (scalar $graph->vertices(), 3, '3 vertices');
is (scalar $graph->edges(), 3, '3 vertices');


