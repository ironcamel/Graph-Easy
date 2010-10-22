#!/usr/bin/perl -w

# test ranking of nodes, especially _assign_ranks():

use Test::More;
use strict;

BEGIN
   {
   plan tests => 60;
   chdir 't' if -d 't';
   use lib '../lib';
   use_ok ("Graph::Easy::Layout") or die($@);
   };

use Graph::Easy;

#############################################################################
# rank tests

my $graph = Graph::Easy->new();

is (ref($graph), 'Graph::Easy');
is ($graph->error(), '', 'no error yet');

my $A = Graph::Easy::Node->new( name => 'A' );
my $B = Graph::Easy::Node->new( 'B' );
my $C = Graph::Easy::Node->new( 'C' );
my $D = Graph::Easy::Node->new( 'D' );
my $E = Graph::Easy::Node->new( 'E' );

is ($B->name(), 'B');
is ($A->{rank}, undef, 'no ranks assigned yet');

$graph->_assign_ranks();
is ($A->{rank}, undef, 'A not part of graph');
is ($A->connections(), 0);

$graph->add_edge( $A, $B );
$graph->_assign_ranks();
is ($A->connections(), 1);
is ($B->connections(), 1);
is_rank($A, 0); is_rank($B, 1);

$graph->add_edge( $B, $C );
$graph->_assign_ranks();
is_rank($A, 0); is_rank($B, 1); is_rank($C, 2);

$graph->add_edge( $C, $D );
$graph->_assign_ranks();
is_rank($A, 0); is_rank($B, 1); is_rank($C, 2); is_rank($D, 3);

$graph = Graph::Easy->new();
$graph->add_edge( $C, $D );
$graph->add_edge( $A, $B );
$graph->_assign_ranks();
is_rank($A, 0); is_rank($B, 1);
is_rank($C, 0); is_rank($D, 1);

$graph->add_edge( $D, $E );
$graph->_assign_ranks();
is_rank($A, 0); is_rank($B, 1);
is_rank($C, 0); is_rank($D, 1); is_rank($E, 2);

print "# IDs A B C D E: ".
      $A->{id}. " ".
      $B->{id}. " ".
      $C->{id}. " ".
      $D->{id}. " ".
      $E->{id}. "\n";

# circular path C->D->E->C
$graph->add_edge( $E, $C );

$graph->_assign_ranks();
is_rank($A, 0); is_rank($B, 1);
is_rank($C, 0); is_rank($D, 1); is_rank($E, 2);

#############################################################################
# looping node

$graph = Graph::Easy->new();
$graph->add_edge( $A, $A );
$graph->_assign_ranks();
is ($A->connections(), 2);
is_rank($A, 0);

#############################################################################
# multiedged graph

$graph = Graph::Easy->new();
$graph->add_edge( $A, $B );
$graph->add_edge( $A, $B ); # add second edge
$graph->_assign_ranks();
# second edge does not alter result
is (scalar $A->successors(), 1);
is ($A->connections(), 2);
is (scalar $B->predecessors(), 1);
is ($B->connections(), 2);
is_rank($A, 0);
is_rank($B, 1);

#############################################################################
# near nodes (2 in rank 0, one in rank 1, 1 in rank 2)

$graph = Graph::Easy->new();
$graph->add_node($A);
$graph->add_node($B);
$graph->add_node($C);
$graph->add_node($D);
$graph->add_edge( $A, $B );
$graph->add_edge( $C, $B );
$graph->add_edge( $B, $D );
$graph->_assign_ranks();
is ($A->connections(), 1);
is ($B->connections(), 3);
is ($C->connections(), 1);
is ($D->connections(), 1);
is_rank($A, 0);
is_rank($B, 1);
is_rank($C, 0);
is_rank($D, 2);

my @nodes = $graph->sorted_nodes();
is_deeply (\@nodes, [ $A, $B, $C, $D ], 'nodes sorted on id');

@nodes = $graph->sorted_nodes('rank');
is_deeply (\@nodes, [ $A, $C, $B, $D ], 'nodes sorted on rank');

@nodes = $graph->sorted_nodes('rank', 'name');
is_deeply (\@nodes, [ $A, $C, $B, $D ], 'nodes sorted on rank and name');

$A->{name} = 'a';
@nodes = $graph->sorted_nodes('rank', 'name');
is_deeply (\@nodes, [ $C, $A, $B, $D ], 'nodes sorted on rank and name');

$A->{name} = 'Z';
@nodes = $graph->sorted_nodes('rank', 'name');
is_deeply (\@nodes, [ $C, $A, $B, $D ], 'nodes sorted on rank and name');

@nodes = $graph->sorted_nodes('rank', 'id');
is_deeply (\@nodes, [ $A, $C, $B, $D ], 'nodes sorted on rank and id');

@nodes = $graph->sorted_nodes('name', 'id');
is_deeply (\@nodes, [ $B, $C, $D, $A ], 'nodes sorted on name and id');

#############################################################################
# explicit set ranks

$graph = Graph::Easy->new();
$graph->add_edge( $A, $B );
$graph->add_edge( $B, $C );
$graph->add_edge( $C, $D );
$graph->add_edge( $D, $E );

$C->set_attribute('rank', '0');
$E->set_attribute('rank', '5');

$graph->_assign_ranks();

is_rank($A, 0);
is_rank($B, 1);
is_rank($C, 0);
is_rank($D, 1);
is_rank($E, 5);

1;

#############################################################################

sub is_rank
  {
  my ($n, $l) = @_;

  # Rank is "-1..-inf" for automatically assigned ranks, and "1..inf" for
  # user supplied ranks:
  my $rank = abs($n->{rank})-1;

  print STDERR "# called from: ", join(" ", caller),"\n" unless
    is ($rank, $l, "$n->{name} has rank $l");
  }
