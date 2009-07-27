#!/usr/bin/perl 

use strict;
use Graph::Easy;
use LWP;
use HTML::TokeParser;
use utf8;
use Getopt::Long;
use Encode;
use Data::Dumper;

my $VERSION = 0.03;

# things that shouldn't be looked at
my %bad = map { $_ => 1 } qw/
  Wikipedia Image Talk Help Template Portal Special User Category
  Wikipedia Bild Diskussion Hilfe Vorlage Portal Spezial Benutzer Kategorie
  Wikipédia Image Discuter Modèle Mod%C3%A9le Aide Utilisateur Catégorie Cat%C3%A9gorie
  /;
# do not crawl these:
my $skip = qr/\((disambiguation|Begriffsklärung|Homonymie)\)/i;
# to figure out redirections
my $redir = qr/(Weitergeleitet von|Redirected from|Redirig. depuis).*?title="(.*?)"/i;

# the default settings are defined in get_options()
# option handling
my $help_requested = 0; $help_requested = 1 if @ARGV == 0;

my $opt = get_options();

# error?
$help_requested = 1 if !ref($opt);

# no error and --help was specified
$help_requested = 2 if ref($opt) && $opt->{help} ne '';

my $copyright = "wikicrawl v$VERSION  (c) by Tels 2008.  "
        	."Released under the GPL 2.0 or later.\n\n"
        	."After a very cool idea by 'integral' on forum.xkcd.com. Thanx! :)\n\n";

if (ref($opt) && $opt->{version} != 0)
  {
  print $copyright;
  print "Running under Perl v$].\n\n";
  exit 2;
  }

if ($help_requested > 0)
  {
  print STDERR $copyright;
  require Pod::Usage;
  if ($help_requested > 1 && $Pod::Usage::VERSION < 1.35)
    {
    # The way old Pod::Usage executes "perldoc" might fail:
    system('perldoc', $0);
    exit 2;
    }
  Pod::Usage::pod2usage( { -exitval => 2, -verbose => $help_requested } );
  }

my $verbose = $opt->{verbose};

output ($copyright);

my $graph = Graph::Easy->new();
# set some default attributes on the graph
$graph->set_attribute('node','shape',$opt->{nodeshape});
$graph->set_attribute('node','font-size','80%');
$graph->set_attribute('edge','arrowstyle','filled');
$graph->set_attribute('graph','label',"Wikipedia map for $opt->{root}");
$graph->set_attribute('graph','font-size', '200%');
$graph->set_attribute('graph','comment', "Created with wikicrawl.pl v$VERSION");

output ("Using the following settings:\n");
print Data::Dumper->Dump([$opt], ['opt']);

# don't crawl stuff twice
my %visitedLinks;
# re-use the UserAgent object
my $ua = LWP::UserAgent->new();
#$ua->agent("WikiCrawl/$VERSION - " . $ua->_agent . " - vGraph::Easy $Graph::Easy::VERSION");

# count how many we have done
my $nodes = 0;

# enable UTF-8 output
binmode STDERR, ':utf8';
binmode STDOUT, ':utf8';

# push the first node on the stack
my @todo = [$opt->{root},0];
# and work on it (this will take one off and then push more nodes on it)
while (@todo && crawl()) { };

my $file = "wikicrawl-$opt->{lang}.txt";
output ("Generating $file:\n");
open(my $DATA, ">", "$file") or die("Could not write to '$file': $!");
binmode ($DATA,':utf8');
print $DATA $graph->as_txt();
close $DATA;
output ("All done.\n");

my $png = $file; $png =~ s/.txt/.png/;

output ("Generating $png:\n");
`perl -Ilib bin/graph-easy --png --renderer=$opt->{renderer} $file`;

output ("All done.\n");

########################################################################################

# main crawl routine
sub crawl {
  no warnings 'recursion';

  # all done?
  return if @todo == 0;
  my ($name,$depth) = ($todo[0]->[0],$todo[0]->[1]);
  shift @todo;

  my $page = "http://$opt->{lang}.wikipedia.org/wiki/$name";

  # limit depth
  return if $depth + 1 > $opt->{maxdepth};
  # already did as many nodes?
  return if $opt->{maxnodes} > 0 && $nodes > $opt->{maxnodes};
  # skip this page
  return 1 if exists $visitedLinks{$page};

  # crawl page
  my $res = $ua->request(HTTP::Request->new(GET => $page));
  return 1 unless $res->is_success();

  # remove the " - Wikipedia" (en) or " – Wikipedia" (de) from the title
  my $title = decode('utf8',$res->title);	# convert to UTF-8
  $title =~ s/ [–-] Wikip[ée]dia.*//;
  return 1 if $title =~ $skip;			# no disambiguation pages

  # tels: not sure when/why these happen:
  print STDERR "# $title ",$res->title()," $page\n" if $title eq '';

  output ("Crawling node #$nodes '$title' at depth $depth\n"); $nodes++;

  # set flag
  $visitedLinks{$page} = undef;
  my $content = $res->content;

  # parse anchors
  my $parser = HTML::TokeParser->new(\$content) or die("Could not parse page.");

  # handle redirects:
  $content = decode('utf-8', $content);
  $content =~ $redir; my $old = $2;

  if ($old)
    {
    output (" Redirected to '$title' from '$old'\n");
    # find the node named "$old" (at the same time adding it if it didn't exist yet)
    my $source = $graph->add_node($old);
    # and mention the redirect in the label
    $source->set_attribute('label', "$old\\n($title)");
    # now force edges to come from that node
    $title = $old; 
    }

  # iterate over all links
  for(my $i = 0; (my $token = $parser->get_tag("a")) && ($i < $opt->{maxspread} || $opt->{maxspread} == 0);)
    {
    my $url = $token->[1]{href};
    my $alt = $token->[1]{title};

    next unless defined $url;
    # we do not crawl these:
    next if $url !~ m/^\/wiki\//;	 	# no pages outside of wikipedia
    next if $alt =~ $skip;			# no disambiguation pages
    next if $alt =~ m/\[/;			# no brackets

    my @chunks = split ":", substr(decode('utf-8',$url), 6);	# extract special pages, if any
    next if exists $bad{$chunks[0]};		# no bad pages

    $i++;
    if ($title ne $alt)
      {
      output (" Adding link from '$title' to '$alt'\n", 1);
      my ($from,$to,$edge) = $graph->add_edge_once($title,$alt);
      if (defined $to)
	{
	my $old_depth = $to->raw_attribute('rank');
        if (!$old_depth)
	  {
	  my $color = sprintf("%i", (360 / $opt->{maxdepth}) * ($depth));
	  $to->set_attribute('fill', 'hsl(' .$color.',1,0.7)');
	  # store rank
	  $to->set_attribute('rank', $depth+1);
          }
	}
      }
    my $u = $url; $u =~ s/^\/wiki\///;
    push @todo, [$u,$depth+1];
    }

  # continue
  return 1;
  }

sub get_options
  {
  my $opt = {};
  $opt->{help} = '';
  $opt->{version} = 0;
  # max depth to crawl
  $opt->{maxdepth} = 4;
  # max number of links per node
  $opt->{maxspread} = 5;
  # stop after so many nodes, -1 to disable
  $opt->{maxnodes} = -1;
  # language
  $opt->{lang} = 'en';
  # root node
  $opt->{root} = 'Xkcd';
  $opt->{renderer} = 'neato';
  $opt->{nodeshape} = 'rect';
  my @o = (
    "language=s" => \$opt->{lang},
    "root=s" => \$opt->{root},
    "maxdepth=i" => \$opt->{maxdepth},
    "maxspread=i" => \$opt->{maxspread},
    "maxnodes=i" => \$opt->{maxnodes},
    "version" => \$opt->{version},
    "help|?" => \$opt->{help},
    "verbose" => \$opt->{verbose},
    "nodeshape" => \$opt->{nodeshape},
    );
  return unless Getopt::Long::GetOptions (@o);
  $opt;
  }

sub output
  {
  my ($txt, $level) = @_;

  $level |= 0;

  print STDERR $txt if $opt->{verbose} || $level == 0;
  }

=pod

=head1 NAME

wikicrawl - crawl Wikipedia to generate graph from the found article links

=head1 SYNOPSIS

Crawl wikipedia and create a L<Graph::Easy> text describing the inter-article links
that were found during the crawl.

At least one argument must be given to start:

	perl examples/wikicrawl.pl --lang=fr

=head1 ARGUMENTS

Here are the options:

=over 12

=item --help

Print the full documentation, not just this short overview.

=item --version

Write version info and exit.

=item --language

Select the language of Wikipedia that we should crawl. Currently supported
are 'de', 'en' and 'fr'. Default is 'en'.

=item --root

Set the root node where the crawl should start. Default is of course 'Xkcd'.

=item --maxdepth

The maximum depth the crawl should go. Please select small values under 10. Default is 4.

=item --maxspread

The maximum number of links we follow per article. Please select small values under 10. Default is 5.

=item --maxnodes

The maximum number of nodes we crawl. Set to -1 (default) to disable.

=back

=head1 SEE ALSO

L<http://forums.xkcd.com/viewtopic.php?f=2&t=21300&p=672184> and
L<Graph::Easy>.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the terms of the GPL.

See the LICENSE file of Graph::Easy for a copy of the GPL.

X<license>

=head1 AUTHOR

Copyright (C) 2008 by integral L<forum.xkcd.com>
Copyright (C) 2008 by Tels L<http://bloodgate.com>

=cut
