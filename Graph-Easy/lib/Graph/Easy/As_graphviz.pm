#############################################################################
# output the graph in dot-format text
#
#############################################################################

package Graph::Easy::As_graphviz;

$VERSION = '0.31';

#############################################################################
#############################################################################

package Graph::Easy;

use strict;

my $remap = {
  node => {
    'align' => undef,
    'background' => undef,   # need a way to simulate that on non-rect nodes
    'basename' => undef,
    'bordercolor' => \&_remap_color,
    'borderstyle' => \&_graphviz_remap_border_style,
    'borderwidth' => undef,
    'border' => undef,
    'color' => \&_remap_color,
    'fill' => \&_remap_color,
    'label' => \&_graphviz_remap_label,
    'pointstyle' => undef,
    'pointshape' => undef,
    'rotate' => \&_graphviz_remap_node_rotate,
    'shape' => \&_graphviz_remap_node_shape,
    'title' => 'tooltip',
    'rows' => undef,
    'columns' => undef,
    },
  edge => {
    'align' => undef,
    'arrowstyle' => \&_graphviz_remap_arrow_style,
    'background' => undef,
    'color' => \&_graphviz_remap_edge_color,
    'end' => \&_graphviz_remap_port,
    'headtitle' => 'headtooltip',
    'headlink' => 'headURL',
    'labelcolor' => \&_graphviz_remap_label_color,
    'start' => \&_graphviz_remap_port,
    'style' => \&_graphviz_remap_edge_style,
    'tailtitle' => 'tailtooltip',
    'taillink' => 'tailURL',
    'title' => 'tooltip',
    'minlen' => \&_graphviz_remap_edge_minlen,
    },
  graph => {
    align => \&_graphviz_remap_align,
    background => undef,
    bordercolor => \&_remap_color,
    borderstyle => \&_graphviz_remap_border_style,
    borderwidth => undef,
    color => \&_remap_color,
    fill => \&_remap_color,
    gid => undef,
    label => \&_graphviz_remap_label,
    labelpos => 'labelloc',
    output => undef,
    type => undef,
    },
  group => {
    align => \&_graphviz_remap_align,
    background => undef,
    bordercolor => \&_remap_color,
    borderstyle => \&_graphviz_remap_border_style,
    borderwidth => undef,
    color => \&_remap_color,
    fill => \&_remap_color,
    labelpos => 'labelloc',
    rank => undef,
    title => 'tooltip',
    },
  all => {
    arrowshape => undef,
    autolink => undef,
    autotitle => undef,
    autolabel => undef,
    class => undef,
    colorscheme => undef,
    flow => undef,
    fontsize => \&_graphviz_remap_fontsize,
    font => \&_graphviz_remap_font,
    format => undef,
    group => undef,
    link => \&_graphviz_remap_link,
    linkbase => undef,
    textstyle => undef,
    textwrap => undef,
    },
  always => {
    node	=> [ qw/borderstyle label link rotate color fill/ ],
    'node.anon' => [ qw/bordercolor borderstyle label link rotate color/ ],
    edge	=> [ qw/labelcolor label link color/ ],
    graph	=> [ qw/labelpos borderstyle label link color/ ],
    },
  # this routine will handle all custom "x-dot-..." attributes
  x => \&_remap_custom_dot_attributes,
  };

sub _remap_custom_dot_attributes
  {
  my ($self, $name, $value) = @_;

  # drop anything that is not starting with "x-dot-..."
  return (undef,undef) unless $name =~ /^x-dot-/;

  $name =~ s/^x-dot-//;			# "x-dot-foo" => "foo"
  ($name,$value);
  }

my $color_remap = {
  bordercolor => 'color',
  color => 'fontcolor',
  fill => 'fillcolor',
  };

sub _remap_color
  {
  # remap one color value
  my ($self, $name, $color, $object) = @_;

  # guard against always doing the remap even when the attribute is not set
  return (undef,undef) unless defined $color;

  if (!ref($object) && $object eq 'graph')
    {
    # 'fill' => 'bgcolor';
    $name = 'bgcolor' if $name eq 'fill';
    }

  $name = $color_remap->{$name} || $name;

  $color = $self->_color_as_hex_or_hsv($object,$color);

  ($name, $color);
  }

sub _color_as_hex_or_hsv
  {
  # Given a color in hex, hsv, hsl or rgb, will return either a hex or hsv
  # color to preserve as much precision as possible:
  my ($graph, $self, $color) = @_;

  if ($color !~ /^#/)
    {
    # HSV colors with an alpha channel are not supported by graphviz, and
    # hence converted to RGB here:
    if ($color =~ /^hsv\(([0-9\.]+),([0-9\.]+),([0-9\.]+)\)/)
      {
      # hsv(1.0,1.0,1.0) => 1.0 1.0 1.0
      $color = "$1 $2 $3";
      }
    else
      {
      my $cs = ref($self) ? $self->attribute('colorscheme') :
			$graph->attribute($self,'colorscheme');
      # red => hex
      $color = $graph->color_as_hex($color, $cs);
      }
    }

  $color;
  }

sub _graphviz_remap_align
  {
  my ($self, $name, $style) = @_;

  my $s = lc(substr($style,0,1));		# 'l', 'r', or 'c'

  ('labeljust', $s);
  }

sub _graphviz_remap_edge_minlen
  {
  my ($self, $name, $len) = @_;

  $len = int(($len + 1) / 2);
  ($name, $len);
  }

sub _graphviz_remap_edge_color
  {
  my ($self, $name, $color, $object) = @_;

  my $style = ref($object) ? 
    $object->attribute('style') : 
    $self->attribute('edge','style');

  if (!defined $color)
    {
    $color = ref($object) ? 
      $object->attribute('color') : 
      $self->attribute('edge','color');
    }

  $color = '#000000' unless defined $color;
  $color = $self->_color_as_hex_or_hsv($object, $color);

  $color = $color . ':' . $color	# 'red:red'
    if $style =~ /^double/;

  ($name, $color);
  }

sub _graphviz_remap_edge_style
  {
  my ($self, $name, $style) = @_;

  # valid output styles are: solid dashed dotted bold invis

  $style = 'solid' unless defined $style;

  $style = 'dotted' if $style =~ /^dot-/;	# dot-dash, dot-dot-dash
  $style = 'dotted' if $style =~ /^wave/;	# wave

  # double lines will be handled in the color attribute as "color:color"
  $style = 'solid' if $style eq 'double';	# double
  $style = 'dashed' if $style =~ /^double-dash/;

  $style = 'invis' if $style eq 'invisible';	# invisible

  # XXX TODO: These should be (2, 0.5em, 1em) instead of 2,5,11
  $style = 'setlinewidth(2), dashed' if $style =~ /^bold-dash/;
  $style = 'setlinewidth(5)' if $style =~ /^broad/;
  $style = 'setlinewidth(11)' if $style =~ /^wide/;
  
  return (undef, undef) if $style eq 'solid';	# default style can be suppressed

  ($name, $style);
  }

sub _graphviz_remap_node_rotate
  {
  my ($graph, $name, $angle, $self) = @_;

  # do this only for objects, not classes 
  return (undef,undef) unless ref($self) && defined $angle;

  return (undef,undef) if $angle == 0;

  # despite what the manual says, dot rotates counter-clockwise, so fix that
  $angle = 360 - $angle;

  ('orientation', $angle);
  }

sub _graphviz_remap_port
  {
  my ($graph, $name, $side, $self) = @_;

  # do this only for objects, not classes 
  return (undef,undef) unless ref($self) && defined $side;

  # XXX TODO
  # remap relative ports (front etc) to "south" etc

  # has a specific port, aka shared a port with another edge
  return (undef, undef) if $side =~ /,/;

  $side = $graph->_flow_as_side($self->flow(),$side);

  $side = substr($side,0,1);	# "south" => "s"

  my $n = 'tailport'; $n = 'headport' if $name eq 'end';

  ($n, $side);
  }

sub _graphviz_remap_font
  {
  # Remap the font names
  my ($self, $name, $style) = @_;

  # XXX TODO: "times" => "Times.ttf" ?
  ('fontname', $style);
  }

sub _graphviz_remap_fontsize
  {
  # make sure the fontsize is in pixel or percent
  my ($self, $name, $style) = @_;

  # XXX TODO: This should be actually 1 em
  my $fs = '11';

  if ($style =~ /^([\d\.]+)em\z/)
    {
    $fs = $1 * 11;
    }
  elsif ($style =~ /^([\d\.]+)%\z/)
    {
    $fs = ($1 / 100) * 11;
    }
  # this is discouraged:
  elsif ($style =~ /^([\d\.]+)px\z/)
    {
    $fs = $1;
    }
  else
    {
    $self->_croak("Illegal font-size '$style'");
    }

  # font-size => fontsize
  ('fontsize', $fs);
  }

sub _graphviz_remap_border_style
  {
  my ($self, $name, $style, $node) = @_;

  my $shape = '';
  $shape = ($node->attribute('shape') || '') if ref($node);

  # some shapes don't need a border:
  return (undef,undef) if $shape =~ /^(none|invisible|img|point)\z/;

  $style = $node->attribute('borderstyle') unless defined $style;
 
  # valid styles are: solid dashed dotted bold invis

  $style = '' unless defined $style;

  $style = 'dotted' if $style =~ /^dot-/;	# dot-dash, dot-dot-dash
  $style = 'dashed' if $style =~ /^double-/;	# double-dash
  $style = 'dotted' if $style =~ /^wave/;	# wave

  # borderstyle double will be handled extra with peripheries=2 later
  $style = 'solid' if $style eq 'double';

  # XXX TODO: These should be (2, 0.5em, 1em) instead of 2,5,11
  $style = 'setlinewidth(2)' if $style =~ /^bold/;
  $style = 'setlinewidth(5)' if $style =~ /^broad/;
  $style = 'setlinewidth(11)' if $style =~ /^wide/;

  # "solid 0px" => "none"
  my $w = 0; $w = $node->attribute('borderwidth') if (ref($node) && $style ne 'none');
  $style = 'none' if $w == 0;

  my @rc;
  if ($style eq 'none')
    {
    my $fill = 'white'; $fill = $node->color_attribute('fill') if ref($node);
    $style = 'filled'; @rc = ('color', $fill);
    }
  
  # default style can be suppressed
  return (undef, undef) if $style =~ /^(|solid)\z/ && $shape ne 'rounded';

  # for graphviz v2.4 and up
  $style = 'filled' if $style eq 'solid';
  $style = 'filled,'.$style unless $style eq 'filled';
  $style = 'rounded,'.$style if $shape eq 'rounded' && $style ne 'none';

  $style =~ s/,\z//;		# "rounded," => "rounded"

  push @rc, 'style', $style;
  @rc;
  }

sub _graphviz_remap_link
  {
  my ($self, $name, $l, $object) = @_;

  # do this only for objects, not classes 
  return (undef,undef) unless ref($object);
  
  $l = $object->link() unless defined $l;

  ('URL', $l);
  }

sub _graphviz_remap_label_color
  {
  my ($graph, $name, $color, $self) = @_;

  # do this only for objects, not classes 
  return (undef,undef) unless ref($self);
  
  # no label => no color nec.
  return (undef, $color) if ($self->label()||'') eq '';

  $color = $self->raw_attribute('labelcolor') unless defined $color;

  # the label color falls back to the edge color
  $color = $self->attribute('color') unless defined $color;

  $color = $graph->_color_as_hex_or_hsv($self,$color);

  ('fontcolor', $color);
  }

sub _graphviz_remap_node_shape
  {
  my ($self, $name, $style, $object) = @_;

  # img needs no shape, and rounded is handled as style
  return (undef,undef) if $style =~ /^(img|rounded)\z/;

  # valid styles are: solid dashed dotted bold invis

  my $s = $style;
  $s = 'plaintext' if $style =~ /^(invisible|none|point)\z/;

  if (ref($object))
    {
    my $border = $object->attribute('borderstyle');
    $s = 'plaintext' if $border eq 'none';
    }

  ($name, $s);
  }

sub _graphviz_remap_arrow_style
  {
  my ($self, $name, $style) = @_;

  my $s = 'normal';
 
  $s = $style if $style =~ /^(none|open)\z/;
  $s = 'empty' if $style eq 'closed';

  my $n = 'arrowhead';
  $n = 'arrowtail' if $self->{_flip_edges};

  ($n, $s);
  }

sub _graphviz_remap_label
  {
  my ($self, $name, $label, $node) = @_;

  my $s = $label;

  # call label() to handle thinks like "autolabel: 15" properly
  $s = $node->label() if ref($node);

  if (ref($node))
    {
    # remap all "\n" and "\c" to either "\l" or "\r", depending on align
    my $align = $node->attribute('align');
    my $next_line = '\n';
    # the align of the line-ends counts for the line _before_ them, so
    # add one more to fix the last line
    $next_line = '\l', $s .= '\l' if $align eq 'left';
    $next_line = '\r', $s .= '\r' if $align eq 'right';

    $s =~ s/(^|[^\\])\\n/$1$next_line/g;	# \n => align
    }

  $s =~ s/(^|[^\\])\\c/$1\\n/g;			# \c => \n (for center)

  my $shape = 'rect';
  $shape = ($node->attribute('shape') || '') if ref($node);

  # only for nodes and when they have a "shape: img"
  if ($shape eq 'img')
    {
    my $s = '<<TABLE BORDER="0"><TR><TD><IMG SRC="##url##" /></TD></TR></TABLE>>';

    my $url = $node->label();
    $url =~ s/\s/\+/g;				# space
    $url =~ s/'/%27/g;				# replace quotation marks
    $s =~ s/##url##/$url/g;
    }

  ($name, $s);
  }

#############################################################################

sub _att_as_graphviz
  {
  # convert a hash with attribute => value mappings to a string
  my ($self, $out) = @_;

  my $att = '';
  for my $atr (keys %$out)
    {
    my $v = $out->{$atr};
    $v =~ s/\n/\\n/g;

    $v = '"' . $v . '"' if $v !~ /^[a-z0-9A-Z]+\z/;	# quote if nec.

    # convert "x-dot-foo" to "foo". Special case "K":
    my $name = $atr; $name =~ s/^x-dot-//; $name = 'K' if $name eq 'k';

    $att .= "  $name=$v,\n";
    }

  $att =~ s/,\n\z/ /;			# remove last ","
  if ($att ne '')
    {
    # the following makes short, single definitions to fit on one line
    if ($att !~ /\n.*\n/ && length($att) < 40)
      {
      $att =~ s/\n/ /; $att =~ s/( )+/ /g;
      }
    else
      {
      $att =~ s/\n/\n  /g;
      $att = "\n  $att";
      }
    }
  $att;
  }

sub _generate_group_edge
  {
  # Given an edge (from/to at least one group), generate the graphviz code
  my ($self, $e, $indent) = @_;

  my $edge_att = $e->attributes_as_graphviz();

  my $a = ''; my $b = '';
  my $from = $e->{from};
  my $to = $e->{to};

  ($from,$to) = ($to,$from) if $self->{_flip_edges};
  if ($from->isa('Graph::Easy::Group'))
    {
    # find an arbitray node inside the group
    my ($n, $v) = each %{$from->{nodes}};
    
    $a = 'ltail="cluster' . $from->{id}.'"';	# ltail=cluster0
    $from = $v;
    }

  # XXX TODO:
  # this fails for empty groups
  if ($to->isa('Graph::Easy::Group'))
    {
    # find an arbitray node inside the group
    my ($n, $v) = each %{$to->{nodes}};
    
    $b = 'lhead="cluster' . $to->{id}.'"';	# lhead=cluster0
    $to = $v;
    }

  my $other = $to->_graphviz_point();
  my $first = $from->_graphviz_point();

  $e->{_p} = undef;				# mark as processed

  my $att = $a; 
  $att .= ', ' . $b if $b ne ''; $att =~ s/^,//;
  if ($att ne '')
    {
    if ($edge_att eq '')
      {
      $edge_att = " [ $att ]";
      }
    else
      {
      $edge_att =~ s/ \]/, $att \]/;
      }
    }

  "$indent$first $self->{edge_type} $other$edge_att\n";		# return edge text
  }

sub _insert_edge_attribute
  {
  # insert an additional attribute into an edge attribute string
  my ($self, $att, $new_att) = @_;

  return '[ $new_att ]' if $att eq '';		# '' => '[ ]'

  # remove any potential old attribute with the same name
  my $att_name = $new_att; $att_name =~ s/=.*//;
  $att =~ s/$att_name=("[^"]+"|[^\s]+)//;
  
  # insert the new attribute at the end
  $att =~ s/\s?\]/,$new_att ]/;

  $att;
  }

sub _suppress_edge_attribute
  {
  # remove the named attribute from the edge attribute string
  my ($self, $att, $sup_att) = @_;

  $att =~ s/$sup_att=("(\\"|[^"])*"|[^\s\n,;]+)[,;]?//;
  $att;
  }

sub _generate_edge
  {
  # Given an edge, generate the graphviz code for it
  my ($self, $e, $indent) = @_;

  # skip links from/to groups, these will be done later
  return '' if 
    $e->{from}->isa('Graph::Easy::Group') ||
    $e->{to}->isa('Graph::Easy::Group');

  my $invis = $self->{_graphviz_invis};

  # attributes for invisible helper nodes (the color will be filled in from the edge color)
  my $inv       = ' [ label="",shape=none,style=filled,height=0,width=0,fillcolor="';

  my $other = $e->{to}->_graphviz_point();
  my $first = $e->{from}->_graphviz_point();

  my $edge_att = $e->attributes_as_graphviz();
  my $txt = '';

  my $modify_edge = 0;
  my $suppress_start = (!$self->{_flip_edges} ? 'arrowtail=none' : 'arrowhead=none');
  my $suppress_end   = ( $self->{_flip_edges} ? 'arrowtail=none' : 'arrowhead=none');
  my $suppress;

  # if the edge has a shared start/end port
  if ($e->has_ports())
    {
    my @edges = ();

    my ($side,@port) = $e->port('start');
    @edges = $e->{from}->edges_at_port('start',$side,@port) if defined $side && @port > 0;

    if (@edges > 1)					# has strict port
      {
      # access the invisible node
      my $sp = $e->port('start');
      my $key = "$e->{from}->{name},start,$sp";
      my $invis_id = $invis->{$key};
      $suppress = $suppress_start;
      if (!defined $invis_id)
	{
	# create the invisible helper node
	# find a name for it, carefully avoiding names of other nodes: 
	$self->{_graphviz_invis_id}++ while (defined $self->node($self->{_graphviz_invis_id}));
	$invis_id = $self->{_graphviz_invis_id}++;

	# output the helper node
	my $e_color = $e->color_attribute('color');
	$txt .= $indent . "$invis_id$inv$e_color\" ]\n";
	my $e_att = $self->_insert_edge_attribute($edge_att,$suppress_end);
	$e_att = $self->_suppress_edge_attribute($e_att,'label');
	my $before = ''; my $after = ''; my $i = $indent;
	if ($e->{group})
	  {
	  $before = $indent . 'subgraph "cluster' . $e->{group}->{id} . "\" {\n";
	  $after = $indent . "}\n";
	  $i = $indent . $indent;
	  }
	if ($self->{_flip_edges})
	  {
	  $txt .= $before . $i . "$invis_id $self->{_edge_type} $first$e_att\n" . $after;
	  }
	else
	  {
	  $txt .= $before . $i . "$first $self->{_edge_type} $invis_id$e_att\n" . $after;
	  }
	$invis->{$key} = $invis_id;		# mark as created
	}
      # "joint0" etc
      $first = $invis_id;
      $modify_edge++;
      }

    ($side,@port) = $e->port('end');
    @edges = ();
    @edges = $e->{to}->edges_at_port('end',$side,@port) if defined $side && @port > 0;
    if (@edges > 1)
      {
      my $ep = $e->port('end');
      my $key = "$e->{to}->{name},end,$ep";
      my $invis_id = $invis->{$key};
      $suppress = $suppress_end;

      if (!defined $invis_id)
	{
	# create the invisible helper node
	# find a name for it, carefully avoiding names of other nodes:
	$self->{_graphviz_invis_id}++ while (defined $self->node($self->{_graphviz_invis_id}));
	$invis_id = $self->{_graphviz_invis_id}++;

        my $e_att = $self->_insert_edge_attribute($edge_att,$suppress_start);
	# output the helper node
	my $e_color = $e->color_attribute('color');
	$txt .= $indent . "$invis_id$inv$e_color\" ]\n";
	my $before = ''; my $after = ''; my $i = $indent;
	if ($e->{group})
	  {
	  $before = $indent . 'subgraph "cluster' . $e->{group}->{id} . "\" {\n";
	  $after = $indent . "}\n";
	  $i = $indent . $indent;
	  }
	if ($self->{_flip_edges})
	  {
	  $txt .= $before . $i . "$other $self->{_edge_type} $invis_id$e_att\n" . $after;
	  }
	else
	  {
	  $txt .= $before . $i . "$invis_id $self->{_edge_type} $other$e_att\n" . $after;
	  }
	$invis->{$key} = $invis_id;			# mark as output
	}
      # "joint1" etc
      $other = $invis_id;
      $modify_edge++;
      }
    }

  ($other,$first) = ($first,$other) if $self->{_flip_edges};

  $e->{_p} = undef;				# mark as processed

  $edge_att = $self->_insert_edge_attribute($edge_att,$suppress)
    if $modify_edge;

  $txt . "$indent$first $self->{_edge_type} $other$edge_att\n";		# return edge text
  }

sub _order_group 
  {
  my ($self,$group) = @_;
  $group->{_order}++;
  for my $sg (values %{$group->{groups}})
	{
		$self->_order_group($sg);
	}
  }


sub _as_graphviz_group 
  {
  my ($self,$group) = @_;

  my $txt = '';
    # quote special chars in group name
    my $name = $group->{name}; $name =~ s/([\[\]\(\)\{\}\#"])/\\$1/g;

   return if $group->{_p};
    # output group attributes first
    my $indent = '  ' x ($group->{_order});
    $txt .= $indent."subgraph \"cluster$group->{id}\" {\n${indent}label=\"$name\";\n";

	for my $sg (values %{$group->{groups}})
	{
		#print '--'.$sg->{name}."\n";
		$txt .= $self->_as_graphviz_group($sg,$indent);
		$sg->{_p} = 1;
	}
    # Make a copy of the attributes, including our class attributes:
    my $copy = {};
    my $attribs = $group->get_attributes();

    for my $a (keys %$attribs)
      {
      $copy->{$a} = $attribs->{$a};
      }
    # set some defaults
    $copy->{'borderstyle'} = 'solid' unless defined $copy->{'borderstyle'};

    my $out = $self->_remap_attributes( $group->class(), $copy, $remap, 'noquote');

    # Set some defaults:
    $out->{fillcolor} = '#a0d0ff' unless defined $out->{fillcolor};
    $out->{labeljust} = 'l' unless defined $out->{labeljust};

    my $att = '';
    # we need to output style first ("filled" and "color" need come later)
    for my $atr (reverse sort keys %$out)
      {
      my $v = $out->{$atr};
      $v = '"' . $v . '"' if $v !~ /^[a-z0-9A-Z]+\z/;	# quote if nec.

      # convert "x-dot-foo" to "foo". Special case "K":
      my $name = $atr; $name =~ s/^x-dot-//; $name = 'K' if $name eq 'k';

      $att .= $indent."$name=$v;\n";
      }
    $txt .= $att . "\n" if $att ne '';
 
    # output nodes (w/ or w/o attributes) in that group
    for my $n ($group->sorted_nodes())
      {
      # skip nodes that are relativ to others (these are done as part
      # of the HTML-like label of their parent)
      next if $n->{origin};

      my $att = $n->attributes_as_graphviz();
      $n->{_p} = undef;			# mark as processed
      $txt .= $indent . $n->as_graphviz_txt() . $att . "\n";
      }

    # output node connections in this group
    for my $e (values %{$group->{edges}})
      {
      next if exists $e->{_p};
      $txt .= $self->_generate_edge($e, $indent);
      }

    $txt .= $indent."}\n";
   
   return $txt;
  }

sub _as_graphviz
  {
  my ($self) = @_;

  # convert the graph to a textual representation
  # does not need a layout() beforehand!

  my $name = "GRAPH_" . ($self->{gid} || '0');

  my $type = $self->attribute('type');
  $type = $type eq 'directed' ? 'digraph' : 'graph';	# directed or undirected?

  $self->{_edge_type} = $type eq 'digraph' ? '->' : '--';	# "a -- b" vs "a -> b"

  my $txt = "$type $name {\n\n" .
            "  // Generated by Graph::Easy $Graph::Easy::VERSION" .
	    " at " . scalar localtime() . "\n\n";


  my $flow = $self->attribute('graph','flow');
  $flow = 'east' unless defined $flow;

  $flow = Graph::Easy->_direction_as_number($flow);

  # for LR, BT layouts
  $self->{_flip_edges} = 0;
  $self->{_flip_edges} = 1 if $flow == 270 || $flow == 0;
  
  my $groups = $self->groups();

  # to keep track of invisible helper nodes
  $self->{_graphviz_invis} = {};
  # name for invisible helper nodes
  $self->{_graphviz_invis_id} = 'joint0';

  # generate the class attributes first
  my $atts =  $self->{att};
  # It is not possible to set attributes for groups in the DOT language that way
  for my $class (qw/edge graph node/)
    {
    next if $class =~ /\./;		# skip subclasses

    my $out = $self->_remap_attributes( $class, $atts->{$class}, $remap, 'noquote');

    # per default, our nodes are rectangular, white, filled boxes
    if ($class eq 'node')
      {
      $out->{shape} = 'box' unless $out->{shape}; 
      $out->{style} = 'filled' unless $out->{style};
      $out->{fontsize} = '11' unless $out->{fontsize};
      $out->{fillcolor} = 'white' unless $out->{fillcolor};
      }
    elsif ($class eq 'graph')
      {
      $out->{rankdir} = 'LR' if $flow == 90 || $flow == 270;
      $out->{labelloc} = 'top' if defined $out->{label} && !defined $out->{labelloc};
      $out->{style} = 'filled' if $groups > 0;
      }
    elsif ($class eq 'edge')
      {
      $out->{dir} = 'back' if $flow == 270 || $flow == 0;
      my ($name,$style) = $self->_graphviz_remap_arrow_style('',
        $self->attribute('edge','arrowstyle') );
      $out->{$name} = $style;
      }

    my $att = $self->_att_as_graphviz($out);

    $txt .= "  $class [$att];\n" if $att ne '';
    }

  $txt .= "\n" if $txt ne '';		# insert newline

  ###########################################################################
  # output groups as subgraphs

  # insert the edges into the proper group
  $self->_edges_into_groups() if $groups > 0;

  # output the groups (aka subclusters)
  for my $group (values %{$self->{groups}})
  {
   $self->_order_group($group);
  }
  for my $group (sort { $a->{_order} cmp $b->{_order} } values %{$self->{groups}})
  {
    $txt .= $self->_as_graphviz_group($group) || '';
  }

  my $root = $self->attribute('root');
  $root = '' unless defined $root;

  my $count = 0;
  # output nodes with attributes first, sorted by their name
  for my $n (sort { $a->{name} cmp $b->{name} } values %{$self->{nodes}})
    {
    next if exists $n->{_p};
    # skip nodes that are relativ to others (these are done as part
    # of the HTML-like label of their parent)
    next if $n->{origin};
    my $att = $n->attributes_as_graphviz($root);
    if ($att ne '')
      {
      $n->{_p} = undef;			# mark as processed
      $count++;
      $txt .= "  " . $n->as_graphviz_txt() . $att . "\n"; 
      }
    }
 
  $txt .= "\n" if $count > 0;		# insert a newline

  my @nodes = $self->sorted_nodes();

  # output the edges
  foreach my $n (@nodes)
    {
    my @out = $n->successors();
    my $first = $n->as_graphviz_txt();
    if ((@out == 0) && ( (scalar $n->predecessors() || 0) == 0))
      {
      # single node without any connections (unless already output)
      $txt .= "  " . $first . "\n" unless exists $n->{_p} || $n->{origin};
      }
    # for all outgoing connections
    foreach my $other (reverse @out)
      {
      # in case there is more than one edge going from N to O
      my @edges = $n->edges_to($other);
      foreach my $e (@edges)
        {
        next if exists $e->{_p};
        $txt .= $self->_generate_edge($e, '  ');
        }
      }
    }

  # insert now edges between groups (clusters/subgraphs)

  foreach my $e (values %{$self->{edges}})
    {
    $txt .= $self->_generate_group_edge($e, '  ') 
     if $e->{from}->isa('Graph::Easy::Group') ||
        $e->{to}->isa('Graph::Easy::Group');
    }

  # clean up
  for my $n ( values %{$self->{nodes}}, values %{$self->{edges}})
    {
    delete $n->{_p};
    }
  delete $self->{_graphviz_invis};		# invisible helper nodes for joints
  delete $self->{_flip_edges};
  delete $self->{_edge_type};

  $txt .  "\n}\n";				# close the graph
  }

package Graph::Easy::Node;

sub attributes_as_graphviz
  {
  # return the attributes of this node as text description
  my ($self, $root) = @_;
  $root = '' unless defined $root;

  my $att = '';
  my $class = $self->class();

  return '' unless ref $self->{graph};

  my $g = $self->{graph};

  # get all attributes, excluding the class attributes
  my $a = $self->raw_attributes();

  # add the attributes that are listed under "always":
  my $attr = $self->{att};
  my $base_class = $class; $base_class =~ s/\..*//;
  my $list = $remap->{always}->{$class} || $remap->{always}->{$base_class};
  for my $name (@$list)
    {
    # for speed, try to look it up directly

    # look if we have a code ref:
    if ( ref($remap->{$base_class}->{$name}) ||
         ref($remap->{all}->{$name}) )
      {
      $a->{$name} = $self->raw_attribute($name);
      if (!defined $a->{$name})
        {
        my $b_attr = $g->get_attribute($base_class,$name);
        my $c_attr = $g->get_attribute($class,$name);
        if (defined $b_attr && defined $c_attr && $b_attr ne $c_attr)
          {
          $a->{$name} = $c_attr;
          $a->{$name} = $b_attr unless defined $a->{$name};
          }
        }
      }
    else
      {
      $a->{$name} = $attr->{$name};
      $a->{$name} = $self->attribute($name) unless defined $a->{$name} && $a->{$name} ne 'inherit';
      }
    }

  $a = $g->_remap_attributes( $self, $a, $remap, 'noquote');

  # do not needlessly output labels:
  delete $a->{label} if !$self->isa('Graph::Easy::Edge') &&		# not an edge
	exists $a->{label} && $a->{label} eq $self->{name};

  # generate HTML-like labels for nodes with children, but do so only
  # for the node which is not itself a child
  if (!$self->{origin} && $self->{children} && keys %{$self->{children}} > 0)
    {
    #print "Generating HTML-like label for $self->{name}\n";
    $a->{label} = $self->_html_like_label();
    # make Graphviz avoid the outer border
    $a->{shape} = 'none';
    }

  # bidirectional and undirected edges
  if ($self->{bidirectional})
    {
    delete $a->{dir};
    my ($n,$s) = Graph::Easy::_graphviz_remap_arrow_style(
	$self,'', $self->attribute('arrowstyle'));
    $a->{arrowhead} = $s; 
    $a->{arrowtail} = $s; 
    }
  if ($self->{undirected})
    {
    delete $a->{dir};
    $a->{arrowhead} = 'none'; 
    $a->{arrowtail} = 'none'; 
    }

  if (!$self->isa_cell())
    {
    # borderstyle: double:
    my $style = $self->attribute('borderstyle');
    my $w = $self->attribute('borderwidth');
    $a->{peripheries} = 2 if $style =~ /^double/ && $w > 0;
    }

  # For nodes with shape plaintext, set the fillcolor to the background of
  # the graph/group
  my $shape = $a->{shape} || 'rect';
  if ($class =~ /node/ && $shape eq 'plaintext')
    {
    my $p = $self->parent();
    $a->{fillcolor} = $p->attribute('fill');
    $a->{fillcolor} = 'white' if $a->{fillcolor} eq 'inherit';
    }

  $shape = $self->attribute('shape') unless $self->isa_cell();

  # for point-shaped nodes, include the point as label and set width/height
  if ($shape eq 'point')
    {
    require Graph::Easy::As_ascii;		# for _u8 and point-style

    my $style = $self->_point_style( 
	$self->attribute('pointshape'), 
	$self->attribute('pointstyle') );

    $a->{label} = $style;
    # for point-shaped invisible nodes, set height/width = 0
    $a->{width} = 0, $a->{height} = 0 if $style eq '';  
    }
  if ($shape eq 'invisible')
    {
    $a->{label} = ' ';
    }

  $a->{rank} = '0' if $root ne '' && $root eq $self->{name};

  # create the attributes as text:
  for my $atr (sort keys %$a)
    {
    my $v = $a->{$atr};
    $v =~ s/"/\\"/g;		# '2"' => '2\"'

    # don't quote labels like "<<TABLE.."
    if ($atr eq 'label' && $v =~ /^<<TABLE/)
      {
      my $va = $v; $va =~ s/\\"/"/g;		# unescape \"
      $att .= "$atr=$va, ";
      next;
      }

    $v = '"' . $v . '"' if $v !~ /^[a-z0-9A-Z]+\z/
	  || $atr eq 'URL';	# quote if nec.

    # convert "x-dot-foo" to "foo". Special case "K":
    my $name = $atr; $name =~ s/^x-dot-//; $name = 'K' if $name eq 'k';

    $att .= "$name=$v, ";
    }
  $att =~ s/,\s$//;             # remove last ","

  # generate attribute text if nec.
  $att = ' [ ' . $att . ' ]' if $att ne '';

  $att;
  }

sub _html_like_label
  {
  # Generate a HTML-like label from one node with its relative children
  my ($self) = @_;

  my $cells = {};
  my $rc = $self->_do_place(0,0, { cells => $cells, cache => {} } );

  # <TABLE BORDER="0" CELLPADDING="0" CELLSPACING="0"><TR><TD>Name2</TD></TR><TR><TD
  # ALIGN ="LEFT" BALIGN="LEFT" PORT="E4">Somewhere<BR/>test1<BR>test</TD></TR></TABLE>

  my $label = '<<TABLE BORDER="0"><TR>';

  my $old_y = 0; my $old_x = 0;
  # go through all children, and sort them by Y then X coordinate
  my @cells = ();
  for my $cell (sort {
	my ($ax,$ay) = split /,/,$a;
	my ($bx,$by) = split /,/,$b;
	$ay <=> $by or $ax <=> $bx; } keys %$cells )
    {
    #print "cell $cell\n";
    my ($x,$y) = split /,/, $cell;
    if ($y > $old_y)
      {
      $label .= '</TR><TR>'; $old_x = 0;
      }
    my $n = $cells->{$cell};
    my $l = $n->label();
    $l =~ s/\\n/<BR\/>/g;
    my $portname = $n->{autosplit_portname};
    $portname = $n->label() unless defined $portname;
    my $name = $self->{name};
    $portname =~ s/\"/\\"/g;			# quote "
    $name =~ s/\"/\\"/g;			# quote "
    # store the "nodename:portname" combination for potential edges
    $n->{_graphviz_portname} = '"' . $name . '":"' . $portname . '"';
    if (($x - $old_x) > 0)
      {
      # need some spacers
      $label .= '<TD BORDER="0" COLSPAN="' . ($x - $old_x) . '"></TD>';
      } 
    $label .= '<TD BORDER="1" PORT="' . $portname . '">' . $l . '</TD>';
    $old_y = $y + $n->{cy}; $old_x = $x + $n->{cx};
    }

  # return "<<TABLE.... /TABLE>>"
  $label . '</TR></TABLE>>';
  }

sub _graphviz_point
  {
  # return the node as the target/source of an edge
  # either "name", or "name:port"
  my ($n) = @_;

  return $n->{_graphviz_portname} if exists $n->{_graphviz_portname};

  $n->as_graphviz_txt();
  }

sub as_graphviz_txt
  {
  # return the node itself (w/o attributes) as graphviz representation
  my $self = shift;

  my $name = $self->{name};

  # escape special chars in name (including doublequote!)
  $name =~ s/([\[\]\(\)\{\}"])/\\$1/g;

  # quote if necessary:
  # 2, A, A2, "2A", "2 A" etc
  $name = '"' . $name . '"' if $name !~ /^([a-zA-Z_]+|\d+)\z/ ||
 	$name =~ /^(subgraph|graph|node|edge|strict)\z/i;	# reserved keyword

  $name;
  }
 
1;
__END__

=head1 NAME

Graph::Easy::As_graphviz - Generate graphviz description from graph object

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

	print $graph->as_graphviz();

	# prints something like:

	# digraph NAME { Bonn -> Berlin }

=head1 DESCRIPTION

C<Graph::Easy::As_graphviz> contains just the code for converting a
L<Graph::Easy|Graph::Easy> object to a textual description suitable for
feeding it to Graphviz programs like C<dot>.

=head1 EXPORT

Exports nothing.

=head1 SEE ALSO

L<Graph::Easy>, L<Graph::Easy::Parser::Graphviz>.

=head1 AUTHOR

Copyright (C) 2004 - 2008 by Tels L<http://bloodgate.com>

See the LICENSE file for information.

=cut
