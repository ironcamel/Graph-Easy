#!/usr/bin/perl -w

use Test::More;
use strict;

BEGIN
   {
   plan tests => 6;
   chdir 't' if -d 't';
   use lib '../lib';
   use_ok ("Graph::Easy::Base") or die($@);
   };

can_ok ("Graph::Easy::Base", qw/
  new error error_as_html
  _init
  self
  class
  sub_class
  main_class
  fatal_errors
  no_fatal_errors
  /);

#############################################################################
# Base tests

my $base = Graph::Easy::Base->new();

is (ref($base), 'Graph::Easy::Base', 'new seemed to work');
is ($base->error(), '', 'no error yet');

$base->{class} = 'group.test';

is ($base->main_class(), 'group', 'main_class works');
is ($base->error(), '', 'no error yet');

