#!/usr/bin/perl -w

# test nodes with more than one cell

use Test::More;
use strict;

BEGIN
   {
   plan tests => 30;
   chdir 't' if -d 't';
   use lib '../lib';
   use_ok ("Graph::Easy::Node") or die($@);
   use_ok ("Graph::Easy") or die($@);
   };

can_ok ("Graph::Easy::Node", qw/
  new
  /);

#############################################################################

my $node = Graph::Easy::Node->new();

is (ref($node), 'Graph::Easy::Node');

is ($node->error(), '', 'no error yet');

is ($node->connections(), 0, 'no connections yet');

my $other = Graph::Easy::Node->new();

#############################################################################
# connections() tests

my $graph = Graph::Easy->new( );

$other = Graph::Easy::Node->new( 'Name' );
$graph->add_edge ($node, $other);

is ($node->connections(), 1, 'one connection');

#############################################################################
# grow tests

for (1..4)
  {
  my $o = Graph::Easy::Node->new( "Name $_" );
  $graph->add_edge ($node, $o);
  }

is ($node->connections(), 5, '5 connections');

$node->_grow();

is ($node->connections(), 5, '5 connections');
is ($node->columns(), 1, '1 column');
is ($node->rows(), 3, '3 rows');
is ($node->is_multicelled(), 1, 'is multicelled');

#############################################################################
# edges_to() tests

# this will delete the old Graph::Easy object in graph, and clean out
# the refs in the nodes/edges. Thus $node will have {edges} == undef.
$graph = Graph::Easy->new();

is ($node->{edges}, undef, 'cleanup worked');

$other = Graph::Easy::Node->new( "other" );
my @E;
for (1..5)
  {
  push @E, scalar $graph->add_edge ($node, $other);
  }

@E = sort { $a->{id} <=> $b->{id} } @E;

is ($node->connections(), 5, '5 connections');
is (scalar $node->edges_to($other), 5, '5 edges from node to other');

my @E2 = $node->edges_to($other);
@E2 = sort { $a->{id} <=> $b->{id} } @E2;

for (1..5)
  {
  is ($E[$_], $E2[$_], 'edges_to() worked');
  }

my @suc = $node->successors();

is (scalar @suc, 1, 'one successor');
is ($suc[0], $other, 'one successor');

#use Data::Dumper; print Dumper(\@suc);

#############################################################################
# node placement (multi-cell)

my $cells = { };
my $parent = { cells => $cells };

is ($node->_do_place(1,1,$parent), 1, 'node can be placed');

is (scalar keys %$cells, 3, '3 entries (3 rows)');
is ($cells->{"1,1"}, $node, 'node was really placed');
my $filler = $cells->{"1,2"};
is (ref($filler), 'Graph::Easy::Node::Cell', 'filler cell');
is ($filler->node(), $node, 'filler associated with node');

is ($node->_do_place(1,1,$parent), 0, 'node cannot be placed again');
is ($cells->{"1,1"}, $node, 'node still there placed');
is (scalar keys %$cells, 3, 'still three entries');


