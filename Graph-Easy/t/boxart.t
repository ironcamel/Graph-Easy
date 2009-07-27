#!/usr/bin/perl -w

use Test::More;
use strict;

BEGIN
   {
   plan tests => 15;
   chdir 't' if -d 't';
   use lib '../lib';
   use_ok ("Graph::Easy") or die($@);
   use_ok ("Graph::Easy::As_ascii") or die($@);
   };

can_ok ("Graph::Easy", qw/
  as_boxart
  as_boxart_html
  as_boxart_html_file
  as_boxart_file
  /);

#############################################################################

binmode STDERR, ':utf8';
# some of our strings are written in utf8
use utf8;

my $graph = Graph::Easy->new();

my ($bonn, $berlin, $edge) = $graph->add_edge ('Bonn', 'Berlin');

my $boxart = $graph->as_boxart();

like ($boxart, qr/Bonn/, 'contains Bonn');
like ($boxart, qr/Berlin/, 'contains Berlin');
unlike ($boxart, qr/-/, "doesn't contain '-'");

#############################################################################
# border tests

$berlin->set_attribute('border-style', 'dotted');

#############################################################################
# arrow tests

my $open = '──>';
my $closed = '──▷';
my $filled = '──▶';

$boxart = $graph->as_boxart();
like ($boxart, qr/$open/, 'contains edge with open arrow');

$edge->set_attribute('arrow-style', 'open');
$boxart = $graph->as_boxart();
like ($boxart, qr/$open/, 'contains edge with open arrow');

$edge->set_attribute('arrow-style', 'closed');
$boxart = $graph->as_boxart();
like ($boxart, qr/$closed/, 'contains edge with closed arrow');

$edge->set_attribute('arrow-style', 'filled');
$boxart = $graph->as_boxart();
like ($boxart, qr/$filled/, 'contains edge with filled arrow');

#############################################################################
# arrow tests with dotted lines

$open = "··>";
$closed = '··▷';
$filled = '··▶';

$edge->set_attribute('style', 'dotted');
$edge->del_attribute('arrow-style');

is ($edge->style(), 'dotted', 'edge is now dotted');

$boxart = $graph->as_boxart();
like ($boxart, qr/$open/, 'contains edge with open arrow');

$edge->set_attribute('arrow-style', 'open');
$boxart = $graph->as_boxart();
like ($boxart, qr/$open/, 'contains edge with open arrow');

$edge->set_attribute('arrow-style', 'closed');
$boxart = $graph->as_boxart();
like ($boxart, qr/$closed/, 'contains edge with closed arrow');

$edge->set_attribute('arrow-style', 'filled');
$boxart = $graph->as_boxart();
like ($boxart, qr/$filled/, 'contains edge with filled arrow');


