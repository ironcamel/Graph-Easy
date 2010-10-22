#!/usr/bin/perl -w

use Test::More;
use strict;

BEGIN
   {
   plan tests => 12;
   chdir 't' if -d 't';
   use lib '../lib';
   use_ok ("Graph::Easy") or die($@);
   };

#############################################################################
# basic tests

my $graph = Graph::Easy->new();

my ($first, $second, $edge) = $graph->add_edge('first', 'second');

$second->set_attribute('origin', $first->{name});

is (join(",", $second->offset()), '0,0', 'offset is 0,0');
is ($second->origin(), $first, 'origin is $first');

#############################################################################
# graph tests
# node placement (clustered)

$graph = Graph::Easy->new();

$first = $graph->add_node('A');
$second = $graph->add_node('B');

$second->relative_to($first, 1,0);

is (scalar $graph->nodes(), 2, 'two nodes');

my $cells = { };
my $parent = { cells => $cells };

is ($first->_do_place(1,1,$parent), 1, 'node can be placed');

is ($cells->{"1,1"}, $first, 'first was really placed');
is ($cells->{"2,1"}, $second, 'second node was placed, too');
is (scalar keys %$cells, 2, 'two nodes placed');

# 1,0 and 2,0 are blocked, so 0,0+1,0; 1,0+2,0 and 2,0+3,0 are blocked, too:
is ($first->_do_place(0,1,$parent), 0, 'node cannot be placed again');
is ($first->_do_place(1,1,$parent), 0, 'node cannot be placed again');
is ($first->_do_place(2,1,$parent), 0, 'node cannot be placed again');

is (scalar keys %$cells, 2, 'two nodes placed');


