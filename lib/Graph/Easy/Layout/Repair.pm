#############################################################################
# Layout directed graphs on a flat plane. Part of Graph::Easy.
#
# Code to repair spliced layouts (after group cells have been inserted).
#
#############################################################################

package Graph::Easy::Layout::Repair;

$VERSION = '0.08';

#############################################################################
#############################################################################
# for layouts with groups:

package Graph::Easy;

use strict;

sub _edges_into_groups
  {
  my $self = shift;

  # Put all edges between two nodes with the same group in the group as well
  for my $edge (values %{$self->{edges}})
    {
    my $gf = $edge->{from}->group();
    my $gt = $edge->{to}->group();

    $gf->_add_edge($edge) if defined $gf && defined $gt && $gf == $gt;
    }

  $self;
  }

sub _repair_nodes
  {
  # Splicing the rows/columns to add filler cells will have torn holes into
  # multi-edges nodes, so we insert additional filler cells.
  my ($self) = @_;
  my $cells = $self->{cells};

  # Make multi-celled nodes occupy the proper double space due to splicing
  # in group cell has doubled the layout in each direction:
  for my $n ($self->nodes())
    {
    # 1 => 1, 2 => 3, 3 => 5, 4 => 7 etc
    $n->{cx} = $n->{cx} * 2 - 1;
    $n->{cy} = $n->{cy} * 2 - 1;
    }

  # We might get away with not inserting filler cells if we just mark the
  # cells as used (e.g. use only one global filler cell) since filler cells
  # aren't actually rendered, anyway.

  for my $cell (values %$cells)
    {
    next unless $cell->isa('Graph::Easy::Node::Cell');

    # we have "[ empty  ] [ filler ]" (unless cell is on the same column as node)
    if ($cell->{x} > $cell->{node}->{x})
      {
      my $x = $cell->{x} - 1; my $y = $cell->{y}; 

#      print STDERR "# inserting filler at $x,$y for $cell->{node}->{name}\n";
      $cells->{"$x,$y"} = 
        Graph::Easy::Node::Cell->new(node => $cell->{node}, x => $x, y => $y );
      }

    # we have " [ empty ]  "
    #         " [ filler ] " (unless cell is on the same row as node)
    if ($cell->{y} > $cell->{node}->{y})
      {
      my $x = $cell->{x}; my $y = $cell->{y} - 1;

#      print STDERR "# inserting filler at $x,$y for $cell->{node}->{name}\n";
      $cells->{"$x,$y"} = 
        Graph::Easy::Node::Cell->new(node => $cell->{node}, x => $x, y => $y );
      }
    }
  }

sub _repair_cell
  {
  my ($self, $type, $edge, $x, $y, $after, $before) = @_;

  # already repaired?
  return if exists $self->{cells}->{"$x,$y"};

#  print STDERR "# Insert edge cell at $x,$y (type $type) for edge $edge->{from}->{name} --> $edge->{to}->{name}\n";

  $self->{cells}->{"$x,$y"} =
    Graph::Easy::Edge::Cell->new( 
      type => $type, 
      edge => $edge, x => $x, y => $y, before => $before, after => $after );

  }

sub _splice_edges
  {
  # Splicing the rows/columns to add filler cells might have torn holes into
  # edges, so we splice these together again.
  my ($self) = @_;

  my $cells = $self->{cells};

  print STDERR "# Reparing spliced layout\n" if $self->{debug};

  # Edge end/start points inside groups are not handled here, but in
  # _repair_group_edge()

  # go over the old layout, because the new cells were inserted into odd
  # rows/columns and we do not care for these:
  for my $cell (sort { $a->{x} <=> $b->{x} || $a->{y} <=> $b->{y} } values %$cells)
    {
    next unless $cell->isa('Graph::Easy::Edge::Cell');
 
    my $edge = $cell->{edge}; 

    #########################################################################
    # check for "[ JOINT ] [ empty  ] [ edge ]"
    
    my $x = $cell->{x} + 2; my $y = $cell->{y}; 

    my $type = $cell->{type} & EDGE_TYPE_MASK;

    # left is a joint and right exists
    if ( ($type == EDGE_S_E_W || $type == EDGE_N_E_W || $type == EDGE_E_N_S)
         && exists $cells->{"$x,$y"})
      {
      my $right = $cells->{"$x,$y"};

#      print STDERR "# at $x,$y\n";

      # |-> [ empty ] [ node ]
      if ($right->isa('Graph::Easy::Edge::Cell'))
	{
        # when the left one is a joint, the right one must be an edge
        $self->error("Found non-edge piece ($right->{type} $right) right to a joint ($type)") 
          unless $right->isa('Graph::Easy::Edge::Cell');

#        print STDERR "splicing in HOR piece to the right of joint at $x, $y ($edge $right $right->{edge})\n";

        # insert the new piece before the first part of the edge after the joint
        $self->_repair_cell(EDGE_HOR(), $right->{edge},$cell->{x}+1,$y,0)
          if $edge != $right->{edge};
        }
      }

    #########################################################################
    # check for "[ edge ] [ empty  ] [ joint ]"
    
    $x = $cell->{x} - 2; $y = $cell->{y}; 

    # right is a joint and left exists
    if ( ($type == EDGE_S_E_W || $type == EDGE_N_E_W || $type == EDGE_W_N_S)
         && exists $cells->{"$x,$y"})
     {
      my $left = $cells->{"$x,$y"};

      # [ node ] [ empty ] [ <-| ]
      if (!$left->isa('Graph::Easy::Node'))
	{
        # when the left one is a joint, the right one must be an edge
        $self->error('Found non-edge piece right to a joint') 
          unless $left->isa('Graph::Easy::Edge::Cell');

        # insert the new piece before the joint
        $self->_repair_cell(EDGE_HOR(), $edge, $cell->{x}+1,$y,0) # $left,$cell)
          if $edge != $left->{edge};
	}
      }

    #########################################################################
    # check for " [ joint ]
    #		  [ empty ]
    #             [ edge ]"
    
    $x = $cell->{x}; $y = $cell->{y} + 2; 

    # top is a joint and down exists
    if ( ($type == EDGE_S_E_W || $type == EDGE_E_N_S || $type == EDGE_W_N_S)
         && exists $cells->{"$x,$y"})
     {
      my $bottom = $cells->{"$x,$y"};

      # when top is a joint, the bottom one must be an edge
      $self->error('Found non-edge piece below a joint') 
        unless $bottom->isa('Graph::Easy::Edge::Cell');

#      print STDERR "splicing in VER piece below joint at $x, $y\n";

	# XXX TODO
      # insert the new piece after the joint
      $self->_repair_cell(EDGE_VER(), $bottom->{edge},$x,$cell->{y}+1,0)
        if $edge != $bottom->{edge}; 
      }

    #########################################################################
    # check for "[ --- ] [ empty  ] [ ---> ]"

    $x = $cell->{x} + 2; $y = $cell->{y}; 

    if (exists $cells->{"$x,$y"})
      {
      my $right = $cells->{"$x,$y"};

      $self->_repair_cell(EDGE_HOR(), $edge, $cell->{x}+1,$y,$cell,$right)
        if $right->isa('Graph::Easy::Edge::Cell') && 
           defined $right->{edge} && defined $right->{type} &&
	# check that both cells belong to the same edge
	(  $edge == $right->{edge}  ||
	# or the right part is a cross
	   $right->{type} == EDGE_CROSS ||
	# or the left part is a cross
	   $cell->{type} == EDGE_CROSS );
      }
    
    #########################################################################
    # check for [ | ]
    #		[ empty ]
    #		[ | ]
    $x = $cell->{x}; $y = $cell->{y}+2; 

    if (exists $cells->{"$x,$y"})
      {
      my $below = $cells->{"$x,$y"};

      $self->_repair_cell(EDGE_VER(),$edge,$x,$cell->{y}+1,$cell,$below)
	if $below->isa('Graph::Easy::Edge::Cell') &&
        # check that both cells belong to the same edge
	(  $edge == $below->{edge}  ||
	# or the lower part is a cross
	   $below->{type} == EDGE_CROSS ||
	# or the upper part is a cross
	   $cell->{type} == EDGE_CROSS );
      }

    } # end for all cells

  $self;
  }

sub _new_edge_cell
  {
  # create a new edge cell to be spliced into the layout for repairs
  my ($self, $cells, $group, $edge, $x, $y, $after, $type) = @_;

  $type += EDGE_SHORT_CELL() if defined $group;

  my $e_cell = Graph::Easy::Edge::Cell->new( 
	  type => $type, edge => $edge, x => $x, y => $y, after => $after);
  $group->_del_cell($e_cell) if defined $group;
  $cells->{"$x,$y"} = $e_cell;
  }

sub _check_edge_cell
  {
  # check a start/end edge cell and if nec. repair it
  my ($self, $cell, $x, $y, $flag, $type, $match, $check, $where) = @_;

  my $edge = $cell->{edge};
  if (grep { exists $_->{cell_class} && $_->{cell_class} =~ $match } values %$check)
    {
    $cell->{type} &= ~ $flag;		# delete the flag

    $self->_new_edge_cell(
	$self->{cells}, $edge->{group}, $edge, $x, $y, $where, $type + $flag);
    }
  }

sub _repair_group_edge
  {
  # repair an edges inside a group
  my ($self, $cell, $rows, $cols, $group) = @_;

  my $cells = $self->{cells};
  my ($x,$y,$doit);

  my $type = $cell->{type};

  #########################################################################
  # check for " [ empty ] [ |---> ]"
  $x = $cell->{x} - 1; $y = $cell->{y};

  $self->_check_edge_cell($cell, $x, $y, EDGE_START_W, EDGE_HOR, qr/g[rl]/, $cols->{$x}, 0)
    if (($type & EDGE_START_MASK) == EDGE_START_W);

  #########################################################################
  # check for " [ <--- ] [ empty ]"
  $x = $cell->{x} + 1;

  $self->_check_edge_cell($cell, $x, $y, EDGE_START_E, EDGE_HOR, qr/g[rl]/, $cols->{$x}, 0)
    if (($type & EDGE_START_MASK) == EDGE_START_E);

  #########################################################################
  # check for " [ --> ] [ empty ]"
  $x = $cell->{x} + 1;

  $self->_check_edge_cell($cell, $x, $y, EDGE_END_E, EDGE_HOR, qr/g[rl]/, $cols->{$x}, -1)
    if (($type & EDGE_END_MASK) == EDGE_END_E);

#  $self->_check_edge_cell($cell, $x, $y, EDGE_END_E, EDGE_E_N_S, qr/g[rl]/, $cols->{$x}, -1)
#    if (($type & EDGE_END_MASK) == EDGE_END_E);

  #########################################################################
  # check for " [ empty ] [ <-- ]"
  $x = $cell->{x} - 1;

  $self->_check_edge_cell($cell, $x, $y, EDGE_END_W, EDGE_HOR, qr/g[rl]/, $cols->{$x}, -1)
    if (($type & EDGE_END_MASK) == EDGE_END_W);

  #########################################################################
  #########################################################################
  # vertical cases

  #########################################################################
  # check for [empty] 
  #           [ | ]
  $x = $cell->{x}; $y = $cell->{y} - 1;

  $self->_check_edge_cell($cell, $x, $y, EDGE_START_N, EDGE_VER, qr/g[tb]/, $rows->{$y}, 0)
    if (($type & EDGE_START_MASK) == EDGE_START_N);

  #########################################################################
  # check for [ |] 
  #           [ empty ]
  $y = $cell->{y} + 1;

  $self->_check_edge_cell($cell, $x, $y, EDGE_START_S, EDGE_VER, qr/g[tb]/, $rows->{$y}, 0)
    if (($type & EDGE_START_MASK) == EDGE_START_S);

  #########################################################################
  # check for [ v ]
  #           [empty] 
  $y = $cell->{y} + 1;

  $self->_check_edge_cell($cell, $x, $y, EDGE_END_S, EDGE_VER, qr/g[tb]/, $rows->{$y}, -1)
    if (($type & EDGE_END_MASK) == EDGE_END_S);

  #########################################################################
  # check for [ empty ]
  #           [ ^     ] 
  $y = $cell->{y} - 1;

  $self->_check_edge_cell($cell, $x, $y, EDGE_END_N, EDGE_VER, qr/g[tb]/, $rows->{$y}, -1)
    if (($type & EDGE_END_MASK) == EDGE_END_N);
  }

sub _repair_edge
  {
  # repair an edge outside a group
  my ($self, $cell, $rows, $cols) = @_;

  my $cells = $self->{cells};

  #########################################################################
  # check for [ |\n|\nv ]
  #	        [empty]	... [non-empty]
  #	        [node]

  my $x = $cell->{x}; my $y = $cell->{y} + 1;

  my $below = $cells->{"$x,$y"}; 		# must be empty

  if  (!ref($below) && (($cell->{type} & EDGE_END_MASK) == EDGE_END_S))
    {
    if (grep { exists $_->{cell_class} && $_->{cell_class} =~ /g[tb]/ } values %{$rows->{$y}})
      {
      # delete the start flag
      $cell->{type} &= ~ EDGE_END_S;

      $self->_new_edge_cell($cells, undef, $cell->{edge}, $x, $y, -1, 
          EDGE_VER() + EDGE_END_S() );
      }
    }
  # XXX TODO: do the other ends (END_N, END_W, END_E), too

  }

sub _repair_edges
  {
  # fix edge end/start cells to be closer to the node cell they point at
  my ($self, $rows, $cols) = @_;

  my $cells = $self->{cells};

  # go over all existing cells
  for my $cell (sort { $a->{x} <=> $b->{x} || $a->{y} <=> $b->{y} } values %$cells)
    {
    next unless $cell->isa('Graph::Easy::Edge::Cell');

    # skip odd positions
    next unless ($cell->{x} & 1) == 0 && ($cell->{y} & 1) == 0; 

    my $group = $cell->group();

    $self->_repair_edge($cell,$rows,$cols) unless $group;
    $self->_repair_group_edge($cell,$rows,$cols,$group) if $group;

    } # end for all cells
  }

sub _fill_group_cells
  {
  # after doing a layout(), we need to add the group to each cell based on
  # what group the nearest node is in.
  my ($self, $cells_layout) = @_;

  print STDERR "\n# Padding with fill cells, have ", 
    scalar $self->groups(), " groups.\n" if $self->{debug};

  # take a shortcut if we do not have groups
  return $self if $self->groups == 0;

  $self->{padding_cells} = 1;		# set to true

  # We need to insert "filler" cells around each node/edge/cell:

  # To "insert" the filler cells, we simple multiply each X and Y by 2, this
  # is O(N) where N is the number of actually existing cells. Otherwise we
  # would have to create the full table-layout, and then insert rows/columns.
  my $cells = {};
  for my $key (keys %$cells_layout)
    {
    my ($x,$y) = split /,/, $key;
    my $cell = $cells_layout->{$key};

    $x *= 2;
    $y *= 2;
    $cell->{x} = $x;
    $cell->{y} = $y;

    $cells->{"$x,$y"} = $cell; 
    }

  $self->{cells} = $cells;		# override with new cell layout

  $self->_splice_edges();		# repair edges
  $self->_repair_nodes();		# repair multi-celled nodes

  my $c = 'Graph::Easy::Group::Cell';
  for my $cell (values %{$self->{cells}})
    {
    # DO NOT MODIFY $cell IN THE LOOP BODY!

    my ($x,$y) = ($cell->{x},$cell->{y});

    # find the primary node for node cells, for group check
    my $group = $cell->group();

    # not part of group, so no group-cells nec.
    next unless $group;

    # now insert up to 8 filler cells around this cell
    my $ofs = [ -1, 0,
		0, -1,
		+1, 0,
		+1, 0,
		0, +1,
		0, +1,
		-1, 0,
		-1, 0,  ];
    while (@$ofs > 0)
      {
      $x += shift @$ofs;
      $y += shift @$ofs;

      $cells->{"$x,$y"} = $c->new ( graph => $self, group => $group, x => $x, y => $y )
        unless exists $cells->{"$x,$y"};
      }
    }

  # Nodes positioned two cols/rows apart (f.i. y == 0 and y == 2) will be
  # three cells apart (y == 0 and y == 4) after the splicing, the step above
  # will not be able to close that hole - it will create fillers at y == 1 and
  # y == 3. So we close these holes now with an extra step.
  for my $cell (values %{$self->{cells}})
    {
    # only for filler cells
    next unless $cell->isa('Graph::Easy::Group::Cell');

    my ($sx,$sy) = ($cell->{x},$cell->{y});
    my $group = $cell->{group};

    my $x = $sx; my $y2 = $sy + 2; my $y = $sy + 1;
    # look for:
    # [ group ]
    # [ empty ]
    # [ group ]
    if (exists $cells->{"$x,$y2"} && !exists $cells->{"$x,$y"})
      {
      my $down = $cells->{"$x,$y2"};
      if ($down->isa('Graph::Easy::Group::Cell') && $down->{group} == $group)
        {
	$cells->{"$x,$y"} = $c->new ( graph => $self, group => $group, x => $x, y => $y );
        }
      }
    $x = $sx+1; my $x2 = $sx + 2; $y = $sy;
    # look for:
    # [ group ]  [ empty ]  [ group ]
    if (exists $cells->{"$x2,$y"} && !exists $cells->{"$x,$y"})
      {
      my $right = $cells->{"$x2,$y"};
      if ($right->isa('Graph::Easy::Group::Cell') && $right->{group} == $group)
        {
	$cells->{"$x,$y"} = $c->new ( graph => $self, group => $group, x => $x, y => $y );
        }
      }
    }

  # XXX TODO
  # we should "grow" the group area to close holes

  for my $group (values %{$self->{groups}})
    {
    $group->_set_cell_types($cells);
    }

  # create a mapping for each row/column so that we can repair edge starts/ends
  my $rows = {};
  my $cols = {};
  for my $cell (values %$cells)
    {
    $rows->{$cell->{y}}->{$cell->{x}} = $cell;
    $cols->{$cell->{x}}->{$cell->{y}} = $cell;
    }
  $self->_repair_edges($rows,$cols);	# insert short edge cells on group
					# border rows/columns

  # for all groups, set the cell carrying the label (top-left-most cell)
  for my $group (values %{$self->{groups}})
    {
    $group->_find_label_cell();
    }

# DEBUG:
# for my $cell (values %$cells)
#   { 
#   $cell->_correct_size();
#   }
#
# my $y = 0;
# for my $cell (sort { $a->{y} <=> $b->{y} || $a->{x} <=> $b->{x} } values %$cells)
#   {
#  print STDERR "\n" if $y != $cell->{y};
#  print STDERR "$cell->{x},$cell->{y}, $cell->{w},$cell->{h}, ", $cell->{group}->{name} || 'none', "\t";
#   $y = $cell->{y};
#  }
# print STDERR "\n";

  $self;
  }

1;
__END__

=head1 NAME

Graph::Easy::Layout::Repair - Repair spliced layout with group cells

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

C<Graph::Easy::Layout::Repair> contains code that can splice in
group cells into a layout, as well as repair the layout after that step.

It is part of L<Graph::Easy|Graph::Easy> and used automatically.

=head1 METHODS

C<Graph::Easy::Layout> injects the following methods into the C<Graph::Easy>
namespace:

=head2 _edges_into_groups()

Put the edges into the appropriate group and class.

=head2 _assign_ranks()

	$graph->_assign_ranks();

=head2 _repair_nodes()

Splicing the rows/columns to add filler cells will have torn holes into
multi-edges nodes, so we insert additional filler cells to repair this.

=head2 _splice_edges()

Splicing the rows/columns to add filler cells might have torn holes into
multi-celled edges, so we splice these together again.

=head2 _repair_edges()

Splicing the rows/columns to add filler cells might have put "holes"
between an edge start/end and the node cell it points to. This
routine fixes this problem by extending the edge by one cell if
necessary.

=head2 _fill_group_cells()

After doing a C<layout()>, we need to add the group to each cell based on
what group the nearest node is in.

This routine will also find the label cell for each group, and repair
edge/node damage done by the splicing.

=head1 EXPORT

Exports nothing.

=head1 SEE ALSO

L<Graph::Easy>.

=head1 AUTHOR

Copyright (C) 2004 - 2007 by Tels L<http://bloodgate.com>

See the LICENSE file for information.

=cut
