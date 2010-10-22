#############################################################################
# Force-based layouter for Graph::Easy.
#
# (c) by Tels 2004-2007.
#############################################################################

package Graph::Easy::Layout::Force;

$VERSION = '0.01';

#############################################################################
#############################################################################

package Graph::Easy;

use strict;

sub _layout_force
  {
  # Calculate for each node the force on it, then move them accordingly.
  # When things have settled, stop.
  my ($self) = @_;

  # For each node, calculate the force actiing on it, seperated into two
  # components along the X and Y axis:

  # XXX TODO: replace with all contained nodes + groups
  my @nodes = $self->nodes();

  return if @nodes == 0;

  my $root = $self->root_node();

  if (!defined $root)
    {
    # find a suitable root node
    $root = $nodes[0];
    }

  # this node never moves
  $root->{_pinned} = undef;
  $root->{x} = 0;
  $root->{y} = 0;

  # get the "gravity" force
  my $gx = 0; my $gy = 0;

  my $flow = $self->flow();
  if ($flow == 0)
    {
    $gx = 1;
    }
  elsif ($flow == 90)
    {
    $gy = -1;
    }
  elsif ($flow == 270)
    {
    $gy = 1;
    }
  else # ($flow == 180)
    {
    $gx = -1;
    }

  my @particles;
  # set initial positions
  for my $n (@nodes)
    {
    # the net force on this node is the gravity
    $n->{_x_force} = $gx;
    $n->{_y_force} = $gy;
    if ($root == $n || defined $n->{origin})
      {
      # nodes that are relative to another are "pinned"
      $n->{_pinned} = undef;
      }
    else
      {
      $n->{x} = rand(100);
      $n->{y} = rand(100);
      push @particles, $n;
      }
    }

  my $energy = 1;
  while ($energy > 0.1)
    {
    $energy = 0;
    for my $n (@particles)
      {
      # reset forces on this node
      $n->{_x_force} = 0;
      $n->{_y_force} = 0;

      # Add forces of all other nodes. We need to include pinned nodes here,
      # too, since a moving node might get near a pinned one and get repelled.
      for my $n2 (@nodes)
        {
        next if $n2 == $n;			# don't repel yourself

	my $dx = ($n->{x} - $n2->{x});
	my $dy = ($n->{y} - $n2->{y});

	my $r = $dx * $dx + $dy * $dy;

	$r = 0.01 if $r < 0.01;			# too small? 
	if ($r < 4)
	  {
	  # not too big
	  $n->{_x_force} += 1 / $dx * $dx;
	  $n->{_y_force} += 1 / $dy * $dy;

	  my $dx2 = 1 / $dx * $dx;
	  my $dy2 = 1 / $dy * $dy;

	  print STDERR "# Force between $n->{name} and $n2->{name}: fx $dx2, fy $dy2\n";
	  }
        }

      # for all edges connected at this node
      for my $e (values %{$n->{edges}})
	{
	# exclude self-loops
	next if $e->{from} == $n && $e->{to} == $n;

	# get the other end-point of this edge
	my $n2 = $e->{from}; $n2 = $e->{to} if $n2 == $n;

	# XXX TODO
	# we should "connect" the edges to the appropriate port so that
	# they excert an off-center force

	my $dx = -($n->{x} - $n2->{x}) / 2;
	my $dy = -($n->{y} - $n2->{y}) / 2;

	print STDERR "# Spring force between $n->{name} and $n2->{name}: fx $dx, fy $dy\n";
	$n->{_x_force} += $dx; 
	$n->{_y_force} += $dy;
	}

      print STDERR "# $n->{name}: Summed force: fx $n->{_x_force}, fy $n->{_y_force}\n";

      # for grid-like layouts, add a small force drawing this node to the gridpoint
      # 0.7 => 1 - 0.7 => 0.3
      # 1.2 => 1 - 1.2 => -0.2

      my $dx = int($n->{x} + 0.5) - $n->{x};
      $n->{_x_force} += $dx;
      my $dy = int($n->{y} + 0.5) - $n->{y};
      $n->{_y_force} += $dy;

      print STDERR "# $n->{name}: Final force: fx $n->{_x_force}, fy $n->{_y_force}\n";

      $energy += $n->{_x_force} * $n->{_x_force} + $n->{_x_force} * $n->{_y_force}; 

      print STDERR "# Net energy: $energy\n";
      }

    # after having calculated all forces, move the nodes
    for my $n (@particles)
      {
      my $dx = $n->{_x_force};
      $dx = 5 if $dx > 5;		# limit it
      $n->{x} += $dx;

      my $dy = $n->{_y_force};
      $dy = 5 if $dy > 5;		# limit it
      $n->{y} += $dy;

      print STDERR "# $n->{name}: Position $n->{x}, $n->{y}\n";
      }

    sleep(1); print STDERR "\n";
    }

  for my $n (@nodes)
    {
    delete $n->{_x_force};
    delete $n->{_y_force};
    }
  $self;
  }

1;
__END__

=head1 NAME

Graph::Easy::Layout::Force - Force-based layouter for Graph::Easy

=head1 SYNOPSIS

	use Graph::Easy;
	
	my $graph = Graph::Easy->new();

	$graph->add_edge ('Bonn', 'Berlin');
	$graph->add_edge ('Bonn', 'Ulm');
	$graph->add_edge ('Ulm', 'Berlin');

	$graph->layout( type => 'force' );

	print $graph->as_ascii( );

	# prints:
	
	#   +------------------------+
	#   |                        v
	# +------+     +-----+     +--------+
	# | Bonn | --> | Ulm | --> | Berlin |
	# +------+     +-----+     +--------+

=head1 DESCRIPTION

C<Graph::Easy::Layout::Force> contains routines that calculate a
force-based layout for a graph.

Nodes repell each other, while edges connecting them draw them together.

The layouter calculates the forces on each node, then moves them around
according to these forces until things have settled down.

Used automatically by Graph::Easy.

=head1 EXPORT

Exports nothing.

=head1 SEE ALSO

L<Graph::Easy>.

=head1 METHODS

This module injects the following methods into Graph::Easy:

=head2 _layout_force()

Calculates the node position with a force-based method.

=head1 AUTHOR

Copyright (C) 2004 - 2007 by Tels L<http://bloodgate.com>.

See the LICENSE file for information.

=cut
