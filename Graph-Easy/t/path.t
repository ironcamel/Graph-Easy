#!/usr/bin/perl -w

use Test::More;
use strict;

BEGIN
   {
   plan tests => 7;
   chdir 't' if -d 't';
   use lib '../lib';
   use_ok ("Graph::Easy::Layout") or die($@);
   use_ok ("Graph::Easy") or die($@);
   };

can_ok ("Graph::Easy", qw/
  _path_is_clear
  /);

my $path = [
  0,0,0,
  1,0,0,
  2,0,0,
  2,1,0,
  2,2,0,
  2,3,0,
  2,4,0,
  ];

my $cells = {};

#############################################################################
# path tests

my $graph = Graph::Easy->new();
is (ref($graph), 'Graph::Easy');
is ($graph->error(), '', 'no error yet');

$graph->{cells} = $cells;

is ($graph->_path_is_clear( $path, $cells), 1, 'path is clear');

$cells->{"2,2"} = 1;

is ($graph->_path_is_clear( $path, $cells), 0, 'path is blocked');


