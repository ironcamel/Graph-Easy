#!/usr/bin/perl -w

use Test::More;
use strict;

# test catching of error and warnings:

BEGIN
   {
   plan tests => 10;
   chdir 't' if -d 't';
   use lib '../lib';
   use_ok ("Graph::Easy") or die($@);
   };

can_ok ("Graph::Easy", qw/
  catch_messages
  catch_errors
  catch_warnings
  errors
  warnings
  /);

#############################################################################
# adding edges/nodes

my $graph = Graph::Easy->new();

is (ref($graph), 'Graph::Easy');
is ($graph->error(), '', 'no error yet');

$graph->catch_messages(1);

$graph->error('foo');

my @errors = $graph->errors();
my @warnings = $graph->warnings();

is (scalar @errors, 1, '1 error');
is (scalar @warnings, 0, '0 warnings');

is ($errors[0], 'foo', '1 error');

$graph->warn('Bar');

@errors = $graph->errors();
@warnings = $graph->warnings();

is (scalar @errors, 1, '1 error');
is (scalar @warnings, 1, '1 warning');

is ($warnings[0], 'Bar', '1 warning');

1; # all tests done

