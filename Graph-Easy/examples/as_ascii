#!/usr/bin/perl -w

#############################################################################
# This example is a bit outdated, please use the new bin/graph-easy script -
# which is after "make install" available on any command line in your system.

# Convert an input file containing a Graph::Easy description to
# ASCII art.

# Example usage:
#  examples/as_ascii t/in/2nodes.txt
#  echo "[ A ] -> [ B ]" | examples/as_ascii

BEGIN { $|++; }

use lib 'lib';
use Graph::Easy::Parser;

my $file = shift;
my $id = shift || '';
my $debug = shift;

my $parser = Graph::Easy::Parser->new( debug => $debug );

if (!defined $file)
  {
  $file = \*STDIN;
  binmode STDIN, ':utf8' or die ("binmode STDIN, ':utf8' failed: $!");
  }
binmode STDERR, ':utf8' or die ("binmode STDERR, ':utf8' failed: $!");
my $graph = $parser->from_file( $file );

die ($parser->error()) unless defined $graph;

$graph->id($id);
$graph->timeout(360);
$graph->layout();

warn($graph->error()) if $graph->error();

binmode STDOUT, ':utf8' or die ("binmode STDOUT, ':utf8' failed: $!");
print $graph->as_ascii();

