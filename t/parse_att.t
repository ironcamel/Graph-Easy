#!/usr/bin/perl -w

use Test::More;
use strict;

BEGIN
   {
   plan tests => 86;
   chdir 't' if -d 't';
   use lib '../lib';
   use_ok ("Graph::Easy::Parser") or die($@);
   use_ok ("Graph::Easy") or die($@);
   };

can_ok ("Graph::Easy::Parser", qw/
  _parse_attributes
  /);


#############################################################################
# parser object

my $parser = Graph::Easy::Parser->new();

is (ref($parser), 'Graph::Easy::Parser');
is ($parser->error(), '', 'no error yet');

my $line = 0;
$parser->no_fatal_errors(1);

foreach (<DATA>)
  {
  chomp;
  next if $_ =~ /^(\s*\z|#)/;			# skip empty lines or comments
  
  my ($in,$result) = split /\|/, $_;

  my $txt = $in;
  $txt =~ s/\\n/\n/g;					# insert real newlines

  # ^ => to '|' since '|' is the sep.
  $txt =~ s/[\^]/\|/g;

  $parser->reset();

  my $class = 'node';
  $class = 'edge' if $txt =~ /^(start|end|labelcolor|arrow)/;
  $class = 'graph' if $txt =~ /^labelpos/;

  # need to cache this value
  $parser->{_match_single_attribute} = $parser->_match_single_attribute();

  my $att = $parser->_parse_attributes($txt, $class);	# reuse parser object

  if ($parser->error())
    {
    if ($result =~ /^error=/)
      {
      my $res = $result; $res =~ s/^error=//; my $resq = quotemeta($res);
      like ($parser->error(), qr/$resq/, $res);
      }
    else
      {
      print '# Got unexpected error: ' . $parser->error(), "\n";
      fail ("$txt");
      }
    next;
    }

  my $exp = '';
  foreach my $k (sort keys %$att)
    {
    if (ref($att->{$k}) eq 'ARRAY')
      {
      $exp .= "$k=";
      for my $k1 (@{$att->{$k}})
        {
        my $v = $parser->{_graph}->unquote_attribute('graph',$k,$k1);
        $exp .= "$v,";    
        }
      $exp =~ s/,\z//;
      $exp .= ";";
      }
    else
      {
      my $v = $parser->{_graph}->unquote_attribute('graph',$k,$att->{$k});
      $exp .= "$k=$v;";
      }
    }

  is ($exp, $result, $in);
  }

__DATA__
|
color: red;|color=red;
color : red;|color=red;
 color : lime ; |color=lime;
 color : yellow  |color=yellow;
color: rgb(1,1,1);|color=rgb(1,1,1);
color: rgb(255,1,1);|color=rgb(255,1,1);
color: rgb(255,255,1);|color=rgb(255,255,1);
color: rgb(255,255,255);|color=rgb(255,255,255);
color: #ff0;|color=#ff0;
color: #0f0;|color=#0f0;
color: slategrey;|color=slategrey;
color: slategrey;|color=slategrey;
color: gray;|color=gray;
color: gray;|color=gray;
# color names are case-insensitive
color: Slategrey;|color=slategrey;
color: SlateGrey;|color=slategrey;
color: SLATEGREY;|color=slategrey;
colorscheme: w3c;|colorscheme=w3c;
colorscheme: x11;|colorscheme=x11;
colorscheme: puor6;|colorscheme=puor6;
colorscheme: puor16|error=Error in attribute: 'puor16' is not a valid colorscheme for a node
border-style: double;|borderstyle=double;
border-width: 1;|borderwidth=1;
border-color: red;|bordercolor=red;
color: red; border: none; |border=none;color=red;
color:|error=Error in attribute: 'color:' doesn't look valid
: red;|error=Error in attribute: ': red;' doesn't look valid
: red|error=Error in attribute: ': red' doesn't look valid
color: reddish|error=Error in attribute: 'reddish' is not a valid color for a node
color:;background: red|error=Error in attribute: 'color:;background: red' doesn't look valid
shape:fruggle;|error=Error in attribute: 'fruggle' is not a valid shape for a node
color: rgb(256, 0, 0);|error=Error in attribute: 'rgb(256, 0, 0)' is not a valid color for a node
color: rgb(0, 256, 0);|error=Error in attribute: 'rgb(0, 256, 0)' is not a valid color for a node
color: rgb(0, 0, 256);|error=Error in attribute: 'rgb(0, 0, 256)' is not a valid color for a node
shape: qiggle;|error=Error in attribute: 'qiggle' is not a valid shape for a node
offset: -3,-2;|offset=-3,-2;
offset: 3,-2;|offset=3,-2;
offset: -3,2;|offset=-3,2;
offset: 2, 0;|offset=2, 0;
offset:  2 , 0;|offset=2 , 0;
offset:  2  ,  0;|offset=2 , 0;
offset:  2  ,  0 ;|offset=2 , 0;
fill: brown;|fill=brown;
point-style: qiggle;|error=Error in attribute: 'qiggle' is not a valid pointstyle for a node
toint-shape: qiggle;|error=Error in attribute: 'toint-shape' is not a valid attribute name for a node
autolink: qiggle;|error=Error in attribute: 'qiggle' is not a valid autolink for a node
size: 1, 2;|size=1, 2;
start: south, 1;|start=south, 1;
start: south , 1;|start=south , 1;
start: right , -1;|start=right , -1;
end: south, 1;|end=south, 1;
end: south , 1;|end=south , 1;
end: right , -1;|end=right , -1;
end: right,12345;|error=Error in attribute: 'right,12345' is not a valid end for a edge
start: right,12345;|error=Error in attribute: 'right,12345' is not a valid start for a edge
autolabel: 20;|autolabel=20;
autolabel: name,1;|error=Error in attribute: 'name,1' is not a valid autolabel for a node
autolabel: name,10;|autolabel=name,10;
autolabel: name, 10;|autolabel=name, 10;
autolabel: name ,10;|autolabel=name ,10;
autolabel: name , 10;|autolabel=name , 10;
fill: red^green^yellow;|fill=red,green,yellow;
link: http://bloodgate.com/^index.html^/test;|link=http://bloodgate.com/,index.html,/test;
link: http://bloodgate.com/ ^ index.html^/test;|link=http://bloodgate.com/,index.html,/test;
shape: rect^img^rect;|shape=rect,img,rect;
# attribute with a ";" inside quotes, and escaped quotes
label: "baz;bar"; color: red;|color=red;label=baz;bar;
label: "test";|label=test;
label: "test;";|label=test;;
label: "\"test\"";|label="test";
label: "\"test;\"";|label="test;";
# alias names
bordercolor: red;|bordercolor=red;
borderstyle: solid;|borderstyle=solid;
borderwidth: 1px;|borderwidth=1px;
fontsize: 80%;|fontsize=80%;
textstyle: bold;|textstyle=bold;
textwrap: auto;|textwrap=auto;
pointstyle: diamond;|pointstyle=diamond;
arrowstyle: filled;|arrowstyle=filled;
labelcolor: peachpuff;|labelcolor=peachpuff;
labelpos: bottom;|labelpos=bottom;
