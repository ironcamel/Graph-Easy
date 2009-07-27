#!/usr/bin/perl -w

use Test::More;
use strict;

# test text file input => ASCII output, and back to as_txt() again

BEGIN
   {
   plan tests => 451;
   chdir 't' if -d 't';
   use lib '../lib';
   use_ok ("Graph::Easy") or die($@);
   use_ok ("Graph::Easy::Parser") or die($@);
   };

#############################################################################
# parser object

my $parser = Graph::Easy::Parser->new( debug => 0);

is (ref($parser), 'Graph::Easy::Parser');
is ($parser->error(), '', 'no error yet');

opendir DIR, "in" or die ("Cannot read dir 'in': $!");
my @files = readdir(DIR); closedir(DIR);

my @failures;

eval { require Test::Differences; };

binmode (STDERR, ':utf8') or die ("Cannot do binmode(':utf8') on STDERR: $!");
binmode (STDOUT, ':utf8') or die ("Cannot do binmode(':utf8') on STDOUT: $!");

foreach my $f (sort @files)
  {
  next unless -f "in/$f";			# only files
  
  next unless $f =~ /\.txt/;			# ignore anything else

  print "# at $f\n";
  my $txt = readfile("in/$f");
  my $graph = $parser->from_text($txt);		# reuse parser object

  $txt =~ s/\n\s+\z/\n/;			# remove trailing whitespace
  $txt =~ s/(^|\n)\s*#[^#]{2}.*\n//g;		# remove comments
 
  $f =~ /^(\d+)/;
  my $nodes = $1;

  if (!defined $graph)
    {
    warn ("Graph input was invalid: " . $parser->error());
    push @failures, $f;
    next;
    }
  is (scalar $graph->nodes(), $nodes, "$nodes nodes");

  # for slow testing machines
  $graph->timeout(20);
  my $ascii = $graph->as_ascii();
  my $out = readfile("out/$f");
  $out =~ s/(^|\n)\s*#[^#=]{2}.*\n//g;		# remove comments
  $out =~ s/\n\n\z/\n/mg;			# remove empty lines

# print "txt: $txt\n";
# print "ascii: $ascii\n";
# print "should: $out\n";

  if (!
    is ($ascii, $out, "from $f"))
    {
    push @failures, $f;
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
  if (-f "txt/$f")
    {
    $txt = readfile("txt/$f");
    }
#  else
#    {
#    # input might have whitespace at front, remove it because output doesn't
#    $txt =~ s/(^|\n)\x20+/$1/g;
#    }

  if (!
    is ($graph->as_txt(), $txt, "$f as_txt"))
    {
    push @failures, $f;
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

if (@failures)
  {
  print "# !!! Failed the following tests:\n";
  for my $f (@failures)
    {
    print "#      $f\n";
    }
  print "# !!!\n\n";
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
