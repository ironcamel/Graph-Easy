#!/usr/bin/perl -w

# Test the Heap structure for A*

use Test::More;
use strict;

BEGIN
   {
   plan tests => 72;
   chdir 't' if -d 't';
   use lib '../lib';
   use_ok ("Graph::Easy::Layout") or die($@);
   use_ok ("Graph::Easy") or die($@);
   };

can_ok ("Graph::Easy::Heap", qw/
  add
  extract_top
  elements
  delete
  /);

my $heap = Graph::Easy::Heap->new();

#############################################################################
# heap tests

is (ref($heap), 'Graph::Easy::Heap', 'new() worked');
is ($heap->elements(), 0, '0 elements');

# add some elements (some of them with the same weight)
$heap->add( [ 1, '', 0,0] ); is ($heap->elements(), 1, '1 elements');
$heap->add( [ 1, '', 1,0] ); is ($heap->elements(), 2, '2 elements');
$heap->add( [ 2, '', 2,0] ); is ($heap->elements(), 3, '3 elements');
$heap->add( [ 2, '', 3,0] ); is ($heap->elements(), 4, '4 elements');
$heap->add( [ 2, '', 4,0] ); is ($heap->elements(), 5, '5 elements');
$heap->add( [ 2, '', 5,0] ); is ($heap->elements(), 6, '6 elements');
$heap->add( [ 3, '', 6,0] ); is ($heap->elements(), 7, '7 elements');

# extract them again

for (my $i = 0; $i < 7; $i++)
  {
  my $e = $heap->extract_top(); is ($e->[2], $i, "elem $i extracted");
  }

#############################################################################
# add some elements (some of them with the same weight)

$heap->add( [ 1, '', 0,0] ); is ($heap->elements(), 1, '1 elements');
$heap->add( [ 1, '', 1,0] ); is ($heap->elements(), 2, '2 elements');
$heap->add( [ 2, '', 2,0] ); is ($heap->elements(), 3, '3 elements');
$heap->add( [ 2, '', 3,0] ); is ($heap->elements(), 4, '4 elements');
$heap->add( [ 2, '', 4,0] ); is ($heap->elements(), 5, '5 elements');
$heap->add( [ 2, '', 5,0] ); is ($heap->elements(), 6, '6 elements');
$heap->add( [ 3, '', 7,0] ); is ($heap->elements(), 7, '7 elements');
# supposed to end at the end of the row of "2" 
$heap->add( [ 2, '', 6,0] ); is ($heap->elements(), 8, '8 elements');

# extract them again

for (my $i = 0; $i < 8; $i++)
  {
  my $e = $heap->extract_top(); is ($e->[2], $i, "elem $i extracted");
  }
is ($heap->elements(), 0, '0 elements');

#############################################################################
# overflow the simple algorithm (more than 16) and use binary search for add

for (my $i = 0; $i < 8; $i++)
  {
  $heap->add( [ 1, '', $i,0] );
  }
is ($heap->elements(), 8, '8 elements');
for (my $i = 0; $i < 7; $i++)
  {
  $heap->add( [ 2, '', $i+8,0] );
  }
is ($heap->elements(), 15, '15 elements');
for (my $i = 0; $i < 16; $i++)
  {
  $heap->add( [ 3, '', $i+8+8,0] );
  }
is ($heap->elements(), 31, '31 elements');
# supposed to end at the end of the row of "2" 
$heap->add( [ 2, '', 15,0] );

is ($heap->elements(), 32, '32 elements');

# extract them again
for (my $i = 0; $i < 32; $i++)
  {
  my $e = $heap->extract_top(); is ($e->[2], $i, "elem $i extracted");
  }



