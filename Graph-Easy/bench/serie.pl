#!/usr/bin/perl -w

use Benchmark;
use Graph::Easy;
use Time::HiRes qw/time/;
use strict;
use Devel::Size qw/total_size/;

print "# Graph::Easy v", $Graph::Easy::VERSION,"\n";

my @results;

my ($n,$last,$g, $size);

my @counts = ( qw/5 10 50 100 200 500 1000/ );

for my $count (@counts)
  {
  print "Creating graph with ", $count * 3, " nodes and edges...\n";
  my $rc = [ ];
  push @$rc, time_it ( \&create, $count);

  $size = total_size($g);
  print "Graph objects takes $size bytes.\n";

  print "Creating txt...\n";

  print $g->as_ascii() if $count == 5;

  if ($Graph::Easy::VERSION < 0.25 && ($count > 500))
    {
    print "Skipping as_foo() tests.\n";
    push @$rc, 0, 0;
    }
  else
    {
    push @$rc, 
	time_it ( \&as_txt ),
        time_it ( \&as_ascii);
    }

  push @$rc, $size;

  push @results, $rc;
  }

print "Results\n";

for my $r (@results)
  {
  print join (" ", @$r),"\n";
  }

print " <tr>\n  <th>Graph::Easy v$Graph::Easy::VERSION</th>\n  <th>" 
 . join ("</th>\n  <th>", @counts) . "</th>\n </tr>\n";

my $i = 0;
for my $t ( qw/Creation as_txt as_ascii Memory/ )
  {
  print " <tr>\n  <td>$t</td>\n";
  for my $r (@results)
    {
    print "  <td>$r->[$i]</td>\n";
    }
  print " </tr>\n";
  $i++;
  }
  
#print STDERR $g->as_graphviz();

1;

#############################################################################

sub time_it
  {
  my $time = time;

  my $r = shift;

  &$r(@_);

  my $took = sprintf ("%0.4f", time - $time);

  print "Took ${took}s\n";
  $took;
  }

sub as_txt
  {
  my $t = $g->as_txt();
  }

sub as_ascii
  {
  my $t = $g->as_ascii();
  }

sub create
  {
  my $cnt = abs(shift || 1000);

  $g = Graph::Easy->new();

  $n = Graph::Easy::Node->new('0');
  $last = Graph::Easy::Node->new('1');

  for (2..$cnt+1)
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

  $g->{timeout} = 120;
  }

