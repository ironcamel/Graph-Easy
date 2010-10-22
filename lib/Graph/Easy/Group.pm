#############################################################################
# A group of nodes. Part of Graph::Easy.
#
#############################################################################

package Graph::Easy::Group;

use Graph::Easy::Group::Cell;
use Graph::Easy;
use Scalar::Util qw/weaken/;

@ISA = qw/Graph::Easy::Node Graph::Easy/;
$VERSION = '0.22';

use strict;

#############################################################################

sub _init
  {
  # generic init, override in subclasses
  my ($self,$args) = @_;
  
  $self->{name} = 'Group #'. $self->{id};
  $self->{class} = 'group';
  $self->{_cells} = {};				# the Group::Cell objects
#  $self->{cx} = 1;
#  $self->{cy} = 1;

  foreach my $k (keys %$args)
    {
    if ($k !~ /^(graph|name)\z/)
      {
      require Carp;
      Carp::confess ("Invalid argument '$k' passed to Graph::Easy::Group->new()");
      }
    $self->{$k} = $args->{$k};
    }
  
  $self->{nodes} = {};
  $self->{groups} = {};
  $self->{att} = {};

  $self;
  }

#############################################################################
# accessor methods

sub nodes
  {
  my $self = shift;

  wantarray ? ( values %{$self->{nodes}} ) : scalar keys %{$self->{nodes}};
  }

sub edges
  {
  # edges leading from/to this group
  my $self = shift;

  wantarray ? ( values %{$self->{edges}} ) : scalar keys %{$self->{edges}};
  }

sub edges_within
  {
  # edges between nodes inside this group
  my $self = shift;

  wantarray ? ( values %{$self->{edges_within}} ) : 
		scalar keys %{$self->{edges_within}};
  }

sub _groups_within
  {
  my ($self, $level, $max_level, $cur) = @_;

  no warnings 'recursion';

  push @$cur, values %{$self->{groups}};

  return if $level >= $max_level;

  for my $g (values %{$self->{groups}})
    {
    $g->_groups_within($level+1,$max_level, $cur) if scalar keys %{$g->{groups}} > 0;
    }
  }

#############################################################################

sub set_attribute
  {
  my ($self, $name, $val, $class) = @_;

  $self->SUPER::set_attribute($name, $val, $class);

  # if defined attribute "nodeclass", put our nodes into that class
  if ($name eq 'nodeclass')
    {
    my $class = $self->{att}->{nodeclass};
    for my $node (values %{ $self->{nodes} } )
      {
      $node->sub_class($class);
      }
    }
  $self;
  }

sub shape
  {
  my ($self) = @_;

  # $self->{att}->{shape} || $self->attribute('shape');
  '';
  }

#############################################################################
# node handling

sub add_node
  {
  # add a node to this group
  my ($self,$n) = @_;

  if (!ref($n) || !$n->isa("Graph::Easy::Node"))
    {
    if (!ref($self->{graph}))
      {
      return $self->error("Cannot add non node-object $n to group '$self->{name}'");
      }
    $n = $self->{graph}->add_node($n);
    }
  $self->{nodes}->{ $n->{name} } = $n;

  # if defined attribute "nodeclass", put our nodes into that class
  $n->sub_class($self->{att}->{nodeclass}) if exists $self->{att}->{nodeclass};

  # register ourselves with the member
  $n->{group} = $self;

  # set the proper attribute (for layout)
  $n->{att}->{group} = $self->{name};

  # Register the nodes and the edge with our graph object
  # and weaken the references. Be carefull to not needlessly
  # override and weaken again an already existing reference, this
  # is an O(N) operation in most Perl versions, and thus very slow.

  # If the node does not belong to a graph yet or belongs to another
  # graph, add it to our own graph:
  weaken($n->{graph} = $self->{graph}) unless
	$n->{graph} && $self->{graph} && $n->{graph} == $self->{graph};

  $n;
  }

sub add_member
  {
  # add a node or group to this group
  my ($self,$n) = @_;
 
  if (!ref($n) || !$n->isa("Graph::Easy::Node"))
    {
    if (!ref($self->{graph}))
      {
      return $self->error("Cannot add non node-object $n to group '$self->{name}'");
      }
    $n = $self->{graph}->add_node($n);
    }
  return $self->_add_edge($n) if $n->isa("Graph::Easy::Edge");
  return $self->add_group($n) if $n->isa('Graph::Easy::Group');

  $self->{nodes}->{ $n->{name} } = $n;

  # if defined attribute "nodeclass", put our nodes into that class
  my $cl = $self->attribute('nodeclass');
  $n->sub_class($cl) if $cl ne '';

  # register ourselves with the member
  $n->{group} = $self;

  # set the proper attribute (for layout)
  $n->{att}->{group} = $self->{name};

  # Register the nodes and the edge with our graph object
  # and weaken the references. Be carefull to not needlessly
  # override and weaken again an already existing reference, this
  # is an O(N) operation in most Perl versions, and thus very slow.

  # If the node does not belong to a graph yet or belongs to another
  # graph, add it to our own graph:
  weaken($n->{graph} = $self->{graph}) unless
	$n->{graph} && $self->{graph} && $n->{graph} == $self->{graph};

  $n;
  }

sub del_member
  {
  # delete a node or group from this group
  my ($self,$n) = @_;

  # XXX TOOD: groups vs. nodes
  my $class = 'nodes'; my $key = 'name';
  if ($n->isa('Graph::Easy::Group'))
    {
    # XXX TOOD: groups vs. nodes
    $class = 'groups'; $key = 'id';
    }
  delete $self->{$class}->{ $n->{$key} };
  delete $n->{group};			# unregister us

  if ($n->isa('Graph::Easy::Node'))
    {
    # find all edges that mention this node and drop them from the group
    my $edges = $self->{edges_within};
    for my $e (values %$edges)
      {
      delete $edges->{ $e->{id} } if $e->{from} == $n || $e->{to} == $n;
      }
    }

  $self;
  }

sub del_node
  {
  # delete a node from this group
  my ($self,$n) = @_;

  delete $self->{nodes}->{ $n->{name} };
  delete $n->{group};			# unregister us
  delete $n->{att}->{group};		# delete the group attribute

  # find all edges that mention this node and drop them from the group
  my $edges = $self->{edges_within};
  for my $e (values %$edges)
    {
    delete $edges->{ $e->{id} } if $e->{from} == $n || $e->{to} == $n;
    }

  $self;
  }

sub add_nodes
  {
  my $self = shift;

  # make a copy in case of scalars
  my @arg = @_;
  foreach my $n (@arg)
    {
    if (!ref($n) && !ref($self->{graph}))
      {
      return $self->error("Cannot add non node-object $n to group '$self->{name}'");
      }
    return $self->error("Cannot add group-object $n to group '$self->{name}'")
      if $n->isa('Graph::Easy::Group');

    $n = $self->{graph}->add_node($n) unless ref($n);

    $self->{nodes}->{ $n->{name} } = $n;

    # set the proper attribute (for layout)
    $n->{att}->{group} = $self->{name};

#   XXX TODO TEST!
#    # if defined attribute "nodeclass", put our nodes into that class
#    $n->sub_class($self->{att}->{nodeclass}) if exists $self->{att}->{nodeclass};

    # register ourselves with the member
    $n->{group} = $self;

    # Register the nodes and the edge with our graph object
    # and weaken the references. Be carefull to not needlessly
    # override and weaken again an already existing reference, this
    # is an O(N) operation in most Perl versions, and thus very slow.

    # If the node does not belong to a graph yet or belongs to another
    # graph, add it to our own graph:
    weaken($n->{graph} = $self->{graph}) unless
	$n->{graph} && $self->{graph} && $n->{graph} == $self->{graph};

    }

  @arg;
  }

#############################################################################

sub _del_edge
  {
  # delete an edge from this group
  my ($self,$e) = @_;

  delete $self->{edges_within}->{ $e->{id} };
  delete $e->{group};			# unregister us

  $self;
  }

sub _add_edge
  {
  # add an edge to this group (e.g. when both from/to of this edge belong
  # to this group)
  my ($self,$e) = @_;

  if (!ref($e) || !$e->isa("Graph::Easy::Edge"))
    {
    return $self->error("Cannot add non edge-object $e to group '$self->{name}'");
    }
  $self->{edges_within}->{ $e->{id} } = $e;

  # if defined attribute "edgeclass", put our edges into that class
  my $edge_class = $self->attribute('edgeclass');
  $e->sub_class($edge_class) if $edge_class ne '';

  # XXX TODO: inline
  $self->add_node($e->{from});
  $self->add_node($e->{to});

  # register us, but don't do weaken() if the ref was already set
  weaken($e->{group} = $self) unless defined $e->{group} && $e->{group} == $self;

  $e;
  }

sub add_edge
  {
  # Add an edge to the graph of this group, then register it with this group.
  my ($self,$from,$to) = @_;

  my $g = $self->{graph};
  return $self->error("Cannot add edge to group '$self->{name}' without graph")
    unless defined $g;

  my $edge = $g->add_edge($from,$to);

  $self->_add_edge($edge);
  }

sub add_edge_once
  {
  # Add an edge to the graph of this group, then register it with this group.
  my ($self,$from,$to) = @_;

  my $g = $self->{graph};
  return $self->error("Cannot non edge to group '$self->{name}' without graph")
    unless defined $g;

  my $edge = $g->add_edge_once($from,$to);
  # edge already exists => so fetch it
  $edge = $g->edge($from,$to) unless defined $edge;

  $self->_add_edge($edge);
  }

#############################################################################

sub add_group
  {
  # add a group to us
  my ($self,$group) = @_;

  # group with that name already exists?
  my $name = $group;
  $group = $self->{groups}->{ $group } unless ref $group;

  # group with that name doesn't exist, so create new one
  $group = $self->{graph}->add_group($name) unless ref $group;

  # index under the group name for easier lookup
  $self->{groups}->{ $group->{name} } = $group;

  # make attribute->('group') work
  $group->{att}->{group} = $self->{name};

  # register group with the graph and ourself
  $group->{graph} = $self->{graph};
  $group->{group} = $self;
  {
    no warnings; # dont warn on already weak references
    weaken($group->{graph});
    weaken($group->{group});
  }
  $self->{graph}->{score} = undef;		# invalidate last layout

  $group;
  }

# cell management - used by the layouter

sub _cells
  {
  # return all the cells this group currently occupies
  my $self = shift;

  $self->{_cells};
  }

sub _clear_cells
  {
  # remove all belonging cells
  my $self = shift;

  $self->{_cells} = {};

  $self;
  }

sub _add_cell
  {
  # add a cell to the list of cells this group covers
  my ($self,$cell) = @_;

  $cell->_update_boundaries();
  $self->{_cells}->{"$cell->{x},$cell->{y}"} = $cell;
  $cell;
  }

sub _del_cell
  {
  # delete a cell from the list of cells this group covers
  my ($self,$cell) = @_;

  delete $self->{_cells}->{"$cell->{x},$cell->{y}"};
  delete $cell->{group};

  $self;
  }

sub _find_label_cell
  {
  # go through all cells of this group and find one where to attach the label
  my $self = shift;

  my $g = $self->{graph};

  my $align = $self->attribute('align');
  my $loc = $self->attribute('labelpos');

  # depending on whether the label should be on top or bottom:
  my $match = qr/^\s*gt\s*\z/;
  $match = qr/^\s*gb\s*\z/ if $loc eq 'bottom';

  my $lc;						# the label cell

  for my $c (values %{$self->{_cells}})
    {
    # find a cell where to put the label
    next unless $c->{cell_class} =~ $match;

    if (defined $lc)
      {
      if ($align eq 'left')
	{
	# find top-most, left-most cell
	next if $lc->{x} < $c->{x} || $lc->{y} < $c->{y};
	}
      elsif ($align eq 'center')
	{
	# just find any top-most cell
	next if $lc->{y} < $c->{y};
	}
      elsif ($align eq 'right')
	{
	# find top-most, right-most cell
	next if $lc->{x} > $c->{x} || $lc->{y} < $c->{y};
	}
      }  
    $lc = $c;
    }

  # find the cell mostly near the center in the found top-row
  if (ref($lc) && $align eq 'center')
    {
    my ($left, $right);
    # find left/right most coordinates
    for my $c (values %{$self->{_cells}})
      {
      next if $c->{y} != $lc->{y};
      $left = $c->{x} if !defined $left || $left > $c->{x};  
      $right = $c->{x} if !defined $right || $right < $c->{x};
      }
    my $center = int(($right - $left) / 2 + $left);
    my $min_dist;
    # find the cell mostly near the center in the found top-row
    for my $c (values %{$self->{_cells}})
      {
      next if $c->{y} != $lc->{y};
      # squared to get rid of sign
      my $dist = ($center - $c->{x}); $dist *= $dist;
      next if defined $min_dist && $dist > $min_dist;
      $min_dist = $dist; $lc = $c;
      }
    }

  print STDERR "# Setting label for group '$self->{name}' at $lc->{x},$lc->{y}\n"
	if $self->{debug};

  $lc->_set_label() if ref($lc);
  }

sub layout
  {
  my $self = shift;

  $self->_croak('Cannot call layout() on a Graph::Easy::Group directly.');
  }

sub _layout
  {
  my $self = shift;

  ###########################################################################
  # set local {debug} for groups
  local $self->{debug} = $self->{graph}->{debug};

  $self->SUPER::_layout();
  }

sub _set_cell_types
  {
  my ($self, $cells) = @_;

  # Set the right cell class for all of our cells:
  for my $cell (values %{$self->{_cells}})
    {
    $cell->_set_type($cells);
    }
 
  $self;
  }

1;
__END__

=head1 NAME

Graph::Easy::Group - A group of nodes (aka subgraph) in Graph::Easy

=head1 SYNOPSIS

        use Graph::Easy;

        my $bonn = Graph::Easy::Node->new('Bonn');

        $bonn->set_attribute('border', 'solid 1px black');

        my $berlin = Graph::Easy::Node->new( name => 'Berlin' );

	my $cities = Graph::Easy::Group->new(
		name => 'Cities',
	);
        $cities->set_attribute('border', 'dashed 1px blue');

	$cities->add_nodes ($bonn);
	# $bonn will be ONCE in the group
	$cities->add_nodes ($bonn, $berlin);


=head1 DESCRIPTION

A C<Graph::Easy::Group> represents a group of nodes in an C<Graph::Easy>
object. These nodes are grouped together on output.

=head1 METHODS

=head2 new()

	my $group = Graph::Easy::Group->new( $options );

Create a new, empty group. C<$options> are the possible options, see
L<Graph::Easy::Node> for a list.

=head2 error()

	$last_error = $group->error();

	$group->error($error);			# set new messags
	$group->error('');			# clear error

Returns the last error message, or '' for no error.

=head2 as_ascii()

	my $ascii = $group->as_ascii();

Return the group as a little box drawn in ASCII art as a string.

=head2 name()

	my $name = $group->name();

Return the name of the group.

=head2 id()

	my $id = $group->id();

Returns the group's unique ID number.

=head2 set_attribute()

        $group->set_attribute('border-style', 'none');

Sets the specified attribute of this (and only this!) group to the
specified value.

=head2 add_member()

	$group->add_member($node);
	$group->add_member($group);

Add the specified object to this group and returns this member. If the
passed argument is a scalar, will treat it as a node name.

Note that each object can only be a member of one group at a time.

=head2 add_node()

	$group->add_node($node);

Add the specified node to this group and returns this node.

Note that each object can only be a member of one group at a time.

=head2 add_edge(), add_edge_once()

	$group->add_edge($edge);		# Graph::Easy::Edge
	$group->add_edge($from, $to);		# Graph::Easy::Node or
						# Graph::Easy::Group
	$group->add_edge('From', 'To');		# Scalars

If passed an Graph::Easy::Edge object, moves the nodes involved in
this edge to the group.

if passed two nodes, adds these nodes to the graph (unless they already
exist) and adds an edge between these two nodes. See L<add_edge_once()>
to avoid creating multiple edges.

This method works only on groups that are part of a graph.

Note that each object can only be a member of one group at a time,
and edges are automatically a member of a group if and only if both
the target and the destination node are a member of the same group.

=head2 add_group()

	my $inner = $group->add_group('Group name');
	my $nested = $group->add_group($group);

Add a group as subgroup to this group and returns this group.

=head2 del_member()

	$group->del_member($node);
	$group->del_member($group);

Delete the specified object from this group.

=head2 del_node()

	$group->del_node($node);

Delete the specified node from this group.

=head2 del_edge()

	$group->del_edge($edge);

Delete the specified edge from this group.

=head2 add_nodes()

	$group->add_nodes($node, $node2, ... );

Add all the specified nodes to this group and returns them as a list.

=head2 nodes()

	my @nodes = $group->nodes();

Returns a list of all node objects that belong to this group.

=head2 edges()

	my @edges = $group->edges();

Returns a list of all edge objects that lead to or from this group.

Note: This does B<not> return edges between nodes that are inside the group,
for this see L<edges_within()>.

=head2 edges_within()

	my @edges_within = $group->edges_within();

Returns a list of all edge objects that are I<inside> this group, in arbitrary
order. Edges are automatically considered I<inside> a group if their starting
and ending node both are in the same group.

Note: This does B<not> return edges between this group and other groups,
nor edges between this group and nodes outside this group, for this see
L<edges()>.

=head2 groups()

	my @groups = $group->groups();

Returns the contained groups of this group as L<Graph::Easy::Group> objects,
in arbitrary order.
  
=head2 groups_within()

	# equivalent to $group->groups():
	my @groups = $group->groups_within();		# all
	my @toplevel_groups = $group->groups_within(0);	# level 0 only

Return the groups that are inside this group, up to the specified level,
in arbitrary order.

The default level is -1, indicating no bounds and thus all contained
groups are returned.

A level of 0 means only the direct children, and hence only the toplevel
groups will be returned. A level 1 means the toplevel groups and their
toplevel children, and so on.

=head2 as_txt()

	my $txt = $group->as_txt();

Returns the group as Graph::Easy textual description.

=head2 _find_label_cell()

	$group->_find_label_cell();

Called by the layouter once for each group. Goes through all cells of this
group and finds one where to attach the label to. Internal usage only.

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
C<get_attribute()>, etc. on a group, too. For example:

	$group->set_attribute('label', 'by train');
	my $attr = $group->get_attributes();

You can find more documentation in L<Graph::Easy>.

=head2 layout()

This routine should not be called on groups, it only works on the graph
itself.

=head2 shape()

	my $shape = $group->shape();

Returns the shape of the group as string.

=head2 has_as_successor()

	if ($group->has_as_successor($other))
	  {
	  ...
	  }

Returns true if C<$other> (a node or group) is a successor of this group, e.g.
if there is an edge leading from this group to C<$other>.

=head2 has_as_predecessor()

	if ($group->has_as_predecessor($other))
	  {
	  ...
	  }

Returns true if the group has C<$other> (a group or node) as predecessor, that
is if there is an edge leading from C<$other> to this group.

=head2 root_node()

	my $root = $group->root_node();

Return the root node as L<Graph::Easy::Node> object, if it was
set with the 'root' attribute.

=head1 EXPORT

None by default.

=head1 SEE ALSO

L<Graph::Easy>, L<Graph::Easy::Node>, L<Graph::Easy::Manual>.

=head1 AUTHOR

Copyright (C) 2004 - 2008 by Tels L<http://bloodgate.com>

See the LICENSE file for more details.

=cut
