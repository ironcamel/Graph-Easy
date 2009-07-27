#!/usr/bin/perl -w

#############################################################################
# This example is a bit outdated, please use the new bin/grapheasy script -
# which is after "make install" available in your system as simple as
# "grapheasy" on any command line prompt.

#############################################################################
# This script tries to generate graphs from all the files in t/syntax/
# and outputs the result as an HTML page.
# Use it like:

# examples/syntax.pl >test.html

# and then open test.html in your favourite browser.

BEGIN
  {
  chdir 'examples' if -d 'examples'; 
  use lib '../lib';
  }

use strict;
use warnings;
use Graph::Easy::Parser;

my $parser = Graph::Easy::Parser->new( debug => 0);

my ($name, $template, $sep, @dirs) = @ARGV;

$name = 'Graph::Easy Test page' unless $name;
$template = 'syntax.tpl' unless $template;

my @toc = ();

open FILE, $template or die ("Cannot read 'syntax.tpl': $!");
local $/ = undef;
my $html = <FILE>;
close FILE;

my $output = ''; my $ID = '0';

# generate the parts and push their names into @toc
gen_graphs($parser, @dirs);

my $toc = '<ul>';
for my $t (@toc)
  {
  $toc .= " <li><a href='#$t->[0]'>$t->[1]</a>\n";
  }
$toc .= "</ul>\n";

# insert the TOC
$html =~ s/##TOC##/ $toc /;
$html =~ s/##NAME##/ $name /;
$html =~ s/##HTML##/ $output /;
$html =~ s/##time##/ scalar localtime() /eg;
$html =~ s/##version##/$Graph::Easy::VERSION/eg;

print $html;

# all done;

1;

#############################################################################

sub gen_graphs
  {
  # for all files in a dir, generate a graph from it
  my $parser = shift;

  @dirs = qw/syntax stress/ unless @dirs;

  foreach my $dir (@dirs)
    {
    _for_all_files($parser, $dir);
    }
  }

sub _for_all_files
  {
  my ($parser, $dir) = @_;

  opendir DIR, "../t/$dir" or die ("Cannot read dir '../t/$dir': $!");
  my @files = readdir DIR;
  closedir DIR;

  foreach my $file (sort @files)
    {
    my $f = "../t/$dir/" . $file;
    next unless -f $f;			# not a file?

    print STDERR "# at file $f\n";
 
    open FILE, "$f" or die ("Cannot read '$f': $!");
    local $/ = undef;
    my $input = <FILE>;
    close FILE;
    my $graph = $parser->from_text( $input );

    if (!defined $graph)
      {
      my $error = $parser->error();
      $output .=
        "<h2>$dir/$file</h2>" .
	"<a class='top' href='#top' title='Go to the top'>Top -^</a>\n".
	"<div class='text'>\n".
	"Error: Could not parse input from $file: <b style='color: red;'>$error</b>".
	"<br>Input was:\n" .
	"<pre>$input</pre>\n".
	"</div>\n";
      next;
      }

    $graph->timeout(100);
    $graph->layout();

    if ($graph->error())
      {
      my $error = $graph->error();
      $output .=
        "<h2>$dir/$file</h2>" .
	"<a class='top' href='#top' title='Go to the top'>Top -^</a>\n".
	"<div class='text'>\n".
	"Error: $error</b>".
	"<br>Input was:\n" .
	"<pre>$input</pre>\n".
	"</div>\n";
      next;
      }

    $output .= out ($input, $graph, 'html', $dir, $file);
    }
  }

sub out
  {
  my ($txt,$graph,$method,$dir, $file) = @_;

  $method = 'as_' . $method;

  # set unique ID for CSS
  $graph->id($ID++);
  
  my $t = $graph->nodes() . ' Nodes, ' . $graph->edges . ' Edges';
  my $n = $dir."_$file";
 
  $dir = ucfirst($dir);

  # get comment
  $txt =~ /^\s*#\s*(.*)/;
  my $comment = ucfirst($1 || '');
  my $link;
  $link = $1 if $txt =~ /\n#\s*(http.*)/;

  my $name = $comment || $t;
  push @toc, [ $n, $name ];

  my $out = 
  "<style type='text/css'>\n" .
  "<!--\n" .
  $graph->css() . 
  "-->\n" .
  "</style>\n";

  if (!$sep)
    {
    $out .=
    "<a name=\"$n\"></a><h2>$dir: $name</h2>\n" .
    "<a class='top' href='#top' title='Go to the top'>Top -^</a>\n".
     "<div class='text'>\n"; 
  
    $out .= "<span style='color: red; font-weight: bold;'>Error: </span>" .
      $graph->error() if $graph->error();

    my $input =  
     "<div style='float: left;'>\n" . 
     " <h3>Input</h3>\n" . 
     " <pre>$txt</pre>\n</div>" . 
     "<div style='float: left;'>\n" . 
     " <h3>As Text</h3>\n" . 
     "<pre>" . $graph->as_txt() . "</pre>\n</div>";
 
    $out .= $input .
     "<div style='float: left;'>\n" . 
     "<h3>As HTML:</h3>\n" . 
     $graph->$method() . "\n</div>\n";
    $out .= "<div class='clear'>&nbsp;</div></div>\n\n";
    }
  else
    {

    $out .=
    "<a name=\"$n\"></a><h3>$name</h3>\n";

    $out .= "<a class='top' href='#top' title='Go to the top'>Top -^</a>\n";
    $out .= "<a class='top' href='$link' style='color: red;'>Source</a>\n" if $link;

    $out .= "<span style='color: red; font-weight: bold;'>Error: </span> " .
      $graph->error() if $graph->error();

    $out .= $graph->$method() . "\n" .
            "<div class='clear'></div>\n\n";
    # write out the input/text 
    }

  $out;
  }


