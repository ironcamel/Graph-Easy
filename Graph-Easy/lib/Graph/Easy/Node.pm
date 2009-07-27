#############################################################################
# Represents one node in a Graph::Easy graph.
#
# (c) by Tels 2004-2008. Part of Graph::Easy.
#############################################################################

package Graph::Easy::Node;

$VERSION = '0.38';

use Graph::Easy::Base;
use Graph::Easy::Attributes;
@ISA = qw/Graph::Easy::Base/;

# to map "arrow-shape" to "arrowshape"
my $att_aliases;

use strict;
use constant isa_cell => 0;

sub _init
  {
  # Generic init routine, to be overriden in subclasses.
  my ($self,$args) = @_;
  
  $self->{name} = 'Node #' . $self->{id};
  
  $self->{att} = { };
  $self->{class} = 'node';		# default class

  foreach my $k (keys %$args)
    {
    if ($k !~ /^(label|name)\z/)
      {
      require Carp;
      Carp::confess ("Invalid argument '$k' passed to Graph::Easy::Node->new()");
      }
    $self->{$k} = $args->{$k} if $k eq 'name';
    $self->{att}->{$k} = $args->{$k} if $k eq 'label';
    }

  # These are undef (to save memory) until needed: 
  #  $self->{children} = {};
  #  $self->{dx} = 0;		# relative to no other node
  #  $self->{dy} = 0;
  #  $self->{origin} = undef;	# parent node (for relative placement)
  #  $self->{group} = undef;
  #  $self->{parent} = $graph or $group;
  # Mark as not yet laid out: 
  #  $self->{x} = 0;
  #  $self->{y} = 0;
  
  $self;
  }

my $merged_borders = 
  {
    'dotteddashed' => 'dot-dash',
    'dasheddotted' => 'dot-dash',
    'double-dashdouble' => 'double',
    'doubledouble-dash' => 'double',
    'doublesolid' => 'double',
    'soliddouble' => 'double',
    'dotteddot-dash' => 'dot-dash',
    'dot-dashdotted' => 'dot-dash',
  };

sub _collapse_borders
  {
  # Given a right border from node one, and the left border of node two,
  # return what border we need to draw on node two:
  my ($self, $one, $two, $swapem) = @_;

  ($one,$two) = ($two,$one) if $swapem;

  $one = 'none' unless $one;
  $two = 'none' unless $two;

  # If the border of the left/top node is defined, we don't draw the
  # border of the right/bottom node.
  return 'none' if $one ne 'none' || $two ne 'none';

  # otherwise, we draw simple the right border
  $two;
  }

sub _merge_borders
  {
  my ($self, $one, $two) = @_;

  $one = 'none' unless $one;
  $two = 'none' unless $two;
  
  # "nonenone" => "none" or "dotteddotted" => "dotted"
  return $one if $one eq $two;

  # none + solid == solid + none == solid
  return $one if $two eq 'none';
  return $two if $one eq 'none';

  for my $b (qw/broad wide bold double solid/)
    {
    # the stronger one overrides the weaker one
    return $b if $one eq $b || $two eq $b;
    }

  my $both = $one . $two;
  return $merged_borders->{$both} if exists $merged_borders->{$both};

  # fallback
  $two;
  }

sub _border_to_draw
  {
  # Return the border style we need to draw, taking the shape (none) into
  # account
  my ($self, $shape) = @_;

  my $cache = $self->{cache};

  return $cache->{border_style} if defined $cache->{border_style};

  $shape = $self->{att}->{shape} unless defined $shape;
  $shape = $self->attribute('shape') unless defined $shape;

  $cache->{border_style} = $self->{att}->{borderstyle};
  $cache->{border_style} = $self->attribute('borderstyle') unless defined $cache->{border_style};
  $cache->{border_style} = 'none' if $shape =~ /^(none|invisible)\z/;
  $cache->{border_style};
  }

sub _border_styles
  {
  # Return the four border styles (right, bottom, left, top). This takes
  # into account the neighbouring nodes and their borders, so that on
  # ASCII output the borders can be properly collapsed.
  my ($self, $border, $collapse) = @_;

  my $cache = $self->{cache};

  # already computed values?
  return if defined $cache->{left_border};

  $cache->{left_border} = $border; 
  $cache->{top_border} = $border;
  $cache->{right_border} = $border; 
  $cache->{bottom_border} = $border;

  return unless $collapse;

#  print STDERR " border_styles: $self->{name} border=$border\n";

  my $EM = 14;
  my $border_width = Graph::Easy::_border_width_in_pixels($self,$EM);

  # convert overly broad borders to the correct style
  $border = 'bold' if $border_width > 2;
  $border = 'broad' if $border_width > $EM * 0.2 && $border_width < $EM * 0.75;
  $border = 'wide' if $border_width >= $EM * 0.75;

#  XXX TODO
#  handle different colors, too:
#  my $color = $self->color_attribute('bordercolor');

  # Draw border on A (left), and C (left):
  #
  #    +---+
  #  B | A | C 
  #    +---+

  # Ditto, plus C's border:
  #
  #    +---+---+
  #  B | A | C |
  #    +---+---+
  #

  # If no left neighbour, draw border normally

  # XXX TODO: ->{parent} ?
  my $parent = $self->{parent} || $self->{graph};
  return unless ref $parent;

  my $cells = $parent->{cells};
  return unless ref $cells;

  my $x = $self->{x}; my $y = $self->{y};

  $x -= 1; my $left = $cells->{"$x,$y"};
  $x += 1; $y-= 1; my $top = $cells->{"$x,$y"};
  $x += 1; $y += 1; my $right = $cells->{"$x,$y"};
  $x -= 1; $y += 1; my $bottom = $cells->{"$x,$y"};

  # where to store the result
  my @where = ('left', 'top', 'right', 'bottom');
  # need to swap arguments to _collapse_borders()?
  my @swapem = (0, 0, 1, 1);
 
  for my $other ($left, $top, $right, $bottom)
    {
    my $side = shift @where;
    my $swap = shift @swapem;
  
    # see if we have a (visible) neighbour on the left side
    if (ref($other) && 
      !$other->isa('Graph::Easy::Edge') &&
      !$other->isa_cell() &&
      !$other->isa('Graph::Easy::Node::Empty'))
      {
      $other = $other->{node} if ref($other->{node});

#      print STDERR "$side node $other ", $other->_border_to_draw(), " vs. $border (swap $swap)\n";

      if ($other->attribute('shape') ne 'invisible')
        {
        # yes, so take its border style
        my $result;
        if ($swap)
	  {
          $result = $self->_merge_borders($other->_border_to_draw(), $border);
	  }
        else
	  {
	  $result = $self->_collapse_borders($border, $other->_border_to_draw());
	  }
        $cache->{$side . '_border'} = $result;

#	print STDERR "# result: $result\n";
        }
      }
    }
  }

sub _correct_size
  {
  # Correct {w} and {h} after parsing. This is a fallback in case
  # the output specific routines (_correct_site_ascii() etc) do
  # not exist.
  my $self = shift;

  return if defined $self->{w};

  my $shape = $self->attribute('shape');

  if ($shape eq 'point')
    {
    $self->{w} = 5;
    $self->{h} = 3;
    my $style = $self->attribute('pointstyle');
    my $shape = $self->attribute('pointshape');
    if ($style eq 'invisible' || $shape eq 'invisible')
      {
      $self->{w} = 0; $self->{h} = 0; return; 
      }
    }
  elsif ($shape eq 'invisible')
    {
    $self->{w} = 3;
    $self->{h} = 3;
    }
  else
    {
    my ($w,$h) = $self->dimensions();
    $self->{h} = $h;
    $self->{w} = $w + 2;
    }

  my $border = $self->_border_to_draw($shape);

  $self->_border_styles($border, 'collapse');

#  print STDERR "# $self->{name} $self->{w} $self->{h} $shape\n";
#  use Data::Dumper; print Dumper($self->{cache});

  if ($shape !~ /^(invisible|point)/)
    {
    $self->{w} ++ if $self->{cache}->{right_border} ne 'none';
    $self->{w} ++ if $self->{cache}->{left_border} ne 'none';
    $self->{h} ++ if $self->{cache}->{top_border} ne 'none';
    $self->{h} ++ if $self->{cache}->{bottom_border} ne 'none';

    $self->{h} += 2 if $border eq 'none' && $shape !~ /^(invisible|point)/;
    }

  $self;
  }

sub _unplace
  {
  # free the cells this node occupies from $cells
  my ($self,$cells) = @_;

  my $x = $self->{x}; my $y = $self->{y};
  delete $cells->{"$x,$y"};
  $self->{x} = undef;
  $self->{y} = undef;
  $self->{cache} = {};

  $self->_calc_size() unless defined $self->{cx};

  if ($self->{cx} + $self->{cy} > 2)	# one of them > 1!
    {
    for my $ax (1..$self->{cx})
      {
      my $sx = $x + $ax - 1;
      for my $ay (1..$self->{cy})
        {
        my $sy = $y + $ay - 1;
        # free cell
        delete $cells->{"$sx,$sy"};
        }
      }
    } # end handling multi-celled node

  # unplace all edges leading to/from this node, too:
  for my $e (values %{$self->{edges}})
    {
    $e->_unplace($cells);
    }

  $self;
  }

sub _mark_as_placed
  {
  # for creating an action on the action stack we also need to recursively
  # mark all our children as already placed:
  my ($self) = @_;

  no warnings 'recursion';

  delete $self->{_todo};

  for my $child (values %{$self->{children}})
    {
    $child->_mark_as_placed();
    }
  $self;
  }

sub _place_children
  {
  # recursively place node and its children
  my ($self, $x, $y, $parent) = @_;

  no warnings 'recursion';

  return 0 unless $self->_check_place($x,$y,$parent);

  print STDERR "# placing children of $self->{name} based on $x,$y\n" if $self->{debug};

  for my $child (values %{$self->{children}})
    {
    # compute place of children (depending on whether we are multicelled or not)

    my $dx = $child->{dx} > 0 ? $self->{cx} - 1 : 0;
    my $dy = $child->{dy} > 0 ? $self->{cy} - 1 : 0;

    my $rc = $child->_place_children($x + $dx + $child->{dx},$y + $dy + $child->{dy},$parent);
    return $rc if $rc == 0;
    }
  $self->_place($x,$y,$parent);
  }

sub _place
  {
  # place this node at the requested position (without checking)
  my ($self, $x, $y, $parent) = @_;

  my $cells = $parent->{cells};
  $self->{x} = $x;
  $self->{y} = $y;
  $cells->{"$x,$y"} = $self;

  # store our position if we are the first node in that rank
  my $r = abs($self->{rank} || 0);
  my $what = $parent->{_rank_coord} || 'x';	# 'x' or 'y'
  $parent->{_rank_pos}->{ $r } = $self->{$what} 
    unless defined $parent->{_rank_pos}->{ $r };

  # a multi-celled node will be stored like this:
  # [ node   ] [ filler ]
  # [ filler ] [ filler ]
  # [ filler ] [ filler ] etc.

#  $self->_calc_size() unless defined $self->{cx};

  if ($self->{cx} + $self->{cy} > 2)    # one of them > 1!
    {
    for my $ax (1..$self->{cx})
      {
      my $sx = $x + $ax - 1;
      for my $ay (1..$self->{cy})
        {
        next if $ax == 1 && $ay == 1;   # skip left-upper most cell
        my $sy = $y + $ay - 1;

        # We might even get away with creating only one filler cell
        # although then its "x" and "y" values would be "wrong".

        my $filler = 
	  Graph::Easy::Node::Cell->new ( node => $self, x => $sx, y => $sy );
        $cells->{"$sx,$sy"} = $filler;
        }
      }
    } # end handling of multi-celled node

  $self->_update_boundaries($parent);

  1;					# did place us
  } 

sub _check_place
  {
  # chack that a node can be placed at $x,$y (w/o checking its children)
  my ($self,$x,$y,$parent) = @_;

  my $cells = $parent->{cells};

  # node cannot be placed here
  return 0 if exists $cells->{"$x,$y"};

  $self->_calc_size() unless defined $self->{cx};

  if ($self->{cx} + $self->{cy} > 2)	# one of them > 1!
    {
    for my $ax (1..$self->{cx})
      {
      my $sx = $x + $ax - 1;
      for my $ay (1..$self->{cy})
        {
        my $sy = $y + $ay - 1;
        # node cannot be placed here
        return 0 if exists $cells->{"$sx,$sy"};
        }
      }
    }
  1;					# can place it here
  }

sub _do_place
  {
  # Tries to place the node at position ($x,$y) by checking that
  # $cells->{"$x,$y"} is still free. If the node belongs to a cluster,
  # checks all nodes of the cluster (and when all of them can be
  # placed simultanously, does so).
  # Returns true if the operation succeeded, otherwise false.
  my ($self,$x,$y,$parent) = @_;

  my $cells = $parent->{cells};

  # inlined from _check() for speed reasons:

  # node cannot be placed here
  return 0 if exists $cells->{"$x,$y"};

  $self->_calc_size() unless defined $self->{cx};

  if ($self->{cx} + $self->{cy} > 2)	# one of them > 1!
    {
    for my $ax (1..$self->{cx})
      {
      my $sx = $x + $ax - 1;
      for my $ay (1..$self->{cy})
        {
        my $sy = $y + $ay - 1;
        # node cannot be placed here
        return 0 if exists $cells->{"$sx,$sy"};
        }
      }
    }

  my $children = 0;
  $children = scalar keys %{$self->{children}} if $self->{children};

  # relativ to another, or has children (relativ to us)
  if (defined $self->{origin} || $children > 0)
    {
    # The coordinates of the origin node. Because 'dx' and 'dy' give
    # our distance from the origin, we can compute the origin by doing
    # "$x - $dx"

    my $grandpa = $self; my $ox = 0; my $oy = 0;
    # Find our grandparent (e.g. the root of origin chain), and the distance
    # from $x,$y to it:
    ($grandpa,$ox,$oy) = $self->find_grandparent() if $self->{origin};

    # Traverse all children and check their places, place them if poss.
    # This will also place ourselves, because we are a grandchild of $grandpa
    return $grandpa->_place_children($x + $ox,$y + $oy,$parent);
    }

  # finally place this node at the requested position
  $self->_place($x,$y,$parent);
  }

#############################################################################

sub _wrapped_label
  {
  # returns the label wrapped automatically to use the least space
  my ($self, $label, $align, $wrap) = @_;

  return (@{$self->{cache}->{label}}) if $self->{cache}->{label};

  # XXX TODO: handle "paragraphs"
  $label =~ s/\\(n|r|l|c)/ /g;		# replace line splits by spaces

  # collapse multiple spaces
  $label =~ s/\s+/ /g;

  # find out where to wrap
  if ($wrap eq 'auto')
    {
    $wrap = int(sqrt(length($label)) * 1.4);
    }
  $wrap = 2 if $wrap < 2;

  # run through the text and insert linebreaks
  my $i = 0;
  my $line_len = 0;
  my $last_space = 0;
  my $last_hyphen = 0;
  my @lines;
  while ($i < length($label))
    {
    my $c = substr($label,$i,1);
    $last_space = $i if $c eq ' ';
    $last_hyphen = $i if $c eq '-';
    $line_len ++;
    if ($line_len >= $wrap && ($last_space != 0 || $last_hyphen != 0))
      {
#      print STDERR "# wrap at $line_len\n";

      my $w = $last_space; my $replace = '';
      if ($last_hyphen > $last_space)
	{
        $w = $last_hyphen; $replace = '-';
	}

#      print STDERR "# wrap at $w\n";

      # "foo bar-baz" => "foo bar" (lines[0]) and "baz" (label afterwards)

#      print STDERR "# first part '". substr($label, 0, $w) . "'\n";

      push @lines, substr($label, 0, $w) . $replace;
      substr($label, 0, $w+1) = '';
      # reset counters
      $line_len = 0;
      $i = 0;
      $last_space = 0;
      $last_hyphen = 0;
      next;
      }
    $i++;
    }
  # handle what is left over
  push @lines, $label if $label ne '';

  # generate the align array
  my @aligns;
  my $al = substr($align,0,1); 
  for my $i (0.. scalar @lines)
    {
    push @aligns, $al; 
    }
  # cache the result to avoid costly recomputation
  $self->{cache}->{label} = [ \@lines, \@aligns ];
  (\@lines, \@aligns);
  }

sub _aligned_label
  {
  # returns the label lines and for each one the alignment l/r/c
  my ($self, $align, $wrap) = @_;

  $align = 'center' unless $align;
  $wrap = $self->attribute('textwrap') unless defined $wrap;

  my $name = $self->label();

  return $self->_wrapped_label($name,$align,$wrap) unless $wrap eq 'none';

  my (@lines,@aligns);
  my $al = substr($align,0,1);
  my $last_align = $al;

  # split up each line from the front
  while ($name ne '')
    {
    $name =~ s/^(.*?([^\\]|))(\z|\\(n|r|l|c))//;
    my $part = $1;
    my $a = $3 || '\n';

    $part =~ s/\\\|/\|/g;		# \| => |
    $part =~ s/\\\\/\\/g;		# '\\' to '\'
    $part =~ s/^\s+//;			# remove spaces at front
    $part =~ s/\s+\z//;			# remove spaces at end
    $a =~ s/\\//;			# \n => n
    $a = $al if $a eq 'n';
    
    push @lines, $part;
    push @aligns, $last_align;

    $last_align = $a;
    }

  # XXX TODO: should remove empty lines at start/end?
  (\@lines, \@aligns);
  }

#############################################################################
# as_html conversion and helper functions related to that

my $remap = {
  node => {
    align => undef,
    background => undef,
    basename => undef,
    border => undef,
    borderstyle => undef,
    borderwidth => undef,
    bordercolor => undef,
    columns => undef,
    fill => 'background',
    origin => undef,
    offset => undef, 
    pointstyle => undef,
    pointshape => undef,
    rows => undef, 
    size => undef,
    shape => undef,
    },
  edge => {
    fill => undef,
    border => undef,
    },
  all => {
    align => 'text-align',
    autolink => undef,
    autotitle => undef,
    comment => undef,
    fontsize => undef,
    font => 'font-family',
    flow => undef,
    format => undef,
    label => undef,
    link => undef,
    linkbase => undef,
    style => undef,
    textstyle => undef,
    title => undef,
    textwrap => \&Graph::Easy::_remap_text_wrap,
    group => undef,
    },
  };

sub _extra_params
  {
  # return text with a leading " ", that will be appended to "td" when
  # generating HTML
  '';
  }

# XXX TODO: <span class="o">?
my $pod = {
  B => [ '<b>', '</b>' ],
  O => [ '<span style="text-decoration: overline">', '</span>' ],
  S => [ '<span style="text-decoration: line-through">', '</span>' ],
  U => [ '<span style="text-decoration: underline">', '</span>' ],
  C => [ '<code>', '</code>' ],
  I => [ '<i>', '</i>' ],
  };

sub _convert_pod
  {
  my ($self, $type, $text) = @_;

  my $t = $pod->{$type} or return $text;

  # "<b>" . "text" . "</b>"
  $t->[0] . $text . $t->[1];
  }

sub _label_as_html
  {
  # Build the text from the lines, by inserting <b> for each break
  # Also align each line, and if nec., convert B<bold> to <b>bold</b>.
  my ($self) = @_;

  my $align = $self->attribute('align');
  my $text_wrap = $self->attribute('textwrap');

  my ($lines,$aligns);
  if ($text_wrap eq 'auto')
    {
    # set "white-space: nowrap;" in CSS and ignore linebreaks in label
    $lines = [ $self->label() ];
    $aligns = [ substr($align,0,1) ];
    }
  else
    {
    ($lines,$aligns) = $self->_aligned_label($align,$text_wrap);
    }

  # Since there is no "float: center;" in CSS, we must set the general
  # text-align to center when we encounter any \c and the default is
  # left or right:

  my $switch_to_center = 0;
  if ($align ne 'center')
    {
    local $_;
    $switch_to_center = grep /^c/, @$aligns;
    }

  $align = 'center' if $switch_to_center;
  my $a = substr($align,0,1);			# center => c

  my $format = $self->attribute('format');

  my $name = '';
  my $i = 0;
  while ($i < @$lines)
    {
    my $line = $lines->[$i];
    my $al = $aligns->[$i];

    # This code below will not handle B<bold\n and bolder> due to the
    # line break. Also, nesting does not work due to returned "<" and ">".

    if ($format eq 'pod')
      {
      # first inner-most, then go outer until there are none left
      $line =~ s/([BOSUCI])<([^<>]+)>/ $self->_convert_pod($1,$2);/eg
        while ($line =~ /[BOSUCI]<[^<>]+>/)
      }
    else
      { 
      $line =~ s/&/&amp;/g;			# quote &
      $line =~ s/>/&gt;/g;			# quote >
      $line =~ s/</&lt;/g;			# quote <
      $line =~ s/\\\\/\\/g;			# "\\" to "\"
      }

    # insert a span to align the line unless the default already covers it
    $line = '<span class="' . $al . '">' . $line . '</span>'
      if $a ne $al;
    $name .= '<br>' . $line;

    $i++;					# next line
    }
  $name =~ s/^<br>//;				# remove first <br> 

  ($name, $switch_to_center);
  }

sub quoted_comment
  {
  # Comment of this object, quoted suitable as to be embedded into HTML/SVG
  my $self = shift;

  my $cmt = $self->attribute('comment');
  if ($cmt ne '')
    {
    $cmt =~ s/&/&amp;/g;
    $cmt =~ s/</&lt;/g;
    $cmt =~ s/>/&gt;/g;
    $cmt = '<!-- ' . $cmt . " -->\n";
    }

  $cmt;
  }

sub as_html
  {
  # return node as HTML
  my ($self) = @_;

  my $shape = 'rect';
  $shape = $self->attribute('shape') unless $self->isa_cell();

  if ($shape eq 'edge')
    {
    my $edge = Graph::Easy::Edge->new();
    my $cell = Graph::Easy::Edge::Cell->new( edge => $edge );
    $cell->{w} = $self->{w};
    $cell->{h} = $self->{h};
    $cell->{att}->{label} = $self->label();
    $cell->{type} =
     Graph::Easy::Edge::Cell->EDGE_HOR +
     Graph::Easy::Edge::Cell->EDGE_LABEL_CELL;
    return $cell->as_html();
    }

  my $extra = $self->_extra_params();
  my $taga = "td$extra";
  my $tagb = 'td';

  my $id = $self->{graph}->{id};
  my $a = $self->{att};
  my $g = $self->{graph};

  my $class = $self->class();

  # how many rows/columns will this node span?
  my $rs = ($self->{cy} || 1) * 4;
  my $cs = ($self->{cx} || 1) * 4;

  # shape: invisible; must result in an empty cell
  if ($shape eq 'invisible' && $class ne 'node.anon')
    {
    return " <$taga colspan=$cs rowspan=$rs style=\"border: none; background: inherit;\"></$tagb>\n";
    }

  my $c = $class; $c =~ s/\./_/g;	# node.city => node_city

  my $html = " <$taga colspan=$cs rowspan=$rs##class####style##";
   
  my $title = $self->title();
  $title =~ s/'/&#27;/g;			# replace quotation marks

  $html .= " title='$title'" if $title ne '' && $shape ne 'img';	# add mouse-over title

  my ($name, $switch_to_center);

  if ($shape eq 'point')
    {
    require Graph::Easy::As_ascii;		# for _u8 and point-style

    local $self->{graph}->{_ascii_style} = 1;	# use utf-8
    $name = $self->_point_style( $self->attribute('pointshape'), $self->attribute('pointstyle') );
    }
  elsif ($shape eq 'img')
    {
    # take the label as the URL, but escape critical characters
    $name = $self->label();
    $name =~ s/\s/\+/g;				# space
    $name =~ s/'/%27/g;				# replace quotation marks
    $name =~ s/[\x0d\x0a]//g;			# remove 0x0d0x0a and similiar
    my $t = $title; $t = $name if $t eq ''; 
    $name = "<img src='$name' alt='$t' title='$t' border='0' />";
    }
  else
    {
    ($name,$switch_to_center) = $self->_label_as_html(); 
    }

  # if the label is "", the link wouldn't be clickable
  my $link = ''; $link = $self->link() unless $name eq '';

  # the attributes in $out will be applied to either the TD, or the inner DIV,
  # unless if we have a link, then most of them will be moved to the A HREF
  my $att = $self->raw_attributes();
  my $out = $self->{graph}->_remap_attributes( $self, $att, $remap, 'noquote', 'encode', 'remap_colors');

  $out->{'text-align'} = 'center' if $switch_to_center;

  # only for nodes, not for edges
  if (!$self->isa('Graph::Easy::Edge'))
    {
    my $bc = $self->attribute('bordercolor');
    my $bw = $self->attribute('borderwidth');
    my $bs = $self->attribute('borderstyle');

    $out->{border} = Graph::Easy::_border_attribute_as_html( $bs, $bw, $bc );

    # we need to specify the border again for the inner div
    if ($shape !~ /(rounded|ellipse|circle)/)
      {
      my $DEF = $self->default_attribute('border');

      delete $out->{border} if $out->{border} =~ /^\s*\z/ || $out->{border} eq $DEF;
      }

    delete $out->{border} if $class eq 'node.anon' && $out->{border} && $out->{border} eq 'none';
    }

  # we compose the inner part as $inner_start . $label . $inner_end:
  my $inner_start = '';
  my $inner_end = '';

  if ($shape =~ /(rounded|ellipse|circle)/)
    {
    # set the fill on the inner part, but the background and no border on the <td>:
    my $inner_style = '';
    my $fill = $self->color_attribute('fill');
    $inner_style = 'background:' . $fill if $fill; 
    $inner_style .= ';border:' . $out->{border} if $out->{border};
    $inner_style =~ s/;\s?\z$//;				# remove '; ' at end

    delete $out->{background};
    delete $out->{border};

    my $td_style = '';
    $td_style = ' style="border: none;';
    my $bg = $self->color_attribute('background');
    $td_style .= "background: $bg\"";

    $html =~ s/##style##/$td_style/;

    $inner_end = '</span></div>';
    my $c = substr($shape, 0, 1); $c = 'c' if $c eq 'e';	# 'r' or 'c'

    my ($w,$h) = $self->dimensions();

    if ($shape eq 'circle')
      {
      # set both to the biggest size to enforce a circle shape
      my $r = $w;
      $r = $h if $h > $w;
      $w = $r; $h = $r;
      }

    $out->{top} = ($h / 2 + 0.5) . 'em'; delete $out->{top} if $out->{top} eq '1.5em';
    $h = ($h + 2) . 'em';
    $w = ($w + 2) . 'em';

    $inner_style .= ";width: $w; height: $h";

    $inner_style = " style='$inner_style'";
    $inner_start = "<div class='$c'$inner_style><span class='c'##style##>";
    }

  if ($class =~ /^group/)
    {
    delete $out->{border};
    delete $out->{background};
    my $group_class = $class; $group_class =~ s/\s.*//;		# "group gt" => "group"
    my @atr = qw/bordercolor borderwidth fill/;

    # transform "group_foo gr" to "group_foo" if border eq 'none' (for anon groups)
    my $border_style = $self->attribute('borderstyle');
    $c =~ s/\s+.*// if $border_style eq 'none';

    # only need the color for the label cell
    push @atr, 'color' if $self->{has_label};
    $name = '&nbsp;' unless $self->{has_label};
    for my $b (@atr)
      {
      my $def = $g->attribute($group_class,$b);
      my $v = $self->attribute($b);

      my $n = $b; $n = 'background' if $b eq 'fill';
      $out->{$n} = $v unless $v eq '' || $v eq $def;
      }
    $name = '&nbsp;' unless $name ne '';
    }

  # "shape: none;" or point means no border, and background instead fill color
  if ($shape =~ /^(point|none)\z/)
    {
    $out->{background} = $self->color_attribute('background'); 
    $out->{border} = 'none';
    }

  my $style = '';
  for my $atr (sort keys %$out)
    {
    if ($link ne '')
      {
      # put certain styles on the outer container, and not on the link
      next if $atr =~ /^(background|border)\z/;
      }
    $style .= "$atr: $out->{$atr}; ";
    }

  # bold, italic, underline etc. (but not for empty cells)
  $style .= $self->text_styles_as_css(1,1) if $name !~ /^(|&nbsp;)\z/;

  $style =~ s/;\s?\z$//;			# remove '; ' at end
  $style =~ s/\s+/ /g;				# '  ' => ' '
  $style =~ s/^\s+//;				# remove ' ' at front
  $style = " style=\"$style\"" if $style;

  my $end_tag = "</$tagb>\n";

  if ($link ne '')
    {
    # encode critical entities
    $link =~ s/\s/\+/g;				# space
    $link =~ s/'/%27/g;				# replace quotation marks

    my $outer_style = '';
    # put certain styles like border and background on the table cell:
    for my $s (qw/background border/)
      {
      $outer_style .= "$s: $out->{$s};" if exists $out->{$s};
      }
    $outer_style =~ s/;\s?\z$//;			# remove '; ' at end
    $outer_style = ' style="'.$outer_style.'"' if $outer_style;

    $inner_start =~ s/##style##/$outer_style/;	# remove from inner_start

    $html =~ s/##style##/$outer_style/;			# or HTML, depending
    $inner_start .= "<a href='$link'##style##>";	# and put on link
    $inner_end = '</a>'.$inner_end;
    }

  $c = " class='$c'" if $c ne '';
  $html .= ">$inner_start$name$inner_end$end_tag";
  $html =~ s/##class##/$c/;
  $html =~ s/##style##/$style/;

  $self->quoted_comment() . $html;
  }

sub angle
  {
  # return the rotation of the node, dependend on the rotate attribute
  # (and if relative, on the flow)
  my $self = shift;

  my $angle = $self->{att}->{rotate} || 0;

  $angle = 180 if $angle =~ /^(south|down)\z/;
  $angle = 0 if $angle =~ /^(north|up)\z/;
  $angle = 270 if $angle eq 'west';
  $angle = 90 if $angle eq 'east';

  # convert relative angles
  if ($angle =~ /^([+-]\d+|left|right|back|front|forward)\z/)
    {
    my $base_rot = $self->flow();
    $angle = 0 if $angle =~ /^(front|forward)\z/;
    $angle = 180 if $angle eq 'back';
    $angle = -90 if $angle eq 'left';
    $angle = 90 if $angle eq 'right';
    $angle = $base_rot + $angle + 0;	# 0 points up, so front points right
    $angle += 360 while $angle < 0;
    }

  $self->_croak("Illegal node angle $angle") if $angle !~ /^\d+\z/;

  $angle %= 360 if $angle > 359;

  $angle;
  }

# for determining the absolute parent flow
my $p_flow =
  {
  'east' => 90,
  'west' => 270,
  'north' => 0,
  'south' => 180,
  'up' => 0,
  'down' => 180,
  'back' => 270,
  'left' => 270,
  'right' => 90,
  'front' => 90,
  'forward' => 90,
  };

sub _parent_flow_absolute
  {
  # make parent flow absolute
  my ($self, $def)  = @_;

  return '90' if ref($self) eq 'Graph::Easy';

  my $flow = $self->parent()->raw_attribute('flow') || $def;

  return unless defined $flow;

  # in case of relative flow at parent, convert to absolute (right: east, left: west etc) 
  # so that "graph { flow: left; }" results in a westward flow
  my $f = $p_flow->{$flow}; $f = $flow unless defined $f;
  $f;
  }

sub flow
  {
  # Calculate the outgoing flow from the incoming flow and the flow at this
  # node (either from edge(s) or general flow). Returns an absolute flow:
  # See the online manual about flow for a reference and details.
  my $self = shift;

  no warnings 'recursion';

  my $cache = $self->{cache};
  return $cache->{flow} if exists $cache->{flow};

  # detected cycle, so break it
  return $cache->{flow} = $self->_parent_flow_absolute('90') if exists $self->{_flow};

  local $self->{_flow} = undef;		# endless loops really ruin our day

  my $in;
  my $flow = $self->{att}->{flow};

  $flow = $self->_parent_flow_absolute() if !defined $flow || $flow eq 'inherit';

  # if flow is absolute, return it early
  return $cache->{flow} = $flow if defined $flow && $flow =~ /^(0|90|180|270)\z/;
  return $cache->{flow} = Graph::Easy->_direction_as_number($flow)
    if defined $flow && $flow =~ /^(south|north|east|west|up|down)\z/;
  
  # for relative flows, compute the incoming flow as base flow

  # check all edges
  for my $e (values %{$self->{edges}})
    {
    # only count incoming edges
    next unless $e->{from} != $self && $e->{to} == $self;

    # if incoming edge has flow, we take this
    $in = $e->flow();
    # take the first match
    last if defined $in;
    }

  if (!defined $in)
    {
    # check all predecessors
    for my $e (values %{$self->{edges}})
      {
      my $pre = $e->{from};
      $pre = $e->{to} if $e->{bidirectional};
      if ($pre != $self)
        {
        $in = $pre->flow();
        # take the first match
        last if defined $in;
        }
      }
    }

  $in = $self->_parent_flow_absolute('90') unless defined $in;

  $flow = Graph::Easy->_direction_as_number($in) unless defined $flow;

  $cache->{flow} = Graph::Easy->_flow_as_direction($in,$flow);
  }

#############################################################################
# multi-celled nodes

sub _calc_size
  {
  # Calculate the base size in cells from the attributes (before grow())
  # Will return a hash that denotes in which direction the node should grow.
  my $self = shift;

  # If specified only one of "rows" or "columns", then grow the node
  # only in the unspecified direction. Default is grow both.
  my $grow_sides = { cx => 1, cy => 1 };

  my $r = $self->{att}->{rows};
  my $c = $self->{att}->{columns};
  delete $grow_sides->{cy} if defined $r && !defined $c;
  delete $grow_sides->{cx} if defined $c && !defined $r;

  $r = $self->attribute('rows') unless defined $r;
  $c = $self->attribute('columns') unless defined $c;

  $self->{cy} = abs($r || 1);
  $self->{cx} = abs($c || 1);

  $grow_sides;
  }

sub _grow
  {
  # Grows the node until it has sufficient cells for all incoming/outgoing
  # edges. The initial size will be based upon the attributes 'size' (or
  # 'rows' or 'columns', depending on which is set)
  my $self = shift;

  # XXX TODO: grow the node based on its label dimensions
#  my ($w,$h) = $self->dimensions();
#
#  my $cx = int(($w+2) / 5) || 1;
#  my $cy = int(($h) / 3) || 1;
#
#  $self->{cx} = $cx if $cx > $self->{cx};
#  $self->{cy} = $cy if $cy > $self->{cy};

  # satisfy the edge start/end port constraints:

  # We calculate a bitmap (vector) for each side, and mark each
  # used port. Edges that have an unspecified port will just be
  # counted.

  # bitmap for each side:
  my $vec = { north => '', south => '', east => '', west => '' };
  # number of edges constrained to one side, but without port number
  my $cnt = { north => 0, south => 0, east => 0, west => 0 };
  # number of edges constrained to one side, with port number
  my $portnr = { north => 0, south => 0, east => 0, west => 0 };
  # max number of ports for each side
  my $max = { north => 0, south => 0, east => 0, west => 0 };

  my @idx = ( [ 'start', 'from' ], [ 'end', 'to' ] );
  # number of slots we need to edges without port restrictions
  my $unspecified = 0;

  # count of outgoing edges
  my $outgoing = 0;

  for my $e (values %{$self->{edges}})
    {
    # count outgoing edges
    $outgoing++ if $e->{from} == $self;

    # do always both ends, because self-loops can start AND end at this node:
    for my $end (0..1)
      {
      # if the edge starts/ends here
      if ($e->{$idx[$end]->[1]} == $self)		# from/to
	{
	my ($side, $nr) = $e->port($idx[$end]->[0]);	# start/end

	if (defined $side)
	  {
	  if (!defined $nr || $nr eq '')
	    {
	    # no port number specified, so just count
	    $cnt->{$side}++;
	    }
	  else
	    {
	    # mark the bit in the vector
	    # limit to four digits
	    $nr = 9999 if abs($nr) > 9999; 

	    # if slot was not used yet, count it
	    $portnr->{$side} ++ if vec($vec->{$side}, $nr, 1) == 0x0;

	    # calculate max number of ports
            $nr = abs($nr) - 1 if $nr < 0;		# 3 => 3, -3 => 2
            $nr++;					# 3 => 4, -3 => 3

	    # mark as used
	    vec($vec->{$side}, $nr - 1, 1) = 0x01;

	    $max->{$side} = $nr if $nr > $max->{$side};
	    }
          }
        else
          {
          $unspecified ++;
          }
        } # end if port is constrained
      } # end for start/end port
    } # end for all edges

  for my $e (values %{$self->{edges}})
    {
    # the loop above will count all self-loops twice when they are
    # unrestricted. So subtract these again. Restricted self-loops
    # might start at one port and end at another, and this case is
    # covered correctly by the code above.
    $unspecified -- if $e->{to} == $e->{from};
    }

  # Shortcut, if the number of edges is < 4 and we have not restrictions,
  # then a 1x1 node suffices
  if ($unspecified < 4 && ($unspecified == keys %{$self->{edges}}))
    {
    $self->_calc_size();
    return $self;
    }
 
  my $need = {};
  my $free = {};
  for my $side (qw/north south east west/)
    {
    # maximum number of ports we need to reserve, minus edges constrained
    # to unique ports: free ports on that side
    $free->{$side} = $max->{$side} - $portnr->{$side};
    $need->{$side} = $max->{$side};
    if ($free->{$side} < 2 * $cnt->{$side})
      {
      $need->{$side} += 2 * $cnt->{$side} - $free->{$side} - 1;
      }
    }
  # now $need contains for each side the absolut min. number of ports we need

#  use Data::Dumper; 
#  print STDERR "# port contraints for $self->{name}:\n";
#  print STDERR "# count: ", Dumper($cnt), "# max: ", Dumper($max),"\n";
#  print STDERR "# ports: ", Dumper($portnr),"\n";
#  print STDERR "# need : ", Dumper($need),"\n";
#  print STDERR "# free : ", Dumper($free),"\n";
 
  # calculate min. size in X and Y direction
  my $min_x = $need->{north}; $min_x = $need->{south} if $need->{south} > $min_x;
  my $min_y = $need->{west}; $min_y = $need->{east} if $need->{east} > $min_y;

  my $grow_sides = $self->_calc_size();

  # increase the size if the minimum required size is not met
  $self->{cx} = $min_x if $min_x > $self->{cx};
  $self->{cy} = $min_y if $min_y > $self->{cy};

  my $flow = $self->flow();

  # if this is a sink node, grow it more by ignoring free ports on the front side
  my $front_side = 'east';
  $front_side = 'west' if $flow == 270;
  $front_side = 'south' if $flow == 180;
  $front_side = 'north' if $flow == 0;

  # now grow the node based on the general flow first VER, then HOR
  my $grow = 0;					# index into @grow_what
  my @grow_what = sort keys %$grow_sides;	# 'cx', 'cy' or 'cx' or 'cy'

  if (keys %$grow_sides > 1)
    {
    # for left/right flow, swap the growing around
    @grow_what = ( 'cy', 'cx' ) if $flow == 90 || $flow == 270;
    }

  # fake a non-sink node for nodes with an offset/children
  $outgoing = 1 if ref($self->{origin}) || keys %{$self->{children}} > 0;

  while ( 3 < 5 )
    {
    # calculate whether we already found a space for all edges
    my $free_ports = 0;
    for my $side (qw/north south/)
      {
      # if this is a sink node, grow it more by ignoring free ports on the front side
      next if $outgoing == 0 && $front_side eq $side;
      $free_ports += 1 + int(($self->{cx} - $cnt->{$side} - $portnr->{$side}) / 2);
      }     
    for my $side (qw/east west/)
      {
      # if this is a sink node, grow it more by ignoring free ports on the front side
      next if $outgoing == 0 && $front_side eq $side;
      $free_ports += 1 + int(($self->{cy} - $cnt->{$side} - $portnr->{$side}) / 2);
      }
    last if $free_ports >= $unspecified;

    $self->{ $grow_what[$grow] } += 2;

    $grow ++; $grow = 0 if $grow >= @grow_what;
    }

  $self;
  }

sub is_multicelled
  {
  # return true if node consist of more than one cell
  my $self = shift;

  $self->_calc_size() unless defined $self->{cx};

  $self->{cx} + $self->{cy} <=> 2;	# 1 + 1 == 2: no, cx + xy != 2: yes
  }

sub is_anon
  {
  # normal nodes are not anon nodes (but "::Anon" are)
  0;
  }

#############################################################################
# accessor methods

sub _un_escape
  {
  # replace \N, \G, \T, \H and \E (depending on type)
  # if $label is false, also replace \L with the label
  my ($self, $txt, $do_label) = @_;
 
  # for edges:
  if (exists $self->{edge})
    {
    my $e = $self->{edge};
    $txt =~ s/\\E/$e->{from}->{name}\->$e->{to}->{name}/g;
    $txt =~ s/\\T/$e->{from}->{name}/g;
    $txt =~ s/\\H/$e->{to}->{name}/g;
    # \N for edges is the label of the edge
    if ($txt =~ /\\N/)
      {
      my $l = $self->label();
      $txt =~ s/\\N/$l/g;
      }
    }
  else
    {
    # \N for nodes
    $txt =~ s/\\N/$self->{name}/g;
    }
  # \L with the label
  if ($txt =~ /\\L/ && $do_label)
    {
    my $l = $self->label();
    $txt =~ s/\\L/$l/g;
    }

  # \G for edges and nodes
  if ($txt =~ /\\G/)
    {
    my $g = '';
    # the graph itself
    $g = $self->attribute('title') unless ref($self->{graph});
    # any nodes/edges/groups in it
    $g = $self->{graph}->label() if ref($self->{graph});
    $txt =~ s/\\G/$g/g;
    }
  $txt;
  }

sub title
  {
  # Returns a title of the node (or '', if none was set), which can be
  # used for mouse-over titles

  my $self = shift;

  my $title = $self->attribute('title');
  if ($title eq '')
    {
    my $autotitle = $self->attribute('autotitle');
    if (defined $autotitle)
      {
      $title = '';					# default is none

      if ($autotitle eq 'name')				# use name
	{
        $title = $self->{name};
	# edges do not have a name and fall back on their label
        $title = $self->{att}->{label} unless defined $title;
	}

      if ($autotitle eq 'label')
        {
        $title = $self->{name};				# fallback to name
        # defined to avoid overriding "name" with the non-existant label attribute
	# do not use label() here, but the "raw" label of the edge:
        my $label = $self->label(); $title = $label if defined $label;
        }

      $title = $self->link() if $autotitle eq 'link';
      }
    $title = '' unless defined $title;
    }

  $title = $self->_un_escape($title, 1) if !$_[0] && $title =~ /\\[EGHNTL]/;

  $title;
  }

sub background
  {
  # get the background for this group/edge cell, honouring group membership.
  my $self = shift;

  $self->color_attribute('background');
  }

sub label
  {
  my $self = shift;

  # shortcut to speed it up a bit:
  my $label = $self->{att}->{label};
  $label = $self->attribute('label') unless defined $label;

  # for autosplit nodes, use their auto-label first (unless already got 
  # a label from the class):
  $label = $self->{autosplit_label} unless defined $label;
  $label = $self->{name} unless defined $label;

  return '' unless defined $label;

  if ($label ne '')
    {
    my $len = $self->attribute('autolabel');
    if ($len ne '')
      {
      # allow the old format (pre v0.49), too: "name,12" => 12
      $len =~ s/^name\s*,\s*//;			
      # restrict to sane values
      $len = abs($len || 0); $len = 99999 if $len > 99999;
      if (length($label) > $len)
        {
        my $g = $self->{graph} || {};
	if ((($g->{_ascii_style}) || 0) == 0)
	  {
	  # ASCII output
	  $len = int($len / 2) - 3; $len = 0 if $len < 0;
	  $label = substr($label, 0, $len) . ' ... ' . substr($label, -$len, $len);
	  }
	else
	  {
	  $len = int($len / 2) - 2; $len = 0 if $len < 0;
	  $label = substr($label, 0, $len) . ' … ' . substr($label, -$len, $len);
	  }
        }
      }
    }

  $label = $self->_un_escape($label) if !$_[0] && $label =~ /\\[EGHNT]/;

  $label;
  }

sub name
  {
  my $self = shift;

  $self->{name};
  }

sub x
  {
  my $self = shift;

  $self->{x};
  }

sub y
  {
  my $self = shift;

  $self->{y};
  }

sub width
  {
  my $self = shift;

  $self->{w};
  }

sub height
  {
  my $self = shift;

  $self->{h};
  }

sub origin
  {
  # Returns node that this node is relative to or undef, if not.
  my $self = shift;

  $self->{origin};
  }

sub pos
  {
  my $self = shift;

  ($self->{x} || 0, $self->{y} || 0);
  }

sub offset
  {
  my $self = shift;

  ($self->{dx} || 0, $self->{dy} || 0);
  }

sub columns
  {
  my $self = shift;

  $self->_calc_size() unless defined $self->{cx};

  $self->{cx};
  }

sub rows
  {
  my $self = shift;

  $self->_calc_size() unless defined $self->{cy};

  $self->{cy};
  }

sub size
  {
  my $self = shift;

  $self->_calc_size() unless defined $self->{cx};

  ($self->{cx}, $self->{cy});
  }

sub shape
  {
  my $self = shift;

  my $shape;
  $shape = $self->{att}->{shape} if exists $self->{att}->{shape};
  $shape = $self->attribute('shape') unless defined $shape;
  $shape;
  }

sub dimensions
  {
  # Returns the minimum dimensions of the node/cell derived from the
  # label or name, in characters.
  my $self = shift;

  my $align = $self->attribute('align');
  my ($lines,$aligns) = $self->_aligned_label($align);

  my $w = 0; my $h = scalar @$lines;
  foreach my $line (@$lines)
    {
    $w = length($line) if length($line) > $w;
    }
  ($w,$h);
  }

#############################################################################
# edges and connections

sub edges_to
  {
  # Return all the edge objects that start at this vertex and go to $other.
  my ($self, $other) = @_;

  # no graph, no dice
  return unless ref $self->{graph};

  my @edges;
  for my $edge (values %{$self->{edges}})
    {
    push @edges, $edge if $edge->{from} == $self && $edge->{to} == $other;
    }
  @edges;
  }

sub edges_at_port
  {
  # return all edges that share the same given port
  my ($self, $attr, $side, $port) = @_;

  # Must be "start" or "end"
  return () unless $attr =~ /^(start|end)\z/;

  $self->_croak('side not defined') unless defined $side;
  $self->_croak('port not defined') unless defined $port;

  my @edges;
  for my $e (values %{$self->{edges}})
    {
    # skip edges ending here if we look at start
    next if $e->{to} eq $self && $attr eq 'start';
    # skip edges starting here if we look at end
    next if $e->{from} eq $self && $attr eq 'end';

    my ($s_p,@ss_p) = $e->port($attr);	
    next unless defined $s_p;

    # same side and same port number?
    push @edges, $e 
      if $s_p eq $side && @ss_p == 1 && $ss_p[0] eq $port;
    }

  @edges;
  }

sub shared_edges
  {
  # return all edges that share one port with another edge
  my ($self) = @_;

  my @edges;
  for my $e (values %{$self->{edges}})
    {
    my ($s_p,@ss_p) = $e->port('start');
    push @edges, $e if defined $s_p;
    my ($e_p,@ee_p) = $e->port('end');
    push @edges, $e if defined $e_p;
    }
  @edges;
  }

sub nodes_sharing_start
  {
  # return all nodes that share an edge start with an
  # edge from that node
  my ($self, $side, @port) = @_;

  my @edges = $self->edges_at_port('start',$side,@port);

  my $nodes;
  for my $e (@edges)
    {
    # ignore self-loops
    my $to = $e->{to};
    next if $to == $self;

    # remove duplicates
    $nodes->{ $to->{name} } = $to;
    }

  (values %$nodes);
  }

sub nodes_sharing_end
  {
  # return all nodes that share an edge end with an
  # edge from that node
  my ($self, $side, @port) = @_;

  my @edges = $self->edges_at_port('end',$side,@port);

  my $nodes;
  for my $e (@edges)
    {
    # ignore self-loops
    my $from = $e->{from};
    next if $from == $self;

    # remove duplicates
    $nodes->{ $from->{name} } = $from;
    }

  (values %$nodes);
  }

sub incoming
  {
  # return all edges that end at this node
  my $self = shift;

  # no graph, no dice
  return unless ref $self->{graph};

  if (!wantarray)
    {
    my $count = 0;
    for my $edge (values %{$self->{edges}})
      {
      $count++ if $edge->{to} == $self;
      }
    return $count;
    }

  my @edges;
  for my $edge (values %{$self->{edges}})
    {
    push @edges, $edge if $edge->{to} == $self;
    }
  @edges;
  }

sub outgoing
  {
  # return all edges that start at this node
  my $self = shift;

  # no graph, no dice
  return unless ref $self->{graph};

  if (!wantarray)
    {
    my $count = 0;
    for my $edge (values %{$self->{edges}})
      {
      $count++ if $edge->{from} == $self;
      }
    return $count;
    }

  my @edges;
  for my $edge (values %{$self->{edges}})
    {
    push @edges, $edge if $edge->{from} == $self;
    }
  @edges;
  }

sub connections
  {
  # return number of connections (incoming+outgoing)
  my $self = shift;

  return 0 unless defined $self->{graph};

  # We need to count the connections, because "[A]->[A]" creates
  # two connections on "A", but only one edge! 
  my $con = 0;
  for my $edge (values %{$self->{edges}})
    {
    $con ++ if $edge->{to} == $self;
    $con ++ if $edge->{from} == $self;
    }
  $con;
  }

sub edges
  {
  # return all the edges
  my $self = shift;

  # no graph, no dice
  return unless ref $self->{graph};

  wantarray ? values %{$self->{edges}} : scalar keys %{$self->{edges}};
  }

sub sorted_successors
  {
  # return successors of the node sorted by their chain value
  # (e.g. successors with more successors first) 
  my $self = shift;

  my @suc = sort {
       scalar $b->successors() <=> scalar $a->successors() ||
       scalar $a->{name} cmp scalar $b->{name}
       } $self->successors();
  @suc;
  }

sub successors
  {
  # return all nodes (as objects) we are linked to
  my $self = shift;

  return () unless defined $self->{graph};

  my %suc;
  for my $edge (values %{$self->{edges}})
    {
    next unless $edge->{from} == $self;
    $suc{$edge->{to}->{id}} = $edge->{to};	# weed out doubles
    }
  values %suc;
  }

sub predecessors
  {
  # return all nodes (as objects) that link to us
  my $self = shift;

  return () unless defined $self->{graph};

  my %pre;
  for my $edge (values %{$self->{edges}})
    {
    next unless $edge->{to} == $self;
    $pre{$edge->{from}->{id}} = $edge->{from};	# weed out doubles
    }
  values %pre;
  }

sub has_predecessors
  {
  # return true if node has incoming edges (even from itself)
  my $self = shift;

  return undef unless defined $self->{graph};

  for my $edge (values %{$self->{edges}})
    {
    return 1 if $edge->{to} == $self;		# found one
    }
  0;						# found none
  }

sub has_as_predecessor
  {
  # return true if other is a predecessor of node
  my ($self,$other) = @_;

  return () unless defined $self->{graph};

  for my $edge (values %{$self->{edges}})
    {
    return 1 if 
	$edge->{to} == $self && $edge->{from} == $other;	# found one
    }
  0;						# found none
  }

sub has_as_successor
  {
  # return true if other is a successor of node
  my ($self,$other) = @_;

  return () unless defined $self->{graph};

  for my $edge (values %{$self->{edges}})
    {
    return 1 if
	$edge->{from} == $self && $edge->{to} == $other;	# found one

    }
  0;						# found none
  }

#############################################################################
# relatively placed nodes

sub relative_to
  {
  # Sets the new origin if passed a Graph::Easy::Node object.
  my ($self,$parent,$dx,$dy) = @_;

  if (!ref($parent) || !$parent->isa('Graph::Easy::Node'))
    {
    require Carp;
    Carp::confess("Can't set origin to non-node object $parent");
    }

  my $grandpa = $parent->find_grandparent();
  if ($grandpa == $self)
    {
    require Carp;
    Carp::confess( "Detected loop in origin-chain:"
                  ." tried to set origin of '$self->{name}' to my own grandchild $parent->{name}");
    }

  # unregister us with our old parent
  delete $self->{origin}->{children}->{$self->{id}} if defined $self->{origin};

  $self->{origin} = $parent;
  $self->{dx} = $dx if defined $dx;
  $self->{dy} = $dy if defined $dy;
  $self->{dx} = 0 unless defined $self->{dx};
  $self->{dy} = 0 unless defined $self->{dy};

  # register us as a new child
  $parent->{children}->{$self->{id}} = $self;

  $self;
  }

sub find_grandparent
  {
  # For a node that has no origin (is not relative to another), returns
  # $self. For all others, follows the chain of origin back until we
  # hit a node without a parent. This code assumes there are no loops,
  # which origin() prevents from happening.
  my $cur = shift;

  if (wantarray)
    {
    my $ox = 0;
    my $oy = 0;
    while (defined($cur->{origin}))
      {
      $ox -= $cur->{dx};
      $oy -= $cur->{dy};
      $cur = $cur->{origin};
      }
    return ($cur,$ox,$oy);
    }

  while (defined($cur->{origin}))
    {
    $cur = $cur->{origin};
    }
  
  $cur;
  }

#############################################################################
# attributes

sub del_attribute
  {
  my ($self, $name) = @_;

  # font-size => fontsize
  $name = $att_aliases->{$name} if exists $att_aliases->{$name};

  $self->{cache} = {};

  my $a = $self->{att};
  delete $a->{$name};
  if ($name eq 'size')
    {
    delete $a->{rows};
    delete $a->{columns};
    }
  if ($name eq 'border')
    {
    delete $a->{borderstyle};
    delete $a->{borderwidth};
    delete $a->{bordercolor};
    }
  $self;
  }

sub set_attribute
  {
  my ($self, $name, $v, $class) = @_;

  $self->{cache} = {};

  $name = 'undef' unless defined $name;
  $v = 'undef' unless defined $v;

  # font-size => fontsize
  $name = $att_aliases->{$name} if exists $att_aliases->{$name};

  # edge.cities => edge
  $class = $self->main_class() unless defined $class;

  # remove quotation marks, but not for titles, labels etc
  my $val = Graph::Easy->unquote_attribute($class,$name,$v);

  my $g = $self->{graph};
  
  $g->{score} = undef if $g;	# invalidate layout to force a new layout

  my $strict = 0; $strict = $g->{strict} if $g;
  if ($strict)
    {
    my ($rc, $newname, $v) = $g->validate_attribute($name,$val,$class);

    return if defined $rc;		# error?

    $val = $v;
    }

  if ($name eq 'class')
    {
    $self->sub_class($val);
    return $val;
    }
  elsif ($name eq 'group')
    {
    $self->add_to_group($val);
    return $val;
    }
  elsif ($name eq 'border')
    {
    my $c = $self->{att};

    ($c->{borderstyle}, $c->{borderwidth}, $c->{bordercolor}) =
	$g->split_border_attributes( $val );

    return $val;
    }

  if ($name =~ /^(columns|rows|size)\z/)
    {
    if ($name eq 'size')
      {
      $val =~ /^(\d+)\s*,\s*(\d+)\z/;
      my ($cx, $cy) = (abs(int($1)),abs(int($2)));
      ($self->{att}->{columns}, $self->{att}->{rows}) = ($cx, $cy);
      }
    else
      {
      $self->{att}->{$name} = abs(int($val));
      }
    return $self;
    }

  if ($name =~ /^(origin|offset)\z/)
    {
    # Only the first autosplit node get the offset/origin
    return $self if exists $self->{autosplit} && !defined $self->{autosplit};

    if ($name eq 'origin')
      {
      # if it doesn't exist, add it
      my $org = $self->{graph}->add_node($val);
      $self->relative_to($org);
  
      # set the attributes, too, so get_attribute('origin') works, too:
      $self->{att}->{origin} = $org->{name};
      }
    else
      {
      # offset
      # if it doesn't exist, add it
      my ($x,$y) = split/\s*,\s*/, $val;
      $x = int($x);
      $y = int($y);
      if ($x == 0 && $y == 0)
        {
        $g->error("Error in attribute: 'offset' is 0,0 in node $self->{name} with class '$class'");
        return;
        }
      $self->{dx} = $x;
      $self->{dy} = $y;

      # set the attributes, too, so get_attribute('origin') works, too:
      $self->{att}->{offset} = "$self->{dx},$self->{dy}";
      }
    return $self;
    }

  $self->{att}->{$name} = $val;
  }

sub set_attributes
  {
  my ($self, $atr, $index) = @_;

  foreach my $n (keys %$atr)
    {
    my $val = $atr->{$n};
    $val = $val->[$index] if ref($val) eq 'ARRAY' && defined $index;

    next if !defined $val || $val eq '';

    $n eq 'class' ? $self->sub_class($val) : $self->set_attribute($n, $val);
    }
  $self;
  }

BEGIN
  {
  # some handy aliases
  *text_styles_as_css = \&Graph::Easy::text_styles_as_css;
  *text_styles = \&Graph::Easy::text_styles;
  *_font_size_in_pixels = \&Graph::Easy::_font_size_in_pixels;
  *get_color_attribute = \&color_attribute;
  *link = \&Graph::Easy::link;
  *border_attribute = \&Graph::Easy::border_attribute;
  *get_attributes = \&Graph::Easy::get_attributes;
  *get_attribute = \&Graph::Easy::attribute;
  *raw_attribute = \&Graph::Easy::raw_attribute;
  *get_raw_attribute = \&Graph::Easy::raw_attribute;
  *raw_color_attribute = \&Graph::Easy::raw_color_attribute;
  *raw_attributes = \&Graph::Easy::raw_attributes;
  *raw_attributes = \&Graph::Easy::raw_attributes;
  *attribute = \&Graph::Easy::attribute;
  *color_attribute = \&Graph::Easy::color_attribute;
  *default_attribute = \&Graph::Easy::default_attribute;
  $att_aliases = Graph::Easy::_att_aliases();
  }

#############################################################################

sub group
  {
  # return the group this object belongs to
  my $self = shift;

  $self->{group};
  }

sub add_to_group
  {
  my ($self,$group) = @_;
 
  my $graph = $self->{graph};				# shortcut

  # delete from old group if nec.
  $self->{group}->del_member($self) if ref $self->{group};

  # if passed a group name, create or find group object
  $group = $graph->add_group($group) if (!ref($group) && $graph);

  # To make attribute('group') work:
  $self->{att}->{group} = $group->{name};

  $group->add_member($self);

  $self;
  }

sub parent
  {
  # return parent object, either the group the node belongs to, or the graph
  my $self = shift;

  my $p = $self->{graph};

  $p = $self->{group} if ref($self->{group});

  $p;
  }

sub _update_boundaries
  {
  my ($self, $parent) = @_;

  # XXX TODO: use current layout parent for recursive layouter:
  $parent = $self->{graph};

  # cache max boundaries for A* algorithmn:

  my $x = $self->{x};
  my $y = $self->{y};

  # create the cache if it doesn't already exist
  $parent->{cache} = {} unless ref($parent->{cache});

  my $cache = $parent->{cache};
  
  $cache->{min_x} = $x if !defined $cache->{min_x} || $x < $cache->{min_x};
  $cache->{min_y} = $y if !defined $cache->{min_y} || $y < $cache->{min_y};

  $x = $x + ($self->{cx}||1) - 1;
  $y = $y + ($self->{cy}||1) - 1;
  $cache->{max_x} = $x if !defined $cache->{max_x} || $x > $cache->{max_x};
  $cache->{max_y} = $y if !defined $cache->{max_y} || $y > $cache->{max_y};

  if (($parent->{debug}||0) > 1)
    {
    my $n = $self->{name}; $n = $self unless defined $n;
    print STDERR "Update boundaries for $n (parent $parent) at $x, $y\n";
  
    print STDERR "Boundaries are now: " .
		 "$cache->{min_x},$cache->{min_y} => $cache->{max_x},$cache->{max_y}\n";
    }

  $self;
  }

1;
__END__

=head1 NAME

Graph::Easy::Node - Represents a node in a Graph::Easy graph

=head1 SYNOPSIS

        use Graph::Easy::Node;

	my $bonn = Graph::Easy::Node->new('Bonn');

	$bonn->set_attribute('border', 'solid 1px black');

	my $berlin = Graph::Easy::Node->new( name => 'Berlin' );

=head1 DESCRIPTION

A C<Graph::Easy::Node> represents a node in a simple graph. Each
node has contents (a text, an image or another graph), and dimension plus
an origin. The origin is typically determined by a graph layouter module
like L<Graph::Easy>.

=head1 METHODS

Apart from the methods of the base class L<Graph::Easy::Base>, a
C<Graph::Easy::Node> has the following methods:

=head2 new()

        my $node = Graph::Easy::Node->new( name => 'node name' );
        my $node = Graph::Easy::Node->new( 'node name' );

Creates a new node. If you want to add the node to a Graph::Easy object,
then please use the following to create the node object:

	my $node = $graph->add_node('Node name');

You can then use C<< $node->set_attribute(); >>
or C<< $node->set_attributes(); >> to set the new Node's attributes.

=head2 as_ascii()

	my $ascii = $node->as_ascii();

Return the node as a little box drawn in ASCII art as a string.

=head2 as_txt()

	my $txt = $node->as_txt();

Return the node in simple txt format, including attributes.

=head2 as_svg()

	my $svg = $node->as_svg();

Returns the node as Scalable Vector Graphic. The actual code for
that routine is defined L<Graph::Easy::As_svg.pm>.

=head2 as_graphviz()

	my $txt = $node->as_graphviz_txt();

Returns the node as graphviz compatible text which can be feed
to dot etc to create images.
  
=head2 as_graphviz_txt()

	my $txt = $node->as_graphviz_txt();

Return only the node itself (without attributes) as graphviz representation.

=head2 as_pure_txt()

	my $txt = $node->as_pure_txt();

Return the node in simple txt format, without the attributes.

=head2 text_styles_as_css()

	my $styles = $graph->text_styles_as_css();	# or $edge->...() etc.

Return the text styles as a chunk of CSS styling that can be embedded into
a C< style="" > parameter.

=head2 as_html()

	my $html = $node->as_html();

Return the node as HTML code.

=head2 attribute(), get_attribute()

	$node->attribute('border-style');

Returns the respective attribute of the node or undef if it
was not set. If there is a default attribute for all nodes
of the specific class the node is in, then this will be returned.

=head2 get_attributes()

        my $att = $object->get_attributes();

Return all effective attributes on this object (graph/node/group/edge) as
an anonymous hash ref. This respects inheritance and default values.

Note that this does not include custom attributes.

See also L<get_custom_attributes> and L<raw_attributes()>.

=head2 get_custom_attributes()

	my $att = $object->get_custom_attributes();

Return all the custom attributes on this object (graph/node/group/edge) as
an anonymous hash ref.

=head2 custom_attributes()

    my $att = $object->custom_attributes();

C<< custom_attributes() >> is an alias for L<< get_custom_attributes >>.

=head2 raw_attributes()

        my $att = $object->get_attributes();

Return all set attributes on this object (graph/node/group/edge) as
an anonymous hash ref. This respects inheritance, but does not include
default values for unset attributes.

See also L<get_attributes()>.

=head2 default_attribute()

	my $def = $graph->default_attribute($class, 'fill');

Returns the default value for the given attribute B<in the class>
of the object.

The default attribute is the value that will be used if
the attribute on the object itself, as well as the attribute
on the class is unset.

To find out what attribute is on the class, use the three-arg form
of L<attribute> on the graph:

	my $g = Graph::Easy->new();
	my $node = $g->add_node('Berlin');

	print $node->attribute('fill'), "\n";		# print "white"
	print $node->default_attribute('fill'), "\n";	# print "white"
	print $g->attribute('node','fill'), "\n";	# print "white"

	$g->set_attribute('node','fill','red');		# class is "red"
	$node->set_attribute('fill','green');		# this object is "green"

	print $node->attribute('fill'), "\n";		# print "green"
	print $node->default_attribute('fill'), "\n";	# print "white"
	print $g->attribute('node','fill'), "\n";	# print "red"

See also L<raw_attribute()>.

=head2 attributes_as_txt

	my $txt = $node->attributes_as_txt();

Return the attributes of this node as text description. This is used
by the C<< $graph->as_txt() >> code and there should be no reason
to use this function on your own.

=head2 set_attribute()

	$node->set_attribute('border-style', 'none');

Sets the specified attribute of this (and only this!) node to the
specified value.

=head2 del_attribute()

	$node->del_attribute('border-style');

Deletes the specified attribute of this (and only this!) node.

=head2 set_attributes()

	$node->set_attributes( $hash );

Sets all attributes specified in C<$hash> as key => value pairs in this
(and only this!) node.

=head2 border_attribute()

	my $border = $node->border_attribute();

Assembles the C<border-width>, C<border-color> and C<border-style> attributes
into a string like "solid 1px red".

=head2 color_attribute()

	# returns f.i. #ff0000
	my $color = $node->get_color_attribute( 'fill' );

Just like get_attribute(), but only for colors, and returns them as hex,
using the current colorscheme.

=head2 get_color_attribute()

Is an alias for L<color_attribute()>.

=head2 raw_attribute(), get_raw_attribute()

	my $value = $object->raw_attribute( $name );

Return the value of attribute C<$name> from the object it this
method is called on (graph, node, edge, group etc.). If the
attribute is not set on the object itself, returns undef.

This method respects inheritance, so an attribute value of 'inherit'
on an object will make the method return the inherited value:

	my $g = Graph::Easy->new();
	my $n = $g->add_node('A');

	$g->set_attribute('color','red');

	print $n->raw_attribute('color');		# undef
	$n->set_attribute('color','inherit');
	print $n->raw_attribute('color');		# 'red'

See also L<attribute()>.

=head2 raw_color_attribute()

	# returns f.i. #ff0000
	my $color = $graph->raw_color_attribute('color' );

Just like L<raw_attribute()>, but only for colors, and returns them as hex,
using the current colorscheme.

If the attribute is not set on the object, returns C<undef>.

=head2 text_styles()

        my $styles = $node->text_styles();
        if ($styles->{'italic'})
          {
          print 'is italic\n';
          }

Return a hash with the given text-style properties, aka 'underline', 'bold' etc.

=head2 find_grandparent()

	my $grandpa = $node->find_grandparent(); 

For a node that has no origin (is not relative to another), returns
C<$node>. For all others, follows the chain of origin back until
a node without a parent is found and returns this node.
This code assumes there are no loops, which C<origin()> prevents from
happening.

=head2 name()

	my $name = $node->name();

Return the name of the node. In a graph, each node has a unique name,
which, unless a node label is set, will be displayed when rendering the
graph.

=head2 label()

	my $label = $node->label();
	my $label = $node->label(1);		# raw

Return the label of the node. If no label was set, returns the C<name>
of the node.

If the optional parameter is true, then the label will returned 'raw',
that is any potential escape of the form C<\N>, C<\E>, C<\G>, C<\T>
or C<\H> will not be left alone and not be replaced.

=head2 background()

	my $bg = $node->background();

Returns the background color. This method honours group membership and
inheritance.

=head2 quoted_comment()

	my $cmt = $node->comment();

Comment of this object, quoted suitable as to be embedded into HTML/SVG.
Returns the empty string if this object doesn't have a comment set.

=head2 title()

	my $title = $node->title();
	my $title = $node->title(1);		# raw

Returns a potential title that can be used for mouse-over effects.
If no title was set (or autogenerated), will return an empty string.

If the optional parameter is true, then the title will returned 'raw',
that is any potential escape of the form C<\N>, C<\E>, C<\G>, C<\T>
or C<\H> will be left alone and not be replaced.

=head2 link()

	my $link = $node->link();
	my $link = $node->link(1);		# raw

Returns the URL, build from the C<linkbase> and C<link> (or C<autolink>)
attributes.  If the node has no link associated with it, return an empty
string.

If the optional parameter is true, then the link will returned 'raw',
that is any potential escape of the form C<\N>, C<\E>, C<\G>, C<\T>
or C<\H> will not be left alone and not be replaced.

=head2 dimensions()

	my ($w,$h) = $node->dimensions();

Returns the dimensions of the node/cell derived from the label (or name) in characters.
Assumes the label/name has literal '\n' replaced by "\n".

=head2 size()

	my ($cx,$cy) = $node->size();

Returns the node size in cells.

=head2 contents()

	my $contents = $node->contents();

For nested nodes, returns the contents of the node.

=head2 width()

	my $width = $node->width();

Returns the width of the node. This is a unitless number.

=head2 height()

	my $height = $node->height();

Returns the height of the node. This is a unitless number.

=head2 columns()

	my $cols = $node->columns();

Returns the number of columns (in cells) that this node occupies.

=head2 rows()

	my $cols = $node->rows();

Returns the number of rows (in cells) that this node occupies.

=head2 is_multicelled()

	if ($node->is_multicelled())
	  {
	  ...
	  }

Returns true if the node consists of more than one cell. See als
L<rows()> and L<cols()>.

=head2 is_anon()

	if ($node->is_anon())
	  {
	  ...
	  }

Returns true if the node is an anonymous node. False for C<Graph::Easy::Node>
objects, and true for C<Graph::Easy::Node::Anon>.

=head2 pos()

	my ($x,$y) = $node->pos();

Returns the position of the node. Initially, this is undef, and will be
set from L<Graph::Easy::layout()>. Only valid during the layout phase.

=head2 offset()

	my ($dx,$dy) = $node->offset();

Returns the position of the node relativ to the origin. Returns C<(0,0)> if
the origin node was not sset.

=head2 x()

	my $x = $node->x();

Returns the X position of the node. Initially, this is undef, and will be
set from L<Graph::Easy::layout()>. Only valid during the layout phase.

=head2 y()

	my $y = $node->y();

Returns the Y position of the node. Initially, this is undef, and will be
set from L<Graph::Easy::layout()>. Only valid during the layout phase.

=head2 id()

	my $id = $node->id();

Returns the node's unique, internal ID number.

=head2 connections()

	my $cnt = $node->connections();

Returns the count of incoming and outgoing connections of this node.
Self-loops count as two connections, so in the following example, node C<N>
has B<four> connections, but only B<three> edges:

	            +--+
	            v  |
	+---+     +------+     +---+
	| 1 | --> |  N   | --> | 2 |
	+---+     +------+     +---+

See also L<edges()>.

=head2 edges()

	my $edges = $node->edges();

Returns a list of all the edges (as L<Graph::Easy::Edge> objects) at this node,
in no particular order.

=head2 predecessors()

	my @pre = $node->predecessors();

Returns all nodes (as objects) that link to us.

=head2 has_predecessors()

	if ($node->has_predecessors())
	  {
	  ...
	  }

Returns true if the node has one or more predecessors. Will return true for
nodes with selfloops.

=head2 successors()

	my @suc = $node->successors();

Returns all nodes (as objects) that we are linking to.

=head2 sorted_successors()

	my @suc = $node->sorted_successors();

Return successors of the node sorted by their chain value
(e.g. successors with more successors first). 

=head2 has_as_successor()

	if ($node->has_as_successor($other))
	  {
	  ...
	  }

Returns true if C<$other> ( a node or group) is a successor of node, that is if
there is an edge leading from node to C<$other>.

=head2 has_as_predecessor()

	if ($node->has_as_predecessor($other))
	  {
	  ...
	  }

Returns true if the node has C<$other> (a group or node) as predecessor, that
is if there is an edge leading from C<$other> to node.

=head2 edges_to()

	my @edges = $node->edges_to($other_node);

Returns all the edges (as objects) that start at C<< $node >> and go to
C<< $other_node >>.

=head2 shared_edges()

	my @edges = $node->shared_edges();

Return a list of all edges starting/ending at this node, that share a port
with another edge.

=head2 nodes_sharing_start()

	my @nodes = $node->nodes_sharing_start($side, $port);

Return a list of unique nodes that share a start point with an edge
from this node, on the specified side (absolut) and port number.

=head2 nodes_sharing_end()

	my @nodes = $node->nodes_sharing_end($side, $port);

Return a list of unique nodes that share an end point with an edge
from this node, on the specified side (absolut) and port number.

=head2 edges_at_port()

	my @edges = $node->edges_to('start', 'south', '0');

Returns all the edge objects that share the same C<start> or C<end>
port at the specified side and port number. The side must be
one of C<south>, C<north>, C<west> or C<east>. The port number
must be positive.

=head2 incoming()

	my @edges = $node->incoming();

Return all edges that end at this node.

=head2 outgoing()

	my @edges = $node->outgoing();

Return all edges that start at this node.

=head2 add_to_group()

	$node->add_to_group( $group );

Put the node into this group.

=head2 group()

	my $group = $node->group();

Return the group this node belongs to, or undef.

=head2 parent()

	my $parent = $node->parent();

Returns the parent object of the node, which is either the group the node belongs
to, or the graph.

=head2 origin()

	my $origin_node = $node->origin();

Returns the node this node is relativ to, or undef otherwise.

=head2 relative_to()

	$node->relative_to($parent, $dx, $dy);

Sets itself relativ to C<$parent> with the offset C<$dx,$dy>.

=head2 shape()

	my $shape = $node->shape();

Returns the shape of the node as string, defaulting to 'rect'. 

=head2 angle()

	my $angle = $self->rotation();

Return the node's rotation, based on the C<rotate> attribute, and
in case this is relative, on the node's flow.

=head2 flow()

	my $flow = $node->flow();

Returns the outgoing flow for this node as absolute direction in degrees.

The value is computed from the incoming flow (or the general flow as
default) and the flow attribute of this node.

=head2 _extra_params()

	my $extra_params = $node->_extra_params();

The return value of that method is added as extra params to the
HTML tag for a node when as_html() is called. Returns the empty
string by default, and can be overriden in subclasses. See also
L<use_class()>.

Overriden method should return a text with a leading space, or the
empty string.

Example:

	package Graph::Easy::MyNode;
	use base qw/Graph::Easy::Node/;

	sub _extra_params
	  {
	  my $self = shift;

	  ' ' . 'onmouseover="alert(\'' . $self->name() . '\');"'; 
	  }

	1;

=head1 EXPORT

None by default.

=head1 SEE ALSO

L<Graph::Easy>.

=head1 AUTHOR

Copyright (C) 2004 - 2007 by Tels L<http://bloodgate.com>.

See the LICENSE file for more details.

=cut
