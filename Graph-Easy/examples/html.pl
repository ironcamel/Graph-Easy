#!/usr/bin/perl -w

#############################################################################
# This example is a bit outdated, please use the new bin/grapheasy script -
# which is after "make install" available in your system as simple as
# "grapheasy" on any command line prompt.

#############################################################################
# This script uses examples/common.pl to generate some example graphs and
# prints them as HTML page. Use it like:

# ewxamples/html.pl >test.html

# and then open test.html in your favourite browser.

use strict;
use warnings;

BEGIN { chdir 'examples' if -d 'examples'; }

require "common.pl";

my $graph = Graph::Easy->new();

my @toc = ();
my $html = $graph->html_page_header();

$html .= <<HTML

<style type="text/css">
 h1 { border-bottom: 1px solid black; padding-bottom: 0.2em; }
 h2 { border-bottom: 1px solid grey; padding-bottom: 0.2em; margin-bottom: 0em; }
 div { margin-left: 2em; }
 .graph { margin-left: 2em; }
</style>

<h1>Graph-Simple Test page</h1>

<p>
This page was automatically created at <small>##time##</small> by <code>examples/html.pl</code> running
<a href="http://search.cpan.org/~tels/Graph-Simple/" title="Get it from search.cpan.org">Graph::Easy</a> v##version##.
</p>

<p>
On each of the following testcases you will see a text representation of the graph on the left side,
and on the right side the automatically generated HTML+CSS code. 
</p>

<p>
Notes:
</p>

<ul>
  <li>The text representation does not yet carry node attributes, like colors or border style.
  <li>The HTML does not yet have "pretty" edges. This will be fixed later.
  <li>The limitations in <a href="http://search.cpan.org/~tels/Graph-Simple/lib/Graph/Simple.pm#LIMITATIONS">Graph::Easy</a> apply.
</ul>

<h2>Testcases:</h2>

##TOC##

HTML
;

# generate the parts and push their names into @toc
gen_graphs($graph, 'html');

$html .= $graph->html_page_footer();

my $toc = '<ul>';

for my $t (@toc)
  {
  my $n = $t; $n =~ s/\s/_/;
  $toc .= " <li><a href=\"#$n\">" . $t . "</a>\n";
  }
$toc .= "</ul>\n";

# insert the TOC
$html =~ s/##TOC##/ $toc /;
$html =~ s/##time##/ scalar localtime() /e;
$html =~ s/##version##/$Graph::Easy::VERSION/e;

print $html;

# all done;

1;

#############################################################################

sub out
  {
  my ($graph,$method) = @_;

  $method = 'as_' . $method;

  my $t = $graph->nodes() . ' Nodes, ' . $graph->edges . ' Edges';
  my $n = $t; $n =~ s/\s/_/;

  $html .= "<a name=\"$n\"><h2>$t</h2></a>\n" .
   "<div style='float: left; min-widht: 30%'>\n" . 
   "<h3>As Text</h3>\n" . 
   "<pre>" . $graph->as_txt() . "</pre></div>" . 
   "<div style='float: left;'>\n" . 
   "<h3>As HTML:</h3>\n" . 
   $graph->$method() . "</div>\n" .
   "<div style='clear: both;'>&nbsp;</div>\n\n";

  push @toc, $t;
  }

