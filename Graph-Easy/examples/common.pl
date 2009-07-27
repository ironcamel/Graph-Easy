#!/usr/bin/perl -w

#############################################################################
# This script is used by both examples/ascii.pl and examples/html.pl to
# generate some sample graphs and then outputting them in the desired format.

use strict;
use warnings;

BEGIN
  {
  use lib '../lib';
  }

use Graph::Easy;

sub gen_graphs
  {
  my $graph = shift || Graph::Easy->new();
  my $method = shift || 'ascii';

  ###########################################################################

  my $node = $graph->add_node( 'Bonn' );
  my $node2 = $graph->add_node( 'Berlin' );

  $graph->add_edge( $node, $node2 );

  out ($graph, $method);
  
  ###########################################################################
  $graph->{debug} = 0;

  my $node3 = $graph->add_node( 'Frankfurt' );
  $node3->set_attribute('border-style', 'dotted');

  my $edge3 = Graph::Easy::Edge->new( style => 'double' );

  $graph->add_edge( $node2, $node3, $edge3 );

  out ($graph, $method);

  ###########################################################################

  $graph->add_edge( $node3, 'Dresden' );

  out ($graph, $method);

  ###########################################################################

  $graph->add_edge( $node2, 'Potsdam' );

  out ($graph, $method);

  ###########################################################################
  my $node6 = $graph->add_node( 'Cottbus',);
  $node6->set_attribute('border', '1px red dashed');
 
  my $edge5 = $graph->add_edge( 'Potsdam', $node6 );

  out ($graph, $method);
  
  ###########################################################################
  $graph->add_edge( $node6, $node3 );

  out ($graph, $method);

  $graph->add_edge( $node6, $node3 );

  out ($graph, $method);

  }

1;
