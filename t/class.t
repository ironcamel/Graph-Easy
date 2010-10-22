#!/usr/bin/perl -w

# Test class selectors

use Test::More;
use strict;

BEGIN
   {
   plan tests => 23;
   chdir 't' if -d 't';
   use lib '../lib';
   use_ok ("Graph::Easy") or die($@);
   };

can_ok ("Graph::Easy", qw/
  _check_class
  /);

#############################################################################

my $graph = Graph::Easy->new();

is (ref($graph), 'Graph::Easy');

$graph->add_edge( 'A', 'B' );

for my $class ('node', 'edge', 'graph', 'group', 
	       'node.foo', 'edge.foo', 'group.foo')
  {
  _is ($class, $graph->_check_class($class));
  }

_is ('edge.foo,group.foo,node.foo', $graph->_check_class('.foo'));
_is ('edge.b,group.b,node.b', $graph->_check_class('.b'));

#############################################################################
# lists of class selectors

_is ('edge.f,group.f,node.f,edge.b,group.b,node.b', 
  $graph->_check_class('.f, .b'));

_is ('edge,group,node', $graph->_check_class('edge, group, node'));
_is ('edge,group,node', $graph->_check_class('edge,group, node'));
_is ('edge,group,node', $graph->_check_class('edge ,  group , node'));
_is ('edge,group,node', $graph->_check_class('edge, group,node'));
_is ('edge,group,node', $graph->_check_class('edge,group,node'));

_is ('edge.red,group.red,node.red,edge.green,group.green,node.green,group',
  $graph->_check_class('.red, .green, group'));

#############################################################################
# invalid classes

_is (\'.', $graph->_check_class('.'));
_is (\'node.', $graph->_check_class('node.'));
_is (\'foo', $graph->_check_class('foo'));

_is (\'.foo, bar', $graph->_check_class('.foo, bar'));

# all tests done

1;

#############################################################################

sub _is
  {
  my ($expect, @results) = @_;

  if (ref($expect))
    {
    is (scalar @results, 0, "invalid selector $$expect");
    }
  else
    {
    is (join(",", @results), $expect, $expect);
    }
  }

