#!/usr/bin/perl -w

# parser.t does general parser tests, this one deals only with "[A|B|C]" style
# nodes and tests that this feature does work correctly.

use Test::More;
use strict;

BEGIN
   {
   plan tests => 20;
   chdir 't' if -d 't';
   use lib '../lib';
   use_ok ("Graph::Easy::Parser") or die($@);
   };

can_ok ("Graph::Easy::Parser", qw/
  new
  from_text
  from_file
  reset
  error
  _parse_attributes
  /);

#############################################################################
# parser object

my $parser = Graph::Easy::Parser->new();

is (ref($parser), 'Graph::Easy::Parser');
is ($parser->error(), '', 'no error yet');


#############################################################################
# split a node and check all relevant fields

my $graph = $parser->from_text("[A|B|C]");

is (scalar $graph->nodes(), 3, '3 nodes');

my $A = $graph->node('ABC.0');
is (ref($A), 'Graph::Easy::Node', 'node is node');
is ($A->origin(), undef, 'A is the origin itself');

my $B = $graph->node('ABC.1');
is (ref($B), 'Graph::Easy::Node', 'node is node');
is ($B->origin(), $A, 'A is the origin of B');
is (join(",", $B->offset()), "1,0", 'B is at +1,0');

my $C = $graph->node('ABC.2');
is (ref($C), 'Graph::Easy::Node', 'node is node');
is ($C->origin(), $B, 'B is the origin of C');
is (join(",", $C->offset()), "1,0", 'C is at +1,0 from B');

#############################################################################
# general split tests

my $line = 0;

foreach (<DATA>)
  {
  chomp;
  next if $_ =~ /^\s*\z/;			# skip empty lines
  next if $_ =~ /^#/;				# skip comments

  die ("Illegal line $line in testdata") unless $_ =~ /^(.*)\|([^\|]*)$/;
  my ($in,$result) = ($1,$2);

  my $txt = $in;
  $txt =~ s/\\n/\n/g;				# insert real newlines

  Graph::Easy::Node->_reset_id();		# to get "#0" for each test
  my $graph = $parser->from_text($txt);		# reuse parser object

  if (!defined $graph)
    {
    fail($parser->error());
    next;
    }
 
  my $got = scalar $graph->nodes();

  my @edges = $graph->edges();

  my $es = 0;
  foreach my $e (sort { $a->label() cmp $b->label() } @edges)
    {
    $es ++ if $e->label() ne '';
    }

  $got .= '+' . $es if $es > 0;

  for my $n ( sort { $a->{name} cmp $b->{name} } ($graph->nodes(), $graph->edges()) )
    {
    # normalize color output
    my $b = Graph::Easy->color_as_hex($n->attribute('fill'));
    my $dx = $n->{dx}||0;
    my $dy = $n->{dy}||0;
    $got .= ";" . $n->name() . "," . $n->label() . "=$dx.$dy." . $b;
    } 
  
  is ($got, $result, $in);
  }

__DATA__
# split tests with attributes
[A|B|C]|3;ABC.0,A=0.0.#ffffff;ABC.1,B=1.0.#ffffff;ABC.2,C=1.0.#ffffff
[A|B|C] { fill: red; }|3;ABC.0,A=0.0.#ff0000;ABC.1,B=1.0.#ff0000;ABC.2,C=1.0.#ff0000
[A|B|C] { label: foo; fill: red; }|3;ABC.0,foo=0.0.#ff0000;ABC.1,foo=1.0.#ff0000;ABC.2,foo=1.0.#ff0000
[A| |C]|3;AC.0,A=0.0.#ffffff;AC.1, =1.0.#ffffff;AC.2,C=1.0.#ffffff
[A||B|C]|3;ABC.0,A=0.0.#ffffff;ABC.1,B=0.1.#ffffff;ABC.2,C=1.0.#ffffff
[A||B||C]|3;ABC.0,A=0.0.#ffffff;ABC.1,B=0.1.#ffffff;ABC.2,C=0.1.#ffffff
[A|| |C]|3;AC.0,A=0.0.#ffffff;AC.1, =0.1.#ffffff;AC.2,C=1.0.#ffffff
