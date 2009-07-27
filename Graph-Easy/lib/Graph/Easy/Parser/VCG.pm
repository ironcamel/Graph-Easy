#############################################################################
# Parse VCG text into a Graph::Easy object
#
#############################################################################

package Graph::Easy::Parser::VCG;

$VERSION = '0.06';
use Graph::Easy::Parser::Graphviz;
@ISA = qw/Graph::Easy::Parser::Graphviz/;

use strict;
use utf8;
use constant NO_MULTIPLES => 1;
use Encode qw/decode/;

sub _init
  {
  my $self = shift;

  $self->SUPER::_init(@_);
  $self->{attr_sep} = '=';

  $self;
  }

my $vcg_color_by_name = {};

my $vcg_colors = [
  white 	=> 'white',
  blue  	=> 'blue',	
  red 		=> 'red',
  green		=> 'green',
  yellow	=> 'yellow',
  magenta	=> 'magenta',
  cyan		=> 'cyan',
  darkgrey	=> 'rgb(85,85,85)',
  darkblue	=> 'rgb(0,0,128)',
  darkred	=> 'rgb(128,0,0)',
  darkgreen	=> 'rgb(0,128,0)',
  darkyellow	=> 'rgb(128,128,0)',
  darkmagenta	=> 'rgb(128,0,128)',
  darkcyan	=> 'rgb(0,128,128)',
  gold		=> 'rgb(255,215,0)',
  lightgrey	=> 'rgb(170,170,170)',
  lightblue	=> 'rgb(128,128,255)',
  lightred 	=> 'rgb(255,128,128)',
  lightgreen    => 'rgb(128,255,128)',
  lightyellow   => 'rgb(255,255,128)',
  lightmagenta  => 'rgb(255,128,255)',
  lightcyan 	=> 'rgb(128,255,255)',
  lilac 	=> 'rgb(238,130,238)',
  turquoise 	=> 'rgb(64,224,208)',
  aquamarine 	=> 'rgb(127,255,212)',
  khaki 	=> 'rgb(240,230,140)',
  purple 	=> 'rgb(160,32,240)',
  yellowgreen 	=> 'rgb(154,205,50)',
  pink		=> 'rgb(255,192,203)',
  orange 	=> 'rgb(255,165,0)',
  orchid	=> 'rgb(218,112,214)',
  black 	=> 'black',
  ];

  {
  for (my $i = 0; $i < @$vcg_colors; $i+=2)
    {
    $vcg_color_by_name->{$vcg_colors->[$i]} = $vcg_colors->[$i+1];
    }
  }

sub reset
  {
  my $self = shift;

  Graph::Easy::Parser::reset($self, @_);

  my $g = $self->{_graph};
  $self->{scope_stack} = [];

  $g->{_vcg_color_map} = [];
  for (my $i = 0; $i < @$vcg_colors; $i+=2)
    {
    # set the first 32 colors as the default
    push @{$g->{_vcg_color_map}}, $vcg_colors->[$i+1];
    }

  $g->{_vcg_class_names} = {};

  # allow some temp. values during parsing
  $g->_allow_special_attributes(
    {
    edge => {
      source => [ "", undef, '', '', undef, ],
      target => [ "", undef, '', '', undef, ],
    },
    } );

  $g->{_warn_on_unknown_attributes} = 1;

  # a hack to support multiline labels
  $self->{_in_vcg_multi_line_label} = 0;

  # set some default attributes on the graph object, because GDL has
  # some different defaults as Graph::Easy
  $g->set_attribute('flow', 'south');
  $g->set_attribute('edge', 'arrow-style', 'filled');
  $g->set_attribute('node', 'align', 'left');

  $self;
  }

sub _vcg_color_map_entry
  {
  my ($self, $index, $color) = @_;

  $color =~ /([0-9]+)\s+([0-9]+)\s+([0-9]+)/;
  $self->{_graph}->{_vcg_color_map}->[$index] = "rgb($1,$2,$3)";
  }

sub _unquote
  {
  my ($self, $name) = @_;

  $name = '' unless defined $name;

  # "foo bar" => foo bar
  # we need to use "[ ]" here, because "\s" also matches 0x0c, and
  # these color codes need to be kept intact:
  $name =~ s/^"[ ]*//; 		# remove left-over quotes
  $name =~ s/[ ]*"\z//; 

  # unquote special chars
  $name =~ s/\\([\[\(\{\}\]\)#"])/$1/g;

  $name;
  }

#############################################################################

sub _match_commented_line
  {
  # matches only empty lines
  qr/^\s*\z/;
  }

sub _match_multi_line_comment
  {
  # match a multi line comment

  # /* * comment * */
  qr#^\s*/\*.*?\*/\s*#;
  }

sub _match_optional_multi_line_comment
  {
  # match a multi line comment

  # "/* * comment * */" or /* a */ /* b */ or ""
  qr#(?:(?:\s*/\*.*?\*/\s*)*|\s+)#;
  }

sub _match_classname
  {
  # Return a regexp that matches something like classname 1: "foo"
  my $self = shift;

  qr/^\s*classname\s([0-9]+)\s*:\s*"((\\"|[^"])*)"/;
  }

sub _match_node
  {
  # Return a regexp that matches a node at the start of the buffer
  my $self = shift;

  my $attr = $self->_match_attributes();

  # Examples: "node: { title: "a" }"
  qr/^\s*node:\s*$attr/;
  }

sub _match_edge
  {
  # Matches an edge at the start of the buffer
  my $self = shift;

  my $attr = $self->_match_attributes();

  # Examples: "edge: { sourcename: "a" targetname: "b" }"
  #           "backedge: { sourcename: "a" targetname: "b" }"
  qr/^\s*(|near|bentnear|back)edge:\s*$attr/;
  }

sub _match_single_attribute
  {

  qr/\s*(	energetic\s\w+			# "energetic attraction" etc.
		|
		\w+ 				# a word
		|
		border\s(?:x|y)			# "border x" or "border y"
		|
		colorentry\s+[0-9]{1,2}		# colorentry
	)\s*:\s*
    (
      "(?:\\"|[^"])*"				# "foo"
    |
      [0-9]{1,3}\s+[0-9]{1,3}\s+[0-9]{1,3}	# "128 128 64" for color entries
    |
      \{[^\}]+\}				# or {..}
    |
      [^<][^,\]\}\n\s;]*			# or simple 'fooobar'
    )
    \s*/x;					# possible trailing whitespace
  }

sub _match_class_attribute
  {
  # match something like "edge.color: 10"

  qr/\s*(edge|node)\.(\w+)\s*:\s*	# the attribute name (label:")
    (
      "(?:\\"|[^"])*"		# "foo"
    |
      [^<][^,\]\}\n\s]*		# or simple 'fooobar'
    )
    \s*/x;			# possible whitespace
  }

sub _match_attributes
  {
  # return a regexp that matches something like " { color=red; }" and returns
  # the inner text without the {}

  my $qr_att = _match_single_attribute();
  my $qr_cmt = _match_multi_line_comment();
 
  qr/\s*\{\s*((?:$qr_att|$qr_cmt)*)\s*\}/;
  }

sub _match_graph_attribute
  {
  # return a regexp that matches something like " color: red " for attributes
  # that apply to a graph/subgraph
  qr/^\s*(
    (
     colorentry\s+[0-9]{1,2}:\s+[0-9]+\s+[0-9]+\s+[0-9]+
     |
     (?!(node|edge|nearedge|bentnearedge|graph))	# not one of these
     \w+\s*:\s*("(?:\\"|[^"])*"|[^\n\s]+)
    )
   )([\n\s]\s*|\z)/x;
  }

sub _clean_attributes
  {
  my ($self,$text) = @_;

  $text =~ s/^\s*\{\s*//;		# remove left-over "{" and spaces
  $text =~ s/\s*;?\s*\}\s*\z//;		# remove left-over "}" and spaces

  $text;
  }

sub _match_group_end
  {
  # return a regexp that matches something like " }" at the beginning
  qr/^\s*\}\s*/;
  }

sub _match_group_start
  {
  # return a regexp that matches something like "graph {" at the beginning
  qr/^\s*graph:\s+\{\s*/;
  }

sub _clean_line
  { 
  # do some cleanups on a line before handling it
  my ($self,$line) = @_;

  chomp($line);

  # collapse white space at start
  $line =~ s/^\s+//;

  if ($self->{_in_vcg_multi_line_label})
    {
    if ($line =~ /\"[^\"]*\z/)
      {
      # '"\n'
      $self->{_in_vcg_multi_line_label} = 0;
      # restore the match stack
      $self->{match_stack} = $self->{_match_stack};
      delete $self->{_match_stack};
      }
    else
      {
      # hack: convert "a" to \"a\" to fix faulty inputs
      $line =~ s/([^\\])\"/$1\\\"/g;
      }
    }
  # a line ending in 'label: "...\n' means a multi-line label
  elsif ($line =~ /(^|\s)label:\s+\"[^\"]*\z/)
    {
    $self->{_in_vcg_multi_line_label} = 1;
    # swap out the match stack since we just wait for the end of the label
    $self->{_match_stack} = $self->{match_stack};
    delete $self->{match_stack};
    }

  $line;
  }

sub _line_insert
  {
  # What to insert between two lines.
  my ($self) = @_;

  print STDERR "in multiline\n" if $self->{_in_vcg_multi_line_label} && $self->{debug};
  # multiline labels => '\n'
  return '\\n' if $self->{_in_vcg_multi_line_label};

  # the default is ' '
  ' ';
  }

#############################################################################

sub _new_scope
  {
  # create a new scope, with attributes from current scope
  my ($self, $is_group) = @_;

  my $scope = {};

  if (@{$self->{scope_stack}} > 0)
    {
    my $old_scope = $self->{scope_stack}->[-1];

    # make a copy of the old scope's attribtues
    for my $t (keys %$old_scope)
      {
      next if $t =~ /^_/;
      my $s = $old_scope->{$t};
      $scope->{$t} = {} unless ref $scope->{$t}; my $sc = $scope->{$t};
      for my $k (keys %$s)
        {
        # skip things like "_is_group"
        $sc->{$k} = $s->{$k} unless $k =~ /^_/;
        }
      }
    }
  $scope->{_is_group} = 1 if defined $is_group;

  push @{$self->{scope_stack}}, $scope;

  $scope;
  }

sub _edge_style
  {
  # To convert "--" or "->" we simple do nothing, since the edge style in
  # VCG can only be set via the attributes (if at all)
  my ($self, $ed) = @_;

  'solid';
  }

sub _build_match_stack
  {
  my $self = shift;

  my $qr_cn    = $self->_match_classname();
  my $qr_node  = $self->_match_node();
  my $qr_cmt   = $self->_match_multi_line_comment();
  my $qr_ocmt  = $self->_match_optional_multi_line_comment();
  my $qr_attr  = $self->_match_attributes();
  my $qr_gatr  = $self->_match_graph_attribute();
  my $qr_oatr  = $self->_match_optional_attributes();
  my $qr_edge  = $self->_match_edge();
  my $qr_class = $self->_match_class_attribute();

  my $qr_group_end   = $self->_match_group_end();
  my $qr_group_start = $self->_match_group_start();

  # "graph: {"
  $self->_register_handler( $qr_group_start,
    sub
      {
      my $self = shift;

      # the main graph
      if (@{$self->{scope_stack}} == 0)
        {
        print STDERR "# Parser: found main graph\n" if $self->{debug};
	$self->{_vcg_graph_name} = 'unnamed'; 
	$self->_new_scope(1);
        }
      else
	{
        print STDERR "# Parser: found subgraph\n" if $self->{debug};
	# a new subgraph
        push @{$self->{group_stack}}, $self->_new_group();
	}
      1;
      } );

  # graph or subgraph end "}"
  $self->_register_handler( $qr_group_end,
    sub
      {
      my $self = shift;

      print STDERR "# Parser: found end of (sub-)graph\n" if $self->{debug};
      
      my $scope = pop @{$self->{scope_stack}};
      return $self->parse_error(0) if !defined $scope;

      1;
      } );

  # classname 1: "foo"
  $self->_register_handler( $qr_cn,
    sub {
      my $self = shift;
      my $class = $1; my $name = $2;

      print STDERR "#  Found classname '$name' for class '$class'\n" if $self->{debug} > 1;

      $self->{_graph}->{_vcg_class_names}->{$class} = $name;
      1;
      } );

  # node: { ... }
  $self->_register_handler( $qr_node,
    sub {
      my $self = shift;
      my $att = $self->_parse_attributes($1 || '', 'node', NO_MULTIPLES );
      return undef unless defined $att;		# error in attributes?

      my $name = $att->{title}; delete $att->{title};

      print STDERR "#  Found node with name $name\n" if $self->{debug} > 1;

      my $node = $self->_new_node($self->{_graph}, $name, $self->{group_stack}, $att, []);

      # set attributes from scope
      my $scope = $self->{scope_stack}->[-1] || {};
      $node->set_attributes ($scope->{node}) if keys %{$scope->{node}} != 0;

      # override with local attributes
      $node->set_attributes ($att) if keys %$att != 0;
      1;
      } );

  # "edge: { ... }"
  $self->_register_handler( $qr_edge,
    sub {
      my $self = shift;
      my $type = $1 || 'edge';
      my $txt = $2 || '';
      $type = "edge" if $type =~ /edge/;	# bentnearedge => edge
      my $att = $self->_parse_attributes($txt, 'edge', NO_MULTIPLES );
      return undef unless defined $att;		# error in attributes?

      my $from = $att->{source}; delete $att->{source};
      my $to = $att->{target}; delete $att->{target};

      print STDERR "#  Found edge ($type) from $from to $to\n" if $self->{debug} > 1;

      my $edge = $self->{_graph}->add_edge ($from, $to);

      # set attributes from scope
      my $scope = $self->{scope_stack}->[-1] || {};
      $edge->set_attributes ($scope->{edge}) if keys %{$scope->{edge}} != 0;

      # override with local attributes
      $edge->set_attributes ($att) if keys %$att != 0;

      1;
      } );

  # color: red (for graphs or subgraphs)
  $self->_register_attribute_handler($qr_gatr, 'parent');

  # edge.color: 10
  $self->_register_handler( $qr_class,
    sub {
      my $self = shift;
      my $type = $1;
      my $name = $2;
      my $val = $3;

      print STDERR "#  Found color definition $type $name $val\n" if $self->{debug} > 2;

      my $att = $self->_remap_attributes( { $name => $val }, $type, $self->_remap());

      # store the attributes in the current scope
      my $scope = $self->{scope_stack}->[-1];
      $scope->{$type} = {} unless ref $scope->{$type};
      my $s = $scope->{$type};

      for my $k (keys %$att)
        {
        $s->{$k} = $att->{$k};
        }

      #$self->{_graph}->set_attributes ($type, $att);
      1;
      });

  # remove multi line comments /* comment */
  $self->_register_handler( $qr_cmt, undef );
  
  # remove single line comment // comment
  $self->_register_handler( qr/^\s*\/\/.*/, undef );

  $self;
  }

sub _new_node
  {
  # add a node to the graph, overridable by subclasses
  my ($self, $graph, $name, $group_stack, $att, $stack) = @_;

#  print STDERR "add_node $name\n";

  my $node = $graph->node($name);
 
  if (!defined $node)
    {
    $node = $graph->add_node($name);		# add

    # apply attributes from the current scope (only for new nodes)
    my $scope = $self->{scope_stack}->[-1];
    return $self->error("Scope stack is empty!") unless defined $scope;
  
    my $is_group = $scope->{_is_group};
    delete $scope->{_is_group};
    $node->set_attributes($scope->{node});
    $scope->{_is_group} = $is_group if $is_group;

    my $group = $self->{group_stack}->[-1];

    $node->add_to_group($group) if $group;
    }

  $node;
  }

#############################################################################
# attribute remapping

# undef => drop that attribute
# not listed attributes are simple copied unmodified

my $vcg_remap = {
  'node' => {
    iconfile => 'x-vcg-iconfile',
    info1 => 'x-vcg-info1',
    info2 => 'x-vcg-info2',
    info3 => 'x-vcg-info3',
    invisible => \&_invisible_from_vcg,
    importance => 'x-vcg-importance',
    focus => 'x-vcg-focus',
    margin => 'x-vcg-margin',
    textmode => \&_textmode_from_vcg,
    textcolor => \&_node_color_from_vcg,
    color => \&_node_color_from_vcg,
    bordercolor => \&_node_color_from_vcg,
    level => 'rank',
    horizontal_order => \&_horizontal_order_from_vcg,
    shape => \&_vcg_node_shape,
    vertical_order => \&_vertical_order_from_vcg,
    },

  'edge' => {
    anchor => 'x-vcg-anchor',
    right_anchor => 'x-vcg-right_anchor',
    left_anchor => 'x-vcg-left_anchor',
    arrowcolor => 'x-vcg-arrowcolor',
    arrowsize => 'x-vcg-arrowsize',
    # XXX remap this
    arrowstyle => 'x-vcg-arrowstyle',
    backarrowcolor => 'x-vcg-backarrowcolor',
    backarrowsize => 'x-vcg-backarrowsize',
    backarrowstyle => 'x-vcg-backarrowstyle',
    class => \&_edge_class_from_vcg,
    color => \&_edge_color_from_vcg,
    horizontal_order => 'x-vcg-horizontal_order',
    linestyle => 'style',
    priority => 'x-vcg-priority',
    source => 'source',
    sourcename => 'source',
    target => 'target',
    targetname => 'target',
    textcolor => \&_edge_color_from_vcg,
    thickness => 'x-vcg-thickness', 		# remap to broad etc.
    },

  'graph' => {
    color => \&_node_color_from_vcg,
    bordercolor => \&_node_color_from_vcg,
    textcolor => \&_node_color_from_vcg,

    x => 'x-vcg-x',
    y => 'x-vcg-y',
    xmax => 'x-vcg-xmax',
    ymax => 'x-vcg-ymax',
    xspace => 'x-vcg-xspace',
    yspace => 'x-vcg-yspace',
    xlspace => 'x-vcg-xlspace',
    ylspace => 'x-vcg-ylspace',
    xbase => 'x-vcg-xbase',
    ybase => 'x-vcg-ybase',
    xlraster => 'x-vcg-xlraster',
    xraster => 'x-vcg-xraster',
    yraster => 'x-vcg-yraster',

    amax => 'x-vcg-amax',
    bmax => 'x-vcg-bmax',
    cmax => 'x-vcg-cmax',
    cmin => 'x-vcg-cmin',
    smax => 'x-vcg-smax',
    pmax => 'x-vcg-pmax',
    pmin => 'x-vcg-pmin',
    rmax => 'x-vcg-rmax',
    rmin => 'x-vcg-rmin',

    splines => 'x-vcg-splines',
    focus => 'x-vcg-focus',
    hidden => 'x-vcg-hidden',
    horizontal_order => 'x-vcg-horizontal_order',
    iconfile => 'x-vcg-iconfile',
    inport_sharing => \&_inport_sharing_from_vcg,
    importance => 'x-vcg-importance',
    ignore_singles => 'x-vcg-ignore_singles',
    invisible => 'x-vcg-invisible',
    info1 => 'x-vcg-info1',
    info2 => 'x-vcg-info2',
    info3 => 'x-vcg-info3',
    infoname1 => 'x-vcg-infoname1',
    infoname2 => 'x-vcg-infoname2',
    infoname3 => 'x-vcg-infoname3',
    level => 'x-vcg-level',
    loc => 'x-vcg-loc',
    layout_algorithm => 'x-vcg-layout_algorithm',
    # also allow this variant:
    layoutalgorithm => 'x-vcg-layout_algorithm',
    layout_downfactor => 'x-vcg-layout_downfactor',
    layout_upfactor => 'x-vcg-layout_upfactor',
    layout_nearfactor => 'x-vcg-layout_nearfactor',
    linear_segments => 'x-vcg-linear_segments',
    margin => 'x-vcg-margin',
    manhattan_edges => \&_manhattan_edges_from_vcg,
    near_edges => 'x-vcg-near_edges',
    nearedges => 'x-vcg-nearedges',
    node_alignment => 'x-vcg-node_alignment',
    port_sharing => \&_port_sharing_from_vcg,
    priority_phase => 'x-vcg-priority_phase',
    outport_sharing => \&_outport_sharing_from_vcg,
    shape => 'x-vcg-shape',
    smanhattan_edges => 'x-vcg-smanhattan_edges',
    state => 'x-vcg-state',
    splines => 'x-vcg-splines',
    splinefactor => 'x-vcg-splinefactor',
    spreadlevel => 'x-vcg-spreadlevel',

    title => 'label',
    textmode => \&_textmode_from_vcg,
    useractioncmd1 => 'x-vcg-useractioncmd1',
    useractioncmd2 => 'x-vcg-useractioncmd2',
    useractioncmd3 => 'x-vcg-useractioncmd3',
    useractioncmd4 => 'x-vcg-useractioncmd4',
    useractionname1 => 'x-vcg-useractionname1',
    useractionname2 => 'x-vcg-useractionname2',
    useractionname3 => 'x-vcg-useractionname3',
    useractionname4 => 'x-vcg-useractionname4',
    vertical_order => 'x-vcg-vertical_order',

    display_edge_labels => 'x-vcg-display_edge_labels',
    edges => 'x-vcg-edges',
    nodes => 'x-vcg-nodes',
    icons => 'x-vcg-icons',
    iconcolors => 'x-vcg-iconcolors',
    view => 'x-vcg-view',
    subgraph_labels => 'x-vcg-subgraph_labels',
    arrow_mode => 'x-vcg-arrow_mode',
    arrowmode => 'x-vcg-arrowmode',
    crossing_optimization => 'x-vcg-crossing_optimization',
    crossing_phase2 => 'x-vcg-crossing_phase2',
    crossing_weight => 'x-vcg-crossing_weight',
    equal_y_dist => 'x-vcg-equal_y_dist',
    equalydist => 'x-vcg-equalydist',
    finetuning => 'x-vcg-finetuning',
    fstraight_phase => 'x-vcg-fstraight_phase',
    straight_phase => 'x-vcg-straight_phase',
    import_sharing => 'x-vcg-import_sharing',
    late_edge_labels => 'x-vcg-late_edge_labels',
    treefactor => 'x-vcg-treefactor',
    orientation => \&_orientation_from_vcg,

    attraction => 'x-vcg-attraction',
    'border x' => 'x-vcg-border-x',
    'border y' => 'x-vcg-border-y',
    'energetic' => 'x-vcg-energetic',
    'energetic attraction' => 'x-vcg-energetic-attraction',
    'energetic border' => 'x-vcg-energetic-border',
    'energetic crossing' => 'x-vcg-energetic-crossing',
    'energetic gravity' => 'x-vcg-energetic gravity',
    'energetic overlapping' => 'x-vcg-energetic overlapping',
    'energetic repulsion' => 'x-vcg-energetic repulsion',
    fdmax => 'x-vcg-fdmax',
    gravity => 'x-vcg-gravity',

    magnetic_field1 => 'x-vcg-magnetic_field1',
    magnetic_field2 => 'x-vcg-magnetic_field2',
    magnetic_force1 => 'x-vcg-magnetic_force1',
    magnetic_force2 => 'x-vcg-magnetic_force2',
    randomfactor => 'x-vcg-randomfactor',
    randomimpulse => 'x-vcg-randomimpulse',
    randomrounds => 'x-vcg-randomrounds',
    repulsion => 'x-vcg-repulsion',
    tempfactor => 'x-vcg-tempfactor',
    tempmax => 'x-vcg-tempmax',
    tempmin => 'x-vcg-tempmin'.
    tempscheme => 'x-vcg-tempscheme'.
    temptreshold => 'x-vcg-temptreshold',

    dirty_edge_labels => 'x-vcg-dirty_edge_labels',
    fast_icons => 'x-vcg-fast_icons',

    },

  'group' => {
    # graph attributes will be added here automatically
    title => \&_group_name_from_vcg,
    status => 'x-vcg-status',
    },

  'all' => {
    loc => 'x-vcg-loc',
    folding => 'x-vcg-folding',
    scaling => 'x-vcg-scaling',
    shrink => 'x-vcg-shrink',
    stretch => 'x-vcg-stretch',
    width => 'x-vcg-width',
    height => 'x-vcg-height',
    fontname => 'font',
    },
  };

  {
  # add all graph attributes to group, too
  my $group = $vcg_remap->{group};
  my $graph = $vcg_remap->{graph};
  for my $k (keys %$graph)
    {
    $group->{$k} = $graph->{$k};
    }
  }

sub _remap { $vcg_remap; }

my $vcg_edge_color_remap = {
  textcolor => 'labelcolor',
  };

my $vcg_node_color_remap = {
  textcolor => 'color',
  color => 'fill',
  };

sub _vertical_order_from_vcg
  {
  # remap "vertical_order: 5" to "rank: 5"
  my ($graph, $name, $value) = @_;

  my $rank = $value;
  # insert a really really high rank
  $rank = '1000000' if $value eq 'maxdepth';

  # save the original value, too
  ('x-vcg-vertical_order', $value, 'rank', $rank);
  }

sub _horizontal_order_from_vcg
  {
  # remap "horizontal_order: 5" to "rank: 5"
  my ($graph, $name, $value) = @_;

  my $rank = $value;
  # insert a really really high rank
  $rank = '1000000' if $value eq 'maxdepth';

  # save the original value, too
  ('x-vcg-horizontal_order', $value, 'rank', $rank);
  }

sub _invisible_from_vcg
  {
  # remap "invisible: yes" to "shape: invisible"
  my ($graph, $name, $value) = @_;

  return (undef,undef) if $value ne 'yes';

  ('shape', 'invisible');
  }

sub _manhattan_edges_from_vcg
  {
  # remap "manhattan_edges: yes" for graphs
  my ($graph, $name, $value) = @_;

  if ($value eq 'yes')
    {
    $graph->set_attribute('edge','start','front');
    $graph->set_attribute('edge','end','back');
    }
  # store the value for proper VCG output
  ('x-vcg-' . $name, $value);
  }

sub _textmode_from_vcg
  {
  # remap "textmode: left_justify" to "align: left;"
  my ($graph, $name, $align) = @_;

  $align =~ s/_.*//;	# left_justify => left	

  ('align', lc($align));
  }

sub _edge_color_from_vcg
  {
  # remap "darkyellow" to "rgb(128 128 0)"
  my ($graph, $name, $color) = @_;

#  print STDERR "edge $name $color\n";
#  print STDERR ($vcg_edge_color_remap->{$name} || $name, " ", $vcg_color_by_name->{$color} || $color), "\n";

  my $c = $vcg_color_by_name->{$color} || $color;
  $c = $graph->{_vcg_color_map}->[$c] if $c =~ /^[0-9]+\z/ && $c < 256;

  ($vcg_edge_color_remap->{$name} || $name, $c);
  }

sub _edge_class_from_vcg
  {
  # remap "1" to "edgeclass1" to create a valid class name
  my ($graph, $name, $class) = @_;

  $class = $graph->{_vcg_class_names}->{$class} || ('edgeclass' . $class) if $class =~ /^[0-9]+\z/;
  #$class = 'edgeclass' . $class if $class !~ /^[a-zA-Z]/;

  ('class', $class);
  }

my $vcg_orientation = {
  top_to_bottom => 'south',
  bottom_to_top => 'north',
  left_to_right => 'east',
  right_to_left => 'west',
  };

sub _orientation_from_vcg
  {
  my ($graph, $name, $value) = @_;

  ('flow', $vcg_orientation->{$value} || 'south');
  }

sub _port_sharing_from_vcg
  {
  # if we see this, add autojoin/autosplit
  my ($graph, $name, $value) = @_;

  $value = ($value =~ /yes/i) ? 'yes' : 'no';
 
  ('autojoin', $value, 'autosplit', $value);
  }

sub _inport_sharing_from_vcg
  {
  # if we see this, add autojoin/autosplit
  my ($graph, $name, $value) = @_;

  $value = ($value =~ /yes/i) ? 'yes' : 'no';
 
  ('autojoin', $value);
  }

sub _outport_sharing_from_vcg
  {
  # if we see this, add autojoin/autosplit
  my ($graph, $name, $value) = @_;

  $value = ($value =~ /yes/i) ? 'yes' : 'no';
 
  ('autosplit', $value);
  }

sub _node_color_from_vcg
  {
  # remap "darkyellow" to "rgb(128 128 0)"
  my ($graph, $name, $color) = @_;

  my $c = $vcg_color_by_name->{$color} || $color;
  $c = $graph->{_vcg_color_map}->[$c] if $c =~ /^[0-9]+\z/ && $c < 256;

  ($vcg_node_color_remap->{$name} || $name, $c);
  }

my $shapes = {
  box => 'rect',
  rhomb => 'diamond',
  triangle => 'triangle',
  ellipse => 'ellipse',
  circle => 'circle',
  hexagon => 'hexagon',
  trapeze => 'trapezium',
  uptrapeze => 'invtrapezium',
  lparallelogram => 'invparallelogram',
  rparallelogram => 'parallelogram',
  };

sub _vcg_node_shape
  {
  my ($self, $name, $shape) = @_;

  my @rc;
  my $s = lc($shape);

  # map the name to what Graph::Easy expects (ellipse stays as ellipse but
  # everything unknown gets converted to rect)
  $s = $shapes->{$s} || 'rect';

  (@rc, $name, $s);
  }

sub _group_name_from_vcg
  {
  my ($self, $attr, $name, $object) = @_;

  print STDERR "# Renaming anon group '$object->{name}' to '$name'\n"
	if $self->{debug} > 0;

  $self->rename_group($object, $name);

  # name was set, so drop the "title: name" pair
  (undef, undef);
  }

#############################################################################

sub _remap_attributes
  {
  my ($self, $att, $object, $r) = @_;

#  print STDERR "# Remapping attributes\n";
#    use Data::Dumper; print Dumper($att);

  # handle the "colorentry 00" entries:
  for my $key (keys %$att)
    {
    if ($key =~ /^colorentry\s+([0-9]{1,2})/)
      {
      # put the color into the current color map
      $self->_vcg_color_map_entry($1, $att->{$key});
      delete $att->{$key};
      next; 
      }

    # remap \fi065 to 'A'
    $att->{$key} =~ s/(\x0c|\\f)i([0-9]{3})/ decode('iso-8859-1', chr($2)); /eg;

    # XXX TDOO: support inline colorations
    # remap \f65 to ''
    $att->{$key} =~ s/(\x0c|\\f)([0-9]{2})//g;

    # remap \c09 to color 09: TODO for now remove
    $att->{$key} =~ s/(\x0c|\\f)([0-9]{2})//g;

    # XXX TODO: support real hor lines
    # insert a fake <HR>
    $att->{$key} =~ s/(\x0c|\\f)-/\\c ---- \\n /g;

    }
  $self->SUPER::_remap_attributes($att,$object,$r);
  }

#############################################################################

sub _parser_cleanup
  {
  # After initial parsing, do cleanup.
  my ($self) = @_;

  my $g = $self->{_graph};
  $g->{_warn_on_unknown_attributes} = 0;	# reset to die again

  delete $g->{_vcg_color_map};
  delete $g->{_vcg_class_names};

  $self;
  }

1;
__END__

=head1 NAME

Graph::Easy::Parser::VCG - Parse VCG or GDL text into Graph::Easy

=head1 SYNOPSIS

        # creating a graph from a textual description

        use Graph::Easy::Parser::VCG;
        my $parser = Graph::Easy::Parser::VCG->new();

        my $graph = $parser->from_text(
                "graph: { \n" .
	 	"	node: { title: "Bonn" }\n" .
	 	"	node: { title: "Berlin" }\n" .
	 	"	edge: { sourcename: "Bonn" targetname: "Berlin" }\n" .
		"}\n"
        );
        print $graph->as_ascii();

	print $parser->from_file('mygraph.vcg')->as_ascii();

=head1 DESCRIPTION

C<Graph::Easy::Parser::VCG> parses the text format from the VCG or GDL
(Graph Description Language) use by tools like GCC and AiSee, and
constructs a C<Graph::Easy> object from it.

The resulting object can then be used to layout and output the graph
in various formats.

=head2 Output

The output will be a L<Graph::Easy|Graph::Easy> object (unless overrriden
with C<use_class()>), see the documentation for Graph::Easy what you can do
with it.

=head2 Attributes

Attributes will be remapped to the proper Graph::Easy attribute names and
values, as much as possible.

Anything else will be converted to custom attributes starting with "x-vcg-".
So "dirty_edge_labels: yes" will become "x-vcg-dirty_edge_labels: yes".

=head1 METHODS

C<Graph::Easy::Parser::VCG> supports the same methods
as its parent class C<Graph::Easy::Parser>:

=head2 new()

	use Graph::Easy::Parser::VCG;
	my $parser = Graph::Easy::Parser::VCG->new();

Creates a new parser object. There are two valid parameters:

	debug
	fatal_errors

Both take either a false or a true value.

	my $parser = Graph::Easy::Parser::VCG->new( debug => 1 );
	$parser->from_text('graph: { }');

=head2 reset()

	$parser->reset();

Reset the status of the parser, clear errors etc. Automatically called
when you call any of the C<from_XXX()> methods below.

=head2 use_class()

	$parser->use_class('node', 'Graph::Easy::MyNode');

Override the class to be used to constructs objects while parsing.

See L<Graph::Easy::Parser> for further information.

=head2 from_text()

	my $graph = $parser->from_text( $text );

Create a L<Graph::Easy|Graph::Easy> object from the textual description in C<$text>.

Returns undef for error, you can find out what the error was
with L<error()>.

This method will reset any previous error, and thus the C<$parser> object
can be re-used to parse different texts by just calling C<from_text()>
multiple times.

=head2 from_file()

	my $graph = $parser->from_file( $filename );
	my $graph = Graph::Easy::Parser::VCG->from_file( $filename );

Creates a L<Graph::Easy|Graph::Easy> object from the textual description in the file
C<$filename>.

The second calling style will create a temporary parser object,
parse the file and return the resulting C<Graph::Easy> object.

Returns undef for error, you can find out what the error was
with L<error()> when using the first calling style.

=head2 error()

	my $error = $parser->error();

Returns the last error, or the empty string if no error occured.

=head2 parse_error()

	$parser->parse_error( $msg_nr, @params);

Sets an error message from a message number and replaces embedded
templates like C<##param1##> with the passed parameters.

=head1 CAVEATS

The parser has problems with the following things:

=over 12

=item attributes

Some attributes are B<not> remapped properly to what Graph::Easy expects, thus
losing information, either because Graph::Easy doesn't support this feature
yet, or because the mapping is incomplete.

=item comments

Comments written in the source code itself are discarded. If you want to have
comments on the graph, clusters, nodes or edges, use the attribute C<comment>.
These are correctly read in and stored, and then output into the different
formats, too.

=back

=head1 EXPORT

Exports nothing.

=head1 SEE ALSO

L<Graph::Easy>, L<Graph::Write::VCG>.

=head1 AUTHOR

Copyright (C) 2005 - 2008 by Tels L<http://bloodgate.com>

See the LICENSE file for information.

=cut

