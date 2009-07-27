#!/usr/bin/perl -w

# Test nesting of groups

use Test::More;
use strict;

BEGIN
   {
   plan tests => 34;
   chdir 't' if -d 't';
   use lib '../lib';
   use_ok ("Graph::Easy::Group") or die($@);
   use_ok ("Graph::Easy::Group::Cell") or die($@);
   use_ok ("Graph::Easy") or die($@);
   };

#############################################################################
# $group->add_member($inner);

my $graph = Graph::Easy->new();

my $group = $graph->add_group('Outer');

is (ref($group), 'Graph::Easy::Group');
is ($group->error(), '', 'no error yet');

my $inner = $graph->add_group('Inner');
$group->add_member($inner);

check_groups($group,$inner);

#############################################################################
# groups_within():

is ($graph->groups_within(), 2, '2 groups');
is ($graph->groups_within(-1), 2, '2 groups');
is ($graph->groups_within(0), 1, '1 group in outer');
is ($graph->groups_within(1), 2, '2 groups in outer+inner');
is ($graph->groups_within(2), 2, 'no more groups');

#############################################################################
# $inner->add_to_group($group);

$graph = Graph::Easy->new();

$group = $graph->add_group('Outer');

is (ref($group), 'Graph::Easy::Group');
is ($group->error(), '', 'no error yet');

$inner = $graph->add_group('Inner');

$inner->add_to_group($group);

check_groups($group,$inner);

#############################################################################
# groups_within():

my $inner_2 = $graph->add_group('Inner 2');
my $inner_3 = $graph->add_group('Inner 3');

# Level		Groups			Sum
#  0:		Outer			1
#  1:		Inner     Inner 3	3
#  2:		Inner 2			4

$inner_2->add_to_group($inner);
$inner_3->add_to_group($group);

is ($graph->groups_within(), 4, '4 groups');
is ($graph->groups_within(-1), 4, '4 groups');
is ($graph->groups_within(0), 1, '1 group in outer');
is ($graph->groups_within(1), 3, '3 groups in outer+inner');
is ($graph->groups_within(2), 4, '4 groups in total');

# also test calling add_group() with a scalar on another group:
my $inner_4 = $group->add_group('Inner 4');

# Level		Groups					Sum
#  0:		Outer					1
#  1:		Inner     Inner 3	Inner 4		4
#  2:		Inner 2					5

is ($graph->groups_within(), 5, '5 groups');
is ($graph->groups_within(-1), 5, '5 groups');
is ($graph->groups_within(0), 1, '1 group in outer');
is ($graph->groups_within(1), 4, '4 groups in outer+inner');
is ($graph->groups_within(2), 5, '5 groups in total');

# all tests done
1;

#############################################################################

sub check_groups
  {
  my ($group,$inner) = @_;

  is ($inner->{group}, $group, 'inner is in outer');

  my @groups = $group->groups();

  is (@groups, 1, 'one group in outer');
  is ($groups[0], $inner, 'and it is "Inner"');

  @groups = $inner->groups();

  is (@groups, 0, 'no group in Inner');
 
  is ($inner->attribute('group'), 'Outer', 'attribute("group")');
  is ($group->attribute('group'), '', 'attribute("group")');
  }
