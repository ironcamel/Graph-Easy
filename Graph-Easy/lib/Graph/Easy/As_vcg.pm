#############################################################################
# Output the graph as VCG or GDL text.
#
#############################################################################

package Graph::Easy::As_vcg;

$VERSION = '0.05';

#############################################################################
#############################################################################

package Graph::Easy;

use strict;

my $vcg_remap = {
  node => {
    align => \&_vcg_remap_align,
    autolabel => undef,
    autolink => undef,
    autotitle => undef,
    background => undef, 
    basename => undef,
    class => undef,
    colorscheme => undef,
    columns => undef,
    flow => undef,
    fontsize => undef,
    format => undef,
    group => undef,
    id => undef,
    link => undef,
    linkbase => undef,
    offset => undef,
    origin => undef,
    pointstyle => undef,
    rank => 'level',
    rotate => undef,
    rows => undef,
    shape => \&_vcg_remap_shape,
    size => undef,
    textstyle => undef,
    textwrap => undef,
    title => undef,
    },
  edge => {
    color => 'color',			# this entry overrides 'all'!
    align => undef,
    arrowshape => undef,
    arrowstyle => undef,
    autojoin => undef,
    autolabel => undef,
    autolink => undef,
    autosplit => undef,
    autotitle => undef,
    border => undef,
    bordercolor => undef,
    borderstyle => undef,
    borderwidth => undef,
    colorscheme => undef,
    end => undef,
    fontsize => undef,
    format => undef,
    id => undef,
    labelcolor => 'textcolor',
    link => undef,
    linkbase => undef,
    minlen => undef,
    start => undef,
    # XXX TODO: remap unknown styles
    style => 'linestyle',
    textstyle => undef,
    textwrap => undef,
    title => undef, 
    },
  graph => {
    align => \&_vcg_remap_align,
    flow => \&_vcg_remap_flow,
    label => 'title',
    type => undef,
    },
  group => {
    },
  all => {
    background => undef,
    color => 'textcolor',
    comment => undef,
    fill => 'color',
    font => 'fontname',
    },
  always => {
    },
  # this routine will handle all custom "x-dot-..." attributes
  x => \&_remap_custom_vcg_attributes,
  };

sub _remap_custom_vcg_attributes
  {
  my ($self, $name, $value) = @_;

  # drop anything that is not starting with "x-vcg-..."
  return (undef,undef) unless $name =~ /^x-vcg-/;

  $name =~ s/^x-vcg-//;			# "x-vcg-foo" => "foo"
  ($name,$value);
  }

my $vcg_shapes = {
  rect => 'box',
  diamond => 'rhomb',
  triangle => 'triangle',
  invtriangle => 'triangle',
  ellipse => 'ellipse',
  circle => 'circle',
  hexagon => 'hexagon',
  trapezium => 'trapeze',
  invtrapezium => 'uptrapeze',
  invparallelogram => 'lparallelogram',
  parallelogram => 'rparallelogram',
  };

sub _vcg_remap_shape
  {
  my ($self, $name, $shape) = @_;

  return ('invisible','yes') if $shape eq 'invisible';

  ('shape', $vcg_shapes->{$shape} || 'box');
  }

sub _vcg_remap_align
  {
  my ($self, $name, $style) = @_;

  # center => center, left => left_justify, right => right_justify
  $style .= '_justify' unless $style eq 'center';

  ('textmode', $style);
  }

my $vcg_flow = {
  'south' => 'top_to_bottom',
  'north' => 'bottom_to_top',
  'down' => 'top_to_bottom',
  'up' => 'bottom_to_top',
  'east' => 'left_to_right',
  'west' => 'right_to_left',
  'right' => 'left_to_right',
  'left' => 'right_to_left',
  };

sub _vcg_remap_flow
  {
  my ($self, $name, $style) = @_;

  ('orientation', $vcg_flow->{$style} || 'top_to_bottom');
  }

sub _class_attributes_as_vcg
  {
  # convert a hash with attribute => value mappings to a string
  my ($self, $a, $class) = @_;


  my $att = '';
  $class = '' if $class eq 'graph';
  $class .= '.' if $class ne '';
  
  # create the attributes as text:
  for my $atr (sort keys %$a)
    {
    my $v = $a->{$atr};
    $v =~ s/"/\\"/g;            # '2"' => '2\"'
    $v = '"' . $v . '"' unless $v =~ /^[0-9]+\z/;       # 1, "1a"
    $att .= "  $class$atr: $v\n";
    }
  $att =~ s/,\s$//;             # remove last ","

  $att = "\n$att" unless $att eq '';
  $att;
  }

#############################################################################

sub _generate_vcg_edge
  {
  # Given an edge, generate the VCG code for it
  my ($self, $e, $indent) = @_;

  # skip links from/to groups, these will be done later
  return '' if 
    $e->{from}->isa('Graph::Easy::Group') ||
    $e->{to}->isa('Graph::Easy::Group');

  my $edge_att = $e->attributes_as_vcg();

  $e->{_p} = undef;				# mark as processed
  "  edge:$edge_att\n";				# return edge text
  }

sub _as_vcg
  {
  my ($self) = @_;

  # convert the graph to a textual representation
  # does not need a layout() beforehand!

  # gather all edge classes to build the classname attribute from them:
  $self->{_vcg_edge_classes} = {};
  for my $e (values %{$self->{edges}})
    {
    my $class = $e->sub_class();
    $self->{_vcg_edge_classes}->{$class} = undef if defined $class && $class ne '';
    }
  # sort gathered class names and map them to integers
  my $class_names = '';
  if (keys %{$self->{_vcg_edge_classes}} > 0)
    {
    my $i = 1;
    $class_names = "\n";
    for my $ec (sort keys %{$self->{_vcg_edge_classes}})
      {
      $self->{_vcg_edge_classes}->{$ec} = $i;	# remember mapping
      $class_names .= "  classname $i: \"$ec\"\n";
      $i++;
      }
    }

  # generate the class attributes first
  my $label = $self->label();
  my $t = ''; $t = "\n  title: \"$label\"" if $label ne '';

  my $txt = "graph: {$t\n\n" .
            "  // Generated by Graph::Easy $Graph::Easy::VERSION" .
	    " at " . scalar localtime() . "\n" .
	    $class_names;

  my $groups = $self->groups();

  # to keep track of invisible helper nodes
  $self->{_vcg_invis} = {};
  # name for invisible helper nodes
  $self->{_vcg_invis_id} = 'joint0';

  my $atts = $self->{att};
  # insert the class attributes
  for my $class (qw/edge graph node/)
    {
    next if $class =~ /\./;		# skip subclasses

    my $out = $self->_remap_attributes( $class, $atts->{$class}, $vcg_remap, 'noquote');
    $txt .= $self->_class_attributes_as_vcg($out, $class);
    }

  $txt .= "\n" if $txt ne '';		# insert newline

  ###########################################################################
  # output groups as subgraphs

  # insert the edges into the proper group
  $self->_edges_into_groups() if $groups > 0;

  # output the groups (aka subclusters)
  my $indent = '    ';
  for my $group (sort { $a->{name} cmp $b->{name} } values %{$self->{groups}})
    {
    # quote special chars in group name
    my $name = $group->{name}; $name =~ s/([\[\]\(\)\{\}\#"])/\\$1/g;

#    # output group attributes first
#    $txt .= "  subgraph \"cluster$group->{id}\" {\n${indent}label=\"$name\";\n";
   
    # Make a copy of the attributes, including our class attributes:
    my $copy = {};
    my $attribs = $group->get_attributes();

    for my $a (keys %$attribs)
      {
      $copy->{$a} = $attribs->{$a};
      }
#    # set some defaults
#    $copy->{'borderstyle'} = 'solid' unless defined $copy->{'borderstyle'};

    my $out = {};
#    my $out = $self->_remap_attributes( $group->class(), $copy, $vcg_remap, 'noquote');

    # Set some defaults:
    $out->{fillcolor} = '#a0d0ff' unless defined $out->{fillcolor};
#    $out->{labeljust} = 'l' unless defined $out->{labeljust};

    my $att = '';
    # we need to output style first ("filled" and "color" need come later)
    for my $atr (reverse sort keys %$out)
      {
      my $v = $out->{$atr};
      $v = '"' . $v . '"';
      $att .= "    $atr: $v\n";
      }
    $txt .= $att . "\n" if $att ne '';
 
#    # output nodes (w/ or w/o attributes) in that group
#    for my $n ($group->sorted_nodes())
#      {
#      my $att = $n->attributes_as_vcg();
#      $n->{_p} = undef;			# mark as processed
#      $txt .= $indent . $n->as_graphviz_txt() . $att . "\n";
#      }

#    # output node connections in this group
#    for my $e (values %{$group->{edges}})
#      {
#      next if exists $e->{_p};
#      $txt .= $self->_generate_edge($e, $indent);
#      }

    $txt .= "  }\n";
    }

  my $root = $self->attribute('root');
  $root = '' unless defined $root;

  my $count = 0;
  # output nodes with attributes first, sorted by their name
  for my $n (sort { $a->{name} cmp $b->{name} } values %{$self->{nodes}})
    {
    next if exists $n->{_p};
    my $att = $n->attributes_as_vcg($root);
    if ($att ne '')
      {
      $n->{_p} = undef;			# mark as processed
      $count++;
      $txt .= "  node:" . $att . "\n"; 
      }
    }
 
  $txt .= "\n" if $count > 0;		# insert a newline

  my @nodes = $self->sorted_nodes();

  foreach my $n (@nodes)
    {
    my @out = $n->successors();
    my $first = $n->as_vcg_txt();
    if ((@out == 0) && ( (scalar $n->predecessors() || 0) == 0))
      {
      # single node without any connections (unless already output)
      $txt .= "  node: { title: " . $first . " }\n" unless exists $n->{_p};
      }
    # for all outgoing connections
    foreach my $other (reverse @out)
      {
      # in case there is more than one edge going from N to O
      my @edges = $n->edges_to($other);
      foreach my $e (@edges)
        {
        next if exists $e->{_p};
        $txt .= $self->_generate_vcg_edge($e, '  ');
        }
      }
    }

  # insert now edges between groups (clusters/subgraphs)

#  foreach my $e (values %{$self->{edges}})
#    {
#    $txt .= $self->_generate_group_edge($e, '  ') 
#     if $e->{from}->isa('Graph::Easy::Group') ||
#        $e->{to}->isa('Graph::Easy::Group');
#    }

  # clean up
  for my $n ( values %{$self->{nodes}}, values %{$self->{edges}})
    {
    delete $n->{_p};
    }
  delete $self->{_vcg_invis};		# invisible helper nodes for joints
  delete $self->{_vcg_invis_id};	# invisible helper node name
  delete $self->{_vcg_edge_classes};

  $txt .  "\n}\n";			# close the graph
  }

package Graph::Easy::Node;

sub attributes_as_vcg
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
  my $list = $vcg_remap->{always}->{$class} || $vcg_remap->{always}->{$base_class};

  for my $name (@$list)
    {
    # for speed, try to look it up directly

    # look if we have a code ref, if yes, simple set the value to undef
    # and let the coderef handle it later:
    if ( ref($vcg_remap->{$base_class}->{$name}) ||
         ref($vcg_remap->{all}->{$name}) )
      {
      $a->{$name} = $attr->{$name};
      }
    else
      {
      $a->{$name} = $attr->{$name};
      $a->{$name} = $self->attribute($name) unless defined $a->{$name} && $a->{$name} ne 'inherit';
      }
    }

  $a = $g->_remap_attributes( $self, $a, $vcg_remap, 'noquote');

  if ($self->isa('Graph::Easy::Edge'))
    {
    $a->{sourcename} = $self->{from}->{name};
    $a->{targetname} = $self->{to}->{name};
    my $class = $self->sub_class();
    $a->{class} = $self->{graph}->{_vcg_edge_classes}->{ $class } if defined $class && $class ne '';
    }
  else
    {
    # title: "Bonn"
    $a->{title} = $self->{name};
    }

  # do not needlessly output labels:
  delete $a->{label} if !$self->isa('Graph::Easy::Edge') &&		# not an edge
	exists $a->{label} && $a->{label} eq $self->{name};

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

  # borderstyle: double:
  if (!$self->isa('Graph::Easy::Edge'))
    {
    my $style = $self->attribute('borderstyle');
    $a->{peripheries} = 2 if $style =~ /^double/;
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

    my $style = $self->_point_style( $self->attribute('pointstyle') );

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
    $v = '"' . $v . '"' unless $v =~ /^[0-9]+\z/;	# 1, "1a"
    $att .= "$atr: $v ";
    }
  $att =~ s/,\s$//;             # remove last ","

  # generate attribute text if nec.
  $att = ' { ' . $att . '}' if $att ne '';

  $att;
  }

sub as_vcg_txt
  {
  # return the node itself (w/o attributes) as VCG representation
  my $self = shift;

  my $name = $self->{name};

  # escape special chars in name (including doublequote!)
  $name =~ s/([\[\]\(\)\{\}"])/\\$1/g;

  # quote:
  '"' . $name . '"';
  }
 
1;
__END__

=head1 NAME

Graph::Easy::As_vcg - Generate VCG/GDL text from Graph::Easy object

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

	print $graph->as_vcg();


This prints something like this:

	graph: {
		node: { title: "Bonn" }
		node: { title: "Berlin" }
		edge: { sourcename: "Bonn" targetname: "Berlin" }
	}

=head1 DESCRIPTION

C<Graph::Easy::As_vcg> contains just the code for converting a
L<Graph::Easy|Graph::Easy> object to either a VCG 
or GDL textual description.

Note that the generated format is compatible to C<GDL> aka I<Graph
Description Language>.

=head1 EXPORT

Exports nothing.

=head1 SEE ALSO

L<Graph::Easy>, L<http://rw4.cs.uni-sb.de/~sander/html/gsvcg1.html>.

=head1 AUTHOR

Copyright (C) 2004-2008 by Tels L<http://bloodgate.com>

See the LICENSE file for information.

=cut
