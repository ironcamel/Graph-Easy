#!/usr/bin/perl -w

use Test::More;
use strict;

BEGIN
   {
   plan tests => 8;
   chdir 't' if -d 't';
   use lib '../lib';
   use_ok qw/Graph::Easy/;
   use_ok qw/Graph::Easy::Parser/;
   }

######################################################
package Graph::Easy::MyNode;

use Graph::Easy::Node;
use base qw/Graph::Easy::Node/;

# override here methods for your node class

######################################################
# when overriding nodes, we also need ::Anon

package Graph::Easy::MyNode::Anon;

#use Graph::Easy::MyNode;
use base qw/Graph::Easy::MyNode/;
use base qw/Graph::Easy::Node::Anon/;

######################################################
# and :::Empty

package Graph::Easy::MyNode::Empty;

#use Graph::Easy::MyNode;
use base qw/Graph::Easy::MyNode/;

######################################################
package Graph::Easy::MyGraph;

use Graph::Easy;
use base qw/Graph::Easy/;

######################################################
package Graph::Easy::MyGroup;

use Graph::Easy::Group;
use base qw/Graph::Easy::Group/;

######################################################
package Graph::Easy::MyEdge;

use Graph::Easy::Edge;
use base qw/Graph::Easy::Edge/;

######################################################
package main;

use Graph::Easy::Parser;
use Graph::Easy;

my $parser = Graph::Easy::Parser->new();

$parser->use_class('node', 'Graph::Easy::MyNode');
$parser->use_class('edge', 'Graph::Easy::MyEdge');
$parser->use_class('graph', 'Graph::Easy::MyGraph');
$parser->use_class('group', 'Graph::Easy::MyGroup');

my $graph = $parser->from_text("( Cities: [ Bonn ] -> [ Berlin| |Spree ] -> [ ])");

is (ref($graph), 'Graph::Easy::MyGraph', 'graph worked');

my $group = $graph->group('Cities:');

is (ref($group), 'Graph::Easy::MyGroup', 'group worked');

my $bonn = $graph->node('Bonn');

is (ref($bonn), 'Graph::Easy::MyNode', 'node worked');

my @nodes = $graph->nodes();

my $empty = $graph->node('BerlinSpree.1');
is (ref($empty), 'Graph::Easy::MyNode::Empty', 'empty node worked');

$graph = $parser->from_text("[ ]");
is (ref($graph), 'Graph::Easy::MyGraph', 'graph with anon node worked');

@nodes = $graph->nodes();
my $anon = $nodes[0];
is (ref($anon), 'Graph::Easy::MyNode::Anon', 'anon node worked');



