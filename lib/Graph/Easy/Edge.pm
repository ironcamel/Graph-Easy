#############################################################################
# An edge connecting two nodes in Graph::Easy.
#
#############################################################################

package Graph::Easy::Edge;

use Graph::Easy::Node;
@ISA = qw/Graph::Easy::Node/;		# an edge is just a special node
$VERSION = '0.31';

use strict;

use constant isa_cell => 1;

#############################################################################

sub _init
  {
  # generic init, override in subclasses
  my ($self,$args) = @_;
  
  $self->{class} = 'edge';

  # leave this unitialized until we need it
  # $self->{cells} = [ ];

  foreach my $k (keys %$args)
    {
    if ($k !~ /^(label|name|style)\z/)
      {
      require Carp;
      Carp::confess ("Invalid argument '$k' passed to Graph::Easy::Node->new()");
      }
    my $n = $k; $n = 'label' if $k eq 'name';

    $self->{att}->{$n} = $args->{$k};
    }

  $self;
  }

#############################################################################
# accessor methods

sub bidirectional
  {
  my $self = shift;
 
  if (@_ > 0)
    {
    my $old = $self->{bidirectional} || 0;
    $self->{bidirectional} = $_[0] ? 1 : 0; 

    # invalidate layout?
    $self->{graph}->{score} = undef if $old != $self->{bidirectional} && ref($self->{graph});
    }

  $self->{bidirectional};
  }

sub undirected
  {
  my $self = shift;

  if (@_ > 0)
    {
    my $old = $self->{undirected} || 0;
    $self->{undirected} = $_[0] ? 1 : 0; 

    # invalidate layout?
    $self->{graph}->{score} = undef if $old != $self->{undirected} && ref($self->{graph});
    }

  $self->{undirected};
  }

sub has_ports
  {
  my $self = shift;

  my $s_port = $self->{att}->{start} || $self->attribute('start');

  return 1 if $s_port ne '';

  my $e_port = $self->{att}->{end} || $self->attribute('end');

  return 1 if $e_port ne '';

  0;
  }

sub start_port
  {
  # return the side and portnumber if the edge has a shared source port
  # undef for none
  my $self = shift;

  my $s = $self->{att}->{start} || $self->attribute('start');
  return undef if !defined $s || $s !~ /,/;	# "south, 0" => ok, "south" => no

  return (split /\s*,\s*/, $s) if wantarray;

  $s =~ s/\s+//g;		# remove spaces to normalize "south, 0" to "south,0"
  $s;
  }

sub end_port
  {
  # return the side and portnumber if the edge has a shared source port
  # undef for none
  my $self = shift;

  my $s = $self->{att}->{end} || $self->attribute('end');
  return undef if !defined $s || $s !~ /,/;	# "south, 0" => ok, "south" => no

  return split /\s*,\s*/, $s if wantarray;

  $s =~ s/\s+//g;		# remove spaces to normalize "south, 0" to "south,0"
  $s;
  }

sub style
  {
  my $self = shift;

  $self->{att}->{style} || $self->attribute('style');
  }

sub name
  {
  # returns actually the label
  my $self = shift;

  $self->{att}->{label} || '';
  }

#############################################################################
# cell management - used by the cell-based layouter

sub _cells
  {
  # return all the cells this edge currently occupies
  my $self = shift;

  $self->{cells} = [] unless defined $self->{cells};

  @{$self->{cells}};
  }

sub _clear_cells
  { 
  # remove all belonging cells
  my $self = shift;

  $self->{cells} = [];

  $self;
  }

sub _unplace
  {
  # Take an edge, and remove all the cells it covers from the cells area
  my ($self, $cells) = @_;

  print STDERR "# clearing path from $self->{from}->{name} to $self->{to}->{name}\n" if $self->{debug};

  for my $key (@{$self->{cells}})
    {
    # XXX TODO: handle crossed edges differently (from CROSS => HOR or VER)
    # free in our cells area
    delete $cells->{$key};
    }

  $self->clear_cells();

  $self;
  }

sub _distance
  {
  # estimate the distance from SRC to DST node
  my ($self) = @_;

  my $src = $self->{from};
  my $dst = $self->{to};

  # one of them not yet placed?
  return 100000 unless defined $src->{x} && defined $dst->{x};

  my $cells = $self->{graph}->{cells};

  # get all the starting positions
  # distance = 1: slots, generate starting types, the direction is shifted
  # by 90° counter-clockwise

  my @start = $src->_near_places($cells, 1, undef, undef, $src->_shift(-90) );

  # potential stop positions
  my @stop = $dst->_near_places($cells, 1);		# distance = 1: slots

  my ($s_p,@ss_p) = $self->port('start');
  my ($e_p,@ee_p) = $self->port('end');

  # the edge has a port description, limiting the start places
  @start = $src->_allowed_places( \@start, $src->_allow( $s_p, @ss_p ), 3)
    if defined $s_p;

  # the edge has a port description, limiting the stop places
  @stop = $dst->_allowed_places( \@stop, $dst->_allow( $e_p, @ee_p ), 3)
    if defined $e_p;

  my $stop = scalar @stop;

  return 0 unless @stop > 0 && @start > 0;	# no free slots on one node?

  my $lowest;

  my $i = 0;
  while ($i < scalar @start)
    {
    my $sx = $start[$i]; my $sy = $start[$i+1]; $i += 2;

    # for each start point, calculate the distance to each stop point, then use
    # the smallest as value

    for (my $u = 0; $u < $stop; $u += 2)
      {
      my $dist = Graph::Easy::_astar_distance($sx,$sy, $stop[$u], $stop[$u+1]);
      $lowest = $dist if !defined $lowest || $dist < $lowest;
      }
    }

  $lowest;
  }

sub _add_cell
  {
  # add a cell to the list of cells this edge covers. If $after is a ref
  # to a cell, then the new cell will be inserted right after this cell.
  # if after is defined, but not a ref, the new cell will be inserted
  # at the specified position.
  my ($self, $cell, $after, $before) = @_;
 
  $self->{cells} = [] unless defined $self->{cells};
  my $cells = $self->{cells};

  # if both are defined, but belong to different edges, just ignore $before:
  $before = undef if ref($before) && $before->{edge} != $self;
  $after = undef if ref($after) && $after->{edge} != $self;
  if (!defined $after && ref($before))
    {
    $after = $before; $before = undef;
    }

  if (defined $after)
    {
    # insert the new cell right after $after
    my $ofs = $after;
    if (ref($after) && !ref($before))
      {
      # insert after $after
      $ofs = 1;
      for my $cell (@$cells)
        {
        last if $cell == $after;
        $ofs++; 
        }
      }
    elsif (ref($after) && ref($before))
      {
      # insert between after and before (or before/after for "reversed edges)
      $ofs = 0;
      my $found = 0;
      while ($ofs < scalar @$cells - 1)		# 0,1,2,3 => 0 .. 2
        {
        my $c1 = $cells->[$ofs];
        my $c2 = $cells->[$ofs+1];
	$ofs++;
        $found++, last if (($c1 == $after && $c2 == $before) ||
                 ($c1 == $before && $c2 == $after));
        }
      if (!$found)
	{
        # XXX TODO: last effort

        # insert after $after
        $ofs = 1;
        for my $cell (@$cells)
          {
          last if $cell == $after;
          $ofs++; 
          }
        $found++;
	}
      $self->_croak("Could not find $after and $before") unless $found;
      }
    splice (@$cells, $ofs, 0, $cell);
    } 
  else
    {
    # insert new cell at the end
    push @$cells, $cell;
    }

  $cell->_update_boundaries();

  $self;
  }

#############################################################################

sub from
  {
  my $self = shift;

  $self->{from};
  }

sub to
  {
  my $self = shift;

  $self->{to};
  }

sub nodes
  {
  my $self = shift;

  ($self->{from}, $self->{to});
  }

sub start_at
  {
  # move the edge's start point from the current node to the given node
  my ($self, $node) = @_;

  # if not a node yet, or not part of this graph, make into one proper node
  $node = $self->{graph}->add_node($node);

  $self->_croak("start_at() needs a node object, but got $node")
    unless ref($node) && $node->isa('Graph::Easy::Node');

  # A => A => nothing to do
  return $node if $self->{from} == $node;

  # delete self at A
  delete $self->{from}->{edges}->{ $self->{id} };

  # set "from" to B
  $self->{from} = $node;

  # add to B
  $self->{from}->{edges}->{ $self->{id} } = $self;

  # invalidate layout
  $self->{graph}->{score} = undef if ref($self->{graph});

  # return new start point
  $node;
  }

sub end_at
  {
  # move the edge's end point from the current node to the given node
  my ($self, $node) = @_;

  # if not a node yet, or not part of this graph, make into one proper node
  $node = $self->{graph}->add_node($node);

  $self->_croak("start_at() needs a node object, but got $node")
    unless ref($node) && $node->isa('Graph::Easy::Node');

  # A => A => nothing to do
  return $node if $self->{to} == $node;

  # delete self at A
  delete $self->{to}->{edges}->{ $self->{id} };

  # set "to" to B
  $self->{to} = $node;

  # add to node B
  $self->{to}->{edges}->{ $self->{id} } = $self;

  # invalidate layout
  $self->{graph}->{score} = undef if ref($self->{graph});

  # return new end point
  $node;
  }

sub edge_flow
  {
  # return the flow at this edge  or '' if the edge itself doesn't have a flow
  my $self = shift;

  # our flow comes from ourselves
  my $flow = $self->{att}->{flow};
  $flow = $self->raw_attribute('flow') unless defined $flow;

  $flow;
  }

sub flow
  {
  # return the flow at this edge (including inheriting flow from node)
  my ($self) = @_;

  # print STDERR "# flow from $self->{from}->{name} to $self->{to}->{name}\n";

  # our flow comes from ourselves
  my $flow = $self->{att}->{flow};
  # or maybe our class
  $flow = $self->raw_attribute('flow') unless defined $flow;

  # if the edge doesn't have a flow, maybe the node has a default out flow
  $flow = $self->{from}->{att}->{flow} if !defined $flow;

  # if that didn't work out either, use the parents flows
  $flow = $self->parent()->attribute('flow') if !defined $flow; 
  # or finally, the default "east":
  $flow = 90 if !defined $flow;

  # absolute flow does not depend on the in-flow, so can return early
  return $flow if $flow =~ /^(0|90|180|270)\z/;

  # in-flow comes from our "from" node
  my $in = $self->{from}->flow();

# print STDERR "# in: $self->{from}->{name} = $in\n";

  my $out = $self->{graph}->_flow_as_direction($in,$flow);
  $out;
  }

sub port
  {
  my ($self, $which) = @_;

  $self->_croak("'$which' must be one of 'start' or 'end' in port()") unless $which =~ /^(start|end)/;

  # our flow comes from ourselves
  my $sp = $self->attribute($which); 

  return (undef,undef) unless defined $sp && $sp ne '';

  my ($side, $port) = split /\s*,\s*/, $sp;

  # if absolut direction, return as is
  my $s = Graph::Easy->_direction_as_side($side);

  if (defined $s)
    {
    my @rc = ($s); push @rc, $port if defined $port;
    return @rc;
    }

  # in_flow comes from our "from" node
  my $in = 90; $in = $self->{from}->flow() if ref($self->{from});

  # turn left in "south" etc:
  $s = Graph::Easy->_flow_as_side($in,$side);

  my @rc = ($s); push @rc, $port if defined $port;
  @rc;
  }

sub flip
  {
  # swap from and to for this edge
  my ($self) = @_;

  ($self->{from}, $self->{to}) = ($self->{to}, $self->{from});

  # invalidate layout
  $self->{graph}->{score} = undef if ref($self->{graph});

  $self;
  }

sub as_ascii
  {
  my ($self, $x,$y) = @_;

  # invisible nodes, or very small ones
  return '' if $self->{w} == 0 || $self->{h} == 0;

  my $fb = $self->_framebuffer($self->{w}, $self->{h});

  ###########################################################################
  # "draw" the label into the framebuffer (e.g. the edge and the text)
  $self->_draw_label($fb, $x, $y, '');

  join ("\n", @$fb);
  }

sub as_txt
  {
  require Graph::Easy::As_ascii;

  _as_txt(@_);
  }

1;
__END__

=head1 NAME

Graph::Easy::Edge - An edge (a path connecting one ore more nodes)

=head1 SYNOPSIS

        use Graph::Easy;

	my $ssl = Graph::Easy::Edge->new(
		label => 'encrypted connection',
		style => 'solid',
	);
	$ssl->set_attribute('color', 'red');

	my $src = Graph::Easy::Node->new('source');

	my $dst = Graph::Easy::Node->new('destination');

	$graph = Graph::Easy->new();

	$graph->add_edge($src, $dst, $ssl);

	print $graph->as_ascii();

=head1 DESCRIPTION

A C<Graph::Easy::Edge> represents an edge between two (or more) nodes in a
simple graph.

Each edge has a direction (from source to destination, or back and forth),
plus a style (line width and style), colors etc. It can also have a label,
e.g. a text associated with it.

During the layout phase, each edge also contains a list of path-elements
(also called cells), which make up the path from source to destination.

=head1 METHODS

=head2 error()

	$last_error = $edge->error();

	$cvt->error($error);			# set new messags
	$cvt->error('');			# clear error

Returns the last error message, or '' for no error.

=head2 as_ascii()

	my $ascii = $edge->as_ascii();

Returns the edge as a little ascii representation.

=head2 as_txt()

	my $txt = $edge->as_txt();

Returns the edge as a little Graph::Easy textual representation.

=head2 label()

	my $label = $edge->label();

Returns the label (also known as 'name') of the edge.

=head2 name()

	my $label = $edge->name();

To make the interface more consistent, the C<name()> method of
an edge can also be called, and it will returned either the edge
label, or the empty string if the edge doesn't have a label.

=head2 style()

	my $style = $edge->style();

Returns the style of the edge, like 'solid', 'dotted', 'double', etc.

=head2 nodes()

	my @nodes = $edge->nodes();

Returns the source and target node that this edges connects as objects.

=head2 bidirectional()

	$edge->bidirectional(1);
	if ($edge->bidirectional())
	  {
	  }

Returns true if the edge is bidirectional, aka has arrow heads on both ends.
An optional parameter will set the bidirectional status of the edge.

=head2 undirected()

	$edge->undirected(1);
	if ($edge->undirected())
	  {
	  }

Returns true if the edge is undirected, aka has now arrow at all.
An optional parameter will set the undirected status of the edge.

=head2 has_ports()

	if ($edge->has_ports())
	  {
	  ...
	  }

Return true if the edge has restriction on the starting or ending
port, e.g. either the C<start> or C<end> attribute is set on
this edge. 

=head2 start_port()

	my $port = $edge->start_port();

Return undef if the edge does not have a fixed start port, otherwise
returns the port as "side, number", for example "south, 0".

=head2 end_port()

	my $port = $edge->end_port();

Return undef if the edge does not have a fixed end port, otherwise
returns the port as "side, number", for example "south, 0".

=head2 from()

	my $from = $edge->from();

Returns the node that this edge starts at. See also C<to()>.

=head2 to()

	my $to = $edge->to();

Returns the node that this edge leads to. See also C<from()>.

=head2 start_at()

	$edge->start_at($other);
	my $other = $edge->start_at('some node');

Set the edge's start point to the given node. If given a node name,
will add that node to the graph first.

Returns the new edge start point node.

=head2 end_at()

	$edge->end_at($other);
	my $other = $edge->end_at('some other node');

Set the edge's end point to the given node. If given a node name,
will add that node to the graph first.

Returns the new edge end point node.

=head2 flip()

	$edge->flip();

Swaps the C<start> and C<end> nodes on this edge, e.g. reverses the direction
of the edge.

X<transpose>

=head2 flow()

	my $flow = $edge->flow();

Returns the flow for this edge, honoring inheritance. An edge without
a specific flow set will inherit the flow from the node it comes from.

=head2 edge_flow()

	my $flow = $edge->edge_flow();

Returns the flow for this edge, or undef if it has none set on either
the object itself or its class.

=head2 port()

	my ($side, $number) = $edge->port('start');
	my ($side, $number) = $edge->port('end');

Return the side and port number where this edge starts or ends.

Returns undef for $side if the edge has no port restriction. The
returned side will be one absolute direction of C<east>, C<west>,
C<north> or C<south>, depending on the port restriction and
flow at that edge.

=head2 get_attributes()

        my $att = $object->get_attributes();

Return all effective attributes on this object (graph/node/group/edge) as
an anonymous hash ref. This respects inheritance and default values.

See also L<raw_attributes()>.

=head2 raw_attributes()

        my $att = $object->get_attributes();

Return all set attributes on this object (graph/node/group/edge) as
an anonymous hash ref. This respects inheritance, but does not include
default values for unset attributes.

See also L<get_attributes()>.

=head2 attribute related methods

You can call all the various attribute related methods like C<set_attribute()>,
C<get_attribute()>, etc. on an edge, too. For example:

	$edge->set_attribute('label', 'by train');
	my $attr = $edge->get_attributes();
	my $raw_attr = $edge->raw_attributes();

You can find more documentation in L<Graph::Easy>.

=head1 EXPORT

None by default.

=head1 SEE ALSO

L<Graph::Easy>.

=head1 AUTHOR

Copyright (C) 2004 - 2008 by Tels L<http://bloodgate.com>.

See the LICENSE file for more details.

=cut
