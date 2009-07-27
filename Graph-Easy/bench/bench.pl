#!/usr/bin/perl -w

use Benchmark;
use Graph::Easy;
use Time::HiRes qw/time/;
use strict;
use Devel::Size qw/total_size/;

print "# Graph::Easy v", $Graph::Easy::VERSION,"\n";

print "Creating graph...\n";

my ($g,$n,$last);
time_it ( \&create, shift);

print "Creating txt...\n";
time_it ( \&as_txt );

# dump the text for later
#print STDERR $g->as_txt(); exit;
#print STDERR $g->as_graphviz(); exit;

# $g->timeout(20) if $g->can('timeout');
print $g->as_ascii() if $g->nodes() < 40;

# for profile with -d:DProf
#for (0..5) { $g->layout(); } exit;

print "\n";

exit if shift;

print "Benchmarking...\n";

$n = $g->node('1');

timethese (-5,
  {
  'node cnt' => sub { scalar $g->nodes(); },
  'edge cnt' => sub { scalar $g->edges(); },

  'nodes' => sub { my @O = $g->nodes(); },
  'edges' => sub { my @O = $g->edges(); },

  "conn's" => sub { $n->connections(); },

  "succ's" => sub { scalar $n->successors(); },
  "succ' cnt" => sub { my @O = $n->successors(); },
  "edges_to" => sub { my @O = $n->edges_to($last) },
#  "layout" => sub { $g->layout(); },
#  "as_txt" => sub { $g->as_txt(); },

  } );

sub time_it
  {
  my $time = time;

  my $r = shift;

  &$r(@_);

  printf ("Took %0.4fs\n", time - $time);
  }

sub as_txt
  {
  my $t = $g->as_txt();
  }

sub create
  {
  my $cnt = abs(shift || 1000);

  $g = Graph::Easy->new();

  $n = Graph::Easy::Node->new('0');
  $last = Graph::Easy::Node->new('1');

  for (2..$cnt)
    {
    my $node = Graph::Easy::Node->new($_);
    $g->add_edge($last, $node);
    my $n2 = Graph::Easy::Node->new($_.'A');
    $g->add_edge($last, $n2);
    my $n3 = Graph::Easy::Node->new($_.'B');
    $g->add_edge($last, $n3);
    $last = $node;
    }
  # prior to 0.25, the two calls to nodes() and edges() will take O(N) time, further
  # slowing down this routine by about 10-20%.
  print "Have now ", scalar $g->nodes(), " nodes and ", scalar $g->edges()," edges.\n";

  print "Graph objects takes ", total_size($g), " bytes.\n";
  }

