#!/usr/bin/perl -w

# Test deletion of nodes and edges

use Test::More;
use strict;

BEGIN
   {
   plan tests => 46;
   chdir 't' if -d 't';
   use lib '../lib';
   use_ok ("Graph::Easy") or die($@);
   };

can_ok ("Graph::Easy", qw/
  del_node
  del_edge
  /);

#############################################################################
# first we add edges/nodes

my $graph = Graph::Easy->new();

is (ref($graph), 'Graph::Easy');

is ($graph->error(), '', 'no error yet');

$graph->add_edge('Bonn', 'Berlin');

# check that it contains 2 nodes and one edge
is_ok ($graph);

#############################################################################
print "# add edge, delete it again\n";

my $edge = $graph->add_edge('Bonn', 'Berlin');
$graph->del_edge($edge);

# check that it contains 2 nodes and one edge
is_ok ($graph);

#############################################################################
print "# add selfloop edge, delete it again\n";

$edge = $graph->add_edge('Bonn', 'Bonn');
$graph->del_edge($edge);

# check that it contains 2 nodes and one edge
is_ok ($graph);

$edge = $graph->add_edge('Berlin', 'Berlin');
$graph->del_edge($edge);

# check that it contains 2 nodes and one edge
is_ok ($graph);

#############################################################################
print "# add node, delete it again\n";

my $node = $graph->add_node('Cottbus');
$graph->del_node($node);

# check that it contains 2 nodes and one edge
is_ok ($graph);

#############################################################################
print "# add node with edge, delete it again\n";

my ($n1, $n2, $e) = $graph->add_edge('Cottbus', 'Bonn');
$graph->del_node($n1);

# check that it contains 2 nodes and one edge
is_ok ($graph);

($n1, $n2, $e) = $graph->add_edge('Cottbus', 'Bonn');
($n1, $n2, $e) = $graph->add_edge('Cottbus', 'Berlin');
$graph->del_node($n1);

# check that it contains 2 nodes and one edge
is_ok ($graph);


1; # all tests done

#############################################################################
# test graph after deletion

sub is_ok
  {
  my $graph = shift;

  is ($graph->nodes(), 2, '2 nodes'); 
  is ($graph->edges(), 1, '1 edge'); 

  my $t = '';
  for my $n (sort { $a->{name} cmp $b->{name} } $graph->nodes())
    { 
    $t .= $n->name();
    }
  is ($t, 'BerlinBonn', 'two nodes');

  my $bonn = $graph->node('Bonn');
  my $berlin = $graph->node('Berlin');

  is (scalar keys %{$bonn->{edges}}, 1, 'one edge');
  is (scalar keys %{$berlin->{edges}}, 1, 'one edge');

  my $ids = join (',', 
    keys %{$bonn->{edges}},
    keys %{$berlin->{edges}},
    keys %{$graph->{edges}} );

  is ($ids, '0,0,0', 'edge with ID is the only one');
  }

