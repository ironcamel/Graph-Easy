#!/usr/bin/perl -w

# test anonymous groups

use Test::More;
use strict;

BEGIN
   {
   plan tests => 15;
   chdir 't' if -d 't';
   use lib '../lib';
   use_ok ("Graph::Easy::Group::Anon") or die($@);
   use_ok ("Graph::Easy") or die($@);
   use_ok ("Graph::Easy::As_txt") or die($@);
   require_ok ("Graph::Easy::As_ascii") or die($@);
   };

can_ok ("Graph::Easy::Group::Anon", qw/
  new
  as_txt as_html
  error
  class
  name
  successors
  predecessors
  width
  height
  pos
  x
  y
  class
  del_attribute
  set_attribute
  set_attributes
  attribute
  attributes_as_txt
  as_pure_txt
  group add_to_group
  /);

#############################################################################

my $group = Graph::Easy::Group::Anon->new();

is (ref($group), 'Graph::Easy::Group::Anon');

is ($group->error(), '', 'no error yet');

is ($group->label(), '', 'label');
is ($group->name(), 'Group #0', 'name');
is ($group->title(), '', 'no title per default');

is ($group->{graph}, undef, 'no graph');
is (scalar $group->successors(), undef, 'no outgoing links');
is (scalar $group->predecessors(), undef, 'no incoming links');
is ($group->{graph}, undef, 'successors/predecssors leave graph alone');

#############################################################################
# as_txt/as_html

my $graph = Graph::Easy->new();

$graph->add_group($group);

is ($group->as_txt(), "( )\n\n", 'anon group as_txt');

#is ($group->as_html(), " <td colspan=4 rowspan=4 class='node_anon'></td>\n",
# 'as_html');

#is ($group->as_ascii(), "", 'anon as_ascii');

#is ($group->as_graphviz_txt(), '"\#0"', 'anon as_graphviz');

#############################################################################
# anon node as_graphviz

#my $grviz = $graph->as_graphviz();

#my $match = quotemeta('"\#0" [ color="#ffffff", label=" ", style=filled ]');

#like ($grviz, qr/$match/, 'anon node');

