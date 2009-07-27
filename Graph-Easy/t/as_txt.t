#!/usr/bin/perl -w

use Test::More;
use strict;

BEGIN
   {
   plan tests => 4;
   chdir 't' if -d 't';
   use lib '../lib';
   use_ok ("Graph::Easy") or die($@);
   };

can_ok ("Graph::Easy", qw/
  as_txt
  /);

#############################################################################
# as_txt

use Graph::Easy::Parser;

my $parser = Graph::Easy::Parser->new();

my $graph = $parser->from_text( 
  "[A] { link: http://foo.com; color: red; origin: B; offset: 2,1; }" 
  );

is ($parser->error(), '', 'no parsing error' );
is ($graph->as_txt(), <<EOF
[ A ] { color: red; link: http://foo.com; offset: 2,1; origin: B; }

[ B ]
EOF
, 'as_txt with offset and origin');

