#!/usr/bin/perl -w

# test as_graphviz() output

use Test::More;
use strict;

BEGIN
   {
   plan tests => 157;
   chdir 't' if -d 't';
   use lib '../lib';
   use_ok ("Graph::Easy") or die($@);
   };

#############################################################################
my $graph = Graph::Easy->new();

is (ref($graph), 'Graph::Easy');

is ($graph->error(), '', 'no error yet');

is ($graph->nodes(), 0, '0 nodes');
is ($graph->edges(), 0, '0 edges');

is (join (',', $graph->edges()), '', '0 edges');

my $grviz = $graph->as_graphviz();

like ($grviz, qr/digraph.*\{/, 'looks like digraph');
unlike ($grviz, qr/#/, 'and has proper comment');
like ($grviz, qr#// Generated#, 'and has proper comment');

#############################################################################
# after first call to as_graphviz, these should now exist:

can_ok ("Graph::Easy::Node", qw/
  attributes_as_graphviz
  as_graphviz_txt
  /);

#############################################################################
# with some nodes

my $bonn = Graph::Easy::Node->new( name => 'Bonn' );
my $berlin = Graph::Easy::Node->new( 'Berlin' );

my $edge = $graph->add_edge ($bonn, $berlin);

$grviz = $graph->as_graphviz();

like ($grviz, qr/Bonn/, 'contains Bonn');
like ($grviz, qr/Berlin/, 'contains Bonn');

like ($grviz, qr/arrowhead=open/, 'contains open arrowheads');

unlike ($grviz, qr/\w+=,/, "doesn't contain empty defintions");

#############################################################################
# with attributes on the graph

$graph->set_attribute( 'graph', 'fill' => 'red' );

like ($graph->as_graphviz(), qr/bgcolor="#ff0000"/, 'contains bgcolor="#ff0000"');

#############################################################################
# with label/label-pos attributes on the graph

$graph->set_attribute( 'graph', 'label' => 'My Label' );
$grviz = $graph->as_graphviz();

like ($grviz, qr/label="My Label"/, 'graph label');
like ($grviz, qr/labelloc=top/, 'default is top (dot 1.1 seems to get this wrong)');

$graph->set_attribute( 'graph', 'label-pos' => 'top' );
$grviz = $graph->as_graphviz();

like ($grviz, qr/label="My Label"/, 'graph label');
like ($grviz, qr/labelloc=top/, 'default is top');

$graph->set_attribute( 'graph', 'label-pos' => 'bottom' );
$grviz = $graph->as_graphviz();

like ($grviz, qr/label="My Label"/, 'graph label');
like ($grviz, qr/labelloc=bottom/, 'now bottom');

#############################################################################
# with some nodes with atributes

$bonn->set_attribute( 'shape' => 'rect' );

$grviz = $graph->as_graphviz();
like ($grviz, qr/[^"]Bonn[^"]/, 'contains Bonn unquoted');
like ($grviz, qr/[^"]Berlin[^"]/, 'contains Bonn unquoted');
like ($grviz, qr/shape=box/, 'contains shape');

#############################################################################
# remapped attributes, quoted attributes

$bonn->set_attributes( { 
  fill => '#808080', 
  title => 'title string', 
  color => 'red', 
  'border-color' => 'brown',
  class => 'city',
  } );

$grviz = $graph->as_graphviz();

like ($grviz, qr/fillcolor="#808080"/, 'contains fillcolor');
like ($grviz, qr/tooltip="title string"/, 'contains tooltip');
like ($grviz, qr/color="#a52a2a"/, 'contains color');
like ($grviz, qr/fontcolor="#ff0000"/, 'contains fontcolor');
unlike ($grviz, qr/(city|class)/, "doesn't contain class");

#############################################################################
# quoting (including " in node names)

$bonn->{name} = 'Bonn"';

$grviz = $graph->as_graphviz();
like ($grviz, qr/"Bonn\\""/, 'quoted Bonn"');

$bonn->{name} = 'Bonn und Umgebung';

$grviz = $graph->as_graphviz();
like ($grviz, qr/"Bonn und Umgebung"/, 'quoted "Bonn und Umgebung"');

is (join(",", $graph->_graphviz_remap_edge_style('style', 'bold')), 'style,bold', 'style,bold');

my ($name,$style) = $graph->_graphviz_remap_edge_style('style', 'double');
is ($name, undef, 'style=double suppressed');
is ($style, undef, 'style=double suppressed');

($name,$style) = $graph->_graphviz_remap_edge_style('style', 'solid');

is ($name, undef, 'style=solid suppressed');
is ($style, undef, 'style=solid suppressed');

$bonn->{name} = '2A';

$grviz = $graph->as_graphviz();
like ($grviz, qr/"2A"/, '"2A" must be quoted');

$bonn->{name} = '123';

$grviz = $graph->as_graphviz();
like ($grviz, qr/ 123 /, '"123" needs no quotes');

# strict should come last in this list:
for (qw/0AB graph subgraph edge node Graph Edge Strict strict/)
  {
  $bonn->{name} = $_;

  $grviz = $graph->as_graphviz();
  like ($grviz, qr/"$_"/, "'$_' needs quotes");
  }

$bonn->set_attribute('label', 'Graph::Easy');

$grviz = $graph->as_graphviz();
like ($grviz, qr/label="Graph::Easy"/, 'label with non \w needs quoting');

#############################################################################
# flow directions

$graph->set_attribute('graph','flow','south');

$grviz = $graph->as_graphviz();
unlike ($grviz, qr/rankdir/, 'flow south needs no rankdir');
like ($grviz, qr/"strict" -> Berlin/, 'edge direction normal');

$graph->set_attribute('graph','flow','west');

$grviz = $graph->as_graphviz();
like ($grviz, qr/rankdir=LR/, 'flow west has LR and reversed edges');
like ($grviz, qr/Berlin -> "strict"/, 'edge direction reversed');
like ($grviz, qr/dir=back/, 'edge direction reversed');

$graph->set_attribute('graph','flow','up');

$grviz = $graph->as_graphviz();
unlike ($grviz, qr/rankdir/, 'flow west has TB and reversed edges');
like ($grviz, qr/Berlin -> "strict"/, 'edge direction reversed');
like ($grviz, qr/dir=back/, 'edge direction reversed');

#############################################################################
# arrow styles

# flow is up, so arrowhead becomes arrowtail:

$graph->set_attribute('edge', 'arrow-style', 'closed');

is ($graph->get_attribute('edge', 'arrow-style'), 'closed');

$grviz = $graph->as_graphviz();
like ($grviz, qr/arrowtail=empty/, 'arrow-style closed => empty');

$graph->set_attribute('edge', 'arrow-style', 'filled');
is ($graph->get_attribute('edge', 'arrow-style'), 'filled');

$grviz = $graph->as_graphviz();
like ($grviz, qr/arrowtail=normal/, 'arrow-style filled => normal');

# set flow to down, so arrowtail becomes arrowhead again
$graph->set_attribute('graph','flow','down');

$grviz = $graph->as_graphviz();
like ($grviz, qr/arrowhead=normal/, 'arrow-style filled => normal');

$graph->del_attribute('edge','arrow-style');
$edge->set_attribute('arrow-style','filled');
is ($graph->error(),'', 'no error');

$grviz = $graph->as_graphviz();
like ($grviz, qr/arrowhead=normal/, 'arrow-style filled => normal');

$edge->set_attribute('arrow-style','none');
is ($graph->error(),'', 'no error');

$grviz = $graph->as_graphviz();
like ($grviz, qr/arrowhead=none/, 'arrow-style none');

#############################################################################
#############################################################################
# undirected edges

my $e = $graph->add_edge('A','B');

$e->undirected(1); $e->bidirectional(0);

$grviz = $graph->as_graphviz();
like ($grviz, qr/A -> B.*arrowhead=none/, 'arrowhead on undirected edge');
like ($grviz, qr/A -> B.*arrowtail=none/, 'arrowtail on undirected edge');

#############################################################################
# bidirectional edges

$e->undirected(0); $e->bidirectional(1);

$grviz = $graph->as_graphviz();
like ($grviz, qr/A -> B.*arrowhead=open/, 'arrowhead on bidirectional edge');
like ($grviz, qr/A -> B.*arrowtail=open/, 'arrowtail on bidirectional edge');


#############################################################################
#############################################################################
# label-color vs. color

$e->bidirectional(0);

$e->set_attribute('color','red');
$e->set_attribute('label-color','blue');
$e->set_attribute('label','A to B');

$grviz = $graph->as_graphviz();
like ($grviz, qr/A -> B \[ color="#ff0000", fontcolor="#0000ff", label/, 'label-color');

#############################################################################
# missing label-color (fall back to color)

$e->del_attribute('label-color');
$grviz = $graph->as_graphviz();
like ($grviz, qr/A -> B \[ color="#ff0000", fontcolor="#ff0000", label/, 'label-color');

$e->del_attribute('label','A to B');

#############################################################################
# no label, no fontcolor nec.:

$e->del_attribute('label');
$grviz = $graph->as_graphviz();
like ($grviz, qr/A -> B \[ color="#ff0000" \]/, 'label-color');

#############################################################################
# link vs. autolink and linkbase

$graph->set_attribute('node','linkbase','http://bloodgate.com/');

$grviz = $graph->as_graphviz();
unlike ($grviz, qr/bloodgate.com/, 'linkbase alone does nothing');
unlike ($grviz, qr/link/, 'linkbase alone does nothing');

$graph->set_attribute('node','autolink','name');

$grviz = $graph->as_graphviz();
like ($grviz, qr/URL="http:\/\/bloodgate.com/, 'linkbase plus link');

$graph->del_attribute('node','autolink');
$graph->set_attribute('graph','autolink','name');

is ($graph->attribute('graph','autolink'), 'name', 'autolink=name');

$grviz = $graph->as_graphviz();
like ($grviz, qr/URL="http:\/\/bloodgate.com/, 'linkbase plus link');

#############################################################################
# link vs. autolink and linkbase

$bonn->set_attribute('point-style', 'star');
is ($graph->error(),'', 'no error');

$grviz = $graph->as_graphviz();
unlike ($grviz, qr/point-style/, 'point-style is filtered out');


#############################################################################
# node shape "none"

$bonn->{name} = 'Bonn';
$bonn->set_attribute( 'shape' => 'none' );

$grviz = $graph->as_graphviz();
like ($grviz, qr/[^"]Bonn[^"]/, 'contains Bonn unquoted');
like ($grviz, qr/Bonn.*shape=plaintext/, 'contains shape=plaintext');


# some different node shapes

for my $s (qw/
  invhouse invtrapezium invtriangle
  triangle octagon hexagon pentagon house
  septagon trapezium
  /)
  {
  $bonn->set_attribute( 'shape' => $s );

  $grviz = $graph->as_graphviz();
  like ($grviz, qr/[^"]Bonn[^"]/, 'contains Bonn unquoted');
  like ($grviz, qr/Bonn.*shape=$s/, "contains shape=$s");
  }

#############################################################################
# font-size support

$bonn->set_attribute( 'font-size' => '2em' );

$grviz = $graph->as_graphviz();
like ($grviz, qr/[^"]Bonn[^"]/, 'contains Bonn unquoted');
like ($grviz, qr/Bonn.*fontsize=22/, '11px eq 1em');

#############################################################################
# bold-dash, broad and wide edges

$bonn->set_attribute( 'border-style' => 'broad' );

$grviz = $graph->as_graphviz();
like ($grviz, qr/[^"]Bonn[^"]/, 'contains Bonn unquoted');
like ($grviz, qr/Bonn.*style="filled,setlinewidth\(5\)"/, 
 '5 pixel for broad border');

#############################################################################
# quoting of special characters

$bonn->set_attribute( 'label' => '$a = 2;' );
$grviz = $graph->as_graphviz();

like ($graph->as_graphviz(), qr/Bonn.*label="\$a = 2;"/, 'contains label unquoted');

$bonn->set_attribute( 'label' => '2"' );
$grviz = $graph->as_graphviz();

like ($grviz, qr/Bonn.*label="2\\""/, 'contains label 2"');


#############################################################################
# groups as clusters

$graph = Graph::Easy->new();

($bonn, $berlin, $edge) = $graph->add_edge ('Bonn', 'Berlin');
my $group = $graph->add_group ('Test:');

$group->add_node($bonn);
$group->add_node($berlin);

$grviz = $graph->as_graphviz();

like ($grviz, qr/subgraph "cluster\d+"\s+\{/, 'contains cluster');

#############################################################################
# nodes w/o links and attributes in a group

$graph = Graph::Easy->new();

$bonn = $graph->add_node ('Bonn');
$berlin = $graph->add_node ('Berlin');

$group = $graph->add_group ('Test:');

$group->add_node($bonn);
$group->add_node($berlin);

$grviz = $graph->as_graphviz();

like ($grviz, qr/Bonn(.|\n)*Berlin(.|\n)*\}(.|\n)*\}/, 'contains nodes inside group');

#############################################################################
# node with border-style: none:

$graph = Graph::Easy->new();

$bonn = $graph->add_node ('Bonn');
$bonn->set_attribute('border-style', 'none');

$grviz = $graph->as_graphviz();

like ($grviz, qr/Bonn.*color="#ffffff".*style=filled/,
  'contains color white, style filled');

#############################################################################
# node with shape: rounded;

$bonn->del_attribute('border-style');
$bonn->set_attribute( 'shape' => 'rounded' );

$grviz = $graph->as_graphviz();
like ($grviz, qr/[^"]Bonn[^"]/, 'contains Bonn unquoted');
like ($grviz, qr/Bonn.*style="rounded,filled"/, 'contains rounded,filled'); 

#############################################################################
# invisible nodes and node with shape: point;

$bonn->del_attribute('border-style');
$bonn->set_attribute( 'shape' => 'invisible' );

$grviz = $graph->as_graphviz();
like ($grviz, qr/[^"]Bonn[^"]/, 'contains Bonn unquoted');
like ($grviz, qr/Bonn.*shape=plaintext/, 'contains shape plaintext'); 
like ($grviz, qr/Bonn.*label=" "/, 'contains label=" "'); 

$bonn->del_attribute('border-style');
$bonn->set_attribute( 'shape' => 'point' );

$grviz = $graph->as_graphviz();
like ($grviz, qr/[^"]Bonn[^"]/, 'contains Bonn unquoted');
like ($grviz, qr/Bonn.*shape=plaintext/, 'contains shape plaintext'); 
like ($grviz, qr/Bonn.*label="*"/, 'contains label="*"'); 

#############################################################################
# edge styles double and double-dash

$graph = Graph::Easy->new();

($bonn,$berlin,$edge) = $graph->add_edge ('Bonn','Berlin');
$edge->set_attribute('style','double');

$grviz = $graph->as_graphviz();
like ($grviz, qr/[^"]Bonn[^"].*color="#000000:#000000/, 'contains Bonn and black:black');
unlike ($grviz, qr/style="?solid/, "doesn't contain solid");

$edge->set_attribute('style','double-dash');

$grviz = $graph->as_graphviz();
like ($grviz, qr/[^"]Bonn[^"].*color="#000000:#000000/, 'contains Bonn and black:black');
unlike ($grviz, qr/style="?solid/, "doesn't contain solid");
like ($grviz, qr/style="?dashed/, 'contains solid');

#############################################################################
# root node (also testing that a root of '0' actually works)

$graph = Graph::Easy->new();

($bonn,$berlin,$edge) = $graph->add_edge ('0','1');
$graph->set_attribute('root','0');

$grviz = $graph->as_graphviz();
like ($grviz, qr/root=0/, 'contains root=0');
like ($grviz, qr/0.*rank=0/, 'contains rank=0');

$graph = Graph::Easy->new();

($bonn,$berlin,$edge) = $graph->add_edge ('a','b');
$graph->set_attribute('root','b');

$grviz = $graph->as_graphviz();
like ($grviz, qr/root=b/, 'contains root=0');
like ($grviz, qr/b.*rank=0/, 'contains rank=0');

#############################################################################
# headport/tailport

$graph = Graph::Easy->new();

($bonn,$berlin,$edge) = $graph->add_edge ('Bonn','Berlin');
$edge->set_attribute('start','west');
$edge->set_attribute('end','east');

$grviz = $graph->as_graphviz();
like ($grviz, qr/tailport=w/, 'contains tailport=w');
like ($grviz, qr/headport=e/, 'contains headport=e');

# headport/tailport with relative flow

$edge->set_attribute('start','right');
$edge->set_attribute('end','left');

$grviz = $graph->as_graphviz();
like ($grviz, qr/tailport=s/, 'contains tailport=s');
like ($grviz, qr/headport=n/, 'contains headport=n');

#############################################################################
# colorscheme support

$graph = Graph::Easy->new();

($bonn,$berlin,$edge) = $graph->add_edge ('Bonn','Berlin');

$graph->add_group('Cities');

$graph->set_attribute('node','colorscheme','pastel19');
$graph->set_attribute('color','red');
$edge->set_attribute('color','1');
$berlin->set_attribute('color','1');
$berlin->set_attribute('colorscheme','set23');
$bonn->set_attribute('color','1');

$grviz = $graph->as_graphviz();
like ($grviz, qr/graph(.|\n)*color="#ff0000"/, 'contains graph color=#ff0000');
like ($grviz, qr/Bonn.*color="#fbb4ae"/, 'contains Bonn color=#fbb4ae');
like ($grviz, qr/Berlin.*color="#66c2a5"/, 'contains Berlin color=#66c2a5');
like ($grviz, qr/->.*Berlin.*color="#a6cee3"/, 'contains edge with default color 1 from set312');

#############################################################################
# test inheritance of colorscheme for edges, groups and anon things:

$graph->set_attribute('colorscheme','pastel19');

$grviz = $graph->as_graphviz();
like ($grviz, qr/->.*Berlin.*color="#fbb4ae"/, 'contains edge with color 1 from pastel19');

#############################################################################
# autolabel is skipped

$graph->set_attribute('node','autolabel','15');

$grviz = $graph->as_graphviz();
unlike ($grviz, qr/autolabel/, "doesn't contain autolabel");

#############################################################################
# test that the attributes group, rows and columns are skipped

$graph = Graph::Easy->new();

($bonn,$berlin,$edge) = $graph->add_edge ('Bonn','Berlin');
$group = $graph->add_group('Cities');
$group->add_nodes($bonn, $berlin);
$bonn->set_attribute('size','2,2');

$graph->layout();
$grviz = $graph->as_graphviz();
unlike ($grviz, qr/rows=/, 'does not contain rows=');
unlike ($grviz, qr/columns=/, 'does not contain columns=');
unlike ($grviz, qr/group=/, 'does not contain group=');

#############################################################################
# test output of fillcolor and color of groups

$graph = Graph::Easy->new();

($bonn,$berlin,$edge) = $graph->add_edge ('Bonn','Berlin');
$group = $graph->add_group('Cities');
$group->add_nodes($bonn, $berlin);
$group->set_attribute('fill','red');
$group->set_attribute('color','blue');

$graph->layout();
$grviz = $graph->as_graphviz();
like ($grviz, qr/fillcolor="#ff0000"/, 'fillcolor=red');
like ($grviz, qr/fontcolor="#0000ff"/, 'fontcolor=blue');

#############################################################################
# test group class attributes

$graph = Graph::Easy->new();

($bonn,$berlin,$edge) = $graph->add_edge ('Bonn','Berlin');
$group = $graph->add_group('Cities');
$group->add_nodes($bonn, $berlin);

$graph->set_attribute('group','fill','red');

$graph->layout();
$grviz = $graph->as_graphviz();
like ($grviz, qr/cluster(.|\n)*fillcolor="#ff0000"/, 'fillcolor=blue');

#############################################################################
# node->as_graphviz()

$graph = Graph::Easy->new();

($bonn,$berlin,$edge) = $graph->add_edge ('Bonn','Berlin');
$group = $graph->add_group('Cities');
$group->add_nodes($bonn, $berlin);

$grviz = $graph->as_graphviz();

unlike ($grviz, qr/Berlin.*label=.*Berlin/, "label isn't output needlessly");

#############################################################################
# HSV colors and alpha channel should be preserved in output

$graph = Graph::Easy->new();

($bonn,$berlin,$edge) = $graph->add_edge ('Bonn','Berlin');
$group = $graph->add_group('Cities');
$group->add_nodes($bonn, $berlin);

# as hex (not preserved) due to alpha channel
$bonn->set_attribute('color', 'hsv(0, 1.0, 0.5, 0.5)');
$berlin->set_attribute('color', '#ff000080');

# preserved
$graph->set_attribute('color', 'hsv(0, 0.6, 0.7)');

$grviz = $graph->as_graphviz();

like ($grviz, qr/fontcolor="0 0.6 0.7"/, "graph color was preserved");
like ($grviz, qr/Berlin.*fontcolor="#ff000080"/, "Berlin's color got converted");
like ($grviz, qr/Bonn.*fontcolor="#8000007f"/, "Bonn's color got converted");

#############################################################################
# edge label

$graph = Graph::Easy->new();

($bonn,$berlin,$edge) = $graph->add_edge ('Bonn','Berlin');
$edge->set_attribute('label','car');

$grviz = $graph->as_graphviz();
like ($grviz, qr/label=car/, "edge label appears in output");

#############################################################################
# fill as class attribute

$graph = Graph::Easy->new();

($bonn,$berlin,$edge) = $graph->add_edge ('Bonn','Berlin');
$bonn->set_attribute('class','red');

$graph->set_attribute('node.red', 'fill', 'red');

$grviz = $graph->as_graphviz();
like ($grviz, qr/fillcolor="#ff0000"/, "contains fill red");

#############################################################################
# \c in labels

$graph = Graph::Easy->new();

$graph->set_attribute('label', 'foo\cbar');

($bonn,$berlin,$edge) = $graph->add_edge ('Bonn','Berlin');

$bonn->set_attribute('label', 'bar\cbar');

$grviz = $graph->as_graphviz();
unlike ($grviz, qr/\\c/, "no \\c in output");

#############################################################################
# borderwidth == 0 overrides style

$graph = Graph::Easy->new();
($bonn,$berlin,$edge) = $graph->add_edge ('Bonn','Berlin');

$bonn->set_attribute('borderstyle','dashed');
$bonn->set_attribute('borderwidth','0');

$berlin->set_attribute('borderstyle','double');
$berlin->set_attribute('borderwidth','0');

$grviz = $graph->as_graphviz();
print $grviz;
unlike ($grviz, qr/style=.*dashed/, "no dashed in output");
unlike ($grviz, qr/peripheries/, "no peripheries in output");

#############################################################################
# subgraph

#$graph = Graph::Easy->new();
my $g  = Graph::Easy->new;
my $a  = $g->add_group('A');
my $b  = $g->add_group('B');
my $c  = $g->add_group('C');
my $d  = $g->add_group('D');
my $n1 = $g->add_node('one');
my $n2 = $g->add_node('two');
my $n3 = $g->add_node('three');
my $n4 = $g->add_node('four');

$a->add_member($n1);
$b->add_member($c);
$b->add_member($n2);
$a->add_member($b);
$c->add_member($n3);
$d->add_member($n4);

$grviz = $g->as_graphviz();
is($a->{_order},1,'subgraph A is level 1');
is($d->{_order},1,'subgraph D is level 1');
is($b->{_order},2,'subgraph B is level 2');
is($c->{_order},3,'subgraph C is level 3');
like($grviz,qr/subgraph "cluster\d+" {\n  label="A";\n    subgraph "cluster\d+" {/,'subgraph indent');
