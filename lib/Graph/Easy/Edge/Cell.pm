#############################################################################
# Part of Graph::Easy.
#
#############################################################################

package Graph::Easy::Edge::Cell;

use strict;
use Graph::Easy::Edge;
use Graph::Easy::Attributes;
require Exporter;

use vars qw/$VERSION @EXPORT_OK @ISA/;
@ISA = qw/Exporter Graph::Easy::Edge/;

$VERSION = '0.29';

use Scalar::Util qw/weaken/;

#############################################################################

# The different cell types:
use constant {
  EDGE_CROSS	=> 0,		# +	crossing lines
  EDGE_HOR	=> 1,	 	# --	horizontal line
  EDGE_VER	=> 2,	 	# |	vertical line

  EDGE_N_E	=> 3,		# |_	corner (N to E)
  EDGE_N_W	=> 4,		# _|	corner (N to W)
  EDGE_S_E	=> 5,		# ,-	corner (S to E)
  EDGE_S_W	=> 6,		# -,	corner (S to W)

# Joints:
  EDGE_S_E_W	=> 7,		# -,-	three-sided corner (S to W/E)
  EDGE_N_E_W	=> 8,		# -'-	three-sided corner (N to W/E)
  EDGE_E_N_S	=> 9,		#  |-   three-sided corner (E to S/N)
  EDGE_W_N_S	=> 10,		# -|	three-sided corner (W to S/N)

  EDGE_HOLE	=> 11,		# 	a hole (placeholder for the "other"
				#	edge in a crossing section
				#	Holes are inserted in the layout stage
				#	and removed in the optimize stage, before
				#	rendering occurs.

# these loop types must come last
  EDGE_N_W_S	=> 12,		# v--+  loop, northwards
  EDGE_S_W_N	=> 13,		# ^--+  loop, southwards
  EDGE_E_S_W	=> 14,		# [_    loop, westwards
  EDGE_W_S_E	=> 15,		# _]    loop, eastwards

  EDGE_MAX_TYPE		=> 15, 	# last valid type
  EDGE_LOOP_TYPE	=> 12, 	# first LOOP type

# Flags:
  EDGE_START_E		=> 0x0100,	# start from East	(sorted ESWN)
  EDGE_START_S		=> 0x0200,	# start from South
  EDGE_START_W		=> 0x0400,	# start from West
  EDGE_START_N		=> 0x0800,	# start from North

  EDGE_END_W		=> 0x0010,	# end points to West	(sorted WNES)
  EDGE_END_N		=> 0x0020,	# end points to North
  EDGE_END_E		=> 0x0040,	# end points to East
  EDGE_END_S		=> 0x0080,	# end points to South

  EDGE_LABEL_CELL	=> 0x1000,	# this cell carries the label
  EDGE_SHORT_CELL	=> 0x2000,	# a short edge pice (for filling)

  EDGE_ARROW_MASK	=> 0x0FF0,	# mask out the end/start type
  EDGE_START_MASK	=> 0x0F00,	# mask out the start type
  EDGE_END_MASK		=> 0x00F0,	# mask out the end type
  EDGE_TYPE_MASK	=> 0x000F,	# mask out the basic cell type
  EDGE_FLAG_MASK	=> 0xFFF0,	# mask out the flags
  EDGE_MISC_MASK	=> 0xF000,	# mask out the misc. flags
  EDGE_NO_M_MASK	=> 0x0FFF,	# anything except the misc. flags

  ARROW_RIGHT	=> 0,
  ARROW_LEFT	=> 1,
  ARROW_UP	=> 2,
  ARROW_DOWN	=> 3,
  };

use constant {
  EDGE_ARROW_HOR	=> EDGE_END_E() + EDGE_END_W(),
  EDGE_ARROW_VER	=> EDGE_END_N() + EDGE_END_S(),

# shortcuts to not need to write EDGE_HOR + EDGE_START_W + EDGE_END_E
  EDGE_SHORT_E => EDGE_HOR + EDGE_END_E + EDGE_START_W,		# |-> start/end at this cell
  EDGE_SHORT_S => EDGE_VER + EDGE_END_S + EDGE_START_N,		# v   start/end at this cell
  EDGE_SHORT_W => EDGE_HOR + EDGE_END_W + EDGE_START_E,		# <-| start/end at this cell
  EDGE_SHORT_N => EDGE_VER + EDGE_END_N + EDGE_START_S,		# ^   start/end at this cell

  EDGE_SHORT_BD_EW => EDGE_HOR + EDGE_END_E + EDGE_END_W,	# <-> start/end at this cell
  EDGE_SHORT_BD_NS => EDGE_VER + EDGE_END_S + EDGE_END_N,	# ^
								# | start/end at this cell
								# v
  EDGE_SHORT_UN_EW => EDGE_HOR + EDGE_START_E + EDGE_START_W,	# --
  EDGE_SHORT_UN_NS => EDGE_VER + EDGE_START_S + EDGE_START_N,   # |

  EDGE_LOOP_NORTH  => EDGE_N_W_S + EDGE_END_S + EDGE_START_N + EDGE_LABEL_CELL,
  EDGE_LOOP_SOUTH  => EDGE_S_W_N + EDGE_END_N + EDGE_START_S + EDGE_LABEL_CELL,
  EDGE_LOOP_WEST   => EDGE_W_S_E + EDGE_END_E + EDGE_START_W + EDGE_LABEL_CELL,
  EDGE_LOOP_EAST   => EDGE_E_S_W + EDGE_END_W + EDGE_START_E + EDGE_LABEL_CELL,
  };

#############################################################################

@EXPORT_OK = qw/
  EDGE_START_E
  EDGE_START_W
  EDGE_START_N
  EDGE_START_S

  EDGE_END_E
  EDGE_END_W	
  EDGE_END_N
  EDGE_END_S

  EDGE_SHORT_E
  EDGE_SHORT_W	
  EDGE_SHORT_N
  EDGE_SHORT_S

  EDGE_SHORT_BD_EW
  EDGE_SHORT_BD_NS

  EDGE_SHORT_UN_EW
  EDGE_SHORT_UN_NS

  EDGE_HOR
  EDGE_VER
  EDGE_CROSS
  EDGE_HOLE

  EDGE_N_E
  EDGE_N_W
  EDGE_S_E
  EDGE_S_W

  EDGE_S_E_W
  EDGE_N_E_W
  EDGE_E_N_S
  EDGE_W_N_S	

  EDGE_LOOP_NORTH
  EDGE_LOOP_SOUTH
  EDGE_LOOP_EAST
  EDGE_LOOP_WEST

  EDGE_N_W_S
  EDGE_S_W_N
  EDGE_E_S_W
  EDGE_W_S_E

  EDGE_TYPE_MASK
  EDGE_FLAG_MASK
  EDGE_ARROW_MASK
  
  EDGE_START_MASK
  EDGE_END_MASK
  EDGE_MISC_MASK

  EDGE_LABEL_CELL
  EDGE_SHORT_CELL

  EDGE_NO_M_MASK

  ARROW_RIGHT
  ARROW_LEFT
  ARROW_UP
  ARROW_DOWN
  /;

my $edge_types = {
  EDGE_HOR() => 'horizontal',
  EDGE_VER() => 'vertical',

  EDGE_CROSS() => 'crossing',

  EDGE_N_E() => 'north/east corner',
  EDGE_N_W() => 'north/west corner',
  EDGE_S_E() => 'south/east corner',
  EDGE_S_W() => 'south/west corner',

  EDGE_S_E_W() => 'joint south to east/west',
  EDGE_N_E_W() => 'joint north to east/west',
  EDGE_E_N_S() => 'joint east to north/south',
  EDGE_W_N_S() => 'joint west to north/south',

  EDGE_N_W_S() => 'selfloop, northwards',
  EDGE_S_W_N() => 'selfloop, southwards',
  EDGE_E_S_W() => 'selfloop, eastwards',
  EDGE_W_S_E() => 'selfloop, westwards',
  };

my $flag_types = {
  EDGE_LABEL_CELL() => 'labeled',
  EDGE_SHORT_CELL() => 'short',

  EDGE_START_E() => 'starting east',
  EDGE_START_W() => 'starting west',
  EDGE_START_N() => 'starting north',
  EDGE_START_S() => 'starting south',

  EDGE_END_E() => 'ending east',
  EDGE_END_W() => 'ending west',
  EDGE_END_N() => 'ending north',
  EDGE_END_S() => 'ending south',
  };

use constant isa_cell => 1;

sub edge_type
  {
  # convert edge type number to some descriptive text
  my $type = shift;

  my $flags = $type & EDGE_FLAG_MASK;
  $type &= EDGE_TYPE_MASK;

  my $t = $edge_types->{$type} || ('unknown edge type #' . $type);

  $flags &= EDGE_FLAG_MASK;

  my $mask = 0x0010;
  while ($mask < 0xFFFF)
    {
    my $tf = $flags & $mask; $mask <<= 1;
    $t .= ", $flag_types->{$tf}" if $tf != 0;
    }

  $t;
  }

#############################################################################

sub _init
  {
  # generic init, override in subclasses
  my ($self,$args) = @_;
  
  $self->{type} = EDGE_SHORT_E();	# -->
  $self->{style} = 'solid';
  
  $self->{x} = 0;
  $self->{y} = 0;
  $self->{w} = undef;
  $self->{h} = 3;

  foreach my $k (keys %$args)
    {
    # don't store "after" and "before"
    next unless $k =~ /^(graph|edge|x|y|type)\z/;
    $self->{$k} = $args->{$k};
    }

  $self->_croak("Creating edge cell without a parent edge object")
    unless defined $self->{edge};
  $self->_croak("Creating edge cell without a type")
    unless defined $self->{type};

  # take over settings from edge
  $self->{style} = $self->{edge}->style();
  $self->{class} = $self->{edge}->class();
  $self->{graph} = $self->{edge}->{graph};
  $self->{group} = $self->{edge}->{group};
  weaken($self->{graph});
  weaken($self->{group});
  $self->{att} = $self->{edge}->{att};

  # register ourselves at this edge
  $self->{edge}->_add_cell ($self, $args->{after}, $args->{before});

  $self;
  }

sub arrow_count
  {
  # return 0, 1 or 2, depending on the number of end points
  my $self = shift;

  return 0 if $self->{edge}->{undirected};

  my $count = 0;
  my $type = $self->{type};
  $count ++ if ($type & EDGE_END_N) != 0;
  $count ++ if ($type & EDGE_END_S) != 0;
  $count ++ if ($type & EDGE_END_W) != 0;
  $count ++ if ($type & EDGE_END_E) != 0;
  if ($self->{edge}->{bidirectional})
    {
    $count ++ if ($type & EDGE_START_N) != 0;
    $count ++ if ($type & EDGE_START_S) != 0;
    $count ++ if ($type & EDGE_START_W) != 0;
    $count ++ if ($type & EDGE_START_E) != 0;
    }
  $count;
  }

sub _make_cross
  {
  # Upgrade us to a cross-section.
  my ($self, $edge, $flags) = @_;
  
  my $type = $self->{type} & EDGE_TYPE_MASK;
    
  $self->_croak("Trying to cross non hor/ver piece at $self->{x},$self->{y}")
    if (($type != EDGE_HOR) && ($type != EDGE_VER));

  $self->{color} = $self->get_color_attribute('color');
  $self->{style_ver} = $edge->style();
  $self->{color_ver} = $edge->get_color_attribute('color');

  # if we are the VER piece, switch styles around
  if ($type == EDGE_VER)
    {
    ($self->{style_ver}, $self->{style}) = ($self->{style},$self->{style_ver});
    ($self->{color_ver}, $self->{color}) = ($self->{color},$self->{color});
    }

  $self->{type} = EDGE_CROSS + ($flags || 0);

  $self;
  }

sub _make_joint
  {
  # Upgrade us to a joint
  my ($self, $edge, $new_type) = @_;
  
  my $type = $self->{type} & EDGE_TYPE_MASK;

  $self->_croak("Trying to join non hor/ver piece (type: $type) at $self->{x},$self->{y}")
     if $type >= EDGE_S_E_W;

  $self->{color} = $self->get_color_attribute('color');
  $self->{style_ver} = $edge->style();
  $self->{color_ver} = $edge->get_color_attribute('color');

  # if we are the VER piece, switch styles around
  if ($type == EDGE_VER)
    {
    ($self->{style_ver}, $self->{style}) = ($self->{style},$self->{style_ver});
    ($self->{color_ver}, $self->{color}) = ($self->{color},$self->{color});
    }

  print STDERR "# creating joint at $self->{x}, $self->{y} with new type $new_type (old $type)\n"
    if $self->{graph}->{debug};

  $self->{type} = $new_type;

  $self;
  }

#############################################################################
# conversion to HTML

my $edge_end_north = 
   ' <td colspan=2 class="##class## eb" style="##bg####ec##">&nbsp;</td>' . "\n" .
   ' <td colspan=2 class="##class## eb" style="##bg####ec##"><span class="su">^</span></td>' . "\n";
my $edge_end_south = 
   ' <td colspan=2 class="##class## eb" style="##bg####ec##">&nbsp;</td>' . "\n" .
   ' <td colspan=2 class="##class## eb" style="##bg####ec##"><span class="sv">v</span></td>' . "\n";

my $edge_empty_row =
   ' <td colspan=4 class="##class## eb"></td>';

my $edge_arrow_west_upper = 
   '<td rowspan=2 class="##class## eb" style="##ec####bg##"><span class="shl">&lt;</span></td>' . "\n";
my $edge_arrow_west_lower = 
   '<td rowspan=2 class="##class## eb">&nbsp;</td>' . "\n";

my $edge_arrow_east_upper = 
   '<td rowspan=2 class="##class## eb" style="##ec####bg##"><span class="sh">&gt;</span></td>' . "\n";
my $edge_arrow_east_lower =
   '<td rowspan=2 class="##class## eb"></td>' . "\n";

my $edge_html = {

  # The "&nbsp;" in empty table cells with borders are here to make IE display
  # the border. I so hate browser bugs :-(

  EDGE_S_E() => [
    ' <td colspan=2 rowspan=2 class="##class## eb"></td>' . "\n" .
    ' <td colspan=2 rowspan=2 class="##class## eb" style="border-bottom: ##border##;">&nbsp;</td>',
    '',
    ' <td colspan=2 rowspan=2 class="##class## eb"></td>'. "\n" .
    ' <td colspan=2 rowspan=2 class="##class## eb" style="border-left: ##border##;">&nbsp;</td>',
    '',
   ],

  EDGE_S_E() + EDGE_START_E() + EDGE_END_S() => [
    ' <td colspan=2 rowspan=2 class="##class## eb"></td>' . "\n" .
    ' <td rowspan=2 class="##class## eb" style="border-bottom: ##border##;">&nbsp;</td>' . "\n" .
    ' <td rowspan=4 class="##class## el"></td>',
    '',
    ' <td colspan=2 class="##class## eb"></td>'. "\n" .
    ' <td class="##class## eb" style="border-left: ##border##;">&nbsp;</td>',
    $edge_end_south,
   ],

  EDGE_S_E() + EDGE_START_E() => [
    ' <td colspan=2 rowspan=2 class="##class## eb"></td>' . "\n" .
    ' <td rowspan=2 class="##class## eb" style="border-bottom: ##border##;">&nbsp;</td>' . "\n" .
    ' <td rowspan=4 class="##class## el"></td>',
    '',
    ' <td colspan=2 rowspan=2 class="##class## eb"></td>'. "\n" .
    ' <td colspan=2 rowspan=2 class="##class## eb" style="border-left: ##border##;">&nbsp;</td>',
    '',
   ],

  EDGE_S_E() + EDGE_END_E() => [
    ' <td colspan=2 rowspan=2 class="##class## eb"></td>' . "\n" .
    ' <td rowspan=2 class="##class## eb" style="border-bottom: ##border##;">&nbsp;</td>' . "\n" .
    ' <td rowspan=4 class="##class##"##edgecolor##><span class="sa">&gt;</span></td>',
    '',
    ' <td colspan=2 rowspan=2 class="##class## eb"></td>'. "\n" .
    ' <td rowspan=2 class="##class## eb" style="border-left: ##border##;">&nbsp;</td>',
    '',
   ],

  EDGE_S_E() + EDGE_START_S() => [
    ' <td colspan=2 rowspan=2 class="##class## eb"></td>' . "\n" .
    ' <td colspan=2 rowspan=2 class="##class## eb" style="border-bottom: ##border##;">&nbsp;</td>',
    '',
    ' <td colspan=2 class="##class## eb"></td>'. "\n" .
    ' <td colspan=2 class="##class## eb" style="border-left: ##border##;">&nbsp;</td>' . "\n",
    $edge_empty_row,
   ],

  EDGE_S_E() + EDGE_START_S() + EDGE_END_E() => [
    ' <td colspan=2 rowspan=2 class="##class## eb"></td>' . "\n" .
    ' <td rowspan=2 class="##class## eb" style="border-bottom: ##border##;">&nbsp;</td>'.
    ' <td rowspan=4 class="##class##"##edgecolor##><span class="sa">&gt;</span></td>',
    '',
    ' <td colspan=2 rowspan=2 class="##class## eb"></td>'. "\n" .
    ' <td class="##class## eb" style="border-left: ##border##;">&nbsp;</td>' . "\n",
    ' <td class="##class## eb"></td>',
   ],

  EDGE_S_E() + EDGE_END_S() => [
    ' <td colspan=2 rowspan=2 class="##class## eb"></td>' . "\n" .
    ' <td colspan=2 rowspan=2 class="##class## eb" style="border-bottom: ##border##;">&nbsp;</td>',
    '',
    ' <td colspan=2 class="##class## eb"></td>'. "\n" .
    ' <td colspan=2 class="##class## eb" style="border-left: ##border##;">&nbsp;</td>' . "\n",
    $edge_end_south,
   ],

  EDGE_S_E() + EDGE_END_S() + EDGE_END_E() => [
    ' <td colspan=2 rowspan=2 class="##class## eb"></td>' . "\n" .
    ' <td rowspan=2 class="##class## eb" style="border-bottom: ##border##;">&nbsp;</td>' . "\n" .
    ' <td rowspan=4 class="##class## ha"##edgecolor##><span class="sa">&gt;</span></td>',
    '',
    ' <td colspan=2 class="##class## eb"></td>'. "\n" .
    ' <td class="##class## eb" style="border-left: ##border##;">&nbsp;</td>' . "\n",
    ' <td colspan=3 class="##class## v"##edgecolor##>v</td>',
   ],

  ###########################################################################
  ###########################################################################
  # S_W

  EDGE_S_W() => [
    ' <td colspan=2 rowspan=2 class="##class## eb" style="border-bottom: ##border##;">&nbsp;</td>' . "\n" .
    ' <td colspan=2 rowspan=2 class="##class## eb"></td>',
    '',
    ' <td colspan=2 rowspan=2 class="##class## eb"></td>'. "\n" .
    ' <td colspan=2 rowspan=2 class="##class## eb" style="border-left: ##border##;">&nbsp;</td>',
    '',
   ],

  EDGE_S_W() + EDGE_START_W() => [
    ' <td rowspan=2 class="##class## el"></td>' . "\n" .
    ' <td rowspan=2 class="##class## eb" style="border-bottom: ##border##;">&nbsp;</td>' . "\n" .
    ' <td colspan=2 rowspan=2 class="##class## eb"></td>',
    '',
    ' <td colspan=2 rowspan=2 class="##class## eb"></td>'. "\n" .
    ' <td colspan=2 rowspan=2 class="##class## eb" style="border-left: ##border##;">&nbsp;</td>',
    '',
   ],

  EDGE_S_W() + EDGE_END_W() => [
    ' <td rowspan=2 class="##class## va"##edgecolor##><span class="shl">&lt;</span></td>' . "\n" .
    ' <td rowspan=2 class="##class## eb" style="border-bottom: ##border##;">&nbsp;</td>' . "\n" .
    ' <td colspan=2 rowspan=2 class="##class## eb"></td>',
    '',
    ' <td colspan=2 rowspan=2 class="##class## eb"></td>'. "\n" .
    ' <td colspan=2 rowspan=2 class="##class## eb" style="border-left: ##border##;">&nbsp;</td>',
    '',
   ],

  EDGE_S_W() + EDGE_START_S() => [
    ' <td colspan=2 rowspan=2 class="##class## eb" style="border-bottom: ##border##;">&nbsp;</td>' . "\n" .
    ' <td colspan=2 rowspan=2 class="##class## eb"></td>',
    '',
    ' <td colspan=2 class="##class## eb"></td>'. "\n" .
    ' <td colspan=2 class="##class## eb" style="border-left: ##border##;">&nbsp;</td>',
    $edge_empty_row,
   ],

  EDGE_S_W() + EDGE_END_S() => [
    ' <td colspan=2 rowspan=2 class="##class## eb" style="border-bottom: ##border##;">&nbsp;</td>' . "\n" .
    ' <td colspan=2 rowspan=2 class="##class## eb"></td>',
    '',
    ' <td colspan=2 class="##class## eb"></td>'. "\n" .
    ' <td colspan=2 class="##class## eb" style="border-left: ##border##;">&nbsp;</td>',
    $edge_end_south,
   ],

  EDGE_S_W() + EDGE_START_W() + EDGE_END_S() => [
    ' <td rowspan=2 class="##class## el"></td>' . "\n" .
    ' <td rowspan=2 class="##class## eb" style="border-bottom: ##border##;">&nbsp;</td>' . "\n" .
    ' <td colspan=2 rowspan=2 class="##class## eb"></td>',
    '',
    ' <td colspan=2 class="##class## eb"></td>'. "\n" .
    ' <td colspan=2 class="##class## eb" style="border-left: ##border##;">&nbsp;</td>',
    $edge_end_south,
   ],

  EDGE_S_W() + EDGE_START_S() + EDGE_END_W() => [
    ' <td rowspan=3 class="##class## sh"##edgecolor##>&lt;</td>' . "\n" .
    ' <td rowspan=2 class="##class## eb" style="border-bottom: ##border##;">&nbsp;</td>' . "\n" .
    ' <td colspan=2 rowspan=2 class="##class## eb"></td>',
    '',
    ' <td class="##class## eb"></td>'. "\n" .
    ' <td colspan=2 class="##class## eb" style="border-left: ##border##;">&nbsp;</td>',
    $edge_empty_row,
   ],

  ###########################################################################
  ###########################################################################
  # N_W

  EDGE_N_W() => [
    ' <td colspan=2 rowspan=2 class="##class## eb" style="border-bottom: ##border##;">&nbsp;</td>' . "\n" .
    ' <td colspan=2 rowspan=2 class="##class## eb" style="border-left: ##border##;">&nbsp;</td>',
    '',
    ' <td colspan=4 rowspan=2 class="##class## eb"></td>',
    '',
   ],

  EDGE_N_W() + EDGE_START_N() => [
    $edge_empty_row,
    ' <td colspan=2 class="##class## eb" style="border-bottom: ##border##;">&nbsp;</td>' . "\n" .
    ' <td colspan=2 class="##class## eb" style="border-left: ##border##;">&nbsp;</td>',
    '',
    ' <td colspan=4 rowspan=2 class="##class## eb"></td>',
   ],

  EDGE_N_W() + EDGE_END_N() => [
    $edge_end_north,
    ' <td colspan=2 class="##class## eb" style="border-bottom: ##border##;">&nbsp;</td>' . "\n" .
    ' <td colspan=2 class="##class## eb" style="border-left: ##border##;">&nbsp;</td>',
    ' <td colspan=4 rowspan=2 class="##class## eb"></td>',
    '',
   ],

  EDGE_N_W() + EDGE_END_N() + EDGE_START_W() => [
    $edge_end_north,
    ' <td rowspan=3 class="##class## eb"></td>'.
    ' <td class="##class## eb" style="border-bottom: ##border##;">&nbsp;</td>' . "\n" .
    ' <td colspan=2 class="##class## eb" style="border-left: ##border##;">&nbsp;</td>',
    ' <td colspan=4 rowspan=2 class="##class## eb"></td>',
    '',
   ],

  EDGE_N_W() + EDGE_START_W() => [
    ' <td rowspan=2 class="##class## el"></td>' . "\n" . 
    ' <td rowspan=2 class="##class## eb" style="border-bottom: ##border##;">&nbsp;</td>' . "\n" .
    ' <td colspan=2 rowspan=2 class="##class## eb" style="border-left: ##border##;">&nbsp;</td>' . "\n",
    '',
    ' <td colspan=4 rowspan=2 class="##class## eb"></td>',
    '',
   ],

  EDGE_N_W() + EDGE_END_W() => [
    ' <td rowspan=4 class="##class## sh"##edgecolor##>&lt;</td>' . "\n" . 
    ' <td rowspan=2 class="##class## eb" style="border-bottom: ##border##;">&nbsp;</td>' . "\n" .
    ' <td colspan=2 rowspan=2 class="##class## eb" style="border-left: ##border##;">&nbsp;</td>' . "\n",
    '',
    ' <td colspan=3 rowspan=2 class="##class## eb"></td>',
    '',
   ],

  ###########################################################################
  ###########################################################################
  # N_E

  EDGE_N_E() => [
    ' <td colspan=2 rowspan=2 class="##class## eb"></td>' . "\n" .
    ' <td colspan=2 rowspan=2 class="##class## eb" style="border-bottom: ##border##; border-left: ##border##;">&nbsp;</td>',
    '',
    ' <td colspan=4 rowspan=2 class="##class## eb"></td>',
    '',
   ],

  EDGE_N_E() + EDGE_START_E() => [
    ' <td colspan=2 rowspan=2 class="##class## eb"></td>' . "\n" .
    ' <td rowspan=2 class="##class## eb" style="border-bottom: ##border##; border-left: ##border##;">&nbsp;</td>' . "\n" .
    ' <td rowspan=4 class="##class## el"></td>',
    '',
    ' <td colspan=3 rowspan=2 class="##class## eb"></td>',
    '',
   ],

  EDGE_N_E() + EDGE_END_E() => [
    ' <td colspan=2 rowspan=2 class="##class## eb"></td>' . "\n" .
    ' <td rowspan=2 class="##class## eb" style="border-bottom: ##border##; border-left: ##border##;">&nbsp;</td>' . "\n" .
    ' <td rowspan=4 class="##class## va"##edgecolor##><span class="sa">&gt;</span></td>',
    '',
    ' <td colspan=3 rowspan=2 class="##class## eb"></td>',
    '',
   ],

  EDGE_N_E() + EDGE_END_E() + EDGE_START_N() => [
    $edge_empty_row,
    ' <td colspan=2 class="##class## eb"></td>' . "\n" .
    ' <td class="##class## eb" style="border-bottom: ##border##; border-left: ##border##;">&nbsp;</td>' . "\n" .
    ' <td rowspan=3 class="##class## va"##edgecolor##><span class="sa">&gt;</span></td>',
    ' <td colspan=3 rowspan=2 class="##class## eb"></td>',
    '',
   ],

  EDGE_N_E() + EDGE_START_E() + EDGE_END_N() => [
    $edge_end_north,
    ' <td colspan=2 class="##class## eb"></td>' . "\n" .
    ' <td class="##class## eb" style="border-bottom: ##border##; border-left: ##border##;">&nbsp;</td>' . "\n" .
    ' <td rowspan=3 class="##class## eb">&nbsp;</td>',
    ' <td colspan=3 rowspan=2 class="##class## eb"></td>',
    '',
   ],

  EDGE_N_E() + EDGE_START_N() => [
    $edge_empty_row,
    ' <td colspan=2 rowspan=3 class="##class## eb"></td>' . "\n" .
    ' <td colspan=2 class="##class## eb" style="border-bottom: ##border##; border-left: ##border##;">&nbsp;</td>',
    ' <td colspan=2 class="##class## eb"></td>',
    '',
   ],

  EDGE_N_E() + EDGE_END_N() => [
    $edge_end_north,
    ' <td colspan=2 rowspan=3 class="##class## eb"></td>' . "\n" .
    ' <td colspan=2 class="##class## eb" style="border-bottom: ##border##; border-left: ##border##;">&nbsp;</td>',
    '',
    ' <td colspan=2 class="##class## eb"></td>',
   ],

  ###########################################################################
  ###########################################################################
  # self loops

  EDGE_LOOP_NORTH() - EDGE_LABEL_CELL() => [
    '<td rowspan=2 class="##class## eb">&nbsp;</td>' . "\n".
    ' <td colspan=2 rowspan=2 class="##class## lh" style="border-bottom: ##border##;##lc####bg##">##label##</td>' . "\n" .
    ' <td rowspan=2 class="##class## eb">&nbsp;</td>',
    '',
    '<td class="##class## eb">&nbsp;</td>' . "\n".
    ' <td colspan=2 class="##class## eb" style="border-left: ##border##;##bg##">&nbsp;</td>'."\n".
    ' <td class="##class## eb" style="border-left: ##border##;##bg##">&nbsp;</td>',

    '<td colspan=2 class="##class## v" style="##bg##"##edgecolor##>v</td>' . "\n" .
    ' <td colspan=2 class="##class## eb">&nbsp;</td>',

   ],

  EDGE_LOOP_SOUTH() - EDGE_LABEL_CELL() => [
    '<td colspan=2 class="##class## v" style="##bg##"##edgecolor##>^</td>' . "\n" . 
    ' <td colspan=2 class="##class## eb">&nbsp;</td>',

    '<td rowspan=2 class="##class## eb">&nbsp;</td>' . "\n".
    ' <td colspan=2 rowspan=2 class="##class## lh" style="border-left:##border##;border-bottom:##border##;##lc####bg##">##label##</td>'."\n".
    ' <td rowspan=2 class="##class## eb" style="border-left:##border##;##bg##">&nbsp;</td>',

    '',

    '<td colspan=4 class="##class## eb">&nbsp;</td>',

   ],

  EDGE_LOOP_WEST() - EDGE_LABEL_CELL() => [
    $edge_empty_row.
    ' <td colspan=2 rowspan=2 class="##class## lh" style="border-bottom: ##border##;##lc####bg##">##label##</td>'."\n".
    ' <td rowspan=2 class="##class## eb">&nbsp;</td>',

    '',

    '<td colspan=2 class="##class## eb" style="border-left: ##border##; border-bottom: ##border##;##bg##">&nbsp;</td>' . "\n".
    ' <td rowspan=2 class="##class## va" style="##bg##"##edgecolor##><span class="sa">&gt;</span></td>',
    
    '<td colspan=2 class="##class## eb">&nbsp;</td>',
   ],

  EDGE_LOOP_EAST() - EDGE_LABEL_CELL() => [

    '<td rowspan=2 class="##class## eb">&nbsp;</td>' . "\n" .
    ' <td colspan=2 rowspan=2 class="##class## lh" style="border-bottom: ##border##;##lc####bg##">##label##</td>' ."\n".
    ' <td rowspan=2 class="##class## eb">&nbsp;</td>',

    '',

    '<td rowspan=2 class="##class## va" style="##bg##"##edgecolor##><span class="sh">&lt;</span></td>' ."\n".
    ' <td colspan=2 class="##class## eb" style="border-bottom: ##border##;##bg##">&nbsp;</td>'."\n".
    ' <td class="##class## eb" style="border-left: ##border##;##bg##">&nbsp;</td>',
   
    '<td colspan=3 class="##class## eb">&nbsp;</td>',
   ],

  ###########################################################################
  ###########################################################################
  # joints

  ###########################################################################
  # E_N_S

  EDGE_E_N_S() => [
    '<td colspan=2 rowspan=2 class="##class## eb">&nbsp;</td>' . "\n" .
    ' <td colspan=2 rowspan=2 class="##class## eb" style="border-left:##borderv##;border-bottom:##border##;##bg##">&nbsp;</td>',
    '',
    '<td colspan=2 rowspan=2 class="##class## eb">&nbsp;</td>' ."\n".
    ' <td colspan=2 rowspan=2 class="##class## eb" style="border-left: ##borderv##;##bg##">&nbsp;</td>',
    '',
   ],

  EDGE_E_N_S() + EDGE_END_E() => [
    '<td colspan=2 rowspan=2 class="##class## eb">&nbsp;</td>' . "\n" .
    ' <td rowspan=2 class="##class## eb" style="border-left: ##borderv##; border-bottom: ##border##;##bg##">&nbsp;</td>' . "\n" .
    ' <td rowspan=4 class="##class## va"##edgecolor##><span class="sa">&gt;</span></td>',
    '',
    '<td colspan=2 rowspan=2 class="##class## eb">&nbsp;</td>' ."\n".
    ' <td rowspan=2 class="##class## eb" style="border-left: ##borderv##;##bg##">&nbsp;</td>',
    '',
   ],

  ###########################################################################
  # W_N_S

  EDGE_W_N_S() => [
    '<td colspan=2 rowspan=2 class="##class## eb" style="border-bottom: ##border##;##bg##">&nbsp;</td>' . "\n" .
    ' <td colspan=2 rowspan=4 class="##class## eb" style="border-left: ##borderv##;##bg##">&nbsp;</td>',
    '',
    '<td colspan=2 rowspan=2 class="##class## eb">&nbsp;</td>',
    '',
   ],

  ###########################################################################
  # S_E_W

  EDGE_S_E_W() => [
    '<td colspan=4 rowspan=2 class="##class## eb" style="border-bottom: ##border##;##bg##">&nbsp;</td>',
    '',
    '<td colspan=2 rowspan=2 class="##class## eb">&nbsp;</td>' ."\n".
    ' <td colspan=2 rowspan=2 class="##class## eb" style="border-left: ##borderv##;##bg##">&nbsp;</td>',
    '',
   ],

  EDGE_S_E_W() + EDGE_END_S() => [
    '<td colspan=4 rowspan=2 class="##class## eb" style="border-bottom: ##border##;##bg##">&nbsp;</td>',
    '',
    '<td colspan=2 class="##class## eb">&nbsp;</td>' ."\n".
    ' <td colspan=2 class="##class## eb" style="border-left: ##borderv##;##bg##">&nbsp;</td>',
    $edge_end_south,
   ],

  EDGE_S_E_W() + EDGE_START_S() => [
    '<td colspan=4 rowspan=2 class="##class## eb" style="border-bottom: ##border##;##bg##">&nbsp;</td>',
    '',
    '<td colspan=2 class="##class## eb">&nbsp;</td>' ."\n".
    ' <td colspan=2 class="##class## eb" style="border-left: ##borderv##;##bg##">&nbsp;</td>',
    ' <td colspan=4 class="##class## eb"></td>',
   ],

  EDGE_S_E_W() + EDGE_START_W() => [
    '<td rowspan=4 class="##class## el"></td>' . "\n" .
    '<td colspan=3 rowspan=2 class="##class## eb" style="border-bottom: ##border##;##bg##">&nbsp;</td>',
    '',
    '<td rowspan=2 class="##class## eb">&nbsp;</td>' ."\n".
    ' <td rowspan=2 class="##class## eb" style="border-left: ##borderv##;##bg##">&nbsp;</td>',
    '',

   ],

  EDGE_S_E_W() + EDGE_END_E() => [
    '<td colspan=3 rowspan=2 class="##class## eb" style="border-bottom: ##border##;##bg##">&nbsp;</td>' . "\n" .
    ' <td rowspan=4 class="##class## va"##edgecolor##><span class="sa">&gt;</span></td>',
    '',
    '<td colspan=2 rowspan=2 class="##class## eb">&nbsp;</td>' ."\n".
    ' <td rowspan=2 class="##class## eb" style="border-left: ##borderv##;##bg##">&nbsp;</td>',
    '',
   ],

  EDGE_S_E_W() + EDGE_END_W() => [
    $edge_arrow_west_upper .
    '<td colspan=3 rowspan=2 class="##class## eb" style="border-bottom: ##border##;##bg##">&nbsp;</td>' . "\n" ,
    '',
    '<td colspan=2 rowspan=2 class="##class## eb">&nbsp;</td>' ."\n" .
    '<td colspan=2 rowspan=2 class="##class## eb" style="border-left: ##borderv##;##bg##">&nbsp;</td>',
   ],

  ###########################################################################
  # N_E_W

  EDGE_N_E_W() => [
    ' <td colspan=2 rowspan=2 class="##class## eb" style="border-bottom: ##borderv##;##bg##">&nbsp;</td>' ."\n".
    '<td colspan=2 rowspan=2 class="##class## eb" style="border-left: ##borderv##; border-bottom: ##border##;##bg##">&nbsp;</td>',
    '',
    '<td colspan=4 rowspan=2 class="##class## eb">&nbsp;</td>',
    '',
   ],

  EDGE_N_E_W() + EDGE_END_N() => [
    $edge_end_north,
    ' <td colspan=2 class="##class## eb" style="border-bottom: ##borderv##;##bg##">&nbsp;</td>' ."\n".
    '<td colspan=2 class="##class## eb" style="border-left: ##borderv##; border-bottom: ##border##;##bg##">&nbsp;</td>',
    '',
    '<td colspan=4 rowspan=2 class="##class## eb">&nbsp;</td>',
    '',
   ],

  EDGE_N_E_W() + EDGE_START_N() => [
    $edge_empty_row,
    ' <td colspan=2 class="##class## eb" style="border-bottom: ##borderv##;##bg##">&nbsp;</td>' ."\n".
    '<td colspan=2 class="##class## eb" style="border-left: ##borderv##; border-bottom: ##border##;##bg##">&nbsp;</td>',
    '',
    '<td colspan=4 rowspan=2 class="##class## eb">&nbsp;</td>',
    '',
   ],

  };

sub _html_edge_hor
  {
  # Return HTML code for a horizontal edge (with all start/end combinations)
  # as [], with code for each table row.
  my ($self, $as) = @_;

  my $s_flags = $self->{type} & EDGE_START_MASK;
  my $e_flags = $self->{type} & EDGE_END_MASK;

  $e_flags = 0 if $as eq 'none';

  # XXX TODO: we could skip the output of "eb" parts when this edge doesn't belong
  # to a group.

  my $rc = [
    ' <td colspan=##mod## rowspan=2 class="##class## lh" style="border-bottom: ##border##;##lc####bg##">##label##</td>',
    '',
    '<td colspan=##mod## rowspan=2 class="##class## eb">&nbsp;</td>', 
    '',
    ];

  # This assumes that only 2 end/start flags are set at the same time:

  my $mod = 4;							# modifier
  if ($s_flags & EDGE_START_W)
    {
    $mod--;
    $rc->[0] = '<td rowspan=4 class="##class## el"></td>' . "\n" . $rc->[0];
    };
  if ($s_flags & EDGE_START_E)
    {
    $mod--;
    $rc->[0] .= "\n " . '<td rowspan=4 class="##class## el"></td>';
    };
  if ($e_flags & EDGE_END_W)
    {
    $mod--;
    $rc->[0] = $edge_arrow_west_upper . $rc->[0]; 
    $rc->[2] = $edge_arrow_west_lower . $rc->[2]; 
    }
  if ($e_flags & EDGE_END_E)
    { 
    $mod--;
    $rc->[0] .= "\n " . $edge_arrow_east_upper;
    $rc->[2] .= "\n " . $edge_arrow_east_lower;
    };

  # cx == 1: mod = 2..4, cx == 2: mod = 6..8, etc.
  $self->{cx} ||= 1;
  $mod = $self->{cx} * 4 - 4 + $mod;

  for my $e (@$rc)
    {
    $e =~ s/##mod##/$mod/g;
    }

  $rc;
  }

sub _html_edge_ver
  {
  # Return HTML code for a vertical edge (with all start/end combinations)
  # as [], with code for each table row.
  my ($self, $as) = @_;

  my $s_flags = $self->{type} & EDGE_START_MASK;
  my $e_flags = $self->{type} & EDGE_END_MASK;

  $e_flags = 0 if $as eq 'none';

  my $mod = 4; 							# modifier

  # normal vertical edge with no start/end flags
  my $rc = [
    '<td colspan=2 rowspan=##mod## class="##class## el">&nbsp;</td>' . "\n " . 
    '<td colspan=2 rowspan=##mod## class="##class## lv" style="border-left: ##border##;##lc####bg##">##label##</td>' . "\n",
    '',
    '',
    '',
    ];

  # flag north
  if ($s_flags & EDGE_START_N)
    {
    $mod--;
    unshift @$rc, '<td colspan=4 class="##class## eb"></td>' . "\n";
    delete $rc->[-1];
    }
  elsif ($e_flags & EDGE_END_N)
    {
    $mod--;
    unshift @$rc, $edge_end_north;
    delete $rc->[-1];
    }

  # flag south
  if ($s_flags & EDGE_START_S)
    {
    $mod--;
    $rc->[3] = '<td colspan=4 class="##class## eb"></td>' . "\n"
    }

  if ($e_flags & EDGE_END_S)
    {
    $mod--;
    $rc->[3] = $edge_end_south;
    }

  $self->{cy} ||= 1;
  $mod = $self->{cy} * 4 - 4 + $mod;

  for my $e (@$rc)
    {
    $e =~ s/##mod##/$mod/g;
    }

  $rc;
  }

sub _html_edge_cross
  {
  # Return HTML code for a crossingedge (with all start/end combinations)
  # as [], with code for each table row.
  my ($self, $N, $S, $E, $W) = @_;

#  my $s_flags = $self->{type} & EDGE_START_MASK;
#  my $e_flags = $self->{type} & EDGE_END_MASK;

  my $rc = [
    ' <td colspan=2 rowspan=2 class="##class## eb el" style="border-bottom: ##border##">&nbsp;</td>' . "\n" .
    ' <td colspan=2 rowspan=2 class="##class## eb el" style="border-left: ##borderv##; border-bottom: ##border##">&nbsp;</td>' . "\n",
    '',
    ' <td colspan=2 rowspan=2 class="##class## eb el"></td>' . "\n" .
    ' <td colspan=2 rowspan=2 class="##class## eb el" style="border-left: ##borderv##">&nbsp;</td>' . "\n",
    '',
    ];

  $rc;
  }

sub as_html
  {
  my ($self) = shift;

  my $type = $self->{type} & EDGE_NO_M_MASK;
  my $style = $self->{style};

  # none, open, filled, closed
  my $as; $as = 'none' if $self->{edge}->{undirected};
  $as = $self->attribute('arrowstyle') unless $as;
  
  # triangle, box, dot, inv, diamond, line etc.
  my $ashape; $ashape = 'triangle' if $self->{edge}->{undirected};
  $ashape = $self->attribute('arrowshape') unless $ashape;

  my $code = $edge_html->{$type};

  if (!defined $code)
    {
    my $t = $self->{type} & EDGE_TYPE_MASK;

    if ($style ne 'invisible')
      {
      $code = $self->_html_edge_hor($as) if $t == EDGE_HOR;
      $code = $self->_html_edge_ver($as) if $t == EDGE_VER;
      $code = $self->_html_edge_cross($as) if $t == EDGE_CROSS;
      }
    else
      {
      $code = [ ' <td colspan=4 rowspan=4 class="##class##">&nbsp;</td>' ];
      }

    if (!defined $code)
      {
      $code = [ ' <td colspan=4 rowspan=4 class="##class##">???</td>' ];
      warn ("as_html: Unimplemented edge type $self->{type} ($type) at $self->{x},$self->{y} "
	. edge_type($self->{type}));
      }
    }

  my $id = $self->{graph}->{id};

  my $color = $self->get_color_attribute('color');
  my $label = '';
  my $label_style = '';

  # only include the label if we are the label cell
  if ($style ne 'invisible' && ($self->{type} & EDGE_LABEL_CELL))
    {
    my $switch_to_center;
    ($label,$switch_to_center) = $self->_label_as_html();

    # replace linebreaks by <br>, but remove extra spaces 
    $label =~ s/\s*\\n\s*/<br \/>/g;

    my $label_color = $self->raw_color_attribute('labelcolor') || $color;
    $label_color = '' if $label_color eq '#000000';
    $label_style = "color: $label_color;" if $label_color;

    my $font = $self->attribute('font') || '';
    $font = '' if $font eq ($self->default_attribute('font') || '');
    $label_style = "font-family: $font;" if $font;
  
    $label_style .= $self->text_styles_as_css(1,1) unless $label eq '';

    $label_style =~ s/^\s*//;

    my $link = $self->link();
    if ($link ne '')
      {
      # encode critical entities
      $link =~ s/\s/\+/g;			# space
      $link =~ s/'/%27/g;			# single-quote

      # put the style on the link
      $label_style = " style='$label_style'" if $label_style;
      $label = "<a href='$link'$label_style>$label</a>";
      $label_style = '';
      }

    }
  # without &nbsp;, IE doesn't draw the cell-border nec. for edges
  $label = '&nbsp;' unless $label ne '';

  ###########################################################################
  # get the border styles/colors:

  # width for the edge is "2px"
  my $bow = '2';
  my $border = Graph::Easy::_border_attribute_as_html( $self->{style}, $bow, $color);
  my $border_v = $border;

  if (($self->{type} & EDGE_TYPE_MASK) == EDGE_CROSS)
   {
   $border_v = Graph::Easy::_border_attribute_as_html( $self->{style_ver}, $bow, $self->{color_ver});
   }

  ###########################################################################
  my $edge_color = ''; $edge_color = " color: $color;" if $color;

  # If the group doesn't have a fill attribute, then it is defined in the CSS
  # of the group, and since we get the same class, we can skip the background.
  # But if the group has a fill, we need to use this as override.
  # The idea behind is to omit the "background: #daffff;" as much as possible.

  my $bg = $self->attribute('background') || '';
  my $group = $self->{edge}->{group};
  $bg = '' if $bg eq 'inherit';
  $bg = $group->{att}->{fill} if $group->{att}->{fill} && $bg eq '';
  $bg = '' if $bg eq 'inherit';
  $bg = " background: $bg;" if $bg;

  my $title = $self->title();
  $title =~ s/"/&#22;/g;			# replace quotation marks
  $title = " title=\"$title\"" if $title ne '';	# add mouse-over title

  ###########################################################################
  # replace templates
      
  require Graph::Easy::As_ascii if $as ne 'none';	# for _unicode_arrow()

  # replace borderv with the border for the vertical edge on CROSS sections
  $border =~ s/\s+/ /g;			# collapse multiple spaces
  $border_v =~ s/\s+/ /g;
  my $cl = $self->class(); $cl =~ s/\./_/g;	# group.cities => group_cities

  my $rc;
  for my $a (@$code)
    {
    if (ref($a))
      {
      for my $c (@$a)
        {
        push @$rc, $self->_format_td($c, 
	  $border, $border_v, $label_style, $edge_color, $bg, $as, $ashape, $title, $label, $cl);
	}
      }
    else
      {
      push @$rc, $self->_format_td($a, 
	$border, $border_v, $label_style, $edge_color, $bg, $as, $ashape, $title, $label, $cl);
      }
    }

  $rc;
  }

sub _format_td
  {
  my ($self, $c,
	$border, $border_v, $label_style, $edge_color, $bg, $as, $ashape, $title, $label, $cl) = @_;

  # insert 'style="##bg##"' unless there is already a style 
  $c =~ s/( e[bl]")(>(&nbsp;)?<\/td>)/$1 style="##bg##"$2/g;
  # insert missing "##bg##"
  $c =~ s/style="border/style="##bg##border/g;

  $c =~ s/##class##/$cl/g;
  $c =~ s/##border##/$border/g;
  $c =~ s/##borderv##/$border_v/g;
  $c =~ s/##lc##/$label_style/g;
  $c =~ s/##edgecolor##/ style="$edge_color"/g;
  $c =~ s/##ec##/$edge_color/g;
  $c =~ s/##bg##/$bg/g;
  $c =~ s/ style=""//g;		# remove empty styles

  # remove arrows if edge is undirected
  $c =~ s/>(v|\^|&lt;|&gt;)/>/g if $as eq 'none';

  # insert "nice" looking Unicode arrows
  $c =~ s/>(v|\^|&lt;|&gt;)/'>' . $self->_unicode_arrow($ashape, $as, $1); /eg;

  # insert the label last, other "v" as label might get replaced above
  $c =~ s/>##label##/$title>$label/;
  # for empty labels use a different class
  $c =~ s/ lh"/ eb"/ if $label eq '';

  $c .= "\n" unless $c =~ /\n\z/;

  $self->quoted_comment() . $c;
  }

sub class
  {
  my $self = shift;

  my $c = $self->{class} . ($self->{cell_class} || '');
  $c = $self->{edge}->{group}->class() . ' ' . $c if ref($self->{edge}->{group});

  $c;
  }

sub group
  {
  # return the group we belong to as the group of our parent-edge
  my $self = shift;

  $self->{edge}->{group};
  }

#############################################################################
# accessor methods

sub type
  {
  # get/set type of this path element
  # type - EDGE_START, EDGE_END, EDGE_HOR, EDGE_VER, etc
  my ($self,$type) = @_;

  if (defined $type)
    {
    if (defined $type && $type < 0 || $type > EDGE_MAX_TYPE)
      {
      require Carp;
      Carp::confess ("Cell type $type for cell $self->{x},$self->{y} is not valid.");
      }
    $self->{type} = $type;
    }

  $self->{type};
  }

#############################################################################

# For rendering this path element as ASCII, we need to correct our width based
# on whether we have a border or not. But this is only known after parsing is
# complete.

sub _correct_size
  {
  my ($self,$format) = @_;

  return if defined $self->{w};

  # min-size is this 
  $self->{w} = 5; $self->{h} = 3;
  # make short cell pieces very small
  if (($self->{type} & EDGE_SHORT_CELL) != 0)
    {
    $self->{w} = 1; $self->{h} = 1;
    return;
    }
    
  my $arrows = ($self->{type} & EDGE_ARROW_MASK);
  my $type = ($self->{type} & EDGE_TYPE_MASK);

  if ($self->{edge}->{bidirectional} && $arrows != 0)
    {
    $self->{w}++ if $type == EDGE_HOR;
    $self->{h}++ if $type == EDGE_VER;
    }

  # make joints bigger if they got arrows
  my $ah = $self->{type} & EDGE_ARROW_HOR;
  my $av = $self->{type} & EDGE_ARROW_VER;
  $self->{w}++ if $ah && ($type == EDGE_S_E_W || $type == EDGE_N_E_W);
  $self->{h}++ if $av && ($type == EDGE_E_N_S || $type == EDGE_W_N_S);

  my $style = $self->{edge}->attribute('style') || 'solid';

  # make the edge to display ' ..-> ' instead of ' ..> ':
  $self->{w}++ if $style eq 'dot-dot-dash';

  if ($type >= EDGE_LOOP_TYPE)
    {
    #  +---+ 
    #  |   V

    #       +
    #  +--> |
    #  |    |
    #  +--- |
    #       +
    $self->{w} = 7;
    $self->{w} = 8 if $type == EDGE_N_W_S || $type == EDGE_S_W_N;
    $self->{h} = 3;
    $self->{h} = 5 if $type != EDGE_N_W_S && $type != EDGE_S_W_N;
    }

  if ($self->{type} == EDGE_HOR)
    {
    $self->{w} = 0;
    }
  elsif ($self->{type} == EDGE_VER)
    {
    $self->{h} = 0;
    }
  elsif ($self->{type} & EDGE_LABEL_CELL)
    {
    # edges do not have borders
    my ($w,$h) = $self->dimensions(); $h-- unless $h == 0;

    $h += $self->{h};
    $w += $self->{w};
    $self->{w} = $w;
    $self->{h} = $h;
    }
  }

#############################################################################
# attribute handling

sub attribute
  {
  my ($self, $name) = @_;

  my $edge = $self->{edge};

#  my $native = $edge->{att}->{$name};
#  return $native if defined $native && $native ne 'inherit';

  # shortcut, look up the attribute directly
  return $edge->{att}->{$name}
    if defined $edge->{att}->{$name} && $edge->{att}->{$name} ne 'inherit';

  return $edge->attribute($name);

  # XXX TODO This does not work, since caching the attribute doesn't get invalidated
  # upon set_attribute().

#  $edge->{cache} = {} unless exists $edge->{cache};
#  $edge->{cache}->{att} = {} unless exists $edge->{cache}->{att};
#
#  my $cache = $edge->{cache}->{att};
#  return $cache->{$name} if exists $cache->{$name};
#
#  my $rc = $edge->attribute($name);
#  # only cache values that weren't inherited to avoid cache problems
#  $cache->{$name} = $rc unless defined $native && $native eq 'inherit';
#
#  $rc;
  }

1;

#############################################################################
#############################################################################

package Graph::Easy::Edge::Cell::Empty;

require Graph::Easy::Node::Cell;
our @ISA = qw/Graph::Easy::Node::Cell/;

#use vars qw/$VERSION/;

our $VERSION = '0.02';

use constant isa_cell => 1;

1;
__END__

=head1 NAME

Graph::Easy::Edge::Cell - A cell in an edge in Graph::Easy

=head1 SYNOPSIS

        use Graph::Easy;

	my $ssl = Graph::Easy::Edge->new(
		label => 'encrypted connection',
		style => 'solid',
		color => 'red',
	);
	my $src = Graph::Easy::Node->new( 'source' );
	my $dst = Graph::Easy::Node->new( 'destination' );

	$graph = Graph::Easy->new();

	$graph->add_edge($src, $dst, $ssl);

	print $graph->as_ascii();

=head1 DESCRIPTION

A C<Graph::Easy::Edge::Cell> represents an edge between two (or more) nodes
in a simple graph.

Each edge has a direction (from source to destination, or back and forth),
plus a style (line width and style), colors etc. It can also have a name,
e.g. a text label associated with it.

There should be no need to use this package directly.

=head1 METHODS

=head2 error()

	$last_error = $edge->error();

	$cvt->error($error);			# set new messags
	$cvt->error('');			# clear error

Returns the last error message, or '' for no error.

=head2 as_ascii()

	my $ascii = $path->as_ascii();

Returns the path-cell as a little ascii representation.

=head2 as_html()

	my $html = $path->as_html($tag,$id);

eturns the path-cell as HTML code.

=head2 label()

	my $label = $path->label();

Returns the name (also known as 'label') of the path-cell.

=head2 style()

	my $style = $edge->style();

Returns the style of the edge.

=head1 EXPORT

None by default. Can export the following on request:

  EDGE_START_E
  EDGE_START_W
  EDGE_START_N
  EDGE_START_S

  EDGE_END_E
  EDGE_END_W	
  EDGE_END_N
  EDGE_END_S

  EDGE_SHORT_E
  EDGE_SHORT_W	
  EDGE_SHORT_N
  EDGE_SHORT_S

  EDGE_SHORT_BD_EW
  EDGE_SHORT_BD_NS

  EDGE_SHORT_UN_EW
  EDGE_SHORT_UN_NS

  EDGE_HOR
  EDGE_VER
  EDGE_CROSS

  EDGE_N_E
  EDGE_N_W
  EDGE_S_E
  EDGE_S_W

  EDGE_S_E_W
  EDGE_N_E_W
  EDGE_E_N_S
  EDGE_W_N_S	

  EDGE_LOOP_NORTH
  EDGE_LOOP_SOUTH
  EDGE_LOOP_EAST
  EDGE_LOOP_WEST

  EDGE_N_W_S
  EDGE_S_W_N
  EDGE_E_S_W
  EDGE_W_S_E

  EDGE_TYPE_MASK
  EDGE_FLAG_MASK
  EDGE_ARROW_MASK
  
  EDGE_START_MASK
  EDGE_END_MASK
  EDGE_MISC_MASK

  ARROW_RIGHT
  ARROW_LEFT
  ARROW_UP
  ARROW_DOWN

=head1 SEE ALSO

L<Graph::Easy>.

=head1 AUTHOR

Copyright (C) 2004 - 2007 by Tels L<http://bloodgate.com>.

See the LICENSE file for more details.

=cut
