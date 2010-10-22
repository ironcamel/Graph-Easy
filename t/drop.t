#!/usr/bin/perl -w

# test multiple calls to as_ascii()/as_boxart() as well as merge_nodes

use Test::More;

BEGIN
  {
  plan tests => 5;
  chdir 't' if -d 't';
  use lib '../lib';
  use_ok("Graph::Easy") or die (@!);
  use_ok("Graph::Easy::Parser") or die (@!);
  }

my $graph = Graph::Easy::Parser->from_file('stress/drop.txt');

binmode STDOUT, ':utf8' or die ("binmode STDOUT, ':utf8' failed: $!");
binmode STDERR, ':utf8' or die ("binmode STDERR, ':utf8' failed: $!");

my $bonn = $graph->node('Bonn');

my $first = $graph->as_ascii();
my $second = $graph->as_ascii();

is ($first, $second, 'two times as_ascii() changes nothing');

$first = $graph->as_boxart();
$second = $graph->as_boxart();

is ($first, $second, 'two times as_boxart() changes nothing');


# drop any connection between Bonn and Berlin, as well as self-loops
# from Berlin to Berlin

$graph->merge_nodes('Bonn', 'Berlin');

my $result = $first . "\n" . $graph->as_boxart();

my $expected = readfile('out/drop_result.txt');

is ($result, $expected, 'dropping a node works');

# all tests done

1;

sub readfile
  {
  my ($file) = @_;

  open FILE, $file or die ("Cannot read file $file: $!");
  binmode FILE, ':utf8' or die ("binmode $file, ':utf8' failed: $!");
  local $/ = undef;                             # slurp mode
  my $doc = <FILE>;
  close FILE;

  $doc;
  }

