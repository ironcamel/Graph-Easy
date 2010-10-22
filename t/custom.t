#!/usr/bin/perl -w

# Test the custom attributes.

use Test::More;
use strict;

BEGIN
   {
   plan tests => (4*4+4) * 6 + (8+2) * 4 + 3;
   chdir 't' if -d 't';
   use lib '../lib';
   use_ok ("Graph::Easy::Attributes") or die($@);
   use_ok ("Graph::Easy") or die($@);
   };

can_ok ("Graph::Easy", qw/
  valid_attribute
  /);

#############################################################################
# valid_attribute:

my $att = Graph::Easy->new();

$att->no_fatal_errors(1);

for my $n (qw/ foo-bar bar-foo b-f-a boo-f-bar bar b-f /)
  {
  my $new_value = $att->valid_attribute( "x-$n", 'furble, barble' );
  is ($new_value, "furble, barble", "x-$n is valid");

  my @new_value = $att->validate_attribute( "x-$n", 'furble, barble' );
  is ($new_value[0], undef, "x-$n is valid");
  is ($new_value[1], "x-$n", "x-$n is valid");
  is ($new_value[2], "furble, barble", "x-$n is valid");

  for my $class (qw/ graph group node edge /)
   {
    my $new_value = $att->valid_attribute( "x-$n", 'furble, barble', $class );
    is ($new_value, "furble, barble", "x-$n is valid in class $class");

    my @new_value = $att->validate_attribute( "x-$n", 'furble, barble', $class );
    is ($new_value[0], undef, "x-$n is valid in class $class");
    is ($new_value[1], "x-$n", "x-$n is valid");
    is ($new_value[2], "furble, barble", "x-$n is valid in class $class");
    }

  }

for my $n (qw/ -foo-bar bar-foo- b--a -boo-f-bar- /)
  {
  my $new_value = $att->valid_attribute( "x-$n", 'furble, barble' );
  is (ref($new_value), 'ARRAY', "x-$n is not valid");

  my @new_value = $att->validate_attribute( "x-$n", 'furble, barble' );
  is ($new_value[0], 1, "x-$n is not valid");

  for my $class (qw/ graph group node edge /)
    {
    my $new_value = $att->valid_attribute( "x-$n", 'furble, barble', $class );
    is (ref($new_value), 'ARRAY', "x-$n is not valid in class $class");

    my @new_value = $att->validate_attribute( "x-$n", 'furble, barble', $class );
    is ($new_value[0], 1, "x-$n is not valid in class $class");
    }
  }

1;
