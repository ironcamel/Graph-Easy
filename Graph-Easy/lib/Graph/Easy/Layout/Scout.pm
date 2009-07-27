#############################################################################
# Find paths from node to node in a Manhattan-style grid via A*.
#
# (c) by Tels - part of Graph::Easy
#############################################################################

package Graph::Easy::Layout::Scout;

$VERSION = '0.25';

#############################################################################
#############################################################################

package Graph::Easy;

use strict;
use Graph::Easy::Node::Cell;
use Graph::Easy::Edge::Cell qw/
  EDGE_SHORT_E EDGE_SHORT_W EDGE_SHORT_N EDGE_SHORT_S

  EDGE_SHORT_BD_EW EDGE_SHORT_BD_NS
  EDGE_SHORT_UN_EW EDGE_SHORT_UN_NS

  EDGE_START_E EDGE_START_W EDGE_START_N EDGE_START_S

  EDGE_END_E EDGE_END_W EDGE_END_N EDGE_END_S

  EDGE_N_E EDGE_N_W EDGE_S_E EDGE_S_W

  EDGE_N_W_S EDGE_S_W_N EDGE_E_S_W EDGE_W_S_E

  EDGE_LOOP_NORTH EDGE_LOOP_SOUTH EDGE_LOOP_WEST EDGE_LOOP_EAST

  EDGE_HOR EDGE_VER EDGE_HOLE

  EDGE_S_E_W EDGE_N_E_W EDGE_E_N_S EDGE_W_N_S

  EDGE_LABEL_CELL
  EDGE_TYPE_MASK
  EDGE_ARROW_MASK
  EDGE_FLAG_MASK
  EDGE_START_MASK
  EDGE_END_MASK
  EDGE_NO_M_MASK
 /;

#############################################################################

# mapping edge type (HOR, VER, NW etc) and dx/dy to startpoint flag
my $start_points = {
#               [ dx == 1, 	dx == -1,     dy == 1,      dy == -1 ,
#                 dx == 1, 	dx == -1,     dy == 1,      dy == -1 ]
  EDGE_HOR() => [ EDGE_START_W, EDGE_START_E, 0,	    0 			,
		  EDGE_END_E,   EDGE_END_W,   0,	    0,			],
  EDGE_VER() => [ 0,		0, 	      EDGE_START_N, EDGE_START_S 	,
		  0,		0,	      EDGE_END_S,   EDGE_END_N,		],
  EDGE_N_E() => [ 0,		EDGE_START_E, EDGE_START_N, 0		 	,
		  EDGE_END_E,	0,	      0, 	    EDGE_END_N, 	],
  EDGE_N_W() => [ EDGE_START_W,	0, 	      EDGE_START_N, 0			,
		  0,	        EDGE_END_W,   0,	    EDGE_END_N,		],
  EDGE_S_E() => [ 0,		EDGE_START_E, 0,	    EDGE_START_S 	,
		  EDGE_END_E,   0,            EDGE_END_S,   0,			],
  EDGE_S_W() => [ EDGE_START_W,	0, 	      0,	    EDGE_START_S	,
		  0,		EDGE_END_W,   EDGE_END_S,   0,			],
  };

my $start_to_end = {
  EDGE_START_W() => EDGE_END_W(),
  EDGE_START_E() => EDGE_END_E(),
  EDGE_START_S() => EDGE_END_S(),
  EDGE_START_N() => EDGE_END_N(),
  };

sub _end_points
  {
  # modify last field of path to be the correct endpoint; and the first field
  # to be the correct startpoint:
  my ($self, $edge, $coords, $dx, $dy) = @_;
  
  return $coords if $edge->undirected();

  # there are two cases (for each dx and dy)
  my $i = 0;					# index 0,1
  my $co = 2;
  my $case;

  for my $d ($dx,$dy,$dx,$dy)
    {
    next if $d == 0;

    my $type = $coords->[$co] & EDGE_TYPE_MASK;

    $case = 0; $case = 1 if $d == -1;

    # modify first/last cell
    my $t = $start_points->{ $type }->[ $case + $i ];
    # on bidirectional edges, turn START_X into END_X
    $t = $start_to_end->{$t} || $t if $edge->{bidirectional};

    $coords->[$co] += $t;

    } continue {
    $i += 2; 					# index 2,3, 4,5 etc
    $co = -1 if $i == 4;			# modify now last cell
    }
  $coords;
  }

sub _find_path
  {
  # Try to find a path between two nodes. $options contains direction
  # preferences. Returns a list of cells like:
  # [ $x,$y,$type, $x1,$y1,$type1, ...]
  my ($self, $src, $dst, $edge) = @_;

  # one node pointing back to itself?
  if ($src == $dst)
    {
    my $rc = $self->_find_path_loop($src,$edge);
    return $rc unless scalar @$rc == 0;
    }

  # If one of the two nodes is bigger than 1 cell, use _find_path_astar(),
  # because it automatically handles all the possibilities:
  return $self->_find_path_astar($edge)
    if ($src->is_multicelled() || $dst->is_multicelled() || $edge->has_ports());
  
  my ($x0, $y0) = ($src->{x}, $src->{y});
  my ($x1, $y1) = ($dst->{x}, $dst->{y});
  my $dx = ($x1 - $x0) <=> 0;
  my $dy = ($y1 - $y0) <=> 0;
    
  my $cells = $self->{cells};
  my @coords;
  my ($x,$y) = ($x0,$y0);			# starting pos

  ###########################################################################
  # below follow some shortcuts for easy things like straight paths:

  print STDERR "#  dx,dy: $dx,$dy\n" if $self->{debug};

  if ($dx == 0 || $dy == 0)
    {
    # try straight path to target:
 
    print STDERR "#  $src->{x},$src->{y} => $dst->{x},$dst->{y} - trying short path\n" if $self->{debug};

    # distance to node:
    my $dx1 = ($x1 - $x0);
    my $dy1 = ($y1 - $y0);
    ($x,$y) = ($x0+$dx,$y0+$dy);			# starting pos

    if ((abs($dx1) == 2) || (abs($dy1) == 2))
      {
      if (!exists ($cells->{"$x,$y"}))
        {
        # a single step for this edge:
        my $type = EDGE_LABEL_CELL;
        # short path
        if ($edge->bidirectional())
	  {
          $type += EDGE_SHORT_BD_EW if $dy == 0;
          $type += EDGE_SHORT_BD_NS if $dx == 0;
          }
        elsif ($edge->undirected())
          {
          $type += EDGE_SHORT_UN_EW if $dy == 0;
          $type += EDGE_SHORT_UN_NS if $dx == 0;
          }
        else
          {
          $type += EDGE_SHORT_E if ($dx ==  1 && $dy ==  0);
          $type += EDGE_SHORT_S if ($dx ==  0 && $dy ==  1);
          $type += EDGE_SHORT_W if ($dx == -1 && $dy ==  0);
          $type += EDGE_SHORT_N if ($dx ==  0 && $dy == -1);
          }
	# if one of the end points of the edge is of shape 'edge'
	# remove end/start flag
        if (($edge->{to}->attribute('shape') ||'') eq 'edge')
	  {
	  # we only need to remove one start point, namely the one at the "end"
	  if ($dx > 0)
	    {
	    $type &= ~EDGE_START_E;
	    }
	  elsif ($dx < 0)
	    {
	    $type &= ~EDGE_START_W;
	    }
	  }
        if (($edge->{from}->attribute('shape') ||'') eq 'edge')
	  {
	  $type &= ~EDGE_START_MASK;
	  }

        return [ $x, $y, $type ];			# return a short EDGE
        }
      }

    my $type = EDGE_HOR; $type = EDGE_VER if $dx == 0;	# - or |
    my $done = 0;
    my $label_done = 0;
    while (3 < 5)		# endless loop
      {
      # Since we do not handle crossings here, A* will be tried if we hit an
      # edge in this test.
      $done = 1, last if exists $cells->{"$x,$y"};	# cell already full

      # the first cell gets the label
      my $t = $type; $t += EDGE_LABEL_CELL if $label_done++ == 0;

      push @coords, $x, $y, $t;				# good one, is free
      $x += $dx; $y += $dy;				# next field
      last if ($x == $x1) && ($y == $y1);
      }

    if ($done == 0)
      {
      print STDERR "#  success for ", scalar @coords / 3, " steps in path\n" if $self->{debug};
      # return all fields of path
      return $self->_end_points($edge, \@coords, $dx, $dy);
      }

    } # end else straight path try

  ###########################################################################
  # Try paths with one bend:

  # ($dx != 0 && $dy != 0) => path with one bend
  # XXX TODO:
  # This could be handled by A*, too, but it would be probably a bit slower.
  else
    {
    # straight path not possible, since x0 != x1 AND y0 != y1

    #           "  |"                        "|   "
    # try first "--+" (aka hor => ver), then "+---" (aka ver => hor)
    my $done = 0;

    print STDERR "#  bend path from $x,$y\n" if $self->{debug};

    # try hor => ver
    my $type = EDGE_HOR;

    my $label = 0;						# attach label?
    $label = 1 if ref($edge) && ($edge->label()||'') eq '';	# no label?
    $x += $dx;
    while ($x != $x1)
      {
      $done++, last if exists $cells->{"$x,$y"};	# cell already full
      print STDERR "#  at $x,$y\n" if $self->{debug};
      my $t = $type; $t += EDGE_LABEL_CELL if $label++ == 0;
      push @coords, $x, $y, $t;				# good one, is free
      $x += $dx;					# next field
      };

    # check the bend itself     
    $done++ if exists $cells->{"$x,$y"};	# cell already full

    if ($done == 0)
      {
      my $type_bend = _astar_edge_type ($x-$dx,$y, $x,$y, $x,$y+$dy);
 
      push @coords, $x, $y, $type_bend;			# put in bend
      print STDERR "# at $x,$y\n" if $self->{debug};
      $y += $dy;
      $type = EDGE_VER;
      while ($y != $y1)
        {
        $done++, last if exists $cells->{"$x,$y"};	# cell already full
	print STDERR "# at $x,$y\n" if $self->{debug};
        push @coords, $x, $y, $type;			# good one, is free
        $y += $dy;
        } 
      }

    if ($done != 0)
      {
      $done = 0;
      # try ver => hor
      print STDERR "# hm, now trying first vertical, then horizontal\n" if $self->{debug};
      $type = EDGE_VER;

      @coords = ();					# drop old version
      ($x,$y) = ($x0, $y0 + $dy);			# starting pos
      while ($y != $y1)
        {
        $done++, last if exists $cells->{"$x,$y"};	# cell already full
        print STDERR "# at $x,$y\n" if $self->{debug};
        push @coords, $x, $y, $type;			# good one, is free
        $y += $dy;					# next field
        };

      # check the bend itself     
      $done++ if exists $cells->{"$x,$y"};		# cell already full

      if ($done == 0)
        {
        my $type_bend = _astar_edge_type ($x,$y-$dy, $x,$y, $x+$dx,$y);

        push @coords, $x, $y, $type_bend;		# put in bend
        print STDERR "# at $x,$y\n" if $self->{debug};
        $x += $dx;
        my $label = 0;					# attach label?
        $label = 1 if $edge->label() eq '';		# no label?
        $type = EDGE_HOR;
        while ($x != $x1)
          {
          $done++, last if exists $cells->{"$x,$y"};	# cell already full
	  print STDERR "# at $x,$y\n" if $self->{debug};
          my $t = $type; $t += EDGE_LABEL_CELL if $label++ == 0;
          push @coords, $x, $y, $t;			# good one, is free
	  $x += $dx;
          } 
        }
      }

    if ($done == 0)
      {
      print STDERR "# success for ", scalar @coords / 3, " steps in path\n" if $self->{debug};
      # return all fields of path
      return $self->_end_points($edge, \@coords, $dx, $dy);
      }

    print STDERR "# no success\n" if $self->{debug};

    } # end path with $dx and $dy

  $self->_find_path_astar($edge);		# try generic approach as last hope
  }

sub _find_path_loop
  {
  # find a path from one node back to itself
  my ($self, $src, $edge) = @_;

  print STDERR "# Finding looping path from $src->{name} to $src->{name}\n" if $self->{debug};

  my ($n, $cells, $d, $type, $loose) = @_;

  # get a list of all places

  my @places = $src->_near_places( 
    $self->{cells}, 1, [
      EDGE_LOOP_EAST,
      EDGE_LOOP_SOUTH,
      EDGE_LOOP_WEST,
      EDGE_LOOP_NORTH,
    ], 0, 90);
  
  my $flow = $src->flow();

  # We cannot use _shuffle_dir() here, because self-loops
  # are tried in a different order:

  # the default (east)
  my $index = [
    EDGE_LOOP_NORTH,
    EDGE_LOOP_SOUTH,
    EDGE_LOOP_WEST,
    EDGE_LOOP_EAST,
   ];

  # west
  $index = [
    EDGE_LOOP_SOUTH,
    EDGE_LOOP_NORTH,
    EDGE_LOOP_EAST,
    EDGE_LOOP_WEST,
   ] if $flow == 270;

  # north
  $index = [
    EDGE_LOOP_WEST,
    EDGE_LOOP_EAST,
    EDGE_LOOP_SOUTH,
    EDGE_LOOP_NORTH,
   ] if $flow == 0;
  
  # south
  $index = [
    EDGE_LOOP_EAST,
    EDGE_LOOP_WEST,
    EDGE_LOOP_NORTH,
    EDGE_LOOP_SOUTH,
   ] if $flow == 180;
  
  for my $this_try (@$index)
    {
    my $idx = 0;
    while ($idx < @places)
      {
      print STDERR "# Trying $places[$idx+0],$places[$idx+1]\n" if $self->{debug};
      next unless $places[$idx+2] == $this_try;
      
      # build a path from the returned piece
      my @rc = ($places[$idx], $places[$idx+1], $places[$idx+2]);

      print STDERR "# Trying $rc[0],$rc[1]\n" if $self->{debug};

      next unless $self->_path_is_clear(\@rc);

      print STDERR "# Found looping path\n" if $self->{debug};
      return \@rc;
      } continue { $idx += 3; } 
    }

  [];		# no path found
  }

#############################################################################
#############################################################################

# This package represents a simple/cheap/fast heap:
package Graph::Easy::Heap;

require Graph::Easy::Base;
our @ISA = qw/Graph::Easy::Base/;

use strict;

sub _init
  {
  my ($self,$args) = @_;

  $self->{_heap} = [ ];

  $self;
  }

sub add
  {
  # add one element to the heap
  my ($self,$elem) = @_;

  my $heap = $self->{_heap};

  # heap empty?
  if (@$heap == 0)
    {
    push @$heap, $elem;
    }
  # smaller than first elem?
  elsif ($elem->[0] < $heap->[0]->[0])
    {
    #print STDERR "# $elem->[0] is smaller then first elem $heap->[0]->[0] (with ", scalar @$heap," elems on heap)\n";
    unshift @$heap, $elem;
    }
  # bigger than or equal to last elem?
  elsif ($elem->[0] > $heap->[-1]->[0])
    {
    #print STDERR "# $elem->[0] is bigger then last elem $heap->[-1]->[0] (with ", scalar @$heap," elems on heap)\n";
    push @$heap, $elem;
    }
  else
    {
    # insert the elem at the right position

    # if we have less than X elements, use linear search
    my $el = $elem->[0];
    if (scalar @$heap < 10)
      {
      my $i = 0;
      for my $e (@$heap)
        {
        if ($e->[0] > $el)
          {
          splice (@$heap, $i, 0, $elem);		# insert $elem
          return undef;
          }
        $i++;
        }
      # else, append at the end
      push @$heap, $elem;
      }
    else
      {
      # use binary search
      my $l = 0; my $r = scalar @$heap;
      while (($r - $l) > 2)
        {
        my $m = int((($r - $l) / 2) + $l);
#        print "l=$l r=$r m=$m el=$el heap=$heap->[$m]->[0]\n";
        if ($heap->[$m]->[0] <= $el)
          {
          $l = $m;
          }
        else
          {
          $r = $m;
          }
        }
      while ($l < @$heap)
        {
        if ($heap->[$l]->[0] > $el)
          {
          splice (@$heap, $l, 0, $elem);		# insert $elem
          return undef;
          }
        $l++;
        }
      # else, append at the end
      push @$heap, $elem;
      }
    }
  undef;
  }

sub elements
  {
  scalar @{$_[0]->{_heap}};
  }

sub extract_top
  {
  # remove and return the top elemt
  shift @{$_[0]->{_heap}};
  }

sub delete
  {
  # Find an element by $x,$y and delete it
  my ($self, $x, $y) = @_;

  my $heap = $self->{_heap};
  
  my $i = 0;
  for my $e (@$heap)
    {
    if ($e->[1] == $x && $e->[2] == $y)
      {
      splice (@$heap, $i, 1);
      return;
      }
    $i++;
    }

  $self;
  }

sub sort_sub
  {
  my ($self) = shift;

  $self->{_sort} = shift;
  }

#############################################################################
#############################################################################

package Graph::Easy;

# Generic pathfinding via the A* algorithm:
# See http://bloodgate.com/perl/graph/astar.html for some background.

sub _astar_modifier
  {
  # calculate the cost for the path at cell x1,y1 
  my ($x1,$y1,$x,$y,$px,$py, $cells) = @_;

  my $add = 1;

  if (defined $x1)
    {
    my $xy = "$x1,$y1";
    # add a harsh penalty for crossing an edge, meaning we can travel many
    # fields to go around.
    $add += 30 if ref($cells->{$xy}) && $cells->{$xy}->isa('Graph::Easy::Edge');
    }
 
  if (defined $px)
    {
    # see whether the new position $x1,$y1 is a continuation from $px,$py => $x,$y
    # e.g. if from we go down from $px,$py to $x,$y, then anything else then $x,$y+1 will
    # get a penalty
    my $dx1 = ($px-$x) <=> 0;
    my $dy1 = ($py-$y) <=> 0;
    my $dx2 = ($x-$x1) <=> 0;
    my $dy2 = ($y-$y1) <=> 0;
    $add += 6 unless $dx1 == $dx2 || $dy1 == $dy2;
    }
  $add;
  }

sub _astar_distance
  {
  # calculate the manhattan distance between x1,y1 and x2,y2
#  my ($x1,$y1,$x2,$y2) = @_;

  my $dx = abs($_[2] - $_[0]);
  my $dy = abs($_[3] - $_[1]);

  # plus 1 because we need to go around one corner if $dx != 0 && $dx != 0
  $dx++ if $dx != 0 && $dy != 0;

  $dx + $dy;
  }

my $edge_type = {
    '0,1,-1,0' => EDGE_N_W,
    '0,1,0,1' => EDGE_VER,
    '0,1,1,0' => EDGE_N_E,

    '-1,0,0,-1' => EDGE_N_E,
    '-1,0,-1,0' => EDGE_HOR,
    '-1,0,0,1' => EDGE_S_E,

    '0,-1,-1,0' => EDGE_S_W,
    '0,-1,0,-1' => EDGE_VER,
    '0,-1,1,0' => EDGE_S_E,

    '1,0,0,-1' => EDGE_N_W,
    '1,0,1,0' => EDGE_HOR,
    '1,0,0,1' => EDGE_S_W,

    # loops (left-right-left etc)
    '0,-1,0,1' => EDGE_N_W_S,
    '0,1,0,-1' => EDGE_S_W_N,
    '1,0,-1,0' => EDGE_E_S_W,
    '-1,0,1,0' => EDGE_W_S_E,
  };

sub _astar_edge_type
  {
  # from three consecutive positions calculate the edge type (VER, HOR, N_W etc)
  my ($x,$y, $x1,$y1, $x2, $y2) = @_;

  my $dx1 = ($x1 - $x) <=> 0;
  my $dy1 = ($y1 - $y) <=> 0;

  my $dx2 = ($x2 - $x1) <=> 0;
  my $dy2 = ($y2 - $y1) <=> 0;

  # in some cases we get (0,-1,0,0), so set the missing parts
  ($dx2,$dy2) = ($dx1,$dy1) if $dx2 == 0 && $dy2 == 0;
  # can this case happen?
  ($dx1,$dy1) = ($dx2,$dy2) if $dx1 == 0 && $dy1 == 0;

  # return correct type depending on differences
  $edge_type->{"$dx1,$dy1,$dx2,$dy2"} || EDGE_HOR;
  }

sub _astar_near_nodes
  {
  # return possible next nodes from $nx,$ny
  my ($self, $nx, $ny, $cells, $closed, $min_x, $min_y, $max_x, $max_y) = @_;

  my @places = ();

  my @tries  = (	# ordered E,S,W,N:
    $nx + 1, $ny, 	# right
    $nx, $ny + 1,	# down
    $nx - 1, $ny,	# left
    $nx, $ny - 1,	# up
    );

  # on crossings, only allow one direction (NS or EW)
  my $type = EDGE_CROSS;
  # including flags, because only flagless edges may be crossed
  $type = $cells->{"$nx,$ny"}->{type} if exists $cells->{"$nx,$ny"};
  if ($type == EDGE_HOR)
    {
    @tries  = (
      $nx, $ny + 1,	# down
      $nx, $ny - 1,	# up
    );
    }
  elsif ($type == EDGE_VER)
    {
    @tries  = (
      $nx + 1, $ny, 	# right
      $nx - 1, $ny,	# left
    );
    }

  # This loop does not check whether the position is already open or not,
  # the caller will later check if the already-open position needs to be
  # replaced by one with a lower cost.

  my $i = 0;
  while ($i < @tries)
    {
    my ($x,$y) = ($tries[$i], $tries[$i+1]);

    print STDERR "# $min_x,$min_y => $max_x,$max_y\n" if $self->{debug} > 2;

    # drop cells outside our working space:
    next if $x < $min_x || $x > $max_x || $y < $min_y || $y > $max_y;

    my $p = "$x,$y";
    print STDERR "# examining pos $p\n" if $self->{debug} > 2;

    next if exists $closed->{$p};

    if (exists $cells->{$p} && ref($cells->{$p}) && $cells->{$p}->isa('Graph::Easy::Edge'))
      {
      # If the existing cell is an VER/HOR edge, then we may cross it
      my $type = $cells->{$p}->{type};	# including flags, because only flagless edges
					# may be crossed

      push @places, $x, $y if ($type == EDGE_HOR) || ($type == EDGE_VER);
      next;
      }
    next if exists $cells->{$p};	# uncrossable cell

    push @places, $x, $y;

    } continue { $i += 2; }
 
  @places;
  }

sub _astar_boundaries
  {
  # Calculate boundaries for area that A* should not leave.
  my $self = shift;

  my $cache = $self->{cache};

  return ( $cache->{min_x}-1, $cache->{min_y}-1, 
	   $cache->{max_x}+1, $cache->{max_y}+1 ) if defined $cache->{min_x};

  my ($min_x, $min_y, $max_x, $max_y);

  my $cells = $self->{cells};

  $min_x = 10000000;
  $min_y = 10000000;
  $max_x = -10000000;
  $max_y = -10000000;

  for my $c (keys %$cells)
    {
    my ($x,$y) = split /,/, $c;
    $min_x = $x if $x < $min_x;
    $min_y = $y if $y < $min_y;
    $max_x = $x if $x > $max_x;
    $max_y = $y if $y > $max_y;
    }

  print STDERR "# A* working space boundaries: $min_x, $min_y, $max_x, $max_y\n" if $self->{debug};

  ( $cache->{min_x}, $cache->{min_y}, $cache->{max_x}, $cache->{max_y} ) = 
  ($min_x, $min_y, $max_x, $max_y);

  # make the area one bigger in each direction
  $min_x --; $min_y --; $max_x ++; $max_y ++;
  ($min_x, $min_y, $max_x, $max_y);
  }

# on edge pieces, select start fields (left/right of a VER, above/below of a HOR etc)
# contains also for each starting position the joint-type
my $next_fields =
  {
  EDGE_VER() => [ -1,0, EDGE_W_N_S, +1,0, EDGE_E_N_S ],
  EDGE_HOR() => [ 0,-1, EDGE_N_E_W, 0,+1, EDGE_S_E_W ],
  EDGE_N_E() => [ 0,+1, EDGE_E_N_S, -1,0, EDGE_N_E_W ],		# |_
  EDGE_N_W() => [ 0,+1, EDGE_W_N_S, +1,0, EDGE_N_E_W ],		# _|
  EDGE_S_E() => [ 0,-1, EDGE_E_N_S, -1,0, EDGE_S_E_W ],
  EDGE_S_W() => [ 0,-1, EDGE_W_N_S, +1,0, EDGE_S_E_W ],
  };

# on edge pieces, select end fields (left/right of a VER, above/below of a HOR etc)
# contains also for each end position the joint-type
my $prev_fields =
  {
  EDGE_VER() => [ -1,0, EDGE_W_N_S, +1,0, EDGE_E_N_S ],
  EDGE_HOR() => [ 0,-1, EDGE_N_E_W, 0,+1, EDGE_S_E_W ],
  EDGE_N_E() => [ 0,+1, EDGE_E_N_S, -1,0, EDGE_N_E_W ],		# |_
  EDGE_N_W() => [ 0,+1, EDGE_W_N_S, +1,0, EDGE_N_E_W ],		# _|
  EDGE_S_E() => [ 0,-1, EDGE_E_N_S, -1,0, EDGE_S_E_W ],
  EDGE_S_W() => [ 0,-1, EDGE_W_N_S, +1,0, EDGE_S_E_W ],
  };

sub _get_joints
  { 
  # from a list of shared, already placed edges, get possible start/end fields
  my ($self, $shared, $mask, $types, $cells, $next_fields) = @_;

  # XXX TODO: do not do this for edges with no free places for joints

  # take each cell from all edges shared, already placed edges as start-point
  for my $e (@$shared)
    {
    for my $c (@{$e->{cells}})
      {
      my $type = $c->{type} & EDGE_TYPE_MASK;

      next unless exists $next_fields->{ $type };

      # don't consider end/start (depending on $mask) cells

      # do not join EDGE_HOR or EDGE_VER, but join corner pieces
      next if ( ($type == EDGE_HOR()) || 
		($type == EDGE_VER()) ) &&
		($c->{type} & $mask);

      my $fields = $next_fields->{$type};

      my ($px,$py) = ($c->{x},$c->{y});
      my $i = 0;
      while ($i < @$fields)
	{
	my ($sx,$sy, $jt) = ($fields->[$i], $fields->[$i+1], $fields->[$i+2]);
	$sx += $px; $sy += $py; $i += 3;
        my $sxsy = "$sx,$sy";
        # don't add the field twice
	next if exists $cells->{$sxsy};
	$cells->{$sxsy} = [ $sx, $sy, undef, $px, $py ];
	# keep eventually set start/end points on the original cell
	$types->{$sxsy} = $jt + ($c->{type} & EDGE_FLAG_MASK);
	} 
      }
    }
 
  my @R;
  # convert hash to array
  for my $s (values %{$cells})
    {
    push @R, @$s;
    }
  @R;
  }

sub _join_edge
  {
  # Find out whether an edge sharing an ending point with the source edge
  # runs alongside the source node, if so, convert it to a joint:
  my ($self, $node, $edge, $shared, $end) = @_;

  # we check the sides B,C,D and E for HOR and VER edge pices:
  #   --D--
  # | +---+ |
  # E | A | B
  # | +---+ |
  #   --C--

  my $flags = 
   [ 
      EDGE_W_N_S + EDGE_START_W,
      EDGE_N_E_W + EDGE_START_N,
      EDGE_E_N_S + EDGE_START_E,
      EDGE_S_E_W + EDGE_START_S,
   ];
  $flags = 
   [ 
      EDGE_W_N_S + EDGE_END_W,
      EDGE_N_E_W + EDGE_END_N,
      EDGE_E_N_S + EDGE_END_E,
      EDGE_S_E_W + EDGE_END_S,
   ] if $end || $edge->{bidirectional};
  
  my $cells = $self->{cells};
  my @places = $node->_near_places($cells, 1, # distance 1
   $flags, 'loose'); 

  my $i = 0;
  while ($i < @places)
    {
    my ($x,$y) = ($places[$i], $places[$i+1]); $i += 3;
    
    next unless exists $cells->{"$x,$y"};		# empty space?
    # found some cell, check that it is a EDGE_HOR or EDGE_VER
    my $cell = $cells->{"$x,$y"};
    next unless $cell->isa('Graph::Easy::Edge::Cell');

    my $cell_type = $cell->{type} & EDGE_TYPE_MASK;

    next unless $cell_type == EDGE_HOR || $cell_type == EDGE_VER;

    # the cell must belong to one of the shared edges
    my $e = $cell->{edge}; local $_;
    next unless scalar grep { $e == $_ } @$shared;

    # make the cell at the current pos a joint
    $cell->_make_joint($edge,$places[$i-1]);

    # The layouter will check that each edge has a cell, so add a dummy one to
    # $edge to make it happy:
    Graph::Easy::Edge::Cell->new( type => EDGE_HOLE, edge => $edge, x => $x, y => $y );

    return [];					# path is empty
    }

  undef;		# did not find an edge cell that can be used as joint
  }

sub _find_path_astar
  {
  # Find a path with the A* algorithm for the given edge (from node A to B)
  my ($self,$edge) = @_;

  my $cells = $self->{cells};
  my $src = $edge->{from};
  my $dst = $edge->{to};

  print STDERR "# A* from $src->{x},$src->{y} to $dst->{x},$dst->{y}\n" if $self->{debug};

  my $start_flags = [
    EDGE_START_W,
    EDGE_START_N,
    EDGE_START_E,
    EDGE_START_S,
  ]; 

  my $end_flags = [
    EDGE_END_W,
    EDGE_END_N,
    EDGE_END_E,
    EDGE_END_S,
  ]; 

  # if the target/source node is of shape "edge", remove the endpoint
  if ( ($edge->{to}->attribute('shape')) eq 'edge')
    {
    $end_flags = [ 0,0,0,0 ];
    }
  if ( ($edge->{from}->attribute('shape')) eq 'edge')
    {
    $start_flags = [ 0,0,0,0 ];
    }

  my ($s_p,@ss_p) = $edge->port('start');
  my ($e_p,@ee_p) = $edge->port('end');
  my (@A, @B);					# Start/Stop positions
  my @shared_start;
  my @shared_end;

  my $joint_type = {};
  my $joint_type_end = {};

  my $start_cells = {};
  my $end_cells = {};

  ###########################################################################
  # end fields first (because maybe an edge runs alongside the node)

  # has a end point restriction
  @shared_end = $edge->{to}->edges_at_port('end', $e_p, $ee_p[0]) if defined $e_p && @ee_p == 1;

  my @shared = ();
  # filter out all non-placed edges (this will also filter out $edge)
  for my $s (@shared_end)
    {
    push @shared, $s if @{$s->{cells}} > 0;
    }

  my $per_field = 5;			# for shared: x,y,undef, px,py
  if (@shared > 0)
    {
    # more than one edge share the same end port, and one of the others was
    # already placed

    print STDERR "#  edge from '$edge->{from}->{name}' to '$edge->{to}->{name}' shares end port with ",
	scalar @shared, " other edge(s)\n" if $self->{debug};

    # if there is one of the already-placed edges running alongside the src
    # node, we can just convert the field to a joint and be done
    my $path = $self->_join_edge($src,$edge,\@shared);
    return $path if $path;				# already done?

    @B = $self->_get_joints(\@shared, EDGE_START_MASK, $joint_type_end, $end_cells, $prev_fields);
    }
  else
    {
    # potential stop positions
    @B = $dst->_near_places($cells, 1, $end_flags, 1);	# distance = 1: slots

    # the edge has a port description, limiting the end places
    @B = $dst->_allowed_places( \@B, $dst->_allow( $e_p, @ee_p ), 3)
      if defined $e_p;

    $per_field = 3;			# x,y,type
    }

  return unless scalar @B > 0;			# no free slots on target node?

  ###########################################################################
  # start fields

  # has a starting point restriction:
  @shared_start = $edge->{from}->edges_at_port('start', $s_p, $ss_p[0]) if defined $s_p && @ss_p == 1;

  @shared = ();
  # filter out all non-placed edges (this will also filter out $edge)
  for my $s (@shared_start)
    {
    push @shared, $s if @{$s->{cells}} > 0;
    }

  if (@shared > 0)
    {
    # More than one edge share the same start port, and one of the others was
    # already placed, so we just run along until we catch it up with a joint:

    print STDERR "#  edge from '$edge->{from}->{name}' to '$edge->{to}->{name}' shares start port with ",
	scalar @shared, " other edge(s)\n" if $self->{debug};

    # if there is one of the already-placed edges running alongside the src
    # node, we can just convert the field to a joint and be done
    my $path = $self->_join_edge($dst, $edge, \@shared, 'end');
    return $path if $path;				# already done?

    @A = $self->_get_joints(\@shared, EDGE_END_MASK, $joint_type, $start_cells, $next_fields);
    }
  else
    {
    # from SRC to DST

    # get all the starting positions
    # distance = 1: slots, generate starting types, the direction is shifted
    # by 90° counter-clockwise

    my $s = $start_flags; $s = $end_flags if $edge->{bidirectional};
    my @start = $src->_near_places($cells, 1, $s, 1, $src->_shift(-90) );

    # the edge has a port description, limiting the start places
    @start = $src->_allowed_places( \@start, $src->_allow( $s_p, @ss_p ), 3)
      if defined $s_p;

    return unless @start > 0;			# no free slots on start node?

    my $i = 0;
    while ($i < scalar @start)
      {
      my $sx = $start[$i]; my $sy = $start[$i+1]; my $type = $start[$i+2]; $i += 3;

      # compute the field inside the node from where $sx,$sy is reached:
      my $px = $sx; my $py = $sy;
      if ($sy < $src->{y} || $sy >= $src->{y} + $src->{cy})
        {
        $py = $sy + 1 if $sy < $src->{y};		# above
        $py = $sy - 1 if $sy > $src->{y};		# below
        }
      else
        {
        $px = $sx + 1 if $sx < $src->{x};		# right
        $px = $sx - 1 if $sx > $src->{x};		# left
        }

      push @A, ($sx, $sy, $type, $px, $py);
      }
    }

  ###########################################################################
  # use A* to finally find the path:

  my $path = $self->_astar(\@A,\@B,$edge, $per_field);

  if (@$path > 0 && keys %$start_cells > 0)
    {
    # convert the edge piece of the starting edge-cell to a joint
    my ($x, $y) = ($path->[0],$path->[1]);
    my $xy = "$x,$y";
    my ($sx,$sy,$t,$px,$py) = @{$start_cells->{$xy}};

    my $jt = $joint_type->{"$sx,$sy"};
    $cells->{"$px,$py"}->_make_joint($edge,$jt);
    }

  if (@$path > 0 && keys %$end_cells > 0)
    {
    # convert the edge piece of the starting edge-cell to a joint
    my ($x, $y) = ($path->[-3],$path->[-2]);
    my $xy = "$x,$y";
    my ($sx,$sy,$t,$px,$py) = @{$end_cells->{$xy}};

    my $jt = $joint_type_end->{"$sx,$sy"};
    $cells->{"$px,$py"}->_make_joint($edge,$jt);
    }

  $path;
  }

sub _astar
  {
  # The core A* algorithm, finds a path from a given list of start
  # positions @A to and of the given stop positions @B.
  my ($self, $A, $B, $edge, $per_field) = @_;

  my @start = @$A;
  my @stop = @$B;
  my $stop = scalar @stop;

  my $src = $edge->{from};
  my $dst = $edge->{to};
  my $cells = $self->{cells};

  my $open = Graph::Easy::Heap->new();	# to find smallest elem fast
  my $open_by_pos = {};			# to find open nodes by pos
  my $closed = {};			# to find closed nodes by pos

  my $elem;

  # The boundaries of objects in $cell, e.g. the area that the algorithm shall
  # never leave.
  my ($min_x, $min_y, $max_x, $max_y) = $self->_astar_boundaries();

  # Max. steps to prevent endless searching in case of bugs like endless loops.
  my $tries = 0; my $max_tries = 2000000;

  # count how many times we did A*
  $self->{stats}->{astar}++;

  ###########################################################################
  ###########################################################################
  # put the start positions into OPEN

  my $i = 0; my $bias = 0;
  while ($i < scalar @start)
    {
    my ($sx,$sy,$type,$px,$py) = 
     ($start[$i],$start[$i+1],$start[$i+2],$start[$i+3],$start[$i+4]);
    $i += 5;

    my $cell = $cells->{"$sx,$sy"}; my $rcell = ref($cell);
    next if $rcell && $rcell !~ /::Edge/;

    my $t = 0; $t = $cell->{type} & EDGE_NO_M_MASK if $rcell =~ /::Edge/;
    next if $t != 0 && $t != EDGE_HOR && $t != EDGE_VER;

    # For each start point, calculate the distance to each stop point, then use
    # the smallest as value:
    my $lowest_x = $stop[0]; my $lowest_y = $stop[1];
    my $lowest = _astar_distance($sx,$sy, $stop[0], $stop[1]);
    for (my $u = $per_field; $u < $stop; $u += $per_field)
      {
      my $dist = _astar_distance($sx,$sy, $stop[$u], $stop[$u+1]);
      ($lowest_x, $lowest_y) = ($stop[$u],$stop[$u+1]) if $dist < $lowest;
      $lowest = $dist if $dist < $lowest;
      }


    # add a penalty for crossings
    my $malus = 0; $malus = 30 if $t != 0;
    $malus += _astar_modifier($px,$py, $sx, $sy, $sx, $sy);
    $open->add( [ $lowest, $sx, $sy, $px, $py, $type, 1 ] );

    my $o = $malus + $bias + $lowest;
    print STDERR "#   adding open pos $sx,$sy ($o = $malus + $bias + $lowest) at ($lowest_x,$lowest_y)\n"
	 if $self->{debug} > 1;

    # The cost to reach the starting node is obviously 0. That means that there is
    # a tie between going down/up if both possibilities are equal likely. We insert
    # a small bias here that makes the prefered order east/south/west/north. Instead
    # the algorithmn exploring both way and terminating arbitrarily on the one that
    # first hits the target, it will explore only one.
    $open_by_pos->{"$sx,$sy"} = $o;

    $bias += $self->{_astar_bias} || 0;
    } 

  ###########################################################################
  ###########################################################################
  # main A* loop

  my $stats = $self->{stats};

  STEP:
  while( defined( $elem = $open->extract_top() ) )
    {
    $stats->{astar_steps}++ if $self->{debug};

    # hard limit on number of steps todo
    if ($tries++ > $max_tries)
      {
      $self->warn("A* reached maximum number of tries ($max_tries), giving up."); 
      return [];
      }

    print STDERR "#  Smallest elem from ", $open->elements(), 
	" elems is: weight=", $elem->[0], " at $elem->[1],$elem->[2]\n" if $self->{debug} > 1;
    my ($val, $x,$y, $px,$py, $type, $do_stop) = @$elem;

    my $key = "$x,$y";
    # move node into CLOSE and remove from OPEN
    my $g = $open_by_pos->{$key} || 0;
    $closed->{$key} = [ $px, $py, $val - $g, $g, $type, $do_stop ];
    delete $open_by_pos->{$key};

    # we are done when we hit one of the potential stop positions
    for (my $i = 0; $i < $stop; $i += $per_field)
      {
      # reached one stop position?
      if ($x == $stop[$i] && $y == $stop[$i+1])
        {
        $closed->{$key}->[4] += $stop[$i+2] if defined $stop[$i+2];
	# store the reached stop position if it is known
	if ($per_field > 3)
	  {
	  $closed->{$key}->[6] = $stop[$i+3];
	  $closed->{$key}->[7] = $stop[$i+4];
          print STDERR "#  Reached stop position $x,$y (lx,ly $stop[$i+3], $stop[$i+4])\n" if $self->{debug} > 1;
	  }
        elsif ($self->{debug} > 1) {
          print STDERR "#  Reached stop position $x,$y\n";
          }
        last STEP;
        }
      } # end test for stop postion(s)

    $self->_croak("On of '$x,$y' is not defined")
      unless defined $x && defined $y;
      
    # get list of potential positions we need to explore from the current one
    my @p = $self->_astar_near_nodes($x,$y, $cells, $closed, $min_x, $min_y, $max_x, $max_y);

    my $n = 0;
    while ($n < scalar @p)
      {
      my $nx = $p[$n]; my $ny = $p[$n+1]; $n += 2;

      if (!defined $nx || !defined $ny)
        {
        require Carp;
        Carp::confess("On of '$nx,$ny' is not defined");
        }
      my $lg = $g;
      $lg += _astar_modifier($px,$py,$x,$y,$nx,$ny,$cells) if defined $px && defined $py;

      my $n = "$nx,$ny";

      # was already open?
      next if (exists $open_by_pos->{$n});

#      print STDERR "#   Already open pos $nx,$ny with $open_by_pos->{$n} (would be $lg)\n"
#	 if $self->{debug} && exists $open_by_pos->{$n};
#
#      next if exists $open_by_pos->{$n} && $open_by_pos->{$n} <= $lg; 
#
#      if (exists $open_by_pos->{$n})
#        {
#        $open->delete($nx, $ny);
#        }

      # calculate distance to each possible stop position, and
      # use the lowest one
      my $lowest_distance = _astar_distance($nx, $ny, $stop[0], $stop[1]);
      for (my $i = $per_field; $i < $stop; $i += $per_field)
        {
        my $d = _astar_distance($nx, $ny, $stop[$i], $stop[$i+1]);
        $lowest_distance = $d if $d < $lowest_distance; 
        }

      print STDERR "#   Opening pos $nx,$ny ($lowest_distance + $lg)\n" if $self->{debug} > 1;

      # open new position into OPEN
      $open->add( [ $lowest_distance + $lg, $nx, $ny, $x, $y, undef ] );
      $open_by_pos->{$n} = $lg;
      }
    }

  ###########################################################################
  # A* is done, now build a path from the information we computed above:

  # count how many steps we did in A*
  $self->{stats}->{astar_steps} += $tries;

  # no more nodes to follow, so we couldn't find a path
  if (!defined $elem)
    {
    print STDERR "# A* couldn't find a path after $max_tries steps.\n" if $self->{debug};
    return [];
    }

  my $path = [];
  my ($cx,$cy) = ($elem->[1],$elem->[2]);
  # the "last" cell in the path. Since we follow it backwards, it
  # becomes actually the next cell
  my ($lx,$ly);
  my $type;

  my $label_cell = 0;		# found a cell to attach the label to?

  my @bends;			# record all bends in the path to straighten it out

  my $idx = 0;
  # follow $elem back to the source to find the path
  while (defined $cx)
    {
    last unless exists $closed->{"$cx,$cy"};
    my $xy = "$cx,$cy";

    $type = $closed->{$xy}->[ 4 ];

    my ($px,$py) = @{ $closed->{$xy} };		# get X,Y of parent cell

    my $edge_type = ($type||0) & EDGE_TYPE_MASK;
    if ($edge_type == 0)
      {
      my $edge_flags = ($type||0) & EDGE_FLAG_MASK;

      # either a start or a stop cell
      if (!defined $px)
	{
	# We can figure it out from the flag of the position of cx,cy
	#        ................
	#         : EDGE_START_S :
	# .......................................
	# START_E :    px,py     : EDGE_START_W :
	# .......................................
	#         : EDGE_START_N :
	#         ................
	($px,$py) = ($cx, $cy);		# start with same cell
	$py ++ if ($edge_flags & EDGE_START_S) != 0; 
	$py -- if ($edge_flags & EDGE_START_N) != 0; 

	$px ++ if ($edge_flags & EDGE_START_E) != 0; 
	$px -- if ($edge_flags & EDGE_START_W) != 0; 
	}

      # if lx, ly is undefined because px,py is a joint, get it via the stored
      # x,y pos of the very last cell in the path
      if (!defined $lx)
     	{ 
	$lx = $closed->{$xy}->[6];
	$ly = $closed->{$xy}->[7];
	}

      # still not known?
      if (!defined $lx)
	{

	# If lx,ly is undefined because we are at the end of the path,
   	# we can figure out from the flag of the position of cx,cy.
	#       ..............
	#       : EDGE_END_S :
	# .................................
	# END_E :    lx,ly   : EDGE_END_W :
	# .................................
	#       : EDGE_END_N :
	#       ..............
	($lx,$ly) = ($cx, $cy);		# start with same cell

	$ly ++ if ($edge_flags & EDGE_END_S) != 0; 
	$ly -- if ($edge_flags & EDGE_END_N) != 0; 

	$lx ++ if ($edge_flags & EDGE_END_E) != 0; 
	$lx -- if ($edge_flags & EDGE_END_W) != 0; 
	}

      # now figure out correct type for this cell from positions of
      # parent/following cell
      $type += _astar_edge_type($px, $py, $cx, $cy, $lx,$ly);
      }

    print STDERR "#  Following back from $lx,$ly over $cx,$cy to $px,$py\n" if $self->{debug} > 1;

    if ($px == $lx && $py == $ly && ($cx != $lx || $cy != $ly))
      {
      print STDERR 
       "# Warning: A* detected loop in path-backtracking at $px,$py, $cx,$cy, $lx,$ly\n"
       if $self->{debug};
      last;
      }

    $type = EDGE_HOR if ($type & EDGE_TYPE_MASK) == 0;		# last resort

    # if this is the first hor edge, attach the label to it
    # XXX TODO: This clearly is not optimal. Look for left-most HOR CELL
    my $t = $type & EDGE_TYPE_MASK;

    # Do not put the label on crossings:
    if ($label_cell == 0 && (!exists $cells->{"$cx,$cy"}) && ($t == EDGE_HOR || $t == EDGE_VER))
      {
      $label_cell++;
      $type += EDGE_LABEL_CELL;
      }

    push @bends, [ $type, $cx, $cy, -$idx ]
	if ($type == EDGE_S_E || $t == EDGE_S_W || $t == EDGE_N_E || $t == EDGE_N_W);

    unshift @$path, $cx, $cy, $type;		# unshift to reverse the path

    last if $closed->{"$cx,$cy"}->[ 5 ];	# stop here?

    ($lx,$ly) = ($cx,$cy);
    ($cx,$cy) = @{ $closed->{"$cx,$cy"} };	# get X,Y of next cell

    $idx += 3;					# index into $path (for bends)
    }

  print STDERR "# Trying to straighten path\n" if @bends >= 3 && $self->{debug};

  # try to straighten unnec. inward bends
  $self->_straighten_path($path, \@bends, $edge) if @bends >= 3;

  return ($path,$closed,$open_by_pos) if wantarray;
  $path;
  }

  # 1:
  #           |             |
  #      +----+   =>        |
  #      |                  |
  #  ----+            ------+

  # 2:
  #      +---         +------
  #      |            |
  #  +---+        =>  |
  #  |                |

  # 3:
  #  ----+            ------+
  #      |        =>        |
  #      +----+             |
  #           |             |

  # 4:
  #  |                |
  #  +---+            |
  #      |        =>  |
  #      +----+       +------

my $bend_patterns = [

  # The patterns are duplicated to catch both directions of the path:

  # First five entries must match
  #				 dx, dy,
  #				        coordinates for new edge
  #				        (2 == y, 1 == x, first is
  #				        taken from A, second from B)
  # 						  these replace the first & last bend
  # 1:
  [ EDGE_N_W, EDGE_S_E, EDGE_N_W, 0, -1, 2, 1, EDGE_HOR, EDGE_VER, 1,0,  0,-1 ],	# 0
  [ EDGE_N_W, EDGE_S_E, EDGE_N_W, -1, 0, 1, 2, EDGE_VER, EDGE_HOR, 0,1,  -1,0 ],	# 1

  # 2:
  [ EDGE_S_E, EDGE_N_W, EDGE_S_E, 0, -1, 1, 2, EDGE_VER, EDGE_HOR, 0,-1, 1,0 ],		# 2
  [ EDGE_S_E, EDGE_N_W, EDGE_S_E, -1, 0, 2, 1, EDGE_HOR, EDGE_VER, -1,0, 0,1 ],		# 3

  # 3:
  [ EDGE_S_W, EDGE_N_E, EDGE_S_W, 0,  1, 2, 1, EDGE_HOR, EDGE_VER, 1,0, 0,1 ],		# 4
  [ EDGE_S_W, EDGE_N_E, EDGE_S_W, -1, 0, 1, 2, EDGE_VER, EDGE_HOR, 0,-1, -1,0 ],	# 5

  # 4:
  [ EDGE_N_E, EDGE_S_W, EDGE_N_E, 1,  0, 1, 2, EDGE_VER, EDGE_HOR, 0,1, 1,0 ],		# 6
  [ EDGE_N_E, EDGE_S_W, EDGE_N_E, 0, -1, 2, 1, EDGE_HOR, EDGE_VER, -1,0, 0,-1 ],	# 7

  ];

sub _straighten_path
  {
  my ($self, $path, $bends, $edge) = @_;

  # XXX TODO:
  # in case of multiple bends, removes only one of them due to overlap

  my $cells = $self->{cells};

  my $i = 0;
  BEND:
  while ($i < (scalar @$bends - 2))
    {
    # for each bend, check it and the next two bends

#   print STDERR "Checking bend $i at $bends->[$i], $bends->[$i+1], $bends->[$i+2]\n";

    my ($a,$b,$c) = ($bends->[$i],
		     $bends->[$i+1],
		     $bends->[$i+2]);

    my $dx = ($b->[1] - $a->[1]);
    my $dy = ($b->[2] - $a->[2]);

    my $p = 0;
    for my $pattern (@$bend_patterns)
      {
      $p++;
      next if ($a->[0] != $pattern->[0]) ||
	      ($b->[0] != $pattern->[1]) ||
	      ($c->[0] != $pattern->[2]) ||
	      ($dx != $pattern->[3]) ||
	      ($dy != $pattern->[4]);

      # pattern matched
#      print STDERR "# Got bends for pattern ", $p-1," (@$pattern):\n";
#      print STDERR "# type x,y,\n# @$a\n# @$b\n# @$c\n";

      # check that the alternative path is empty

      # new corner:
      my $cx = $a->[$pattern->[5]];
      my $cy = $c->[$pattern->[6]];
      ($cx,$cy) = ($cy,$cx) if $pattern->[5] == 2;	# need to swap?

      next BEND if exists $cells->{"$cx,$cy"};

#      print STDERR "# new corner at $cx,$cy (swap: $pattern->[5])\n";

      # check from A to new corner
      my $x = $a->[1];
      my $y = $a->[2];

      my @replace = ();
      push @replace, $cx, $cy, $pattern->[0] if ($x == $cx && $y == $cy);

      my $ddx = $pattern->[9];
      my $ddy = $pattern->[10];
#      print STDERR "# dx,dy: $ddx,$ddy\n";
      while ($x != $cx || $y != $cy)
	{
	next BEND if exists $cells->{"$x,$y"};
#        print STDERR "# at $x $y (go to $cx,$cy)\n"; sleep(1);
	push @replace, $x, $y, $pattern->[7];
	$x += $ddx;
	$y += $ddy;
	}

      $x = $cx; $y = $cy;

      # check from new corner to C
      $ddx = $pattern->[11];
      $ddy = $pattern->[12];
      while ($x != $c->[1] || $y != $c->[2])
	{
	next BEND if exists $cells->{"$x,$y"};
#        print STDERR "# at $x $y (go to $cx,$cy)\n"; sleep(1);
	push @replace, $x, $y, $pattern->[8];
	
	# set the correct type on the corner
	$replace[-1] = $pattern->[0] if ($x == $cx && $y == $cy);
	$x += $ddx;
	$y += $ddy;
        }
      # insert Corner
      push @replace, $x, $y, $pattern->[8];

#	use Data::Dumper; print STDERR Dumper(@replace);
#	print STDERR "# generated ", scalar @replace, " entries\n";
#	print STDERR "# idx A $a->[3] C $c->[3]\n";

      # the path is clear, so replace the inward bend with the new one
      my $diff = $a->[3] - $c->[3] ? -3 : 3;

      my $idx = 0; my $p_idx = $a->[3] + $diff;
      while ($idx < @replace)
	{
#	 print STDERR "# replace $p_idx .. $p_idx + 2\n";
#	 print STDERR "# replace $path->[$p_idx] with $replace[$idx]\n";
#	 print STDERR "# replace $path->[$p_idx+1] with $replace[$idx+1]\n";
#	 print STDERR "# replace $path->[$p_idx+2] with $replace[$idx+2]\n";

	$path->[$p_idx] = $replace[$idx];
	$path->[$p_idx+1] = $replace[$idx+1];
	$path->[$p_idx+2] = $replace[$idx+2];
	$p_idx += $diff;
	$idx += 3;
 	}
      } # end for this pattern

    } continue { $i++; };
  }

sub _map_as_html
  {
  my ($self, $cells, $p, $closed, $open, $w, $h) = @_;

  $w ||= 20;
  $h ||= 20;

  my $html = <<EOF
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
 <head>
 <style type="text/css">
 <!--
 td {
   background: #a0a0a0;
   border: #606060 solid 1px;
   font-size: 0.75em;
 }
 td.b, td.b, td.c {
   background: #404040;
   border: #606060 solid 1px;
   }
 td.c {
   background: #ffffff;
   }
 table.map {
   border-collapse: collapse;
   border: black solid 1px;
 }
 -->
 </style>
</head>
<body>

<h1>A* Map</h1>

<p>
Nodes examined: <b>##closed##</b> <br>
Nodes still to do (open): <b>##open##</b> <br>
Nodes in path: <b>##path##</b>
</p>
EOF
;

  $html =~ s/##closed##/keys %$closed /eg;
  $html =~ s/##open##/keys %$open /eg;
  my $path = {};
  while (@$p)
    {
    my $x = shift @$p;
    my $y = shift @$p;
    my $t = shift @$p;
    $path->{"$x,$y"} = undef;
    }
  $html =~ s/##path##/keys %$path /eg;
  $html .= '<table class="map">' . "\n";

  for my $y (0..$h)
    {
    $html .= " <tr>\n";
    for my $x (0..$w)
      {
      my $xy = "$x,$y";
      my $c = '&nbsp;' x 4;
      $html .= "  <td class='c'>$c</td>\n" and next if
        exists $cells->{$xy} and ref($cells->{$xy}) =~ /Node/;
      $html .= "  <td class='b'>$c</td>\n" and next if
        exists $cells->{$xy} && !exists $path->{$xy};

      $html .= "  <td>$c</td>\n" and next unless
        exists $closed->{$xy} ||
        exists $open->{$xy};

      my $clr = '#a0a0a0';
      if (exists $closed->{$xy})
        {
        $c =  ($closed->{$xy}->[3] || '0') . '+' . ($closed->{$xy}->[2] || '0');
        my $color = 0x10 + 8 * (($closed->{$xy}->[2] || 0));
        my $color2 = 0x10 + 8 * (($closed->{$xy}->[3] || 0));
        $clr = sprintf("%02x%02x",$color,$color2) . 'a0';
        }
      elsif (exists $open->{$xy})
        {
        $c = '&nbsp;' . $open->{$xy} || '0';
        my $color = 0xff - 8 * ($open->{$xy} || 0);
        $clr = 'a0' . sprintf("%02x",$color) . '00';
        }
      my $b = '';
      $b = 'border: 2px white solid;' if exists $path->{$xy};
      $html .= "  <td style='background: #$clr;$b'>$c</td>\n";
      }
    $html .= " </tr>\n";
    }
 
  $html .= "\n</table>\n";

  $html;
  }
 
1;
__END__

=head1 NAME

Graph::Easy::Layout::Scout - Find paths in a Manhattan-style grid

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

C<Graph::Easy::Layout::Scout> contains just the actual pathfinding code for
L<Graph::Easy|Graph::Easy>. It should not be used directly.

=head1 EXPORT

Exports nothing.

=head1 METHODS

This package inserts a few methods into C<Graph::Easy> and
C<Graph::Easy::Node> to enable path-finding for graphs. It should not
be used directly.

=head1 SEE ALSO

L<Graph::Easy>.

=head1 AUTHOR

Copyright (C) 2004 - 2007 by Tels L<http://bloodgate.com>.

See the LICENSE file for information.

=cut

