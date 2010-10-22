#!/usr/bin/perl -w

use Test::More;
use strict;

BEGIN
   {
   plan tests => 74;
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

my $html = $graph->as_html();

like ($html, qr/<table/, 'looks like HTML to me');

#############################################################################
# with some nodes

my $bonn = Graph::Easy::Node->new( name => 'Bonn' );
my $berlin = Graph::Easy::Node->new( 'Berlin' );

my $edge = $graph->add_edge ($bonn, $berlin);

$html = $graph->as_html();

like ($html, qr/Bonn/, 'contains Bonn');
like ($html, qr/Berlin/, 'contains Berlin');

#############################################################################
# with some nodes with atributes

$bonn->set_attribute( 'autotitle' => 'name' );

$html = $graph->as_html();
like ($html, qr/title='Bonn'/, 'contains title="Bonn"');
unlike ($html, qr/title=['"]Berlin['"]/, "doesn't contain title Berlin");

#############################################################################
# edges do not have a name, will fallback to the label

$edge->set_attribute( 'autotitle' => 'name' );

$html = $graph->as_html();
like ($html, qr/title='Bonn'/, 'contains title="Bonn"');
unlike ($html, qr/title=['"]Berlin['"]/, "doesn't contain title Berlin");
unlike ($html, qr/title=['"]['"]/, "no empty title");

$edge->set_attribute( 'label' => 'my edge' );

$html = $graph->as_html();
like ($html, qr/title="my edge"/, 'contains title="my edge"');

#############################################################################
# check that "shape:" does not appear in CSS or HTML

$bonn->set_attribute( 'shape' => 'circle' );
$graph->set_attribute ( 'node', 'shape', 'ellipse' );

my $css = $graph->css();
$html = $graph->as_html();

unlike ($css, qr/shape/, 'shape does not appear in CSS');
unlike ($html, qr/shape/, 'shape does not appear in HTML');

#############################################################################
# "shape: invisible" should result in an empty td tag w/ "border: none"

$bonn->set_attribute( 'shape' => 'invisible' );

$css = $graph->css();
$html = $graph->as_html();

unlike ($html, qr/display:\s*none/, 'shape invisible is not display: none');
like ($html, qr/td.*border:\s*none/, 'shape invisible results in border: none');

#############################################################################
# label colors

$graph->set_attribute( 'edge', 'label-color' => 'blue' );
$edge->set_attribute( 'label-color' => 'red' );

$css = $graph->css();
$html = $graph->as_html();

unlike ($html, qr/border-bottom:.*;\s*color: #0000ff/, 'no edge is green');
like ($html, qr/border-bottom:.*;\s*color: #ff0000/, 'some edge is red');

#############################################################################
# edge color vs. label colors

$edge->set_attribute( 'color' => 'green' );

$html = $graph->as_html();

unlike ($html, qr/border-bottom:.*#0000ff/, 'no edge got blue');
unlike ($html, qr/border-bottom:.*;\s*color: #0000ff/, 'no edge got blue');

like ($html, qr/border-bottom:.*#008000.*;\s*color: #ff0000/, 
  'color green, label-color red');

#############################################################################
# caption from label

$graph->set_attribute( 'graph', 'label' => 'My Graph Label' );

$html = $graph->as_html();

like ($html, qr/<td colspan=12 style="text-align: center">My Graph Label<\/td>/,
	'graph caption from label');

#############################################################################
# caption with label-pos

$graph->set_attribute( 'graph', 'label' => 'My Graph Label' );
$graph->set_attribute( 'graph', 'label-pos' => 'bottom' );

$html = $graph->as_html();

like ($html, qr/<td colspan=12 style="text-align: center">My Graph Label<\/td>/,
 'graph caption from label');

#############################################################################
# html_file includes <title> and charset:

$html = $graph->as_html_file();

my $charset =
  quotemeta('<meta http-equiv="Content-Type" content="text/html; charset=utf-8">');

like ($html, qr/$charset/, 'html_file includes charset definition');
like ($html, qr/<title>My Graph Label<\/title>/, 'html_file includes <title>');

#############################################################################
# egdes with links, titles and colors

$graph = Graph::Easy->new();

$edge = $graph->add_edge('Friedrichshafen', 'Immenstaad');

$edge->set_attribute('title', 'Vrooom!');
$edge->set_attribute('color', 'orange');
$edge->set_attribute('text-style', 'none');
$edge->set_attribute('font-size', '1.5em');
$edge->set_attribute('link', 'http://bloodgate.com');
$edge->set_attribute('label', 'Schiff');

# This tests edge->as_html(), which will not be called for normal operations,
# in these cases we would convert the single edge cells to HTML.

my $edge_html = <<EDGE
 <td colspan=4 rowspan=4 class='edge' title='Vrooom!'><a href='http://bloodgate.com' style="color: #ffa500; text-decoration: none; font-size: 1.5em">Schiff</a></td>
EDGE
;
is ($edge->as_html(), $edge_html, 'edge->as_html()');

# entire graph as html
$html = $graph->as_html();

$edge_html = <<EDGE_CELL
<td colspan=2 rowspan=2 class="edge lh" style="border-bottom: solid 2px #ffa500;" title="Vrooom!"><a href='http://bloodgate.com' style='color: #ffa500; text-decoration: none; font-size: 1.5em;'>Schiff</a></td>
EDGE_CELL
;
my $like = quotemeta($edge_html); 

like ($html, qr/$like/, 'graph->as_html() contains proper edge html');

#############################################################################
# edge style double, double-dash, bold etc

$graph = Graph::Easy->new();

$edge = $graph->add_edge('Friedrichshafen', 'Immenstaad');

$edge->set_attribute('style', 'double');

$edge_html = <<EDGE_2
 <td colspan=4 rowspan=4 class='edge'></td>
EDGE_2
;
is ($edge->as_html(), $edge_html, 'edge->as_html()');

$edge_html = <<EDGE_CELL
<td colspan=2 rowspan=2 class="edge lh" style="border-bottom: double #000000;">&nbsp;</td>
EDGE_CELL
;

$like = quotemeta($edge_html); 
$html = $graph->as_html();
like ($html, qr/$like/, 'edge->as_html()');

$edge->set_attribute('style', 'double-dash');

$edge_html = <<EDGE_CELL
<td colspan=2 rowspan=2 class="edge lh" style="border-bottom: double #000000;">&nbsp;</td>
EDGE_CELL
;

$like = quotemeta($edge_html); 
$html = $graph->as_html();
like ($html, qr/$like/, 'edge->as_html()');

#############################################################################
# edge color and label-color

$edge->set_attribute('label-color', 'blue');

$edge_html = <<EDGE_CELL
<td colspan=2 rowspan=2 class="edge lh" style="border-bottom: double #000000;color: #0000ff;">&nbsp;</td>
EDGE_CELL
;

$like = quotemeta($edge_html); 
$html = $graph->as_html();
like ($html, qr/$like/, 'edge->as_html()');

#############################################################################
# a node with a link and a fill color at the same time

my $f = $graph->node('Friedrichshafen');
$f->set_attribute('link', 'http://bloodgate.com');
$f->set_attribute('fill', 'red');

$html = $f->as_html();

is ($html, <<EOF
 <td colspan=4 rowspan=4 class='node' style="background: #ff0000"><a href='http://bloodgate.com'>Friedrichshafen</a></td>
EOF
, 'fill is on the TD, not the A HREF');

#############################################################################
# a node with a link and a border at the same time

$f->set_attribute('border', 'orange');

$html = $f->as_html();

is ($html, <<EOF
 <td colspan=4 rowspan=4 class='node' style="background: #ff0000;border: solid 1px #ffa500"><a href='http://bloodgate.com'>Friedrichshafen</a></td>
EOF
, 'border is on the TD, not the A HREF');

#############################################################################
# as_html_file() includes the proper classes

$html = $graph->as_html_file();

for my $c (qw/eb lh lv va el sh shl/)
  {
  like ($html, qr/table.graph \.$c/, "includes '$c'");
  }

#############################################################################
# group labels are left-aligned

$graph = Graph::Easy->new();

my $group = $graph->add_group('Cities');
my ($A,$B) = $graph->add_edge('Krefeld', 'Düren');

$group->add_nodes($A,$B);

$css = $graph->css();
like ($css, qr/group[^\}]*text-align: left;/, 'contains text-align: left');

#############################################################################
# setting a graph color does not override nodes/edges/groups

$graph->set_attribute('color', 'red');

$css = $graph->css();

for my $e (qw/node_anon edge group_anon/)
  {
  unlike ($css, qr/table.graph\s+\.$e\s+\{[^\}]*[^-]color: #ff0000;/m, "contains not $e color red");
  }

#############################################################################
# setting a graph font/fill does not override nodes/edges/groups

$graph->set_attribute('font', 'times');
$graph->set_attribute('fill', 'blue');
$graph->set_attribute('font-size', '8em');
$graph->set_attribute('align', 'left');

$css = $graph->css();
unlike ($css, qr/table.graph\s+\{[^\}]*font-family: /m, "doesn't contain font-family");
unlike ($css, qr/table.graph\s+\{[^\}]*fill: /m, "doesn't contain fill");
unlike ($css, qr/table.graph\s+\{[^\}]*color: /m, "doesn't contain color");
unlike ($css, qr/table.graph\s+\{[^\}]*background[^\}]*background/m, "doesn't contain two times background");
unlike ($css, qr/table.graph\s+\{[^\}]*text-align/m, "doesn't contain font-size");
unlike ($css, qr/table.graph\s+\{[^\}]*font-size/m, "doesn't contain text-align");

#############################################################################
# multiline labels with \c, \r, and \l in them

$graph = Graph::Easy->new();

($A,$B) = $graph->add_edge('Köln', 'Rüdesheim');

$A->set_attribute('label', 'Köln\r(am Rhein)\l(NRW)\c(Deutschland)');
$html = $graph->as_html_file();

like ($html,
  qr/class='node'>Köln<br><span class="r">\(am Rhein\)<\/span><br><span class="l">\(NRW\)<\/span><br>\(Deutschland\)</,
  'Köln with multiline text');

$A->set_attribute('align', 'right');

$html = $graph->as_html_file();

like ($html,
  qr/class='node' style="text-align: center"><span class="r">Köln<\/span><br><span class="r">\(am Rhein\)<\/span><br><span class="l">\(NRW\)<\/span><br>\(Deutschland\)</,
  'Köln with multiline text');

#############################################################################
# multiline labels with "textwrap: N;"

$graph = Graph::Easy->new();

($A,$B) = $graph->add_edge('Köln', 'Rüdesheim');

$A->set_attribute('label', 'Köln\r(am Rhein)\l(NRW)\c(Deutschland)');
$A->set_attribute('textwrap', 10);

#print join (" ", $A->_label_as_html() );

$html = $graph->as_html_file();

like ($html,
  qr/class='node'>Köln \(am<br>Rhein\)<br>\(NRW\)<br>\(Deutschland\)</,
  'Köln with multiline text');

#############################################################################
# invisible edges

$graph = Graph::Easy->new();

($A,$B,$edge) = $graph->add_edge('Hamm', 'Hagen');

$edge->set_attribute('style','invisible');
$edge->set_attribute('label','foobarbaz');
$edge->set_attribute('color','red');

$html = $graph->as_html_file();

unlike ($html, qr/invisible/, 'no border on invisible edges');
unlike ($html, qr/#ff0000/, 'no color on invisible edges');
unlike ($html, qr/foobarbaz/, 'no label on invisible edges');

#############################################################################
# inheritance of attributes via classes

$graph = Graph::Easy->new();

($A,$B,$edge) = $graph->add_edge('green', 'blue.foo');

$graph->set_attribute('color','red');
$graph->set_attribute('node','color','blue');
$graph->set_attribute('node.foo','color','inherit');
$graph->set_attribute('node.bar','color','green');
$graph->set_attribute('edge','color','inherit');
$graph->set_attribute('edge.foo','color','inherit');

$A->set_attribute('class','bar');
$B->set_attribute('class','foo');
$edge->set_attribute('class','foobar');				# no color set

my ($C,$D,$E) = $graph->add_edge('blue','red');

$E->set_attribute('class','foo');			# inherits red
$D->set_attribute('color','inherit');			# inherits red from graph

is ($A->attribute('color'),'green', 'node.bar is green');
is ($B->attribute('color'),'blue', 'node.foo inherits blue from node');
is ($C->attribute('color'),'blue', 'node is just blue');
is ($D->attribute('color'),'red', 'inherits red from graph');

is ($edge->attribute('color'),'black', 'no color set, so defaults to black');
is ($E->attribute('color'),'red', 'inherit red from graph');

#############################################################################
# comments

$graph = Graph::Easy->new();

($A,$B,$edge) = $graph->add_edge('green', 'blue.foo');

$graph->set_attribute('comment', 'My comment --> graph');
$A->set_attribute('comment', 'My comment --> A');
$edge->set_attribute('comment', 'My comment --> edge');

$html = $graph->as_html_file();

like ($html, qr/<!-- My comment --&gt; graph -->/, 'graph comment');
like ($html, qr/<!-- My comment --&gt; A -->/, 'node comment');
like ($html, qr/<!-- My comment --&gt; edge -->/, 'edge comment');

#############################################################################
# colorscheme and class attributes

$graph = Graph::Easy->new();

($A,$B,$edge) = $graph->add_edge('A', 'B');

$graph->set_attribute('colorscheme', 'pastel19');
$graph->set_attribute('node.yellow', 'fill', '1');
$graph->set_attribute('node.yellow', 'color', 'silver');

$A->set_attribute('class', 'yellow');

$html = $graph->as_html_file();

like ($html, 
      qr/node_yellow(.|\n)*background: #fbb4ae;/, 'background is not 1');
like ($html, 
      qr/node_yellow(.|\n)*color: silver;/, 'color is silver');

#############################################################################
# support for \N, \E, \H, \T, \G in titles and labels

$graph = Graph::Easy->new();

($A,$B,$edge) = $graph->add_edge('A', 'B');

$graph->set_attribute('label', 'My Graph');
$graph->set_attribute('node', 'title', 'My \N in \G');
$graph->set_attribute('edge', 'title', 'My \E in \G (\T => \H)');

$html = $graph->as_html_file();

like ($html, qr/title='My A in My Graph'/, 'title with \N and \G');
like ($html, qr/title='My B in My Graph'/, 'title with \N and \G');
like ($html, qr/title="My A->B in My Graph \(A => B\)"/, 'title with \E, \H, \T');

# support for \L in titles
$graph->set_attribute('node', 'label', 'labeled "My \N"');
$graph->set_attribute('node', 'title', 'My \L');
$html = $graph->as_html_file();
like ($html, qr/title='My labeled "My A"'/, 'title with \L');

