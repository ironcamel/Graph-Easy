#!/usr/bin/perl -w

use Test::More;
use strict;

BEGIN
   {
   plan tests => 146;
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
  use_class
  _parse_attributes
  /);

#############################################################################
# parser object

my $parser = Graph::Easy::Parser->new( debug => 0 );

is (ref($parser), 'Graph::Easy::Parser');
is ($parser->error(), '', 'no error yet');

#############################################################################
# parse_error():

$parser->no_fatal_errors(1);
$parser->reset();

$parser->{line_nr} = 0;
is ($parser->parse_error(1,'foo','bar','node'),
    "Error in attribute: 'bar' is not a valid attribute for a node at line 0");

$parser->{line_nr} = 0;
is ($parser->parse_error(2,'boldly','style','edge'),
    "Error in attribute: 'boldly' is not a valid style for a edge at line 0");

$parser->{line_nr} = 0;
is ($parser->parse_error(3),
    "Error: Found attributes, but expected group or node start at line 0");

#############################################################################
# from_text() and from_file() with Class->method style calling

my $graph = Graph::Easy::Parser->from_text('[A]');

is (ref($graph), 'Graph::Easy');
is ($graph->nodes(), 1, 'one node from_text');

# from_text with graphviz code
$graph = Graph::Easy::Parser->from_text('digraph Graph1 { Bonn1 -> Berlin1 }');

is (ref($graph), 'Graph::Easy');
is ($graph->nodes(), 2, 'two nodes from graphviz texts');

$graph = Graph::Easy::Parser->from_file('in/1node.txt');

is (ref($graph), 'Graph::Easy');
is ($graph->nodes(), 1, 'one node');

#############################################################################
# test for invalid input with only one line

my $graph2 = $parser->from_text('invalid');

like ($parser->error(), qr/invalid/, 'one invalid line results in error');

#############################################################################
# matching classes with space in front

$graph2 = $parser->from_text("# comment\n node { color: red; }\n");

is ($parser->error(), '', 'parsed ok');

#############################################################################
# matching nodes

my $node_qr = $parser->_match_node();

like ('[]', $node_qr, '[] is a node');
like ('[ ]', $node_qr, '[ ] is a node');

#############################################################################
# check that setting a new subclass invalidates the cache in Base.pm

$graph = Graph::Easy::Parser->from_text( 
  <<EOF
group.local { fill: yellow; }

( A [A] { class: foo; }
) { class: local; }
EOF
 );

is ($graph->attribute('group.local','fill'), 'yellow', 'fill is yellow');

my $group = $graph->group('A');

is ($graph->attribute('group.local','fill'), 'yellow', 'fill is yellow');
is ($group->attribute('fill'), 'yellow', 'fill is still yellow');
is ($group->class(), 'group.local', 'group class is group.local');

#############################################################################
# general pattern tests

my $line = 0;

foreach (<DATA>)
  {
  chomp;
  next if $_ =~ /^\s*\z/;			# skip empty lines
  next if $_ =~ /^#/;				# skip comments

  $parser->reset();

  die ("Illegal line $line in testdata") unless $_ =~ /^(.*)\|([^\|]*)$/;
  my ($in,$result) = ($1,$2);

  my $txt = $in;
  $txt =~ s/\\n/\n/g;				# insert real newlines

  my $graph = $parser->from_text($txt);		# reuse parser object

  if (!defined $graph || $graph->error() || $parser->error())
    {
    my $error = $parser->error();
    $error = $graph->error() if ref($graph) && $graph->error(); 
    if ($result =~ /ERROR/)
      {
      isnt ($error, '', 'got some error');
      }
    else
      {
      fail("$error. Input was: $txt");
      }
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

  for my $n ( sort { $a->name() cmp $b->name() }
   ($graph->nodes(), $graph->edges()) )
    {
    $got .= "," . $n->label() unless $n->label() =~ /^\s?\z/ || $n->label() eq $n->name();
    $got .= "," . $n->name() unless $n->name() eq '';
    } 
  
  my @groups = $graph->groups();

  for my $gr ( @groups )
    {
    $got .= ',' . $gr->name();
    }

  is ($got, $result, $in);
  }

__DATA__
|0
# attributes
graph { color: red; }|0
group { color: red; }|0
node { color: red; }|0
edge { color: red; }|0
# attributes with space in front
 graph { color: red; }|0
 group { color: red; }|0
 node { color: red; }|0
 edge { color: red; }|0
# anon nodes
[]|1,#0
[]->[]|2,#0,#1
[Bonn]->[]|2,#1,Bonn
[]->[Bonn]|2,#0,Bonn
# First "#0" and "#1" are created, and ID 2 goes to the edge.
# then "#3" is created, and ID 4 goes to the second edge. Therefore
# "#0" and "#3" are the two anon nodes.
[]->[Bonn]->[]|3,#0,#3,Bonn
# multiple spaces in nodes
[ Bonn and Berlin ]|1,Bonn and Berlin
[ Bonn  and  Berlin  ]|1,Bonn and Berlin
[  Bonn   and  Berlin  ]|1,Bonn and Berlin
[  Bonn \n  and  Berlin  ]|1,Bonn and Berlin
[  Bonn \n\n  and  Berlin  ]|1,Bonn and Berlin
# split nodes
[ A | B ]|2,A,AB.0,B,AB.1
[ A | B | C ]|3,A,ABC.0,B,ABC.1,C,ABC.2
[ A | B | C ] => [ A ]|4,A,A,ABC.0,B,ABC.1,C,ABC.2
[ A | B | C ] => [ A ] [ A | B | C ] => [ A ]|7,A,A,ABC-1.0,B,ABC-1.1,C,ABC-1.2,A,ABC.0,B,ABC.1,C,ABC.2
# unique cluster names, despite trickery in source with "ABC-1" as split node:
[ A | B | C | -1 ] => [ A ] [ A | B | C ] => [ A ]|8,A,A,ABC-1.0,B,ABC-1.1,C,ABC-1.2,-1,ABC-1.3,A,ABC.0,B,ABC.1,C,ABC.2
[ A | B | C | -1 ] => [ A ] [ A | B | C ] => [ A ] [ A | B | C ]|11,A,A,ABC-1.0,B,ABC-1.1,C,ABC-1.2,-1,ABC-1.3,A,ABC-2.0,B,ABC-2.1,C,ABC-2.2,A,ABC.0,B,ABC.1,C,ABC.2
# nodes with \[\]
[ char\[\] ]|1,char[]
[ char\[\] ] -> [ \[\] ]|2,[],char[]
# split nodes with \[\]
[ char\[\] || int ]|2,char[],char[]int.0,int,char[]int.1
# error testing (no end of node)
[ Bonn\[\]|ERROR
# normal tests
[ Berlin ]|1,Berlin
[Hamburg]|1,Hamburg
  [  Dresden  ]  |1,Dresden
[ Pirna ] { color: red; }|1,Pirna
[ Bonn ] -> [ Berlin ]|2,Berlin,Bonn
[ Bonn ] -> [ Berlin ]\n[Berlin] -> [Frankfurt]|3,Berlin,Bonn,Frankfurt
[ Bonn ] ==> [ Berlin ]\n[Berlin] -> [Frankfurt]|3,Berlin,Bonn,Frankfurt
[ Bonn ] = > [ Berlin ]\n[Berlin] -> [Frankfurt]|3,Berlin,Bonn,Frankfurt
[ Bonn ] ~~> [ Berlin ]\n[Berlin] -> [Frankfurt]|3,Berlin,Bonn,Frankfurt
[ Bonn ] ..> [ Berlin ]\n[Berlin] -> [Frankfurt]|3,Berlin,Bonn,Frankfurt
[ Bonn ] - > [ Berlin ]\n[Berlin] -> [Frankfurt]|3,Berlin,Bonn,Frankfurt
[ Bonn \( \#1 \) ] - > [ Berlin ]\n[Berlin] -> [Frankfurt]|3,Berlin,Bonn ( #1 ),Frankfurt
[ Bonn ] { color: red; }\n[Berlin] -> [Frankfurt]|3,Berlin,Bonn,Frankfurt
[Bonn]{color:red;}\n[Berlin]->[Frankfurt]|3,Berlin,Bonn,Frankfurt
[ Bonn ] { color: red; } -> [ Berlin ]\n[Berlin] -> [Frankfurt]|3,Berlin,Bonn,Frankfurt
[ Bonn ] { color: red; } -> [ Berlin ] {color: blue} \n[Berlin] -> [Frankfurt]|3,Berlin,Bonn,Frankfurt
[ Bonn ] { color: #fff; } -> [ Berlin ] { color: #A0a0A0 } # failed in v0.09 [ Bonn ] -> [ Ulm ]|2,Berlin,Bonn
[ Bonn ] { color: #fff; } -> [ Berlin ] { color: #A0a0A0 } #80808080 failed in v0.09 [ Bonn ] -> [ Ulm ]|2,Berlin,Bonn
[ Bonn ] { color: #fff; } -> [ Berlin ] { color: #A0a0A0 } #808080 failed in v0.09 [ Bonn ] -> [ Ulm ]|2,Berlin,Bonn
# node chains
[ Bonn ] -> [ Berlin ]\n -> [ Kassel ]|3,Berlin,Bonn,Kassel
[ Bonn ] { color: #fff; } -> [ Berlin ] { color: #A0a0A0 }\n -> [ Kassel ] { color: red; }|3,Berlin,Bonn,Kassel
[ Bonn ] -> [ Berlin ] -> [ Kassel ]|3,Berlin,Bonn,Kassel
[ Bonn ] { color: #fff; } -> [ Berlin ] { color: #A0a0A0 } -> [ Kassel ] { color: red; }|3,Berlin,Bonn,Kassel
[ Bonn ] -> [ Berlin ]\n -> [ Kassel ] -> [ Koblenz ]|4,Berlin,Bonn,Kassel,Koblenz
[ Bonn ] -> [ Berlin ] -> [ Kassel ]\n -> [ Koblenz ]|4,Berlin,Bonn,Kassel,Koblenz
[ Bonn ] -> [ Berlin ] -> [ Kassel ] -> [ Koblenz ]|4,Berlin,Bonn,Kassel,Koblenz
# attributes with ":" in their value
[ Bonn ] { link: http://www.bloodgate.com/Bonn; }|1,Bonn
# attributes "link", "autolink", and "linkbase":
[ Bonn ] { linkbase: http://www.bloodgate.com/; autolink: name; }|1,Bonn
[ Bonn ] { autolink: none; }|1,Bonn
[ Bonn ] { autolink: title; }|1,Bonn
[ Bonn ] { autolink: name; }|1,Bonn
[ Bonn ] { autotitle: label; }|1,Bonn
[ Bonn ] { autotitle: name; }|1,Bonn
[ Bonn ] { autotitle: none; }|1,Bonn
[ Bonn ] { title: my title; }|1,Bonn
[ Bonn ] { shape: point; point-style: square; }|1,Bonn
[ Bonn ] { background: red; }|1,Bonn
[ Bonn ] { background: rgb(255,0,0); }|1,Bonn
[ Bonn ] { background: rgb(100%,0,0); }|1,Bonn
[ Bonn ] { background: rgb(0.0,0.5,1.0); }|1,Bonn
[ Bonn ] { background: rgb(100%,0.5,12); }|1,Bonn
[ Bonn ] { background: #ff0000; }|1,Bonn
[ Bonn ] { background: #ff0; }|1,Bonn
node.red { background: red; } [ Bonn ] { class: red; }|1,Bonn
edge.red { background: red; } [ Bonn ] -> { class: red; } [ Berlin ]|2,Berlin,Bonn
graph { background: red; } [ Bonn ] -> [ Berlin ]|2,Berlin,Bonn
# edges with label
# matching sides
[ Bonn ] - Auto -> [ Berlin ]|2+1,Auto,Berlin,Bonn
[ Bonn ] ~ Auto ~> [ Berlin ]|2+1,Auto,Berlin,Bonn
[ Bonn ] . Auto .> [ Berlin ]|2+1,Auto,Berlin,Bonn
[ Bonn ] = Auto => [ Berlin ]|2+1,Auto,Berlin,Bonn
[ Bonn ] -- Auto --> [ Berlin ]|2+1,Auto,Berlin,Bonn
[ Bonn ] == Auto ==> [ Berlin ]|2+1,Auto,Berlin,Bonn
[ Bonn ] ~~ Auto ~~> [ Berlin ]|2+1,Auto,Berlin,Bonn
[ Bonn ] .. Auto ..> [ Berlin ]|2+1,Auto,Berlin,Bonn
# with pattern in the middle
[ Bonn ] -- Au-to --> [ Berlin ]|2+1,Au-to,Berlin,Bonn
[ Bonn ] == Au--to ==> [ Berlin ]|2+1,Au--to,Berlin,Bonn
# groups
( Group [ Bonn ] -- Auto --> [ Berlin ] )|2+1,Auto,Berlin,Bonn,Group
( Group [ Bonn ] --> [ Berlin ] )|2,Berlin,Bonn,Group
# lists
[ Bonn ], [ Berlin ]\n --> [ Hamburg ]|3,Berlin,Bonn,Hamburg
[ Bonn ], [ Berlin ] --> [ Hamburg ]|3,Berlin,Bonn,Hamburg
[ Bonn ], [ Berlin ], [ Ulm ] --> [ Hamburg ]|4,Berlin,Bonn,Hamburg,Ulm
[ Bonn ], [ Berlin ], [ Ulm ] --> [ Hamburg ] [ Trier ] --> [ Ulm ]|5,Berlin,Bonn,Hamburg,Trier,Ulm
( Group [ Bonn ], [ Berlin ] => [ Leipzig ] ) { color: red; }|3,Berlin,Bonn,Leipzig,Group
[ Bonn ] -> [ Berlin ]\n --> { color: red; } [ Leipzig ]|3,Berlin,Bonn,Leipzig
[ Bonn ] --> { label: test; } [ Berlin ]|2+1,Berlin,Bonn,test
[ Bonn ] --> { label: test; } [ Berlin ] { color: blue; }|2+1,Berlin,Bonn,test
[ Bonn ] --> { label: test; } [ Berlin ] { color: blue; }|2+1,Berlin,Bonn,test
[ Bonn ] --> { label: test; } [ Berlin ] { color: blue; } --> { label: test2; } [ Leipzig ]|3+2,Berlin,Bonn,Leipzig,test,test2
# undirected edges
[ Bonn ] -- [ Berlin ]|2,Berlin,Bonn
[ Bonn ] -- [ Berlin ] [Ulm] --> [ Mainz]|4,Berlin,Bonn,Mainz,Ulm
[ Bonn ] -- { color: red; } [ Berlin ] [Ulm] --> [ Mainz]|4,Berlin,Bonn,Mainz,Ulm
# left over attributes due to node consumed first
[ Bonn ]\n { color: red; } --> [ Berlin ]|2,Berlin,Bonn
[ Bonn ] { color:\n red; } --> [ Berlin ]|2,Berlin,Bonn
( Group [ Bonn ] ) { color: red; }|1,Bonn,Group
([Bonn]){color:red;}|1,Bonn,Group #0
(0[Bonn]){color:red;}|1,Bonn,0
[ $sys$Node ]|1,$sys$Node
# lists on the right side
[ Bonn ] -- test --> [ Berlin], [ Chemnitz ]|3+2,Berlin,Bonn,Chemnitz,test,test
# empty group
()|0,Group #0
# empty group
( )|0,Group #0
# empty group with link
( )->[Bonn]|1,Bonn,Group #0
# empty group linked to another empty group
( )->( )|0,Group #0,Group #1
# link ending at empty group (#1 because Bonn is #0)
[Bonn]->( )|1,Bonn,Group #1
# link ending at empty group, and starting at empty group
# 0,1,3 (and not 0,1,2) because:
# "()" - create first group
# "->()" - create second group and *then* the edge (id #3)
# "()" - create third group as "#3"
()->()->()|0,Group #0,Group #1,Group #3
# group w/o name
([Bonn])|1,Bonn,Group #0
# edge labels with escaped chars
[ Bonn ] -- \[ A \] \<\> \=\-\. --> [ Berlin ]|2+1,Berlin,Bonn,[ A ] <> =-.
# ERROR testing
# no space
[ Bonn ]--test-->[ Berlin ]|ERROR
[ Bonn ]-- test-->[ Berlin ]|ERROR
[ Bonn ]--test -->[ Berlin ]|ERROR
[ Bonn ]-- test--> [ Berlin ]|ERROR
[ Bonn ] -- test--> [ Berlin ]|ERROR
# mismatching left/right side
[ Bonn ] - Auto--> [ Berlin ]|ERROR
[ Bonn ] - Auto --> [ Berlin ]|ERROR
[ Bonn ] == Auto --> [ Berlin ]|ERROR
# unknown edge style
[ Bonn ] . > [ Berlin ]\n[Berlin] -> [Frankfurt]|ERROR
[ Bonn ] . > [ Berlin ]\n[Berlin] -> [Frankfurt]|ERROR

