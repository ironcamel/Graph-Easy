#!/usr/bin/perl -w

# test Graph::Easy::Parser::Graphviz with HTML-like labels

use Test::More;
use strict;
use utf8;

BEGIN
   {
   plan tests => 7;
   chdir 't' if -d 't';
   use lib '../lib';
   use_ok ("Graph::Easy::Parser::Graphviz") or die($@);
   };

can_ok ("Graph::Easy::Parser::Graphviz", qw/
  new
  /);

binmode (STDERR, ':utf8') or die ("Cannot do binmode(':utf8') on STDERR: $!");
binmode (STDOUT, ':utf8') or die ("Cannot do binmode(':utf8') on STDOUT: $!");

#############################################################################
# parser object

my $c = 'Graph::Easy::Parser::Graphviz';

my $parser = Graph::Easy::Parser::Graphviz->new( debug => 0 );

is (ref($parser), $c);
is ($parser->error(), '', 'no error yet');

#############################################################################
# HTML-like labels:

my $graph = Graph::Easy::Parser::Graphviz->from_text(<<EOF
digraph G {
  A [ color="dodgerblue4" shape="box" style="" label=<<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="0"><TR><TD>Name</TD></TR></TABLE>> ];
  B [ color="dodgerblue4" shape="box" style="" label=<<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="0"><TR><TD>Name2</TD></TR><TR><TD ALIGN="LEFT" BALIGN="LEFT" PORT="E4">Somewhere<BR/>test1<BR>test</TD></TR></TABLE>> ];

  A -> B
  }
EOF
);

#print $graph->as_txt();

is (ref($graph), 'Graph::Easy');
is ($graph->nodes(), 3, 'three nodes');
is ($graph->edges(), 1, 'edge did not get lost (bug until v0.60)');

