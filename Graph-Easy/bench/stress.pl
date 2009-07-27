#!/usr/bin/perl -w

BEGIN
  {
  use lib 'lib';
  $|++;
  }

use Scalar::Util qw/weaken/;
use Time::HiRes qw/time/;
use Data::Dumper;
use Graph::Easy;

my $N1 = shift || 5000;
my $N2 = shift || 40000;
my $STEP = shift || 2;

# results
my $RC = [];

print "Using Graph::Easy v$Graph::Easy::VERSION\n";

for (my $N = $N1; $N < $N2; $N *= $STEP)
  {
  my @R = ($N);
  my $start = time();

  print scalar localtime(), " start\n";
  normal($N);
  print scalar localtime(), " done, took ", sprintf("%.2f", time() - $start)," seconds\n";
  push @R, sprintf("%.2f",time() - $start);

  $start = time();

  print scalar localtime(), " start\n";

  my $graph = graph($N);	# return the graph to show that creation sep.

  print scalar localtime(), " done creation, took ", sprintf("%.2f", time() - $start)," seconds\n";
  push @R, sprintf("%.2f",time() - $start);

  $start = time();
  $graph = undef;

  print scalar localtime(), " done destroy, took ", sprintf("%.2f", time() - $start)," seconds\n";
  push @R, sprintf("%.2f",time() - $start);

  $start = time();

  push @$RC, [ @R ];

  }

print "\n";
print "\n", join("\t\t", 'N', 'Normal', 'Graph-Easy'), "\tGraph-Easy\n";
print join("\t\t", '', '', 'Create','Destroy'), "\n";
print '-' x 70,"\n";

# print results
for my $R (@$RC)
  {
  print join("\t\t", @$R), "\n";
  }

sub graph
  {
  my $N = shift;

  my $graph = Graph::Easy->new();

  # create N objects, and "link" them together
  for my $i (1..$N)
    {
    my $b = $i; $b++;
    $graph->add_edge($i,$b);
    }
  print Dumper($graph),"\n" if $N < 10;
  $graph;
  }

sub normal
  {
  my $N = shift;

  my $container = {};

  my $old_object;

  # create N objects, and "link" them together
  for my $i (1..$N)
    {
    my $o = new_object($i);
    $container->{nodes}->{$i} = $o;

    $o->{graph} = $container;
    weaken($o->{graph});
  
    if ($old_object)
      {
      my $link = new_link($old_object, $o, $i);
      $container->{edges}->{$i} = $link;
   
      $link->{graph} = $container;
	{
	no warnings;
	
        weaken($link->{graph});
        weaken($link->{to}->{graph});
        weaken($link->{from}->{graph});
	}
      }

    $old_object = $o;
    }
  print Dumper($container),"\n" if $N < 10;
  }

sub new_object
  {
  my $id = shift;

  my $o = bless { id => $id, att => {}, }, 'main';

  $o;
  }

sub new_link
  {
  my ($a,$b,$id) = @_;

  my $link = bless { id => $id, from => $a, to => $b, att => {} }, 'main';

  $a->{edges}->{$id} = $link;
  $b->{edges}->{$id} = $link;

  $link;
  }
