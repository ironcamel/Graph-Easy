#!/usr/bin/perl -w

# Test the copy() method

use Test::More;
use strict;

BEGIN
   {
   plan tests => 55;
   chdir 't' if -d 't';
   use lib '../lib';
   use_ok ("Graph::Easy") or die($@);
   };

can_ok ('Graph::Easy', qw/
  new
  copy
  /);

#############################################################################
my $graph = Graph::Easy->new();

check_graph($graph);
my $copy = $graph->copy();
check_graph($copy);

my $bonn = Graph::Easy::Node->new( name => 'Bonn' );
my $berlin = Graph::Easy::Node->new( 'Berlin' );
my $edge = $graph->add_edge ($bonn, $berlin);
my $group = $graph->add_group ('Cities');
is (ref($edge), 'Graph::Easy::Edge', 'add_edge() returns the new edge');
$bonn->set_attribute('color','red');
$edge->set_attribute('fill','blue');
$graph->set_attribute('graph','fill','purple');

check_members($graph);
$copy = $graph->copy();
check_members($copy);

#############################################################################
# settings on the graph object itself

$graph->fatal_errors();
$graph->catch_warnings(1);
$graph->catch_errors(1);
 
check_settings($graph);
$copy = $graph->copy();
check_settings($copy);

#############################################################################
# groups with nodes

$graph = Graph::Easy->new('( Cities [ Bonn ] -> [ Berlin ] )' );
$copy = $graph->copy();

$group = $graph->group('Cities');
is (scalar $group->nodes(), 2, '2 nodesi in original group');

$group = $copy->group('Cities');
is (scalar $group->nodes(), 2, '2 nodes in copied group');

#############################################################################
#############################################################################

sub check_settings
  {
  my $graph = shift;

  is ($graph->{_catch_warnings}, 1, 'catch warnings');
  is ($graph->{_catch_errors}, 1, 'catch errors');
  is ($graph->{fatal_errors}, 1, 'fatal errors');
  }

sub check_members
  {
  my $graph = shift;

#  use Data::Dumper; print Dumper($graph);

  is ($graph->nodes(), 2, '2 nodes added');
  is ($graph->edges(), 1, '1 edge');

  is ($graph->as_txt(), <<EOF
graph { fill: purple; }

[ Bonn ] { color: red; }

( Cities )

[ Bonn ] --> { fill: blue; } [ Berlin ]
EOF
, 'as_txt for 2 nodes');

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

  is( $graph->node('Bonn')->attribute('color'),'red', 'Bonn is red');
  is( $graph->edge('Bonn','Berlin')->attribute('fill'),'blue', 'Bonn->Berlin is blue');
  is( $graph->get_attribute('fill'), 'purple', 'graph is purple');
  }

#############################################################################

sub check_graph
  {
  my $graph = shift;

#  use Data::Dumper; print Dumper($graph);
  is (ref($graph), 'Graph::Easy');
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
  }


