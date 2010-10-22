#!/usr/bin/perl -w

# Some basic as_vcg tests

use Test::More;
use strict;

BEGIN
   {
   plan tests => 7;
   chdir 't' if -d 't';
   use lib '../lib';
   use_ok ("Graph::Easy") or die($@);
   use_ok ("Graph::Easy::Parser") or die($@);
   };

can_ok ('Graph::Easy', qw/
  as_vcg
  as_vcg_file
  /);

#############################################################################
my $graph = Graph::Easy->new();

my $vcg = $graph->as_vcg();
my $vcg_file = $graph->as_vcg_file();

# remove time stamp:
$vcg =~ s/ at.*//;
$vcg_file =~ s/ at.*//;
is ($vcg, $vcg_file, 'as_vcg and as_vcg_file are equal');

$graph->add_edge('A','B');

like ($graph->as_vcg(), qr/edge: { sourcename: "A" targetname: "B" }/,
	'as_vcg matches');

# set edge label
my @edges = $graph->edges();
$edges[0]->set_attribute('label', 'my car');

like ($graph->as_vcg(),
	qr/edge: { label: "my car" sourcename: "A" targetname: "B" }/,
	'as_vcg matches');

#############################################################################
# graph label

$graph = Graph::Easy->new();
$graph->set_attribute('label', 'my graph label');

like ($graph->as_vcg(), qr/title: "my graph label"/,
	'as_vcg has graph label');

