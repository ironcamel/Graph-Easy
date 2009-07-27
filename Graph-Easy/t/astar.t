#!/usr/bin/perl -w

use Test::More;
use strict;

BEGIN
   {
   plan tests => 21;
   chdir 't' if -d 't';
   use lib '../lib';
   use_ok ("Graph::Easy") or die($@);
   };

can_ok ("Graph::Easy", qw/
  new
  _find_path_astar
  _astar_distance
  _astar_modifier
  _astar_edge_type
  /);

can_ok ("Graph::Easy::Heap", qw/
  new
  extract_top
  add
  /);

use Graph::Easy::Edge::Cell qw/  
  EDGE_N_E EDGE_N_W EDGE_S_E EDGE_S_W
  EDGE_HOR EDGE_VER
/;

#############################################################################
# _distance tests

my $dis = 'Graph::Easy::_astar_distance';
my $mod = 'Graph::Easy::_astar_modifier';
my $typ = 'Graph::Easy::_astar_edge_type';

{ no strict 'refs';

is (&$dis( 0,0, 3,0 ), 3 + 0 + 0, '0,0 => 3,0: 4 (no corner)');
is (&$dis( 3,0, 3,5 ), 0 + 5 + 0, '3,0 => 3,5: 5 (no corner)');
is (&$dis( 0,0, 3,5 ), 3 + 5 + 1, '0,0 => 3,5: 3+5+1 (one corner)');

is (&$mod( 0,0 ), 1, 'modifier(0,0) is 1');
is (&$mod( 0,0, 1,0, 0,1 ), 7, 'going round a bend is 7');
is (&$mod( 0,0, 1,0, -1,0 ), 1, 'going straight is 1');

is (&$typ( 0,0, 1,0, 2,0 ), EDGE_HOR, 'EDGE_HOR');
is (&$typ( 2,0, 3,0, 4,0 ), EDGE_HOR, 'EDGE_HOR');
is (&$typ( 4,0, 3,0, 2,0 ), EDGE_HOR, 'EDGE_HOR');

is (&$typ( 2,0, 2,1, 2,2 ), EDGE_VER, 'EDGE_VER');
is (&$typ( 2,2, 2,3, 2,4 ), EDGE_VER, 'EDGE_VER');
is (&$typ( 2,2, 2,1, 2,0 ), EDGE_VER, 'EDGE_VER');

is (&$typ( 0,0, 1,0, 1,1 ), EDGE_S_W, 'EDGE_S_W');
is (&$typ( 1,1, 1,0, 0,0 ), EDGE_S_W, 'EDGE_S_W');

is (&$typ( 1,1, 1,0, 2,0 ), EDGE_S_E, 'EDGE_S_E');
is (&$typ( 2,0, 1,0, 1,1 ), EDGE_S_E, 'EDGE_S_E');

is (&$typ( 0,0, 1,0, 1,-1 ), EDGE_N_W, 'EDGE_N_W');
is (&$typ( 1,-1, 1,0, 0,0 ), EDGE_N_W, 'EDGE_N_W');

#print &$typ( 1,2, 2,2, 2,1),"\n";
#print &$typ( 0,2, 1,2, 2,2),"\n";
#print &$typ( 0,1, 0,2, 1,2),"\n";

}

exit;

#############################################################################
# path finding tests

my $graph = Graph::Easy->new();

is (ref($graph), 'Graph::Easy');

is ($graph->error(), '', 'no error yet');

my $node = Graph::Easy::Node->new( name => 'Bonn' );
my $node2 = Graph::Easy::Node->new( name => 'Berlin' );

my $cells = {};
place($cells, $node, 0, 0);
place($cells, $node2, 3, 0);

#my $path = $graph->_find_path_astar( $cells, $node, $node2 );

#is_deeply ($path, [ 0,0, 1,0, 2,0, 3,0 ], '0,0 => 1,0 => 2,0 => 3,0');

place($cells, $node, 0, 0);
place($cells, $node2, 3, 1);

#$path = $graph->_find_path_astar( $cells, $node, $node2 );
#is_deeply ($path, [ 0,0, 1,0, 2,0, 3,0, 3,1 ], '0,0 => 1,0 => 2,0 => 3,0 => 3,1');

$cells = {};
place($cells, $node, 5, 7);
$node2->{cx} = 2;
$node2->{cy} = 2;
place($cells, $node2, 14, 14);

block ($cells,13,14);
block ($cells,14,13);
block ($cells,13,15);
block ($cells,15,13);
block ($cells,14,16);
block ($cells,16,14);

#block ($cells,3,11);
#block ($cells,3,10);
#block ($cells,4,9);
#block ($cells,5,9);
#block ($cells,5,11);
#block ($cells,5,13);

#for (5..15)
#  {
#  block ($cells,15,$_);
#  block ($cells,$_,5);
#  block ($cells,$_,15);
#  }
#block ($cells,15,16);
#block ($cells,14,17);
#block ($cells,3,16);

$graph->{cells} = $cells;
$graph->{_astar_bias} = 0;
my ($p, $closed, $open) = $graph->_find_path_astar($node, $node2 );

#use Data::Dumper; print Dumper($cells);

open FILE, ">test.html" or die ("Cannot write test.html: $!");
print FILE $graph->_map_as_html($cells, $p, $closed, $open);
close FILE;

sub block
  {
  my ($cells, $x,$y) = @_;

  $cells->{"$x,$y"} = 1;
  }

sub place
  {
  my ($cells, $node,$x,$y) = @_;

  my $c = ($node->{cx} || 1) - 1;
  my $r = ($node->{cy} || 1) - 1;

  $node->{x} = $x; $node->{y} = $y;
  
  for my $rr (0..$r)
    {
    my $cy = $y + $rr;
    for my $cc (0..$c)
      {
      my $cx = $x + $cc;
      $cells->{"$cx,$cy"} = $node;
      }
    }
  diag ("Placing $node->{name} at $node->{x},$node->{y}\n");
  }

