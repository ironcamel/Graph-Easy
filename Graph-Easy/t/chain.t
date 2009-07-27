#!/usr/bin/perl -w

use Test::More;
use strict;

BEGIN
   {
   plan tests => 44;
   chdir 't' if -d 't';
   use lib '../lib';
   use_ok ("Graph::Easy::Layout::Chain") or die($@);
   use_ok ("Graph::Easy") or die($@);
   };

can_ok ("Graph::Easy::Layout::Chain", qw/
  new error
  length nodes add_node layout
  /);

#############################################################################
# chain tests

my $c = 'Graph::Easy::Layout::Chain';

my $graph = Graph::Easy->new();
is (ref($graph), 'Graph::Easy');
is ($graph->error(), '', 'no error yet');

my ($node, $node2) = $graph->add_edge('A','B');

my $chain = Graph::Easy::Layout::Chain->new( 
  start => $node, graph => $graph );

is (ref($chain), $c, 'new() seemed to work');
is ($chain->error(), '', 'no error'); 
is ($chain->start(), $node, 'start node is $node');
is ($chain->end(), $node, 'end node is $node');

is ($node->{_chain}, $chain, 'chain stored at node');
is ($chain->length(), 1, 'length() is 1');
is ($chain->length($node), 1, 'length($node) is 1');

$chain->add_node($node2);

is ($node->{_chain}, $chain, 'chain stored at node');
is ($node2->{_chain}, $chain, 'chain stored at node2');
is ($chain->length(), 2, 'length() is now 2');
is ($chain->start(), $node, 'start node is $node');
is ($chain->end(), $node2, 'end node is $node2');
is ($chain->length($node), 2, 'length($node) is 2');
is ($chain->length($node2), 1, 'length($node2) is 1');


#############################################################################
# merging two chains

my ($node3, $node4) = $graph->add_edge('C','D');

my $other = $c->new ( start => $node3, graph => $graph );

is (ref($other), $c, 'new() seemed to work');
is ($other->error(), '', 'no error'); 
is ($other->length(), 1, 'length() is 1');
is ($other->start(), $node3, 'start node is $node3');
is ($other->end(), $node3, 'end node is $node3');

$other->add_node($node4);
is ($other->length(), 2, 'length() is now 2');
is ($other->start(), $node3, 'start node is $node3');
is ($other->end(), $node4, 'end node is $node4');

#diag ("merging chains\n");

$chain->merge($other);

is ($other->error(), '', 'no error'); 
is ($other->length(), 0, 'other length() is still 0');
is ($other->start(), undef, 'start node is $node3');
is ($other->end(), undef, 'end node is $node4');

is ($chain->error(), '', 'no error'); 
is ($chain->length(), 4, 'chain length() is now 4');
is ($chain->start(), $node, 'start node is $node3');
is ($chain->end(), $node4, 'end node is $node4');

my @nodes = $chain->nodes();

is_deeply (\@nodes, [ $node, $node2, $node3, $node4 ], 'nodes got merged');

#############################################################################
# merging two chains, with offset

my ($node5, $node6) = $graph->add_edge('E','F');

$other = $c->new ( start => $node5, graph => $graph );
$other->add_node($node6);

# merge $chain into $other, but keep the first 3 nodes of $chain

$other->merge($chain, $node3);

is ($chain->length(), 4, 'left all four nodes');
is ($other->length(), 4, 'consumed two nodes');

@nodes = $chain->nodes();
is_deeply (\@nodes, [ $node, $node2, $node3, $node4 ], 'nodes got merged');
@nodes = $other->nodes();
is_deeply (\@nodes, [ $node5, $node6, $node3, $node4 ], 'other got two nodes');

for my $node ( @nodes )
  {
  is ($node->{_chain}, $other, 'node got set to new chain');
  }

