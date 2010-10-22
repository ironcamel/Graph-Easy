#############################################################################
# Path and cell management for Graph::Easy.
#
#############################################################################

package Graph::Easy::Layout::Path;

$VERSION = '0.16';

#############################################################################
#############################################################################

package Graph::Easy::Node;

use strict;

use Graph::Easy::Edge::Cell qw/
 EDGE_END_E EDGE_END_N EDGE_END_S EDGE_END_W
/;

sub _shuffle_dir
  {
  # take a list with four entries and shuffle them around according to $dir
  my ($self, $e, $dir) = @_;

  # $dir: 0 => north, 90 => east, 180 => south, 270 => west

  $dir = 90 unless defined $dir;		# default is east

  return [ @$e ] if $dir == 90;			# default is no shuffling

  my @shuffle = (0,1,2,3);			# the default
  @shuffle = (1,2,0,3) if $dir == 180;		# south
  @shuffle = (2,3,1,0) if $dir == 270;		# west
  @shuffle = (3,0,2,1) if $dir == 0;		# north

  [
    $e->[ $shuffle[0] ],
    $e->[ $shuffle[1] ],
    $e->[ $shuffle[2] ],
    $e->[ $shuffle[3] ],
  ];
  }

sub _shift
  {
  # get a flow shifted by X° to $dir
  my ($self, $turn) = @_;

  my $dir = $self->flow();

  $dir += $turn;
  $dir += 360 if $dir < 0;
  $dir -= 360 if $dir > 360;
  $dir;
  }

sub _near_places
  {
  # Take a node and return a list of possible placements around it and
  # prune out already occupied cells. $d is the distance from the node
  # border and defaults to two (for placements). Set it to one for
  # adjacent cells. 

  # If defined, $type contains four flags for each direction. If undef,
  # two entries (x,y) will be returned for each pos, instead of (x,y,type).

  # If $loose is true, no checking whether the returned fields are free
  # is done.

  my ($n, $cells, $d, $type, $loose, $dir) = @_;

  my $cx = $n->{cx} || 1;
  my $cy = $n->{cy} || 1;
  
  $d = 2 unless defined $d;		# default is distance = 2

  my $flags = $type;

  if (ref($flags) ne 'ARRAY')
    {
    $flags = [
      EDGE_END_W,
      EDGE_END_N,
      EDGE_END_E,
      EDGE_END_S,
     ];
    }
  $dir = $n->flow() unless defined $dir;

  my $index = $n->_shuffle_dir( [ 0,3,6,9], $dir);

  my @places = ();

  # single-celled node
  if ($cx + $cy == 2)
    {
    my @tries  = (
  	$n->{x} + $d, $n->{y}, $flags->[0],	# right
	$n->{x}, $n->{y} + $d, $flags->[1],	# down
	$n->{x} - $d, $n->{y}, $flags->[2],	# left
	$n->{x}, $n->{y} - $d, $flags->[3],	# up
      );

    for my $i (0..3)
      {
      my $idx = $index->[$i];
      my ($x,$y,$t) = ($tries[$idx], $tries[$idx+1], $tries[$idx+2]);

#      print STDERR "# Considering place $x, $y \n";

      # This quick check does not take node clusters or multi-celled nodes
      # into account. These are handled in $node->_do_place() later.
      next if !$loose && exists $cells->{"$x,$y"};
      push @places, $x, $y;
      push @places, $t if defined $type;
      }
    return @places;
    }

  # Handle a multi-celled node. For a 3x2 node:
  #      A   B   C
  #   J [00][10][20] D
  #   I [10][11][21] E
  #      H   G   F
  # we have 10 (3 * 2 + 2 * 2) places to consider

  my $nx = $n->{x};
  my $ny = $n->{y};
  my ($px,$py);

  my $idx = 0;
  my @results = ( [], [], [], [] );
 
  $cy--; $cx--;
  my $t = $flags->[$idx++];
  # right
  $px = $nx + $cx + $d;
  for my $y (0 .. $cy)
    {
    $py = $y + $ny;
    next if exists $cells->{"$px,$py"} && !$loose;
    push @{$results[0]}, $px, $py;
    push @{$results[0]}, $t if defined $type;
    }

  # below
  $py = $ny + $cy + $d;
  $t = $flags->[$idx++];
  for my $x (0 .. $cx)
    {
    $px = $x + $nx;
    next if exists $cells->{"$px,$py"} && !$loose;
    push @{$results[1]}, $px, $py;
    push @{$results[1]}, $t if defined $type;
    }

  # left
  $px = $nx - $d;
  $t = $flags->[$idx++];
  for my $y (0 .. $cy)
    {
    $py = $y + $ny;
    next if exists $cells->{"$px,$py"} && !$loose;
    push @{$results[2]}, $px, $py;
    push @{$results[2]}, $t if defined $type;
    }

  # top
  $py = $ny - $d;
  $t = $flags->[$idx];
  for my $x (0 .. $cx)
    {
    $px = $x + $nx;
    next if exists $cells->{"$px,$py"} && !$loose;
    push @{$results[3]}, $px, $py;
    push @{$results[3]}, $t if defined $type;
    }

  # accumulate the results in the requested, shuffled order
  for my $i (0..3)
    {
    my $idx = $index->[$i] / 3;
    push @places, @{$results[$idx]};
    }

  @places;
  }

sub _allowed_places
  {
  # given a list of potential positions, and a list of allowed positions,
  # return the valid ones (e.g. that are in both lists)
  my ($self, $places, $allowed, $step) = @_;

  print STDERR 
   "# calculating allowed places for $self->{name} from " . @$places . 
   " positions and " . scalar @$allowed . " allowed ones:\n"
    if $self->{graph}->{debug};

  $step ||= 2;				# default: "x,y"

  my @good;
  my $i = 0;
  while ($i < @$places)
    {
    my ($x,$y) = ($places->[$i], $places->[$i+1]);
    my $allow = 0;
    my $j = 0;
    while ($j < @$allowed)
      {
      my ($m,$n) = ($allowed->[$j], $allowed->[$j+1]);
      $allow++ and last if ($m == $x && $n == $y);
      } continue { $j += 2; }
    next unless $allow;
    push @good, $places->[$i + $_ -1] for (1..$step);
    } continue { $i += $step; }

  print STDERR "#  left with " . ((scalar @good) / $step) . " position(s)\n" if $self->{graph}->{debug};
  @good;
  }

sub _allow
  {
  # return a list of places, depending on the start/end atribute:
  # "south" - any place south
  # "south,0" - first place south
  # "south,-1" - last place south  
  # XXX TODO:
  # "south,0..2" - first three places south
  # "south,0,1,-1" - first, second and last place south  

  my ($self, $dir, @pos) = @_;

  # for relative direction, get the absolute flow from the node
  if ($dir =~ /^(front|forward|back|left|right)\z/)
    {
    # get the flow at the node
    $dir = $self->flow();
    }

  my $place = {
    'south' => [  0,0, 0,1, 'cx', 1,0 ],
    'north' => [ 0,-1, 0,0, 'cx', 1,0 ],
    'east' =>  [  0,0, 1,0, 'cy', 0,1 ],
    'west' =>  [ -1,0, 0,0, 'cy', 0,1 ] ,
    180 => [  0,0, 0,1, 'cx', 1,0 ],
    0 => [ 0,-1, 0,0, 'cx', 1,0 ],
    90 =>  [  0,0, 1,0, 'cy', 0,1 ],
    270 =>  [ -1,0, 0,0, 'cy', 0,1 ] ,
    };

  my $p = $place->{$dir};

  return [] unless defined $p;

  # start pos
  my $x = $p->[0] + $self->{x} + $p->[2] * $self->{cx};
  my $y = $p->[1] + $self->{y} + $p->[3] * $self->{cy};

  my @allowed;
  push @pos, '' if @pos == 0;

  my $c = $p->[4];
  if (@pos == 1 && $pos[0] eq '')
    {
    # allow all of them
    for (1 .. $self->{$c})
      {
      push @allowed, $x, $y;
      $x += $p->[5];
      $y += $p->[6];
      }
    } 
  else
    {
    # allow only the given position
    my $ps = $pos[0];
    # limit to 0..$self->{cx}-1
    $ps = $self->{$c} + $ps if $ps < 0;
    $ps = 0 if $ps < 0;
    $ps = $self->{$c} - 1 if $ps >= $self->{$c};
    $x += $p->[5] * $ps;
    $y += $p->[6] * $ps;
    push @allowed, $x, $y;
    }

  \@allowed;
  }

package Graph::Easy;
use strict;
use Graph::Easy::Node::Cell;

use Graph::Easy::Edge::Cell qw/
  EDGE_HOR EDGE_VER EDGE_CROSS
  EDGE_TYPE_MASK
  EDGE_HOLE
 /;

sub _clear_tries
  {
  # Take a list of potential positions for a node, and then remove the
  # ones that are immidiately near any other node.
  # Returns a list of "good" positions. Afterwards $node->{x} is undef.
  my ($self, $node, $cells, $tries) = @_;

  my $src = 0; my @new;

  print STDERR "# clearing ", scalar @$tries / 2, " tries for $node->{name}\n" if $self->{debug};

  my $node_grandpa = $node->find_grandparent();

  while ($src < scalar @$tries)
    {
    # check the current position

    # temporary place node here
    my $x = $tries->[$src];
    my $y = $tries->[$src+1];

#    print STDERR "# checking $x,$y\n" if $self->{debug};

    $node->{x} = $x;
    $node->{y} = $y;

    my @near = $node->_near_places($cells, 1, undef, 1);

    # push also the four corner cells to avoid placing nodes corner-to-corner
    push @near, $x-1, $y-1,					# upperleft corner
                $x-1, $y+($node->{cy}||1),			# lowerleft corner
                $x+($node->{cx}||1), $y+($node->{cy}||1),	# lowerright corner
                $x+($node->{cx}||1), $y-1;			# upperright corner
    
    # check all near places to be free from nodes (except our children)
    my $j = 0; my $g = 0;
    while ($j < @near)
      {
      my $xy = $near[$j]. ',' . $near[$j+1];

#      print STDERR "# checking near-place: $xy: " . ref($cells->{$xy}) . "\n" if $self->{debug};
      
      my $cell = $cells->{$xy};

      # skip, unless we are a children of node, or the cell is our children
      next unless ref($cell) && $cell->isa('Graph::Easy::Node');

      my $grandpa = $cell->find_grandparent();

      #       this cell is our children
      #                            this cell is our grandpa
      #                                                      has the same grandpa as node
      next if $grandpa == $node || $cell == $node_grandpa || $grandpa == $node_grandpa;

      $g++; last;

      } continue { $j += 2; }

    if ($g == 0)
      {
      push @new, $tries->[$src], $tries->[$src+1];
      }
    $src += 2;
    }

  $node->{x} = undef;

  @new;
  }

my $flow_shift = {
  270 => [ 0, -1 ],
   90 => [ 0,  1 ],
    0 => [ 1,  0 ],
  180 => [ -1, 0 ],
  };

sub _placed_shared
  {
  # check whether one of the nodes from the list of shared was already placed
  my ($self) = shift;

  my $placed;
  for my $n (@_)
    {
    $placed = [$n->{x}, $n->{y}] and last if defined $n->{x};
    }
  $placed;
  }

sub _find_node_place
  {
  # Try to place a node (or node cluster). Return score (usually 0).
  my ($self, $node, $try, $parent, $edge) = @_;

  $try ||= 0;

  print STDERR "# Finding place for $node->{name}, try #$try\n" if $self->{debug};
  print STDERR "# Parent node is '$parent->{name}'\n" if $self->{debug} && ref $parent;

  print STDERR "# called from ". join (" ", caller) . "\n" if $self->{debug};

  # If the node has a user-set rank, see if we already placed another node in that
  # row/column
  if ($node->{rank} >= 0)
    {
    my $r = abs($node->{rank});
#    print STDERR "# User-set rank for $node->{name} (rank $r)\n";
    my $c = $self->{_rank_coord};
#    use Data::Dumper; print STDERR "# rank_pos: \n", Dumper($self->{_rank_pos});
    if (exists $self->{_rank_pos}->{ $r })
      {
      my $co = { x => 0, y => 0 };
      $co->{$c} = $self->{_rank_pos}->{ $r };
      while (1 < 3)
        {
#	print STDERR "# trying to force placement of '$node->{name}' at $co->{x} $co->{y}\n";    
        return 0 if $node->_do_place($co->{x},$co->{y},$self);
        $co->{$c} += 2;
        }
      }
    }

  my $cells = $self->{cells};

#  local $self->{debug} = 1;

  my $min_dist = 2;
  # minlen = 0 => min_dist = 2,
  # minlen = 1 => min_dist = 2, 
  # minlen = 2 => min_dist = 3, etc
  $min_dist = $edge->attribute('minlen') + 1 if ref($edge);

  # if the node has outgoing edges (which might be shared)
  if (!ref($edge))
    {
    (undef,$edge) = each %{$node->{edges}} if keys %{$node->{edges}} > 0;
    }

  my $dir = undef; $dir = $edge->flow() if ref($edge);

  my @tries;
#  if (ref($parent) && defined $parent->{x})
  if (keys %{$node->{edges}} > 0)
    {
    my $src_node = $parent; $src_node = $edge->{from} if ref($edge) && !ref($parent);
    print STDERR "#  from $src_node->{name} to $node->{name}: edge $edge dir $dir\n" if $self->{debug};

    # if there are more than one edge to this node, and they share a start point,
    # move the node at least 3 cells away to create space for the joints

    my ($s_p, @ss_p);
    ($s_p, @ss_p) = $edge->port('start') if ref($edge);

    my ($from,$to);
    if (ref($edge))
      {
      $from = $edge->{from}; $to = $edge->{to};
      }

    my @shared_nodes;
    @shared_nodes = $from->nodes_sharing_start($s_p,@ss_p) if defined $s_p && @ss_p > 0;

    print STDERR "# Edge from '$src_node->{name}' shares an edge start with ", scalar @shared_nodes, " other nodes\n"
	if $self->{debug};

    if (@shared_nodes > 1)
      {
      $min_dist = 3 if $min_dist < 3;				# make space
      $min_dist++ if $edge->label() ne '';			# make more space for the label

      # if we are the first shared node to be placed
      my $placed = $self->_placed_shared(@shared_nodes);

      if (defined $placed)
        {
        # we are not the first, so skip the placement below
	# instead place on the same column/row as already placed node(s)
        my ($bx, $by) = @$placed;

	my $flow = $node->flow();

	print STDERR "# One of the shared nodes was already placed at ($bx,$by) with flow $flow\n"
	  if $self->{debug};

	my $ofs = 2;			# start with a distance of 2
	my ($mx, $my) = @{ ($flow_shift->{$flow} || [ 0, 1 ]) };

	while (1)
	  {
	  my $x = $bx + $mx * $ofs; my $y = $by + $my * $ofs;

	  print STDERR "# Trying to place $node->{name} at ($x,$y)\n"
	    if $self->{debug};

	  next if $self->_clear_tries($node, $cells, [ $x,$y ]) == 0;
	  last if $node->_do_place($x,$y,$self);
	  }
	continue {
	    $ofs += 2;
	  }
        return 0;			# found place already
	} # end we-are-the-first-to-be-placed
      }

    # shared end point?
    ($s_p, @ss_p) = $edge->port('end') if ref($edge);

    @shared_nodes = $to->nodes_sharing_end($s_p,@ss_p) if defined $s_p && @ss_p > 0;

    print STDERR "# Edge from '$src_node->{name}' shares an edge end with ", scalar @shared_nodes, " other nodes\n"
	if $self->{debug};

    if (@shared_nodes > 1)
      {
      $min_dist = 3 if $min_dist < 3;
      $min_dist++ if $edge->label() ne '';			# make more space for the label

      # if the node to be placed is not in the list to be placed, it is the end-point
      
      # see if we are the first shared node to be placed
      my $placed = $self->_placed_shared(@shared_nodes);

#      print STDERR "# "; for (@shared_nodes) { print $_->{name}, " "; } print "\n";

      if ((grep( $_ == $node, @shared_nodes)) && defined $placed)
	{
        # we are not the first, so skip the placement below
	# instead place on the same column/row as already placed node(s)
        my ($bx, $by) = @$placed;

	my $flow = $node->flow();

	print STDERR "# One of the shared nodes was already placed at ($bx,$by) with flow $flow\n"
	  if $self->{debug};

	my $ofs = 2;			# start with a distance of 2
	my ($mx, $my) = @{ ($flow_shift->{$flow} || [ 0, 1 ]) };

	while (1)
	  {
	  my $x = $bx + $mx * $ofs; my $y = $by + $my * $ofs;

	  print STDERR "# Trying to place $node->{name} at ($x,$y)\n"
	    if $self->{debug};

	  next if $self->_clear_tries($node, $cells, [ $x,$y ]) == 0;
	  last if $node->_do_place($x,$y,$self);
	  }
	continue {
	    $ofs += 2;
	  }
        return 0;			# found place already
	} # end we-are-the-first-to-be-placed
      }
    }

  if (ref($parent) && defined $parent->{x})
    {
    @tries = $parent->_near_places($cells, $min_dist, undef, 0, $dir);

    print STDERR 
	"# Trying chained placement of $node->{name} with min distance $min_dist from parent $parent->{name}\n"
	if $self->{debug};

    # weed out positions that are unsuitable
    @tries = $self->_clear_tries($node, $cells, \@tries);

    splice (@tries,0,$try) if $try > 0;	# remove the first N tries
    print STDERR "# Left with " . scalar @tries . " tries for node $node->{name}\n" if $self->{debug};

    while (@tries > 0)
      {
      my $x = shift @tries;
      my $y = shift @tries;

      print STDERR "# Trying to place $node->{name} at $x,$y\n" if $self->{debug};
      return 0 if $node->_do_place($x,$y,$self);
      } # for all trial positions
    }

  print STDERR "# Trying to place $node->{name} at 0,0\n" if $try == 0 && $self->{debug};
  # Try to place node at upper left corner (the very first node to be
  # placed will usually end up there).
  return 0 if $try == 0 && $node->_do_place(0,0,$self);

  # try to place node near the predecessor(s)
  my @pre_all = $node->predecessors();

  print STDERR "# Predecessors of $node->{name} " . scalar @pre_all . "\n" if $self->{debug};

  # find all already placed predecessors
  my @pre;
  for my $p (@pre_all)
    {
    push @pre, $p if defined $p->{x};
    print STDERR "# Placed predecessors of $node->{name}: $p->{name} at $p->{x},$p->{y}\n" if $self->{debug} && defined $p->{x};
    }

  # sort predecessors on their rank (to try first the higher ranking ones on placement)
  @pre = sort { $b->{rank} <=> $a->{rank} } @pre;

  print STDERR "# Number of placed predecessors of $node->{name}: " . scalar @pre . "\n" if $self->{debug};

  if (@pre <= 2 && @pre > 0)
    {

    if (@pre == 1)
      {
      # only one placed predecessor, so place $node near it
      print STDERR "# placing $node->{name} near predecessor\n" if $self->{debug};
      @tries = ( $pre[0]->_near_places($cells, $min_dist), $pre[0]->_near_places($cells,$min_dist+2) ); 
      }
    else
      {
      # two placed predecessors, so place at crossing point of both of them
      # compute difference between the two nodes

      my $dx = ($pre[0]->{x} - $pre[1]->{x});
      my $dy = ($pre[0]->{y} - $pre[1]->{y});

      # are both nodes NOT on a straight line?
      if ($dx != 0 && $dy != 0)
        {
        # ok, so try to place at the crossing point
	@tries = ( 
	  $pre[0]->{x}, $pre[1]->{y},
	  $pre[0]->{y}, $pre[1]->{x},
	);
        }
      else
        {
        # two nodes on a line, try to place node in the middle
        if ($dx == 0)
          {
	  @tries = ( $pre[1]->{x}, $pre[1]->{y} + int($dy / 2) );
          }
        else
          {
	  @tries = ( $pre[1]->{x} + int($dx / 2), $pre[1]->{y} );
          }
        }
      # XXX TODO BUG: shouldnt we also try this if we have more than 2 placed
      # predecessors?

      # In addition, we can also try to place the node around the
      # different nodes:
      foreach my $n (@pre)
        {
        push @tries, $n->_near_places($cells, $min_dist);
        }
      }
    }

  my @suc_all = $node->successors();

  # find all already placed successors
  my @suc;
  for my $s (@suc_all)
    {
    push @suc, $s if defined $s->{x};
    }
  print STDERR "# Number of placed successors of $node->{name}: " . scalar @suc . "\n" if $self->{debug};
  foreach my $s (@suc)
    {
    # for each successors (especially if there is only one), try to place near
    push @tries, $s->_near_places($cells, $min_dist); 
    push @tries, $s->_near_places($cells, $min_dist + 2);
    }

  # weed out positions that are unsuitable
  @tries = $self->_clear_tries($node, $cells, \@tries);

  print STDERR "# Left with " . scalar @tries . " for node $node->{name}\n" if $self->{debug};

  splice (@tries,0,$try) if $try > 0;	# remove the first N tries
  
  while (@tries > 0)
    {
    my $x = shift @tries;
    my $y = shift @tries;

    print STDERR "# Trying to place $node->{name} at $x,$y\n" if $self->{debug};
    return 0 if $node->_do_place($x,$y,$self);

    } # for all trial positions

  ##############################################################################
  # all simple possibilities exhausted, try a generic approach

  print STDERR "# No more simple possibilities for node $node->{name}\n" if $self->{debug};

  # XXX TODO:
  # find out which sides of the node predecessor node(s) still have free
  # ports/slots. With increasing distances, try to place the node around these.

  # If no predecessors/incoming edges, try to place in column 0, otherwise 
  # considered the node's rank, too

  my $col = 0; $col = $node->{rank} * 2 if @pre > 0;

  $col = $pre[0]->{x} if @pre > 0;
  
  # find the first free row
  my $y = 0;
  $y +=2 while (exists $cells->{"$col,$y"});
  $y += 1 if exists $cells->{"$col," . ($y-1)};		# leave one cell spacing

  # now try to place node (or node cluster)
  while (1)
    {
    next if $self->_clear_tries($node, $cells, [ $col,$y ]) == 0;
    last if $node->_do_place($col,$y,$self);
    }
    continue {
    $y += 2;
    }

  $node->{x} = $col; 

  0;							# success, score 0 
  }

sub _trace_path
  {
  # find a free way from $src to $dst (both need to be placed beforehand)
  my ($self, $src, $dst, $edge) = @_;

  print STDERR "# Finding path from '$src->{name}' to '$dst->{name}'\n" if $self->{debug};
  print STDERR "# src: $src->{x}, $src->{y} dst: $dst->{x}, $dst->{y}\n" if $self->{debug};

  my $coords = $self->_find_path ($src, $dst, $edge);

  # found no path?
  if (!defined $coords)
    {
    print STDERR "# Unable to find path from $src->{name} ($src->{x},$src->{y}) to $dst->{name} ($dst->{x},$dst->{y})\n" if $self->{debug};
    return undef;
    }

  # path is empty, happens for sharing edges with only a joint
  return 1 if scalar @$coords == 0;

  # Create all cells from the returned list and score path (lower score: better)
  my $i = 0;
  my $score = 0;
  while ($i < scalar @$coords)
    {
    my $type = $coords->[$i+2];
    $self->_create_cell($edge,$coords->[$i],$coords->[$i+1],$type);
    $score ++;					# each element: one point
    $type &= EDGE_TYPE_MASK;			# mask flags
    # edge bend or cross: one point extra
    $score ++ if $type != EDGE_HOR && $type != EDGE_VER;
    $score += 3 if $type == EDGE_CROSS;		# crossings are doubleplusungood
    $i += 3;
    }

  $score;
  }

sub _create_cell
  {
  my ($self,$edge,$x,$y,$type) = @_;

  my $cells = $self->{cells}; my $xy = "$x,$y";
  
  if (ref($cells->{$xy}) && $cells->{$xy}->isa('Graph::Easy::Edge'))
    {
    $cells->{$xy}->_make_cross($edge,$type & EDGE_FLAG_MASK);
    # insert a EDGE_HOLE into the cells of the edge (but not into the list of
    # to-be-rendered cells). This cell will be removed by the optimizer later on.
    Graph::Easy::Edge::Cell->new( type => EDGE_HOLE, edge => $edge, x => $x, y => $y );
    return;
    }

  my $path = Graph::Easy::Edge::Cell->new( type => $type, edge => $edge, x => $x, y => $y );
  $cells->{$xy} = $path;	# store in cells
  }

sub _path_is_clear
  {
  # For all points (x,y pairs) in the path, check that the cell is still free
  # $path points to a list of [ x,y,type, x,y,type, ...]
  my ($self,$path) = @_;

  my $cells = $self->{cells};
  my $i = 0;
  while ($i < scalar @$path)
    {
    my $x = $path->[$i];
    my $y = $path->[$i+1];
    # my $t = $path->[$i+2];
    $i += 3;

    return 0 if exists $cells->{"$x,$y"};	# obstacle hit
    } 
  1;						# path is clear
  }

1;
__END__

=head1 NAME

Graph::Easy::Layout::Path - Path management for Manhattan-style grids

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

C<Graph::Easy::Layout::Scout> contains just the actual path-managing code for
L<Graph::Easy|Graph::Easy>, e.g. to create/destroy/maintain paths, node
placement etc.

=head1 EXPORT

Exports nothing.

=head1 SEE ALSO

L<Graph::Easy>.

=head1 METHODS into Graph::Easy

This module injects the following methods into C<Graph::Easy>:

=head2 _path_is_clear()

	$graph->_path_is_clear($path);

For all points (x,y pairs) in the path, check that the cell is still free.
C<$path> points to a list x,y,type pairs as in C<< [ [x,y,type], [x,y,type], ...] >>.

=head2 _create_cell()

	my $cell = $graph->($edge,$x,$y,$type);

Create a cell at C<$x,$y> coordinates with type C<$type> for the specified
edge.

=head2 _path_is_clear()

	$graph->_path_is_clear();

For all points (x,y pairs) in the path, check that the cell is still free.
C<$path> points to a list of C<[ x,y,type, x,y,type, ...]>.

Returns true when the path is clear, false otherwise.

=head2 _trace_path()

	my $path = my $graph->_trace_path($src,$dst,$edge);

Find a free way from source node/group to destination node/group for the
specified edge. Both source and destination need to be placed beforehand.

=head1 METHODS in Graph::Easy::Node

This module injects the following methods into C<Graph::Easy::Node>:

=head2 _near_places()

	my $node->_near_places();
  
Take a node and return a list of possible placements around it and
prune out already occupied cells. $d is the distance from the node
border and defaults to two (for placements). Set it to one for
adjacent cells. 

=head2 _shuffle_dir()

	my $dirs = $node->_shuffle_dir( [ 0,1,2,3 ], $dir);

Take a ref to an array with four entries and shuffle them around according to
C<$dir>.

=head2 _shift()

	my $dir = $node->_shift($degrees);

Return a the C<flow()> direction shifted by X degrees to C<$dir>.

=head1 AUTHOR

Copyright (C) 2004 - 2007 by Tels L<http://bloodgate.com>.

See the LICENSE file for information.

=cut
