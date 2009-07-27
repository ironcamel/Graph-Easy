#!/usr/bin/perl -w

use Test::More;
use strict;
use File::Spec;

# test GDL (Graph Description Language) file input => ASCII output
# and back to as_txt() again

BEGIN
   {
   plan tests => 20;
   chdir 't' if -d 't';
   use lib '../lib';
   use_ok ("Graph::Easy") or die($@);
   use_ok ("Graph::Easy::Parser") or die($@);
   use_ok ("Graph::Easy::Parser::VCG") or die($@);
   };

#############################################################################
# parser object

my $def_parser = Graph::Easy::Parser->new(debug => 0);

is (ref($def_parser), 'Graph::Easy::Parser');
is ($def_parser->error(), '', 'no error yet');

my $dir = File::Spec->catdir('in','gdl');

opendir DIR, $dir or die ("Cannot read dir $dir: $!");
my @files = readdir(DIR); closedir(DIR);

binmode (STDERR, ':utf8') or die ("Cannot do binmode(':utf8') on STDERR: $!");
binmode (STDOUT, ':utf8') or die ("Cannot do binmode(':utf8') on STDOUT: $!");

eval { require Test::Differences; };

foreach my $f (sort { 
  $a =~ /^(\d+)/; my $a1 = $1 || '1'; 
  $b =~ /^(\d+)/; my $b1 = $1 || '1'; 
  $a1 <=> $b1 || $a cmp $b;
  } @files)
  {
  my $file = File::Spec->catfile($dir,$f);
  my $parser = $def_parser;
  
  next unless $f =~ /\.gdl/;			# ignore anything else

  print "# at $f\n";
  my $txt = readfile($file);
  $parser->reset();
  my $graph = $parser->from_text($txt);		# reuse parser object

  $f =~ /^(\d+)/;
  my $nodes = $1;

  if (!defined $graph)
    {
    fail ("GDL input was invalid: " . $parser->error());
    next;
    }
  is (scalar $graph->nodes(), $nodes, "$nodes nodes");

  # for slow testing machines
  $graph->timeout(20);
  my $ascii = $graph->as_ascii();

  my $of = $f; $of =~ s/\.gdl/\.txt/;
  my $out = readfile(File::Spec->catfile('out','gdl',$of));
  $out =~ s/(^|\n)#[^# ]{2}.*\n//g;		# remove comments
  $out =~ s/\n\n\z/\n/mg;			# remove empty lines

# print "txt: $txt\n";
# print "ascii: $ascii\n";
# print "should: $out\n";

  if (!
    is ($ascii, $out, "from $f"))
    {
    if (defined $Test::Differences::VERSION)
      {
      Test::Differences::eq_or_diff ($ascii, $out);
      }
    else
      {
      fail ("Test::Differences not installed");
      }
    }

  # if the txt output differes, read it in
  my $f_txt = File::Spec->catfile('txt','gdl',$of);
  if (-f $f_txt)
    {
    $txt = readfile($f_txt);
    }

  $graph->debug(1);

 if (!
   is ($graph->as_txt(), $txt, "$f as_txt"))
   {
   if (defined $Test::Differences::VERSION)
     {
     Test::Differences::eq_or_diff ($graph->as_txt(), $txt);
     }
   else
     {
     fail ("Test::Differences not installed");
     }
   }

  # print a debug output
  my $debug = $ascii;
  $debug =~ s/\n/\n# /g;
  print "# Generated:\n#\n# $debug\n";
  }

1;

sub readfile
  {
  my ($file) = @_;

  open my $FILE, $file or die ("Cannot read file $file: $!");
  binmode ($FILE, ':utf8') or die ("Cannot do binmode(':utf8') on $FILE: $!");
  local $/ = undef;				# slurp mode
  my $doc = <$FILE>;
  close $FILE;

  $doc;
  }
