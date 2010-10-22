#!/usr/bin/perl -w

# Some basic GraphML tests with the format=yED 

use Test::More;
use strict;
use utf8;

BEGIN
   {
   plan tests => 14;
   chdir 't' if -d 't';
   use lib '../lib';
   use_ok ("Graph::Easy") or die($@);
   use_ok ("Graph::Easy::Parser") or die($@);
   };

can_ok ('Graph::Easy', qw/
  as_graphml
  as_graphml_file
  /);

#############################################################################
my $graph = Graph::Easy->new();

my $graphml_file = $graph->as_graphml_file( format => 'yED' );
$graphml_file =~ s/\n.*<!--.*-->\n//;

_compare ($graph, $graphml_file, 'as_graphml and as_graphml_file are equal');

my $graphml = $graph->as_graphml( format => 'yED' );
like ($graphml, qr/<\?xml version="1.0" encoding="UTF-8"\?>/, 'as_graphml looks like xml');

#############################################################################
# some nodes and edges

$graph->add_edge('Ursel','Viersen');

$graphml = $graph->as_graphml();

like ($graphml, qr/<node.*id="Ursel"/, 'as_graphml contains nodes');
like ($graphml, qr/<node.*id="Viersen"/, 'as_graphml contains nodes');
like ($graphml, qr/<edge.*source="Ursel"/, 'as_graphml contains edge');
like ($graphml, qr/<edge.*target="Viersen"/, 'as_graphml contains edge');

#############################################################################
# some attributes:

# node.foo { color: red; } [A] {class:foo;}-> { color: blue; } [B]
$graph = Graph::Easy->new();
my ($A,$B,$edge) = $graph->add_edge('A','B');

$graph->set_attribute('node.foo','color','red');
$edge->set_attribute('color','blue');
$A->set_attribute('class','foo');

my $result = <<EOT
  <key id="d0" for="node" attr.name="color" attr.type="string">
    <default>black</default>
  </key>
  <key id="d1" for="edge" attr.name="color" attr.type="string">
    <default>black</default>
  </key>

  <graph id="G" edgedefault="directed">
    <node id="A"/>
      <data key="d0">red</data>
    <node id="B"/>

    <edge source="A" target="B"/>
      <data key="d1">blue</data>
  </graph>
</graphml>
EOT
;

_compare($graph, $result, 'GraphML with attributes');

#############################################################################
# some attributes with no default valu with no default value:

# Also test escaping for valid XML:

$edge->set_attribute('label', 'train-station & <Überlingen "Süd">');

$result = <<EOT2
  <key id="d0" for="node" attr.name="color" attr.type="string">
    <default>black</default>
  </key>
  <key id="d1" for="edge" attr.name="color" attr.type="string">
    <default>black</default>
  </key>
  <key id="d2" for="edge" attr.name="label" attr.type="string"/>

  <graph id="G" edgedefault="directed">
    <node id="A"/>
      <data key="d0">red</data>
    <node id="B"/>

    <edge source="A" target="B"/>
      <data key="d1">blue</data>
      <data key="d2">train-station &amp; &lt;Überlingen &quot;Süd&quot;&gt;</data>
  </graph>
</graphml>
EOT2
;

_compare($graph, $result, 'GraphML with attributes');

#############################################################################
# node names with things that need escaping:

$graph->rename_node('A', '<&\'">');

$result = <<EOT3
  <key id="d0" for="node" attr.name="color" attr.type="string">
    <default>black</default>
  </key>
  <key id="d1" for="edge" attr.name="color" attr.type="string">
    <default>black</default>
  </key>
  <key id="d2" for="edge" attr.name="label" attr.type="string"/>

  <graph id="G" edgedefault="directed">
    <node id="&lt;&amp;&apos;&quot;&gt;"/>
      <data key="d0">red</data>
    <node id="B"/>

    <edge source="&lt;&amp;&apos;&quot;&gt;" target="B"/>
      <data key="d1">blue</data>
      <data key="d2">train-station &amp; &lt;Überlingen &quot;Süd&quot;&gt;</data>
  </graph>
</graphml>
EOT3
;

_compare($graph, $result, 'GraphML with attributes');

#############################################################################
# double attributes

$graph = Graph::Easy->new();
($A,$B,$edge) = $graph->add_edge('A','B');
my ($C,$D,$edge2) = $graph->add_edge('A','C');

$edge->set_attribute('label','car');
$edge2->set_attribute('label','train');

$result = <<EOT4
  <key id="d0" for="edge" attr.name="label" attr.type="string"/>

  <graph id="G" edgedefault="directed">
    <node id="A"/>
    <node id="B"/>
    <node id="C"/>

    <edge source="A" target="B"/>
      <data key="d0">car</data>
    <edge source="A" target="C"/>
      <data key="d0">train</data>
  </graph>
</graphml>
EOT4
;

_compare($graph, $result, 'GraphML with attributes');

#############################################################################
# as_graphml() with groups (bug until v0.63):

$graph = Graph::Easy->new();
my $bonn  = Graph::Easy::Node->new('Bonn');
my $cities = $graph->add_group('Cities"');
$cities->add_nodes($bonn);

$result = <<EOT5
  <graph id="G" edgedefault="directed">
    <graph id="Cities&quot;" edgedefault="directed">
      <node id="Bonn"/>
    </graph>
  </graph>
</graphml>
EOT5
;

_compare($graph, $result, 'GraphML with group');

# all tests done

#############################################################################
#############################################################################

sub _compare
  {
  my ($graph, $result, $name) = @_;

  my $graphml = $graph->as_graphml( { format => 'yED' } );
  $graphml =~ s/\n.*<!--.*-->\n//;

  $result = <<EOR
<?xml version="1.0" encoding="UTF-8"?>
<graphml xmlns="http://graphml.graphdrawing.org/xmlns/graphml"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:y="http://www.yworks.com/xml/graphml"
    xsi:schemaLocation="http://graphml.graphdrawing.org/xmlns/graphml
     http://www.yworks.com/xml/schema/graphml/1.0/ygraphml.xsd">

EOR
  . $result unless $result =~ /<\?xml/;

  if (!is ($result, $graphml, $name))
    {
    eval { require Test::Differences; };
    if (defined $Test::Differences::VERSION)
      {
      Test::Differences::eq_or_diff ($result, $graphml);
      }
    }
  }
