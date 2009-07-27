#!/usr/bin/perl -w

# test the recursive layouter

use Test::More;
use strict;

BEGIN
   {
   plan tests => 3;
   chdir 't' if -d 't';
   use lib '../lib';
   use_ok ("Graph::Easy") or die($@);
   use_ok ("Graph::Easy::As_txt") or die($@);
   require_ok ("Graph::Easy::As_ascii") or die($@);
   };

#############################################################################
# laying out a group of nodes

my $g = Graph::Easy->new();

my $gr = $g->add_group('Am Rhein:');

my ($a,$b,$e) =  $g->add_edge('St. Goarshausen','St. Goar', 'Ferry');

$gr->add_node($a);
$gr->add_node($b);

#$g->{debug} = 1;
# this is only called for the graph itself, so force it beforehand
$g->_edges_into_groups();

$gr->_layout();

#use Data::Dumper;
#print STDERR Dumper($gr->{cells});

#print $g->as_ascii();

