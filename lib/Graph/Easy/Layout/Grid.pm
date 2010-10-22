#############################################################################
# Grid-management and layout preperation.
#
# (c) by Tels 2004-2006.
#############################################################################

package Graph::Easy::Layout::Grid;

$VERSION = '0.07';

#############################################################################
#############################################################################

package Graph::Easy;

use strict;

sub _balance_sizes
  {
  # Given a list of column/row sizes and a minimum size that their sum must
  # be, will grow individual sizes until the constraint (sum) is met.
  my ($self, $sizes, $need) = @_;

  # XXX TODO: we can abort the loop and distribute the remaining nec. size
  # once all elements in $sizes are equal.

  return if $need < 1;

  # if there is only one element, return it immidiately
  if (@$sizes == 1)
    {
    $sizes->[0] = $need if $sizes->[0] < $need;
    return;
    }

  # endless loop until constraint is met
  while (1)
    {
  
    # find the smallest size, and also compute their sum
    my $sum = 0; my $i = 0;
    my $sm = $need + 1;		# start with an arbitrary size
    my $sm_i = 0;		# if none is != 0, then use the first
    for my $s (@$sizes)
      {
      $sum += $s;
      next if $s == 0;
      if ($s < $sm)
	{
        $sm = $s; $sm_i = $i; 
	}
      $i++;
      }

    # their sum is already equal or bigger than what we need?
    last if $sum >= $need;

    # increase the smallest size by one, then try again
    $sizes->[$sm_i]++;
    }
 
#  use Data::Dumper; print STDERR "# " . Dumper($sizes),"\n";

  undef;
  }

sub _prepare_layout
  {
  # this method is used by as_ascii() and as_svg() to find out the
  # sizes and placement of the different cells (edges, nodes etc).
  my ($self,$format) = @_;

  # Find out for each row and colum how big they are:
  #   +--------+-----+------+
  #   | Berlin | --> | Bonn | 
  #   +--------+-----+------+
  # results in:
  #        w,  h,  x,  y
  # 0,0 => 10, 3,  0,  0
  # 1,0 => 7,  3,  10, 0
  # 2,0 => 8,  3,  16, 0

  # Technically, we also need to "compress" away non-existant columns/rows.
  # We achive that by simply rendering them with size 0, so they become
  # practically invisible.

  my $cells = $self->{cells};
  my $rows = {};
  my $cols = {};

  # the last column/row (highest X,Y pair)
  my $mx = -1000000; my $my = -1000000;

  # We need to do this twice, once for single-cell objects, and again for
  # objects covering multiple cells. The single-cell objects can be solved
  # first:

  # find all x and y occurances to sort them by row/columns
  for my $cell (values %$cells)
    {
    my ($x,$y) = ($cell->{x}, $cell->{y});

    {
      no strict 'refs';

      my $method = '_correct_size_' . $format;
      $method = '_correct_size' unless $cell->can($method);
      $cell->$method();
    }

    my $w = $cell->{w} || 0;
    my $h = $cell->{h} || 0;

    # Set the minimum cell size only for single-celled objects:
    if ( (($cell->{cx}||1) + ($cell->{cy}||1)) == 2)
      { 
      # record maximum size for that col/row
      $rows->{$y} = $h if $h >= ($rows->{$y} || 0);
      $cols->{$x} = $w if $w >= ($cols->{$x} || 0);
      }

    # Find highest X,Y pair. Always use x,y, and not x+cx,y+cy, because
    # a multi-celled object "sticking" out will not count unless there
    # is another object in the same row/column.
    $mx = $x if $x > $mx;
    $my = $y if $y > $my;
    } 

  # insert a dummy row/column with size=0 as last
  $rows->{$my+1} = 0;
  $cols->{$mx+1} = 0;

  # do the last step again, but for multi-celled objects
  for my $cell (values %$cells)
    {
    my ($x,$y) = ($cell->{x}, $cell->{y});

    my $w = $cell->{w} || 0;
    my $h = $cell->{h} || 0;

    # Set the minimum cell size only for multi-celled objects:
    if ( (($cell->{cx} || 1) + ($cell->{cy}||1)) > 2)
      {
      $cell->{cx} ||= 1;
      $cell->{cy} ||= 1;

      # do this twice, for X and Y:

#      print STDERR "\n# ", $cell->{name} || $cell->{id}, " cx=$cell->{cx} cy=$cell->{cy} $cell->{w},$cell->{h}:\n";

      # create an array with the current sizes for the affacted rows/columns
      my @sizes;

#      print STDERR "# $cell->{cx} $cell->{cy} at cx:\n";

      # XXX TODO: no need to do this for empty/zero cols
      for (my $i = 0; $i < $cell->{cx}; $i++)
        {
        push @sizes, $cols->{$i+$x} || 0;
	}
      $self->_balance_sizes(\@sizes, $cell->{w});
      # store the result back
      for (my $i = 0; $i < $cell->{cx}; $i++)
        {
#        print STDERR "# store back $sizes[$i] to col ", $i+$x,"\n";
        $cols->{$i+$x} = $sizes[$i];
	}

      @sizes = ();

#      print STDERR "# $cell->{cx} $cell->{cy} at cy:\n";

      # XXX TODO: no need to do this for empty/zero cols
      for (my $i = 0; $i < $cell->{cy}; $i++)
        {
        push @sizes, $rows->{$i+$y} || 0;
	}
      $self->_balance_sizes(\@sizes, $cell->{h});
      # store the result back
      for (my $i = 0; $i < $cell->{cy}; $i++)
        {
#        print STDERR "# store back $sizes[$i] to row ", $i+$y,"\n";
        $rows->{$i+$y} = $sizes[$i];
	}
      }
    } 

  print STDERR "# Calculating absolute positions for rows/columns\n" if $self->{debug};

  # Now run through all rows/columns and get their absolute pos by taking all
  # previous ones into account.
  my $pos = 0;
  for my $y (sort { $a <=> $b } keys %$rows)
    {
    my $s = $rows->{$y};
    $rows->{$y} = $pos;			# first is 0, second is $rows[1] etc
    $pos += $s;
    }
  $pos = 0;
  for my $x (sort { $a <=> $b } keys %$cols)
    {
    my $s = $cols->{$x};
    $cols->{$x} = $pos;
    $pos += $s;
    }

  # find out max. dimensions for framebuffer
  print STDERR "# Finding max. dimensions for framebuffer\n" if $self->{debug};
  my $max_y = 0; my $max_x = 0;

  for my $v (values %$cells)
    {
    # Skip multi-celled nodes for later. 
    next if ($v->{cx}||1) + ($v->{cy}||1) != 2;

    # X and Y are col/row, so translate them to real pos
    my $x = $cols->{ $v->{x} };
    my $y = $rows->{ $v->{y} };

    # Also set correct the width/height of each cell to be the maximum
    # width/height of that row/column and store the previous size in 'minw'
    # and 'minh', respectively.

    $v->{minw} = $v->{w};
    $v->{minh} = $v->{h};

    # find next col/row
    my $nx = $v->{x} + 1;
    my $next_col = $cols->{ $nx };
    my $ny = $v->{y} + 1;
    my $next_row = $rows->{ $ny };

    $next_col = $cols->{ ++$nx } while (!defined $next_col);
    $next_row = $rows->{ ++$ny } while (!defined $next_row);

    $v->{w} = $next_col - $x;
    $v->{h} = $next_row - $y;

    my $m = $y + $v->{h} - 1;
    $max_y = $m if $m > $max_y;
    $m = $x + $v->{w} - 1;
    $max_x = $m if $m > $max_x;
    }

  # repeat the previous step, now for multi-celled objects
  foreach my $v (values %{$self->{cells}})
    {
    next unless defined $v->{x} && (($v->{cx}||1) + ($v->{cy}||1) > 2);

    # X and Y are col/row, so translate them to real pos
    my $x = $cols->{ $v->{x} };
    my $y = $rows->{ $v->{y} };

    $v->{minw} = $v->{w};
    $v->{minh} = $v->{h};

    # find next col/row
    my $nx = $v->{x} + ($v->{cx} || 1);
    my $next_col = $cols->{ $nx };
    my $ny = $v->{y} + ($v->{cy} || 1);
    my $next_row = $rows->{ $ny };

    $next_col = $cols->{ ++$nx } while (!defined $next_col);
    $next_row = $rows->{ ++$ny } while (!defined $next_row);

    $v->{w} = $next_col - $x;
    $v->{h} = $next_row - $y;

    my $m = $y + $v->{h} - 1;
    $max_y = $m if $m > $max_y;
    $m = $x + $v->{w} - 1;
    $max_x = $m if $m > $max_x;
    }

  # return what we found out:
  ($rows,$cols,$max_x,$max_y);
  }

1;
__END__

=head1 NAME

Graph::Easy::Layout::Grid - Grid management and size calculation

=head1 SYNOPSIS

	use Graph::Easy;
	
	my $graph = Graph::Easy->new();

	my $bonn = Graph::Easy::Node->new(
		name => 'Bonn',
	);
	my $berlin = Graph::Easy::Node->new(
		name => 'Berlin',
	);

	$graph->add_edge ($bonn, $berlin);

	$graph->layout();

	print $graph->as_ascii( );

	# prints:

	# +------+     +--------+
	# | Bonn | --> | Berlin |
	# +------+     +--------+

=head1 DESCRIPTION

C<Graph::Easy::Layout::Grid> contains routines that calculate cell sizes
on the grid, which is necessary for ASCII, boxart and SVG output.

Used automatically by Graph::Easy.

=head1 EXPORT

Exports nothing.

=head1 SEE ALSO

L<Graph::Easy>.

=head1 METHODS

This module injects the following methods into Graph::Easy:

=head2 _prepare_layout()

  	my ($rows,$cols,$max_x,$max_y, \@V) = $graph->_prepare_layout();

Returns two hashes (C<$rows> and C<$cols>), containing the columns and rows
of the layout with their nec. sizes (in chars) plus the maximum
framebuffer size nec. for this layout. Also returns reference of
a list of all cells to be rendered.

=head1 AUTHOR

Copyright (C) 2004 - 2006 by Tels L<http://bloodgate.com>.

See the LICENSE file for information.

=cut
