############################################################################
# Manage, and layout graphs on a flat plane.
#
#############################################################################

package Graph::Easy;

use 5.008002;
use Graph::Easy::Base;
use Graph::Easy::Attributes;
use Graph::Easy::Edge;
use Graph::Easy::Group;
use Graph::Easy::Group::Anon;
use Graph::Easy::Layout;
use Graph::Easy::Node;
use Graph::Easy::Node::Anon;
use Graph::Easy::Node::Empty;
use Scalar::Util qw/weaken/;

$VERSION = '0.69';
@ISA = qw/Graph::Easy::Base/;

use strict;
my $att_aliases;

BEGIN 
  {
  # a few aliases for backwards compatibility
  *get_attribute = \&attribute; 
  *as_html_page = \&as_html_file;
  *as_graphviz_file = \&as_graphviz;
  *as_ascii_file = \&as_ascii;
  *as_boxart_file = \&as_boxart;
  *as_txt_file = \&as_txt;
  *as_vcg_file = \&as_vcg;
  *as_gdl_file = \&as_gdl;
  *as_graphml_file = \&as_graphml;

  # a few aliases for code re-use
  *_aligned_label = \&Graph::Easy::Node::_aligned_label;
  *quoted_comment = \&Graph::Easy::Node::quoted_comment;
  *_un_escape = \&Graph::Easy::Node::_un_escape;
  *_convert_pod = \&Graph::Easy::Node::_convert_pod;
  *_label_as_html = \&Graph::Easy::Node::_label_as_html;
  *_wrapped_label = \&Graph::Easy::Node::_wrapped_label;
  *get_color_attribute = \&color_attribute;
  *get_custom_attributes = \&Graph::Easy::Node::get_custom_attributes;
  *custom_attributes = \&Graph::Easy::Node::get_custom_attributes;
  $att_aliases = Graph::Easy::_att_aliases();

  # backwards compatibility
  *is_simple_graph = \&is_simple;

  # compatibility to Graph
  *vertices = \&nodes;
  }

#############################################################################

sub new
  {
  # override new() as to not set the {id}
  my $class = shift;

  # called like "new->('[A]->[B]')":
  if (@_ == 1 && !ref($_[0]))
    {
    require Graph::Easy::Parser;
    my $parser = Graph::Easy::Parser->new();
    my $self = eval { $parser->from_text($_[0]); };
    if (!defined $self)
      {
      $self = Graph::Easy->new( fatal_errors => 0 );
      $self->error( 'Error: ' . $parser->error() ||
        'Unknown error while parsing initial text' );
      $self->catch_errors( 0 );
      }
    return $self;
    }

  my $self = bless {}, $class;

  my $args = $_[0];
  $args = { @_ } if ref($args) ne 'HASH';

  $self->_init($args);
  }

sub DESTROY
  {
  my $self = shift;
 
  # Be carefull to not delete ->{graph}, these will be cleaned out by
  # Perl automatically in O(1) time, manual delete is O(N) instead.

  delete $self->{chains};
  # clean out pointers in child-objects so that they can safely be reused
  for my $n (values %{$self->{nodes}})
    {
    if (ref($n))
      {
      delete $n->{edges};
      delete $n->{group};
      }
    }
  for my $e (values %{$self->{edges}})
    {
    if (ref($e))
      {
      delete $e->{cells};
      delete $e->{to};
      delete $e->{from};
      }
    }
  for my $g (values %{$self->{groups}})
    {
    if (ref($g))
      {
      delete $g->{nodes};
      delete $g->{edges};
      }
    }
  }

# Attribute overlay for HTML output:

my $html_att = {
  node => {
    borderstyle => 'solid',
    borderwidth => '1px',
    bordercolor => '#000000',
    align => 'center',
    padding => '0.2em',
    'padding-left' => '0.3em',
    'padding-right' => '0.3em',
    margin => '0.1em',
    fill => 'white',
    },
  'node.anon' => {
    'borderstyle' => 'none',
    # ' inherit' to protect the value from being replaced by the one from "node"
    'background' => ' inherit',
    },
  graph => {
    margin => '0.5em',
    padding => '0.5em',
    'empty-cells' => 'show',
    },
  edge => { 
    border => 'none',
    padding => '0.2em',
    margin => '0.1em',
    'font' => 'monospaced, courier-new, courier, sans-serif',
    'vertical-align' => 'bottom',
    },
  group => { 
    'borderstyle' => 'dashed',
    'borderwidth' => '1',
    'fontsize' => '0.8em',
    fill => '#a0d0ff',
    padding => '0.2em',
# XXX TODO:
# in HTML, align left is default, so we could omit this:
    align => 'left',
    },
  'group.anon' => {
    'borderstyle' => 'none',
    background => 'white',
    },
  };


sub _init
  {
  my ($self,$args) = @_;

  $self->{debug} = 0;
  $self->{timeout} = 5;			# in seconds
  $self->{strict} = 1;			# check attributes strict?
  
  $self->{class} = 'graph';
  $self->{id} = '';
  $self->{groups} = {};

  # node objects, indexed by their unique name
  $self->{nodes} = {};
  # edge objects, indexed by unique ID
  $self->{edges} = {};

  $self->{output_format} = 'html';

  $self->{_astar_bias} = 0.001;

  # default classes to use in add_foo() methods
  $self->{use_class} = {
    edge => 'Graph::Easy::Edge',
    group => 'Graph::Easy::Group',
    node => 'Graph::Easy::Node',
  };

  # Graph::Easy will die, Graph::Easy::Parser::Graphviz will warn
  $self->{_warn_on_unknown_attributes} = 0;
  $self->{fatal_errors} = 1;

  # The attributes of the graph itself, _and_ the class/subclass attributes.
  # These can share a hash, because:
  # *  {att}->{graph} contains both the graph attributes and the class, since
  #    these are synonymous, it is not possible to have more than one graph.
  # *  'node', 'group', 'edge' are not valid attributes for a graph, so
  #    setting "graph { node: 1; }" is not possible and can thus not overwrite
  #    the entries from att->{node}.
  # *  likewise for "node.subclass", attribute names never have a "." in them
  $self->{att} = {};

  foreach my $k (keys %$args)
    {
    if ($k !~ /^(timeout|debug|strict|fatal_errors|undirected)\z/)
      {
      $self->error ("Unknown option '$k'");
      }
    if ($k eq 'undirected' && $args->{$k})
      {
      $self->set_attribute('type', 'undirected'); next;
      }
    $self->{$k} = $args->{$k};
    }

  binmode(STDERR,'utf8') or die ("Cannot do binmode(STDERR,'utf8'")
    if $self->{debug};

  $self->{score} = undef;

  $self->randomize();

  $self;
  }

#############################################################################
# accessors

sub timeout
  {
  my $self = shift;

  $self->{timeout} = $_[0] if @_;
  $self->{timeout};
  }

sub debug
  {
  my $self = shift;

  $self->{debug} = $_[0] if @_;
  $self->{debug};
  }

sub strict
  {
  my $self = shift;

  $self->{strict} = $_[0] if @_;
  $self->{strict};
  }

sub type
  {
  # return the type of the graph, "undirected" or "directed"
  my $self = shift;

  $self->{att}->{type} || 'directed';
  }

sub is_simple
  {
  # return true if the graph does not have multiedges
  my $self = shift;

  my %count;
  for my $e (values %{$self->{edges}})
    {
    my $id = "$e->{to}->{id},$e->{from}->{id}";
    return 0 if exists $count{$id};
    $count{$id} = undef;
    }

  1;					# found none
  }

sub is_directed
  {
  # return true if the graph is directed
  my $self = shift;

  $self->attribute('type') eq 'directed' ? 1 : 0;
  }

sub is_undirected
  {
  # return true if the graph is undirected
  my $self = shift;

  $self->attribute('type') eq 'undirected' ? 1 : 0;
  }

sub id
  {
  my $self = shift;

  $self->{id} = shift if defined $_[0];
  $self->{id};
  }

sub score
  {
  my $self = shift;

  $self->{score};
  }

sub randomize
  {
  my $self = shift;

  srand();
  $self->{seed} = rand(2 ** 31);

  $self->{seed};
  }

sub root_node
  {
  # Return the root node
  my $self = shift;
  
  my $root = $self->{att}->{root};
  $root = $self->{nodes}->{$root} if defined $root;

  $root;
  }

sub source_nodes
  {
  # return nodes with only outgoing edges
  my $self = shift;

  my @roots;
  for my $node (values %{$self->{nodes}})
    {
    push @roots, $node 
      if (keys %{$node->{edges}} != 0) && !$node->has_predecessors();
    }
  @roots;
  }

sub predecessorless_nodes
  {
  # return nodes with no incoming (but maybe outgoing) edges
  my $self = shift;

  my @roots;
  for my $node (values %{$self->{nodes}})
    {
    push @roots, $node 
      if (keys %{$node->{edges}} == 0) || !$node->has_predecessors();
    }
  @roots;
  }

sub label
  {
  my $self = shift;

  my $label = $self->{att}->{graph}->{label}; $label = '' unless defined $label;
  $label = $self->_un_escape($label) if !$_[0] && $label =~ /\\[EGHNT]/;
  $label;
  }

sub link
  {
  # return the link, build from linkbase and link (or autolink)
  my $self = shift;

  my $link = $self->attribute('link');
  my $autolink = ''; $autolink = $self->attribute('autolink') if $link eq '';
  if ($link eq '' && $autolink ne '')
    {
    $link = $self->{name} if $autolink eq 'name';
    # defined to avoid overriding "name" with the non-existant label attribute
    $link = $self->{att}->{label} if $autolink eq 'label' && defined $self->{att}->{label};
    $link = $self->{name} if $autolink eq 'label' && !defined $self->{att}->{label};
    }
  $link = '' unless defined $link;

  # prepend base only if link is relative
  if ($link ne '' && $link !~ /^([\w]{3,4}:\/\/|\/)/)
    {
    $link = $self->attribute('linkbase') . $link;
    }

  $link = $self->_un_escape($link) if !$_[0] && $link =~ /\\[EGHNT]/;

  $link;
  }

sub parent
  {
  # return parent object, for graphs that is undef
  undef;
  }

sub seed
  {
  my $self = shift;

  $self->{seed} = $_[0] if @_ > 0;

  $self->{seed};
  }

sub nodes
  {
  # return all nodes as objects, in scalar context their count
  my ($self) = @_;

  my $n = $self->{nodes};

  return scalar keys %$n unless wantarray;	# shortcut

  values %$n;
  }

sub anon_nodes
  {
  # return all anon nodes as objects
  my ($self) = @_;

  my $n = $self->{nodes};

  if (!wantarray)
    {
    my $count = 0;
    for my $node (values %$n)
      {
      $count++ if $node->is_anon();
      }
    return $count;
    }

  my @anon = ();
  for my $node (values %$n)
    {
    push @anon, $node if $node->is_anon();
    }
  @anon;
  }

sub edges
  {
  # Return all the edges this graph contains as objects
  my ($self) = @_;

  my $e = $self->{edges};

  return scalar keys %$e unless wantarray;	# shortcut

  values %$e;
  }

sub edges_within
  {
  # return all the edges as objects
  my ($self) = @_;

  my $e = $self->{edges};

  return scalar keys %$e unless wantarray;	# shortcut

  values %$e;
  }

sub sorted_nodes
  {
  # return all nodes as objects, sorted by $f1 or $f1 and $f2
  my ($self, $f1, $f2) = @_;

  return scalar keys %{$self->{nodes}} unless wantarray;	# shortcut

  $f1 = 'id' unless defined $f1;
  # sorting on a non-unique field alone will result in unpredictable
  # sorting order due to hashing
  $f2 = 'name' if !defined $f2 && $f1 !~ /^(name|id)$/;

  my $sort;
  $sort = sub { $a->{$f1} <=> $b->{$f1} } if $f1;
  $sort = sub { abs($a->{$f1}) <=> abs($b->{$f1}) } if $f1 && $f1 eq 'rank';
  $sort = sub { $a->{$f1} cmp $b->{$f1} } if $f1 && $f1 =~ /^(name|title|label)$/;
  $sort = sub { $a->{$f1} <=> $b->{$f1} || $a->{$f2} <=> $b->{$f2} } if $f2;
  $sort = sub { abs($a->{$f1}) <=> abs($b->{$f1}) || $a->{$f2} <=> $b->{$f2} } if $f2 && $f1 eq 'rank';
  $sort = sub { $a->{$f1} <=> $b->{$f1} || abs($a->{$f2}) <=> abs($b->{$f2}) } if $f2 && $f2 eq 'rank';
  $sort = sub { $a->{$f1} <=> $b->{$f1} || $a->{$f2} cmp $b->{$f2} } if $f2 &&
           $f2 =~ /^(name|title|label)$/;
  $sort = sub { abs($a->{$f1}) <=> abs($b->{$f1}) || $a->{$f2} cmp $b->{$f2} } if 
           $f1 && $f1 eq 'rank' &&
           $f2 && $f2 =~ /^(name|title|label)$/;
  # 'name', 'id'
  $sort = sub { $a->{$f1} cmp $b->{$f1} || $a->{$f2} <=> $b->{$f2} } if $f2 &&
           $f2 eq 'id' && $f1 ne 'rank';

  # the 'return' here should not be removed
  return sort $sort values %{$self->{nodes}};
  }

sub add_edge_once
  {
  # add an edge, unless it already exists. In that case it returns undef
  my ($self, $x, $y, $edge) = @_;

  # got an edge object? Don't add it twice!
  return undef if ref($edge);

  # turn plaintext scalars into objects 
  my $x1 = $self->{nodes}->{$x} unless ref $x;
  my $y1 = $self->{nodes}->{$y} unless ref $y;

  # nodes do exist => maybe the edge also exists
  if (ref($x1) && ref($y1))
    {
    my @ids = $x1->edges_to($y1);

    return undef if @ids;	# found already one edge?
    }

  $self->add_edge($x,$y,$edge);
  }

sub edge
  {
  # return an edge between two nodes as object
  my ($self, $x, $y) = @_;

  # turn plaintext scalars into objects 
  $x = $self->{nodes}->{$x} unless ref $x;
  $y = $self->{nodes}->{$y} unless ref $y;

  # node does not exist => edge does not exist
  return undef unless ref($x) && ref($y);

  my @ids = $x->edges_to($y);
  
  wantarray ? @ids : $ids[0];
  }

sub flip_edges
  {
  # turn all edges going from $x to $y around
  my ($self, $x, $y) = @_;

  # turn plaintext scalars into objects 
  $x = $self->{nodes}->{$x} unless ref $x;
  $y = $self->{nodes}->{$y} unless ref $y;

  # node does not exist => edge does not exist
  # if $x == $y, return early (no need to turn selfloops)

  return $self unless ref($x) && ref($y) && ($x != $y);

  for my $e (values %{$x->{edges}})
    {
    $e->flip() if $e->{from} == $x && $e->{to} == $y;
    }

  $self;
  }

sub node
  {
  # return node by name
  my ($self,$name) = @_;
  $name = '' unless defined $name;

  $self->{nodes}->{$name};
  }

sub rename_node
  {
  # change the name of a node
  my ($self, $node, $new_name) = @_;

  $node = $self->{nodes}->{$node} unless ref($node);

  if (!ref($node))
    {
    $node = $self->add_node($new_name);
    }
  else
    {
    if (!ref($node->{graph}))
      {
      # add node to ourself
      $node->{name} = $new_name;
      $self->add_node($node);
      }
    else
      {
      if ($node->{graph} != $self)
        {
	$node->{graph}->del_node($node);
	$node->{name} = $new_name;
	$self->add_node($node);
	}
      else
	{
	delete $self->{nodes}->{$node->{name}};
	$node->{name} = $new_name;
	$self->{nodes}->{$node->{name}} = $node;
	}
      }
    }
  if ($node->is_anon())
    {
    # turn anon nodes into a normal node (since it got a new name):
    bless $node, $self->{use_class}->{node} || 'Graph::Easy::Node';
    delete $node->{att}->{label} if $node->{att}->{label} eq ' ';
    $node->{class} = 'group';
    }
  $node;
  }

sub rename_group
  {
  # change the name of a group
  my ($self, $group, $new_name) = @_;

  if (!ref($group))
    {
    $group = $self->add_group($new_name);
    }
  else
    {
    if (!ref($group->{graph}))
      {
      # add node to ourself
      $group->{name} = $new_name;
      $self->add_group($group);
      }
    else
      {
      if ($group->{graph} != $self)
        {
	$group->{graph}->del_group($group);
	$group->{name} = $new_name;
	$self->add_group($group);
	}
      else
	{
	delete $self->{groups}->{$group->{name}};
	$group->{name} = $new_name;
	$self->{groups}->{$group->{name}} = $group;
	}
      }
    }
  if ($group->is_anon())
    {
    # turn anon groups into a normal group (since it got a new name):
    bless $group, $self->{use_class}->{group} || 'Graph::Easy::Group';
    delete $group->{att}->{label} if $group->{att}->{label} eq '';
    $group->{class} = 'group';
    }
  $group;
  }

#############################################################################
# attribute handling

sub _check_class
  {
  # Check the given class ("graph", "node.foo" etc.) or class selector
  # (".foo") for being valid, and return a list of base classes this applies
  # to. Handles also a list of class selectors like ".foo, .bar, node.foo".
  my ($self, $selector) = @_;

  my @parts = split /\s*,\s*/, $selector;

  my @classes = ();
  for my $class (@parts)
    {
    # allowed classes, subclasses (except "graph."), selectors (excpet ".")
    return unless $class =~ /^(\.\w|node|group|edge|graph\z)/;
    # "node." is invalid, too
    return if $class =~ /\.\z/;

    # run a loop over all classes: "node.foo" => ("node"), ".foo" => ("node","edge","group")
    $class =~ /^(\w*)/; 
    my $base_class = $1; 
    if ($base_class eq '')
      {
      push @classes, ('edge'.$class, 'group'.$class, 'node'.$class);
      }
    else
      {
      push @classes, $class;
      }
    } # end for all parts

  @classes;
  }

sub set_attribute
  {
  my ($self, $class_selector, $name, $val) = @_;

  # allow calling in the style of $graph->set_attribute($name,$val);
  if (@_ == 3)
    {
    $val = $name;
    $name = $class_selector;
    $class_selector = 'graph';
    }

  # font-size => fontsize
  $name = $att_aliases->{$name} if exists $att_aliases->{$name};

  $name = 'undef' unless defined $name;
  $val = 'undef' unless defined $val;

  my @classes = $self->_check_class($class_selector);

  return $self->error ("Illegal class '$class_selector' when trying to set attribute '$name' to '$val'")
    if @classes == 0;

  for my $class (@classes)
    {
    $val = $self->unquote_attribute($class,$name,$val);

    if ($self->{strict})
      {
      my ($rc, $newname, $v) = $self->validate_attribute($name,$val,$class);
      return if defined $rc;		# error?

      $val = $v;
      }

    $self->{score} = undef;	# invalidate layout to force a new layout
    delete $self->{cache};	# setting a class or flow must invalidate the cache

    # handle special attribute 'gid' like in "graph { gid: 123; }"
    if ($class eq 'graph')
      {
      if ($name =~ /^g?id\z/)
        {
        $self->{id} = $val;
        }
      # handle special attribute 'output' like in "graph { output: ascii; }"
      if ($name eq 'output')
        {
        $self->{output_format} = $val;
        }
      }

    my $att = $self->{att};
    # create hash if it doesn't exist yet
    $att->{$class} = {} unless ref $att->{$class};

    if ($name eq 'border')
      {
      my $c = $att->{$class};

      ($c->{borderstyle}, $c->{borderwidth}, $c->{bordercolor}) =
	 $self->split_border_attributes( $val );

      return $val;
      }

    $att->{$class}->{$name} = $val;

    } # end for all selected classes

  $val;
  }

sub set_attributes
  {
  my ($self, $class_selector, $att) = @_;

  # if called as $graph->set_attributes( { color => blue } ), assume
  # class eq 'graph'

  if (defined $class_selector && !defined $att)
    {
    $att = $class_selector; $class_selector = 'graph';
    }

  my @classes = $self->_check_class($class_selector);

  return $self->error ("Illegal class '$class_selector' when trying to set attributes")
    if @classes == 0;

  foreach my $a (keys %$att)
    {
    for my $class (@classes)
      {
      $self->set_attribute($class, $a, $att->{$a});
      }
    } 
  $self;
  }

sub del_attribute
  {
  # delete the attribute with the name in the selected class(es)
  my ($self, $class_selector, $name) = @_;

  if (@_ == 2)
    {
    $name = $class_selector; $class_selector = 'graph';
    }

  # font-size => fontsize
  $name = $att_aliases->{$name} if exists $att_aliases->{$name};

  my @classes = $self->_check_class($class_selector);

  return $self->error ("Illegal class '$class_selector' when trying to delete attribute '$name'")
    if @classes == 0;

  for my $class (@classes)
    {
    my $a = $self->{att}->{$class};

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
    }
  $self;
  }

#############################################################################

# for determining the absolute graph flow
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

sub flow
  {
  # return out flow as number
  my ($self)  = @_;

  my $flow = $self->{att}->{graph}->{flow};

  return 90 unless defined $flow;

  my $f = $p_flow->{$flow}; $f = $flow unless defined $f;
  $f;
  }

#############################################################################
#############################################################################
# Output (as_ascii, as_html) routines; as_txt() is in As_txt.pm, as_graphml
# is in As_graphml.pm

sub output_format
  {
  # set the output format
  my $self = shift;

  $self->{output_format} = shift if $_[0];
  $self->{output_format};
  }

sub output
  {
  # general output routine, to output the graph as the format that was
  # specified in the graph source itself
  my $self = shift;

  no strict 'refs';

  my $method = 'as_' . $self->{output_format};

  $self->_croak("Cannot find a method to generate '$self->{output_format}'")
    unless $self->can($method);

  $self->$method();
  }

sub _class_styles
  {
  # Create the style sheet with the class lists. This is used by both
  # css() and as_svg(). $skip is a qr// object that returns true for
  # attribute names to be skipped (e.g. excluded), and $map is a
  # HASH that contains mapping for attribute names for the output.
  # "$base" is the basename for classes (either "table.graph$id" if 
  # not defined, or whatever you pass in, like "" for svg).
  # $indent is a left-indenting spacer like "  ".
  # $overlay contains a HASH with attribute-value pairs to set as defaults.

  my ($self, $skip, $map, $base, $indent, $overlay) = @_;

  my $a = $self->{att};

  $indent = '' unless defined $indent;
  my $indent2 = $indent x 2; $indent2 = '  ' if $indent2 eq '';

  my $class_list = { edge => {}, node => {}, group => {} };
  if (defined $overlay)
    {
    $a = {};

    # make a copy from $self->{att} to $a:

    for my $class (keys %{$self->{att}})
      {
      my $ac = $self->{att}->{$class};
      $a->{$class} = {};
      my $acc = $a->{$class};
      for my $k (keys %$ac)
        {
        $acc->{$k} = $ac->{$k};
        }
      }

    # add the extra keys
    for my $class (keys %$overlay)
      {
      my $oc = $overlay->{$class};
      # create the hash if it doesn't exist yet
      $a->{$class} = {} unless ref $a->{$class};
      my $acc = $a->{$class};
      for my $k (keys %$oc)
        {
        $acc->{$k} = $oc->{$k} unless exists $acc->{$k};
        }
      $class_list->{$class} = {};
      }
    }

  my $id = $self->{id};

  my @primaries = sort keys %$class_list;
  foreach my $primary (@primaries)
    {
    my $cl = $class_list->{$primary};			# shortcut
    foreach my $class (sort keys %$a)
      {
      if ($class =~ /^$primary\.(.*)/)
        {
        $cl->{$1} = undef;				# note w/o doubles
        }
      }
    }

  $base = "table.graph$id " unless defined $base;

  my $groups = $self->groups();				# do we have groups?

  my $css = '';
  foreach my $class (sort keys %$a)
    {
    next if keys %{$a->{$class}} == 0;			# skip empty ones

    my $c = $class; $c =~ s/\./_/g;			# node.city => node_city

    next if $class eq 'group' and $groups == 0;

    my $css_txt = '';
    my $cls = '';
    if ($class eq 'graph' && $base eq '')
      {
      $css_txt .= "${indent}.$class \{\n";			# for SVG
      }
    elsif ($class eq 'graph')
      {
      $css_txt .= "$indent$base\{\n";
      }
    else
      {
      if ($c !~ /\./)					# one of our primary ones
        {
        # generate also class list 			# like: "cities,node_rivers"
        $cls = join (",$base.${c}_", sort keys %{ $class_list->{$c} });
        $cls = ",$base.${c}_$cls" if $cls ne '';		# like: ",node_cities,node_rivers"
        }
      $css_txt .= "$indent$base.$c$cls {\n";
      }
    my $done = 0;
    foreach my $att (sort keys %{$a->{$class}})
      {
      # should be skipped?
      next if $att =~ $skip || $att eq 'border';

      # do not specify attributes for the entire graph (only for the label)
      # $base ne '' skips this rule for SVG output
      next if $class eq 'graph' && $base ne '' && $att =~ /^(color|font|fontsize|align|fill)\z/;

      $done++;						# how many did we really?
      my $val = $a->{$class}->{$att};

      next if !defined $val;

      # for groups, set to none, it will be later overriden for the different
      # cells (like "ga") with a border only on the appropriate side:
      $val = 'none' if $att eq 'borderstyle' && $class eq 'group';
      # fix border-widths to be in pixel
      $val .= 'px' if $att eq 'borderwidth' && $val !~ /(px|em|%)\z/;

      # for color attributes, convert to hex
      my $entry = $self->_attribute_entry($class, $att);

      if (defined $entry)
	{
	my $type = $entry->[ ATTR_TYPE_SLOT ] || ATTR_STRING;
	if ($type == ATTR_COLOR)
	  {
	  # create as RGB color
	  $val = $self->get_color_attribute($class,$att) || $val;
	  }
	}
      # change attribute name/value?
      if (exists $map->{$att})
	{
        $att = $map->{$att} unless ref $map->{$att};		# change attribute name?
        ($att,$val) = &{$map->{$att}}($self,$att,$val,$class) if ref $map->{$att};
	}

      # value is "inherit"?
      if ($class ne 'graph' && $att && $val && $val eq 'inherit')
        {
        # get the value from one class "up"

	# node.foo => node, node => graph
        my $base_class = $class; $base_class = 'graph' unless $base_class =~ /\./;
	$base_class =~ s/\..*//;

        $val = $a->{$base_class}->{$att};

	if ($base_class ne 'graph' && (!defined $val || $val eq 'inherit'))
	  {
	  # node.foo => node, inherit => graph
          $val = $a->{graph}->{$att};
	  $att = undef if !defined $val;
	  }
	}

      $css_txt .= "$indent2$att: $val;\n" if defined $att && defined $val;
      }

    $css_txt .= "$indent}\n";
    $css .= $css_txt if $done > 0;			# skip if no attributes at all
    }
  $css;
  }

sub _skip
  {
  # return a regexp that specifies which attributes to suppress in CSS
  my ($self) = shift;

  # skip these for CSS
  qr/^(basename|columns|colorscheme|comment|class|flow|format|group|rows|root|size|offset|origin|linkbase|(auto)?(label|link|title)|auto(join|split)|(node|edge)class|shape|arrowstyle|label(color|pos)|point(style|shape)|textstyle|style)\z/;
  }

#############################################################################
# These routines are used by as_html for the generation of CSS

sub _remap_text_wrap
  {
  my ($self,$name,$style) = @_;

  return (undef,undef) if $style ne 'auto';

  # make text wrap again
  ('white-space','normal');
  }

sub _remap_fill
  {
  my ($self,$name,$color,$class) = @_;

  return ('background',$color) unless $class =~ /edge/;

  # for edges, the fill is ignored
  (undef,undef);
  }

#############################################################################

sub css
  {
  my $self = shift;

  my $a = $self->{att};
  my $id = $self->{id};

  # for each primary class (node/group/edge) we need to find all subclasses,
  # and list them in the CSS, too. Otherwise "node_city" would not inherit
  # the attributes from "node".

  my $css = $self->_class_styles( $self->_skip(),
    {
      fill => \&_remap_fill,
      textwrap => \&_remap_text_wrap,
      align => 'text-align',
      font => 'font-family',
      fontsize => 'font-size',
      bordercolor => 'border-color',
      borderstyle => 'border-style',
      borderwidth => 'border-width',
    },
    undef,
    undef, 
    $html_att,
    );

  my @groups = $self->groups();

  # Set attributes for all TDs that start with "group":
  $css .= <<CSS
table.graph##id## td[class|="group"] { padding: 0.2em; }
CSS
  if @groups > 0;

  $css .= <<CSS
table.graph##id## td {
  padding: 2px;
  background: inherit;
  white-space: nowrap;
  }
table.graph##id## span.l { float: left; }
table.graph##id## span.r { float: right; }
CSS
;

  # append CSS for edge cells (and their parts like va (vertical arrow
  # (left/right), vertical empty), etc)

  # eb	- empty bottom or arrow pointing down/up
  # el  - (vertical) empty left space of ver edge
  #       or empty vertical space on hor edge starts
  # lh  - edge label horizontal
  # le  - edge label, but empty (no label)
  # lv  - edge label vertical
  # sh  - shifted arrow horizontal (shift right)
  # sa  - shifted arrow horizontal (shift left for corners)
  # shl - shifted arrow horizontal (shift left)
  # sv  - shifted arrow vertical (pointing down)
  # su  - shifted arrow vertical (pointing up)

  $css .= <<CSS
table.graph##id## .va {
  vertical-align: middle;
  line-height: 1em;
  width: 0.4em;
  }
table.graph##id## .el {
  width: 0.1em;
  max-width: 0.1em;
  min-width: 0.1em;
  }
table.graph##id## .lh, table.graph##id## .lv {
  font-size: 0.8em;
  padding-left: 0.4em;
  }
table.graph##id## .sv, table.graph##id## .sh, table.graph##id## .shl, table.graph##id## .sa, table.graph##id## .su {
  max-height: 1em;
  line-height: 1em;
  position: relative;
  top: 0.55em;
  left: -0.3em;
  overflow: visible;
  }
table.graph##id## .sv, table.graph##id## .su {
  max-height: 0.5em;
  line-height: 0.5em;
  }
table.graph##id## .shl { left: 0.3em; }
table.graph##id## .sv { left: -0.5em; top: -0.4em; }
table.graph##id## .su { left: -0.5em; top: 0.4em; }
table.graph##id## .sa { left: -0.3em; top: 0; }
table.graph##id## .eb { max-height: 0; line-height: 0; height: 0; }
CSS
  # if we have edges
  if keys %{$self->{edges}}  > 0;

  # if we have nodes with rounded shapes:
  my $rounded = 0;
  for my $n (values %{$self->{nodes}})
    {
    $rounded ++ and last if $n->shape() =~ /circle|ellipse|rounded/;
    }

  $css .= <<CSS
table.graph##id## span.c { position: relative; top: 1.5em; }
table.graph##id## div.c { -moz-border-radius: 100%; border-radius: 100%; }
table.graph##id## div.r { -moz-border-radius: 1em; border-radius: 1em; }
CSS
  if $rounded > 0;

  # append CSS for group cells (only if we actually have groups)

  if (@groups > 0)
    {
    foreach my $group (@groups)
      {
      my $class = $group->class();

      my $border = $group->attribute('borderstyle'); 

      $class =~ s/.*\.//;	# leave only subclass
      $css .= Graph::Easy::Group::Cell->_css($self->{id}, $class, $border); 
      }
    }

  # replace the id with either '' or '123', depending on our ID
  $css =~ s/##id##/$id/g;

  $css;
  }

sub html_page_header
  {
  # return the HTML header for as_html_file()
  my ($self, $css) = @_;
  
  my $html = <<HTML
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
 <head>
 <meta http-equiv="Content-Type" content="text/html; charset=##charset##">
 <title>##title##</title>##CSS##
</head>
<body bgcolor=white text=black>
HTML
;

  $html =~ s/\n\z//;
  $html =~ s/##charset##/utf-8/g;
  my $t = $self->title();
  $html =~ s/##title##/$t/g;

  # insert CSS if requested
  $css = $self->css() unless defined $css;

  $html =~ s/##CSS##/\n <style type="text\/css">\n <!--\n $css -->\n <\/style>/ if $css ne '';
  $html =~ s/##CSS##//;

  $html;
  }

sub title
  {
  my $self = shift;

  my $title = $self->{att}->{graph}->{title};
  $title = $self->{att}->{graph}->{label} if !defined $title;
  $title = 'Untitled graph' if !defined $title;

  $title = $self->_un_escape($title, 1) if !$_[0] && $title =~ /\\[EGHNTL]/;
  $title;
  }

sub html_page_footer
  {
  # return the HTML footer for as_html_file()
  my $self = shift;

  "\n</body></html>\n";
  }

sub as_html_file
  {
  my $self = shift;

  $self->html_page_header() . $self->as_html() . $self->html_page_footer();
  }

#############################################################################

sub _caption
  {
  # create the graph label as caption
  my $self = shift;

  my ($caption,$switch_to_center) = $self->_label_as_html();

  return ('','') unless defined $caption && $caption ne '';

  my $bg = $self->raw_color_attribute('fill');

  my $style = ' style="';
  $style .= "background: $bg;" if $bg;
    
  # the font family
  my $f = $self->raw_attribute('font') || '';
  $style .= "font-family: $f;" if $f ne '';

  # the text color
  my $c = $self->raw_color_attribute('color');
  $style .= "color: $c;" if $c;

  # bold, italic, underline, incl. fontsize and align
  $style .= $self->text_styles_as_css();

  $style =~ s/;\z//;				# remove last ';'
  $style .= '"' unless $style eq ' style="';

  $style =~ s/style="\s/style="/;		# remove leading space

  my $link = $self->link();

  if ($link ne '')
    {
    # encode critical entities
    $link =~ s/\s/\+/g;				# space
    $link =~ s/'/%27/g;				# replace quotation marks
    $caption = "<a href='$link'>$caption</a>";
    }

  $caption = "<tr>\n  <td colspan=##cols##$style>$caption</td>\n</tr>\n";

  my $pos = $self->attribute('labelpos');

  ($caption,$pos);
  } 

sub as_html
  {
  # convert the graph to HTML+CSS
  my ($self) = shift;

  $self->layout() unless defined $self->{score};

  my $top = "\n" . $self->quoted_comment();
  
  my $cells = $self->{cells};
  my ($rows,$cols);
  
  my $max_x = undef;
  my $min_x = undef;

  # find all x and y occurances to sort them by row/columns
  for my $k (keys %$cells)
    {
    my ($x,$y) = split/,/, $k;
    my $node = $cells->{$k};

    $max_x = $x if !defined $max_x || $x > $max_x;
    $min_x = $x if !defined $min_x || $x < $min_x;
    
    # trace the rows we do have
    $rows->{$y}->{$x} = $node;
    # record all possible columns
    $cols->{$x} = undef;
    }
  
  $max_x = 1, $min_x = 1 unless defined $max_x;
  
  # number of cells in the table, maximum  
  my $max_cells = $max_x - $min_x + 1;
  
  my $groups = scalar $self->groups();

  my $id = $self->{id};

  $top .=  "\n<table class=\"graph$id\" cellpadding=0 cellspacing=0";
  $top .= ">\n";

  my $html = '';

  # prepare the graph label
  my ($caption,$pos) = $self->_caption();

  my $row_id = 0;
  # now run through all rows, and for each of them through all columns 
  for my $y (sort { ($a||0) <=> ($b||0) } keys %$rows)
    {

    # four rows at a time
    my $rs = [ [], [], [], [] ];

    # for all possible columns
    for my $x (sort { $a <=> $b } keys %$cols)
      {
      if (!exists $rows->{$y}->{$x})
	{
	# fill empty spaces with undef, but not for parts of multicelled objects:
	push @{$rs->[0]}, undef;
	next;
	}
      my $node = $rows->{$y}->{$x};
      next if $node->isa('Graph::Easy::Node::Cell');		# skip empty cells

      my $h = $node->as_html();

      if (ref($h) eq 'ARRAY')
        {
        #print STDERR '# expected 4 rows, but got ' . scalar @$h if @$h != 4;
        local $_; my $i = 0;
        push @{$rs->[$i++]}, $_ for @$h;
        }
      else
        {
        push @{$rs->[0]}, $h;
        }
      }

    ######################################################################
    # remove trailing empty tag-pairs, then replace undef with empty tags

    for my $row (@$rs)
      {
      pop @$row while (@$row > 0 && !defined $row->[-1]);
      local $_;
      foreach (@$row)
        {
        $_ = " <td colspan=4 rowspan=4></td>\n" unless defined $_;
        }
      }

    # now combine equal columns to shorten output
    for my $row (@$rs)
      {
      next;

      # append row to output
      my $i = 0;
      while ($i < @$row)
        {
        next if $row->[$i] =~ /border(:|-left)/;
#        next if $row->[$i] !~ />(\&nbsp;)?</;	# non-empty?
#        next if $row->[$i] =~ /span /;		# non-empty?
#        next if $row->[$i] =~ /^(\s|\n)*\z/;	# empty?

	# Combining these cells shows wierd artefacts when using the Firefox
	# WebDeveloper toolbar and outlining table cells, but it does not
	# seem to harm rendering in browsers:
        #next if $row->[$i] =~ /class="[^"]+ eb"/;	# is class=".. eb"

	# contains wo succ. cell?
        next if $row->[$i] =~ /(row|col)span.*\1span/m;	

        # count all sucessive equal ones
        my $j = $i + 1;

        $j++ while ($j < @$row && $row->[$j] eq $row->[$i]); # { $j++; }

        if ($j > $i + 1)
          {
          my $cnt = $j - $i - 1;

#         print STDERR "combining row $i to $j ($cnt) (\n'$row->[$i]'\n'$row->[$i+1]'\n'$row->[$j-1]'\n";

          # throw away
          splice (@$row, $i + 1, $cnt);

          # insert empty colspan if not already there
          $row->[$i] =~ s/<td/<td colspan=0/ unless $row->[$i] =~ /colspan/;
          # replace
          $row->[$i] =~ s/colspan=(\d+)/'colspan='.($1+$cnt*4)/e;
          }
        } continue { $i++; }
      }

    ######################################################################

    my $i = 0;    
    for my $row (@$rs)
      {
      # append row to output
      my $r = join('',@$row);

      if ($r !~ s/^[\s\n]*\z//)
	{
        # non empty rows get "\n</tr>"
        $r = "\n" . $r; # if length($r) > 0;
        }

      $html .= "<!-- row $row_id line $i -->\n" . '<tr>' . $r . "</tr>\n\n";
      $i++;
      }
    $row_id++;
    }

  ###########################################################################
  # finally insert the graph label
  $max_cells *= 4;					# 4 rows for each cell
  $caption =~ s/##cols##/$max_cells/ if defined $caption;

  $html .= $caption if $pos eq 'bottom';
  $top .= $caption if $pos eq 'top';

  $html = $top . $html;

  # remove empty trailing <tr></tr> pairs
  $html =~ s#(<tr></tr>\n\n)+\z##;

  $html .= "</table>\n";
 
  $html;
  } 

############################################################################# 
# as_boxart_*
  
sub as_boxart
  {
  # Create box-drawing art using Unicode characters - will return utf-8.
  my ($self) = shift;

  require Graph::Easy::As_ascii;
  
  # select Unicode box drawing characters
  $self->{_ascii_style} = 1;

  $self->_as_ascii(@_);
  }

sub as_boxart_html
  {
  # Output a box-drawing using Unicode, then return it as a HTML chunk
  # suitable to be embedded into an HTML page.
  my ($self) = shift;

  "<pre style='line-height: 1em; line-spacing: 0;'>\n" . 
    $self->as_boxart(@_) . 
    "\n</pre>\n";
  }

sub as_boxart_html_file
  {
  my $self = shift;

  $self->layout() unless defined $self->{score};

  $self->html_page_header(' ') . "\n" . 
    $self->as_boxart_html() . $self->html_page_footer();
  }

#############################################################################
# as_ascii_*

sub as_ascii
  {
  # Convert the graph to pretty ASCII art - will return utf-8.
  my $self = shift;

  # select 'ascii' characters
  $self->{_ascii_style} = 0;

  $self->_as_ascii(@_);
  }

sub _as_ascii
  {
  # Convert the graph to pretty ASCII or box art art - will return utf-8.
  my $self = shift;

  require Graph::Easy::As_ascii;
  require Graph::Easy::Layout::Grid;

  my $opt = ref($_[0]) eq 'HASH' ? $_[0] : { @_ };

  # include links?
  $self->{_links} = $opt->{links};

  $self->layout() unless defined $self->{score};

  # generate for each cell the width/height etc

  my ($rows,$cols,$max_x,$max_y) = $self->_prepare_layout('ascii');
  my $cells = $self->{cells};

  # offset where to draw the graph (non-zero if graph has label)
  my $y_start = 0;
  my $x_start = 0;

  my $align = $self->attribute('align');

  # get the label lines and their alignment
  my ($label,$aligns) = $self->_aligned_label($align);

  # if the graph has a label, reserve space for it
  my $label_pos = 'top';
  if (@$label > 0)
    {
    # insert one line over and below
    unshift @$label, '';   push @$label, '';
    unshift @$aligns, 'c'; push @$aligns, 'c';

    $label_pos = $self->attribute('graph','label-pos') || 'top';
    $y_start += scalar @$label if $label_pos eq 'top';
    $max_y += scalar @$label + 1;
    print STDERR "# Graph with label, position $label_pos\n" if $self->{debug};

    my $old_max_x = $max_x;
    # find out the dimensions of the label and make sure max_x is big enough
    for my $l (@$label)
      {
      $max_x = length($l)+2 if (length($l) > $max_x+2);
      }
    $x_start = int(($max_x - $old_max_x) / 2);
    }

  print STDERR "# Allocating framebuffer $max_x x $max_y\n" if $self->{debug};

  # generate the actual framebuffer for the output
  my $fb = Graph::Easy::Node->_framebuffer($max_x, $max_y);

  # output the label
  if (@$label > 0)
    {
    my $y = 0; $y = $max_y - scalar @$label if $label_pos eq 'bottom';
    Graph::Easy::Node->_printfb_aligned($fb, 0, $y, $max_x, $max_y, $label, $aligns, 'top');
    }

  # draw all cells into framebuffer
  foreach my $v (values %$cells)
    {
    next if $v->isa('Graph::Easy::Node::Cell');		# skip empty cells

    # get as ASCII box
    my $x = $cols->{ $v->{x} } + $x_start;
    my $y = $rows->{ $v->{y} } + $y_start;
 
    my @lines = split /\n/, $v->as_ascii($x,$y);
    # get position from cell
    for my $i (0 .. scalar @lines-1)
      {
      next if length($lines[$i]) == 0;
      # XXX TODO: framebuffer shouldn't be to small!
      $fb->[$y+$i] = ' ' x $max_x if !defined $fb->[$y+$i];
      substr($fb->[$y+$i], $x, length($lines[$i])) = $lines[$i]; 
      }
    }

  for my $y (0..$max_y)
    {
    $fb->[$y] = '' unless defined $fb->[$y];
    $fb->[$y] =~ s/\s+\z//;		# remove trailing whitespace
    }
  my $out = join("\n", @$fb) . "\n";

  $out =~ s/\n+\z/\n/;		# remove trailing empty lines

  # restore height/width of cells from minw/minh
  foreach my $v (values %$cells)
    {
    $v->{h} = $v->{minh};
    $v->{w} = $v->{minw};
    } 
  $out;				# return output
  }

sub as_ascii_html
  {
  # Convert the graph to pretty ASCII art, then return it as a HTML chunk
  # suitable to be embedded into an HTML page.
  my ($self) = shift;

  "<pre>\n" . $self->_as_ascii(@_) . "\n</pre>\n";
  }

#############################################################################
# as_txt, as_debug, as_graphviz

sub as_txt
  {
  require Graph::Easy::As_txt;

  _as_txt(@_);
  }

sub as_graphviz
  {
  require Graph::Easy::As_graphviz;

  _as_graphviz(@_);
  }

sub as_debug
  {
  require Graph::Easy::As_txt;
  eval { require Graph::Easy::As_svg; };

  my $self = shift;

  my $output = '';
 
  $output .= '# Using Graph::Easy v' . $Graph::Easy::VERSION . "\n";
  if ($Graph::Easy::As_svg::VERSION)
    {
    $output .= '# Using Graph::Easy::As_svg v' . $Graph::Easy::As_svg::VERSION . "\n";
    }
  $output .= '# Running Perl v' . $] . " under $^O\n";

  $output . "\n# Input normalized as_txt:\n\n" . $self->_as_txt(@_);
  }

#############################################################################
# as_vcg(as_gdl

sub as_vcg
  {
  require Graph::Easy::As_vcg;

  _as_vcg(@_);
  }

sub as_gdl
  {
  require Graph::Easy::As_vcg;

  _as_vcg(@_, { gdl => 1 });
  }

#############################################################################
# as_svg

sub as_svg
  {
  require Graph::Easy::As_svg;
  require Graph::Easy::Layout::Grid;

  _as_svg(@_);
  }

sub as_svg_file
  {
  require Graph::Easy::As_svg;
  require Graph::Easy::Layout::Grid;

  _as_svg( $_[0], { standalone => 1 } );
  }

sub svg_information
  {
  my ($self) = @_;

  require Graph::Easy::As_svg;
  require Graph::Easy::Layout::Grid;

  # if it doesn't exist, render as SVG and thus create it
  _as_svg(@_) unless $self->{svg_info};

  $self->{svg_info};
  }

#############################################################################
# as_graphml

sub as_graphml
  {
  require Graph::Easy::As_graphml;

  _as_graphml(@_);
  }

#############################################################################

sub add_edge
  {
  my ($self,$x,$y,$edge) = @_;
 
  my $uc = $self->{use_class};

  my $ec = $uc->{edge};
  $edge = $ec->new() unless defined $edge;
  $edge = $ec->new(label => $edge) unless ref($edge);

  $self->_croak("Adding an edge object twice is not possible")
    if (exists ($self->{edges}->{$edge->{id}}));

  $self->_croak("Cannot add edge $edge ($edge->{id}), it already belongs to another graph")
    if ref($edge->{graph}) && $edge->{graph} != $self;

  my $nodes = $self->{nodes};
  my $groups = $self->{groups};

  $self->_croak("Cannot add edge for undefined node names ($x -> $y)")
    unless defined $x && defined $y;

  my $xn = $x; my $yn = $y;
  $xn = $x->{name} if ref($x);
  $yn = $y->{name} if ref($y);

  # convert plain scalars to Node objects if nec.

  # XXX TODO: this might be a problem when adding an edge from a group with the same
  #           name as a node

  $x = $nodes->{$xn} if exists $nodes->{$xn};		# first look them up
  $y = $nodes->{$yn} if exists $nodes->{$yn};

  $x = $uc->{node}->new( $x ) unless ref $x;		# if this fails, create
  $y = $x if !ref($y) && $y eq $xn;			# make add_edge('A','A') work
  $y = $uc->{node}->new( $y ) unless ref $y;

  print STDERR "# add_edge '$x->{name}' ($x->{id}) -> '$y->{name}' ($y->{id}) (edge $edge->{id}) ($x -> $y)\n" if $self->{debug};

  for my $n ($x,$y)
    {
    $self->_croak("Cannot add node $n ($n->{name}), it already belongs to another graph")
      if ref($n->{graph}) && $n->{graph} != $self;
    }

  # Register the nodes and the edge with our graph object
  # and weaken the references. Be carefull to not needlessly
  # override and weaken again an already existing reference, this
  # is an O(N) operation in most Perl versions, and thus very slow.

  weaken($x->{graph} = $self) unless ref($x->{graph});
  weaken($y->{graph} = $self) unless ref($y->{graph});
  weaken($edge->{graph} = $self) unless ref($edge->{graph});

  # Store at the edge from where to where it goes for easier reference
  $edge->{from} = $x;
  $edge->{to} = $y;
 
  # store the edge at the nodes/groups, too
  $x->{edges}->{$edge->{id}} = $edge;
  $y->{edges}->{$edge->{id}} = $edge;

  # index nodes by their name so that we can find $x from $x->{name} fast
  my $store = $nodes; $store = $groups if $x->isa('Graph::Easy::Group');
  $store->{$x->{name}} = $x;
  $store = $nodes; $store = $groups if $y->isa('Graph::Easy::Group');
  $store->{$y->{name}} = $y;

  # index edges by "edgeid" so we can find them fast
  $self->{edges}->{$edge->{id}} = $edge;

  $self->{score} = undef;			# invalidate last layout

  wantarray ? ($x,$y,$edge) : $edge;
  }

sub add_anon_node
  {
  my ($self) = shift;

  $self->warn('add_anon_node does not take argumens') if @_ > 0;

  my $node = Graph::Easy::Node::Anon->new();

  $self->add_node($node);

  $node;
  }

sub add_node
  {
  my ($self,$x) = @_;

  my $n = $x;
  if (ref($x))
    {
    $n = $x->{name}; $n = '0' unless defined $n;
    }

  return $self->_croak("Cannot add node with empty name to graph.") if $n eq '';

  return $self->_croak("Cannot add node $x ($n), it already belongs to another graph")
    if ref($x) && ref($x->{graph}) && $x->{graph} != $self;

  my $no = $self->{nodes};
  # already exists?
  return $no->{$n} if exists $no->{$n};

  my $uc = $self->{use_class};
  $x = $uc->{node}->new( $x ) unless ref $x;

  # store the node
  $no->{$n} = $x;

  # Register the nodes and the edge with our graph object
  # and weaken the references. Be carefull to not needlessly
  # override and weaken again an already existing reference, this
  # is an O(N) operation in most Perl versions, and thus very slow.

  weaken($x->{graph} = $self) unless ref($x->{graph});

  $self->{score} = undef;			# invalidate last layout

  $x;
  }

sub add_nodes
  {
  my $self = shift;

  my @rc;
  for my $x (@_)
    {
    my $n = $x;
    if (ref($x))
      {
      $n = $x->{name}; $n = '0' unless defined $n;
      }

    return $self->_croak("Cannot add node with empty name to graph.") if $n eq '';

    return $self->_croak("Cannot add node $x ($n), it already belongs to another graph")
      if ref($x) && ref($x->{graph}) && $x->{graph} != $self;

    my $no = $self->{nodes};
    # this one already exists
    next if exists $no->{$n};

    my $uc = $self->{use_class};
    # make it work with read-only scalars:
    my $xx = $x;
    $xx = $uc->{node}->new( $x ) unless ref $x;

    # store the node
    $no->{$n} = $xx;

    # Register the nodes and the edge with our graph object
    # and weaken the references. Be carefull to not needlessly
    # override and weaken again an already existing reference, this
    # is an O(N) operation in most Perl versions, and thus very slow.

    weaken($xx->{graph} = $self) unless ref($xx->{graph});

    push @rc, $xx;
    }

  $self->{score} = undef;			# invalidate last layout

  @rc;
  }

#############################################################################
#############################################################################
# Cloning/merging of graphs and objects

sub copy
  {
  # create a copy of this graph and return it as new graph
  my $self = shift;

  my $new = Graph::Easy->new();

  # clone all the settings
  for my $k (keys %$self)
    {
    $new->{$k} = $self->{$k} unless ref($self->{$k});
    }

  for my $g (keys %{$self->{groups}})
    {
    my $ng = $new->add_group($g);
    # clone the attributes
    $ng->{att} = $self->_clone( $self->{groups}->{$g}->{att} );
    }
  for my $n (values %{$self->{nodes}})
    {
    my $nn = $new->add_node($n->{name});
    # clone the attributes
    $nn->{att} = $self->_clone( $n->{att} );
    # restore group membership for the node
    $nn->add_to_group( $n->{group}->{name} ) if $n->{group};
    }
  for my $e (values %{$self->{edges}})
    {
    my $ne = $new->add_edge($e->{from}->{name}, $e->{to}->{name} );
    # clone the attributes
    $ne->{att} = $self->_clone( $e->{att} );
    }
  # clone the attributes
  $new->{att} = $self->_clone( $self->{att});

  $new;
  }

sub _clone
  {
  # recursively clone a data structure
  my ($self,$in) = @_;

  my $out = { };

  for my $k (keys %$in)
    {
    if (ref($k) eq 'HASH')
      {
      $out->{$k} = $self->_clone($in->{$k});
      }
    elsif (ref($k))
      {
      $self->error("Can't clone $k");
      }
    else
      {
      $out->{$k} = $in->{$k};
      }
    }
  $out;
  }

sub merge_nodes
  {
  # Merge two nodes, by dropping all connections between them, and then
  # drawing all connections from/to $B to $A, then drop $B
  my ($self, $A, $B, $joiner) = @_;

  $A = $self->node($A) unless ref($A);
  $B = $self->node($B) unless ref($B);

  # if the node is part of a group, deregister it first from there
  $B->{group}->del_node($B) if ref($B->{group});

  my @edges = values %{$A->{edges}};

  # drop all connections from A --> B
  for my $edge (@edges)
    {
    next unless $edge->{to} == $B;

#    print STDERR "# dropping $edge->{from}->{name} --> $edge->{to}->{name}\n";
    $self->del_edge($edge);
    }

  # Move all edges from/to B over to A, but drop "B --> B" and "B --> A".
  for my $edge (values %{$B->{edges}})
    {
    # skip if going from B --> A or B --> B
    next if $edge->{to} == $A || ($edge->{to} == $B && $edge->{from} == $B);

#    print STDERR "# moving $edge->{from}->{name} --> $edge->{to}->{name} to ";

    $edge->{from} = $A if $edge->{from} == $B;
    $edge->{to} = $A if $edge->{to} == $B;

#   print STDERR " $edge->{from}->{name} --> $edge->{to}->{name}\n";

    delete $B->{edges}->{$edge->{id}};
    $A->{edges}->{$edge->{id}} = $edge;
    }

  # should we join the label from B to A?
  $A->set_attribute('label', $A->label() . $joiner . $B->label() ) if defined $joiner;

  $self->del_node($B);

  $self;
  }

#############################################################################
# deletion

sub del_node
  {
  my ($self, $node) = @_;

  # make object
  $node = $self->{nodes}->{$node} unless ref($node);

  # doesn't exist, so we don't need to do anything
  return unless ref($node);

  # if node is part of a group, delete it there, too
  $node->{group}->del_node($node) if ref $node->{group};

  delete $self->{nodes}->{$node->{name}};

  # delete all edges from/to this node
  for my $edge (values %{$node->{edges}})
    {
    # drop the edge from our global edge list
    delete $self->{edges}->{$edge->{id}};
 
    my $to = $edge->{to}; my $from = $edge->{from};

    # drop the edge from the other node
    delete $from->{edges}->{$edge->{id}} if $from != $node;
    delete $to->{edges}->{$edge->{id}} if $to != $node;
    }

  # decouple node from the graph
  $node->{graph} = undef;
  # reset cached size
  $node->{w} = undef;

  # drop all edges from the node locally
  $node->{edges} = { };

  # if the node is a child of another node, deregister it there
  delete $node->{origin}->{children}->{$node->{id}} if defined $node->{origin};

  $self->{score} = undef;			# invalidate last layout

  $self;
  }

sub del_edge
  {
  my ($self, $edge) = @_;

  $self->_croak("del_edge() needs an object") unless ref $edge;

  # if edge is part of a group, delete it there, too
  $edge->{group}->_del_edge($edge) if ref $edge->{group};

  my $to = $edge->{to}; my $from = $edge->{from};

  # delete the edge from the nodes
  delete $from->{edges}->{$edge->{id}};
  delete $to->{edges}->{$edge->{id}};
  
  # drop the edge from our global edge list
  delete $self->{edges}->{$edge->{id}};

  $edge->{from} = undef;
  $edge->{to} = undef;

  $self;
  }

#############################################################################
# group management

sub add_group
  {
  # add a group object
  my ($self,$group) = @_;

  my $uc = $self->{use_class};

  # group with that name already exists?
  my $name = $group; 
  $group = $self->{groups}->{ $group } unless ref $group;

  # group with that name doesn't exist, so create new one
  $group = $uc->{group}->new( name => $name ) unless ref $group;

  # index under the group name for easier lookup
  $self->{groups}->{ $group->{name} } = $group;

  # register group with ourself and weaken the reference
  $group->{graph} = $self;
  {
    no warnings; # dont warn on already weak references
    weaken($group->{graph});
  } 
  $self->{score} = undef;			# invalidate last layout

  $group;
  }

sub del_group
  {
  # delete group
  my ($self,$group) = @_;

  delete $self->{groups}->{ $group->{name} };
 
  $self->{score} = undef;			# invalidate last layout

  $self;
  }

sub group
  {
  # return group by name
  my ($self,$name) = @_;

  $self->{groups}->{ $name };
  }

sub groups
  {
  # return number of groups (or groups as object list)
  my ($self) = @_;

  return sort { $a->{name} cmp $b->{name} } values %{$self->{groups}}
    if wantarray;

  scalar keys %{$self->{groups}};
  }

sub groups_within
  {
  # Return the groups that are directly inside this graph/group. The optional
  # level is either -1 (meaning return all groups contained within), or a
  # positive number indicating how many levels down we need to go.
  my ($self, $level) = @_;

  $level = -1 if !defined $level || $level < 0;

  # inline call to $self->groups;
  if ($level == -1)
    {
    return sort { $a->{name} cmp $b->{name} } values %{$self->{groups}}
      if wantarray;

    return scalar keys %{$self->{groups}};
    }

  my $are_graph = $self->{graph} ? 0 : 1;

  # get the groups at level 0
  my $current = 0;
  my @todo;
  for my $g (values %{$self->{groups}})
    {
    # no group set => belongs to graph, set to ourself => belongs to ourself
    push @todo, $g if ( ($are_graph && !defined $g->{group}) || $g->{group} == $self);
    }

  if ($level == 0)
    {
    return wantarray ? @todo : scalar @todo;
    }

  # we need to recursively count groups until the wanted level is reached
  my @cur = @todo;
  for my $g (@todo)
    {
    # _groups_within() is defined in Graph::Easy::Group
    $g->_groups_within(1, $level, \@cur);
    }

  wantarray ? @cur : scalar @cur;
  }

sub anon_groups
  {
  # return all anon groups as objects
  my ($self) = @_;

  my $n = $self->{groups};

  if (!wantarray)
    {
    my $count = 0;
    for my $group (values %$n)
      {
      $count++ if $group->is_anon();
      }
    return $count;
    }

  my @anon = ();
  for my $group (values %$n)
    {
    push @anon, $group if $group->is_anon();
    }
  @anon;
  }

sub use_class
  {
  # use the provided class for generating objects of the type $object
  my ($self, $object, $class) = @_;

  $self->_croak("Expected one of node, edge or group, but got $object")
    unless $object =~ /^(node|group|edge)\z/;

  $self->{use_class}->{$object} = $class;

  $self;  
  }

#############################################################################
#############################################################################
# Support for Graph interface to make Graph::Maker happy:

sub add_vertex
  {
  my ($self,$x) = @_;
  
  $self->add_node($x);
  $self;
  }

sub add_vertices
  {
  my ($self) = shift;
  
  $self->add_nodes(@_);
  $self;
  }

sub add_path
  {
  my ($self) = shift;

  my $first = shift;

  while (@_)
    {
    my $second = shift;
    $self->add_edge($first, $second );
    $first = $second; 
    }
  $self;
  }

sub add_cycle
  {
  my ($self) = shift;

  my $first = shift; my $a = $first;

  while (@_)
    {
    my $second = shift;
    $self->add_edge($first, $second );
    $first = $second; 
    }
  # complete the cycle
  $self->add_edge($first, $a);
  $self;
  }

sub has_edge
  {
  # return true if at least one edge between X and Y exists
  my ($self, $x, $y) = @_;

  # turn plaintext scalars into objects 
  $x = $self->{nodes}->{$x} unless ref $x;
  $y = $self->{nodes}->{$y} unless ref $y;

  # node does not exist => edge does not exist
  return 0 unless ref($x) && ref($y);

  scalar $x->edges_to($y) ? 1 : 0;
  }

sub set_vertex_attribute
  {
  my ($self, $node, $name, $value) = @_;

  $node = $self->add_node($node);
  $node->set_attribute($name,$value);

  $self;
  }

sub get_vertex_attribute
  {
  my ($self, $node, $name) = @_;

  $self->node($node)->get_attribute($name);
  }

#############################################################################
#############################################################################
# Animation support

sub animation_as_graph
  {
  my $self = shift;

  my $graph = Graph::Easy->new();

  $graph->add_node('onload');

  # XXX TODO

  $graph;
  }

1;
__END__

=pod

=encoding utf-8

=head1 NAME

Graph::Easy - Convert or render graphs (as ASCII, HTML, SVG or via Graphviz)

=head1 SYNOPSIS

	use Graph::Easy;
	
	my $graph = Graph::Easy->new();

	# make a fresh copy of the graph
	my $new_graph = $graph->copy();

	$graph->add_edge ('Bonn', 'Berlin');

	# will not add it, since it already exists
	$graph->add_edge_once ('Bonn', 'Berlin');

	print $graph->as_ascii( ); 		# prints:

	# +------+     +--------+
	# | Bonn | --> | Berlin |
	# +------+     +--------+

	#####################################################
	# alternatively, let Graph::Easy parse some text:

	my $graph = Graph::Easy->new( '[Bonn] -> [Berlin]' );

	#####################################################
	# slightly more verbose way:

	my $graph = Graph::Easy->new();

	my $bonn = $graph->add_node('Bonn');
	$bonn->set_attribute('border', 'solid 1px black');

	my $berlin = $graph->add_node('Berlin');

	$graph->add_edge ($bonn, $berlin);

	print $graph->as_ascii( );

	# You can use plain scalars as node names and for the edge label:
	$graph->add_edge ('Berlin', 'Frankfurt', 'via train');

	# adding edges with attributes:

	my $edge = Graph::Easy::Edge->new();
	$edge->set_attributes( {
		label => 'train',
		style => 'dotted',
		color => 'red',
	} );

	# now with the optional edge object
	$graph->add_edge ($bonn, $berlin, $edge);

	# raw HTML section
	print $graph->as_html( );

	# complete HTML page (with CSS)
	print $graph->as_html_file( );

	# Other possibilities:

	# SVG (possible after you installed Graph::Easy::As_svg):
	print $graph->as_svg( );

	# Graphviz:
	my $graphviz = $graph->as_graphviz();
	open $DOT, '|dot -Tpng -o graph.png' or die ("Cannot open pipe to dot: $!");
	print $DOT $graphviz;
	close $DOT;

	# Please see also the command line utility 'graph-easy'

=head1 DESCRIPTION

C<Graph::Easy> lets you generate graphs consisting of various shaped
nodes connected by edges (with optional labels).

It can read and write graphs in a varity of formats, as well as render
them via its own grid-based layouter.

Since the layouter works on a grid (manhattan layout), the output is
most useful for flow charts, network diagrams, or hierarchy trees.

X<graph>
X<drawing>
X<diagram>
X<flowchart>
X<layout>
X<manhattan>

=head2 Input

Apart from driving the module with Perl code, you can also use
C<Graph::Easy::Parser> to parse graph descriptions like:

	[ Bonn ]      --> [ Berlin ]
	[ Frankfurt ] <=> [ Dresden ]
	[ Bonn ]      --  [ Frankfurt ]

See the C<EXAMPLES> section below for how this might be rendered.

=head2 Creating graphs

First, create a graph object:

	my $graph = Graph::Easy->new();

Then add a node to it:

	my $node = $graph->add_node('Koblenz');

Don't worry, adding the node again will do nothing:

	$node = $graph->add_node('Koblenz');

You can get back a node by its name with C<node()>:

	$node = $graph->node('Koblenz');

You can either add another node:

	my $second = $graph->node('Frankfurt');

Or add an edge straight-away:

	my ($first,$second,$edge) = $graph->add_edge('Mainz','Ulm');

Adding the edge the second time creates another edge from 'Mainz' to 'Ulm':

	my $other_edge;
	 ($first,$second,$other_edge) = $graph->add_edge('Mainz','Ulm');

This can be avoided by using C<add_edge_once()>:

	my $edge = $graph->add_edge_once('Mainz','Ulm');
	if (defined $edge)
	  {
	  # the first time the edge was added, do something with it
	  $edge->set_attribute('color','blue');
	  }

You can set attributes on nodes and edges:

	$node->attribute('fill', 'yellow');
	$edge->attribute('label', 'train');

It is possible to add an edge with a label:

	$graph->add_edge('Cottbus', 'Berlin', 'my label');

You can also add self-loops:

	$graph->add_edge('Bremen','Bremen');

Adding multiple nodes is easy:

	my ($bonn,$rom) = Graph::Easy->add_nodes('Bonn','Rom');

You can also have subgraphs (these are called groups):

	my ($group) = Graph::Easy->add_group('Cities');

Only nodes can be part of a group, edges are automatically considered
to be in the group if they lead from one node inside the group to
another node in the same group. There are multiple ways to add one or
more nodes into a group:

	$group->add_member($bonn);
	$group->add_node($rom);
	$group->add_nodes($rom,$bonn);

For more options please see the online manual: 
L<http://bloodgate.com/perl/graph/manual/> .

=head2 Output

The output can be done in various styles:

=over 2

=item ASCII ART

Uses things like C<+>, C<-> C<< < >> and C<|> to render the boxes.

=item BOXART

Uses Unicode box art drawing elements to output the graph.

=item HTML

HTML tables with CSS making everything "pretty".

=item SVG

Creates a Scalable Vector Graphics output.

=item Graphviz

Creates graphviz code that can be feed to 'dot', 'neato' or similar programs.

=item GraphML

Creates a textual description of the graph in the GraphML format.

=item GDL/VCG

Creates a textual description of the graph in the VCG or GDL (Graph
Description Language) format.

=back

X<ascii>
X<html>
X<svg>
X<boxart>
X<graphviz>
X<dot>
X<neato>

=head1 EXAMPLES

The following examples are given in the simple text format that is understood
by L<Graph::Easy::Parser|Graph::Easy::Parser>.

You can also see many more examples at:

L<http://bloodgate.com/perl/graph/>

=head2 One node

The most simple graph (apart from the empty one :) is a graph consisting of
only one node:

	[ Dresden ]

=head2 Two nodes

A simple graph consisting of two nodes, linked together by a directed edge:

	[ Bonn ] -> [ Berlin ]

=head2 Three nodes

A graph consisting of three nodes, and both are linked from the first:

	[ Bonn ] -> [ Berlin ]
	[ Bonn ] -> [ Hamburg ]

=head2 Three nodes in a chain

A graph consisting of three nodes, showing that you can chain connections together:

	[ Bonn ] -> [ Berlin ] -> [ Hamburg ]

=head2 Two not connected graphs

A graph consisting of two separate parts, both of them not connected
to each other:

	[ Bonn ] -> [ Berlin ]
	[ Freiburg ] -> [ Hamburg ]

=head2 Three nodes, interlinked

A graph consisting of three nodes, and two of the are connected from
the first node:

	[ Bonn ] -> [ Berlin ]
	[ Berlin ] -> [ Hamburg ]
	[ Bonn ] -> [ Hamburg ]

=head2 Different edge styles

A graph consisting of a couple of nodes, linked with the
different possible edge styles.

	[ Bonn ] <-> [ Berlin ]		# bidirectional
	[ Berlin ] ==> [ Rostock ]	# double
	[ Hamburg ] ..> [ Altona ]	# dotted
	[ Dresden ] - > [ Bautzen ]	# dashed
	[ Leipzig ] ~~> [ Kirchhain ]	# wave
	[ Hof ] .-> [ Chemnitz ]	# dot-dash
	[ Magdeburg ] <=> [ Ulm ]	# bidrectional, double etc
	[ Magdeburg ] -- [ Ulm ]	# arrow-less edge

More examples at: L<http://bloodgate.com/perl/graph/>

=head1 ANIMATION SUPPORT

B<Note: Animations are not yet implemented!>

It is possible to add animations to a graph. This is done by
adding I<steps> via the pseudo-class C<step>:

	step.0 {
	  target: Bonn;		# find object with id=Bonn, or
				# if this fails, the node named
				# "Bonn".
	  animate: fill:	# animate this attribute
	  from: yellow;		# start value (0% of duration)
	  via: red;		# at 50% of the duration
	  to: yellow;		# and 100% of duration
	  wait: 0;		# after triggering, wait so many seconds
	  duration: 5;		# entire time to go from "from" to "to"
	  trigger: onload;	# when to trigger this animation
	  repeat: 2;		# how often to repeat ("2" means two times)
				# also "infinite", then "next" will be ignored
	  next: 1;		# which step to take after repeat is up
	}
	step.1 {
	  from: white;		# set to white
	  to: white;
	  duration: 0.1;	# 100ms
	  next: 0;		# go back to step.0
	}

Here two steps are created, I<0> and I<1> and the animation will
be going like this:

                               0.1s
	                     +-------------------------------+
	                     v                               |
	+--------+  0s   +--------+  5s   +--------+  5s   +--------+
	| onload | ----> | step.0 | ----> | step.0 | ----> | step.1 |
	+--------+       +--------+       +--------+       +--------+

You can generate a a graph with the animation flow via
C<animation_as_graph()>.

=head2 Output

Currently no output formats supports animations yet.

=head1 METHODS

C<Graph::Easy> supports the following methods:

=head2 new()

        use Graph::Easy;

        my $graph = Graph::Easy->new( );
        
Creates a new, empty C<Graph::Easy> object.

Takes optinal a hash reference with a list of options. The following are
valid options:

	debug			if true, enables debug output
	timeout			timeout (in seconds) for the layouter
	fatal_errors		wrong attributes are fatal errors, default: true
	strict			test attribute names for being valid, default: true
	undirected		create an undirected graph, default: false

=head2 copy()

    my $copy = $graph->copy( );

Create a copy of this graph and return it as a new Graph::Easy object.

=head2 error()

	my $error = $graph->error();

Returns the last error or '' for none.
Optionally, takes an error message to be set.

	$graph->error( 'Expected Foo, but found Bar.' );

See L<warn()> on how to catch error messages. See also L<non_fatal_errors()>
on how to turn errors into warnings.

=head2 warn()

	my $warning = $graph->warn();

Returns the last warning or '' for none.
Optionally, takes a warning message to be output to STDERR:

	$graph->warn( 'Expected Foo, but found Bar.' );

If you want to catch warnings from the layouter, enable catching
of warnings or errors:

	$graph->catch_messages(1);

	# Or individually:
	# $graph->catch_warnings(1);
	# $graph->catch_errors(1);

	# something which warns or throws an error:
	...

	if ($graph->error())
	  {
	  my @errors = $graph->errors();
	  }
	if ($graph->warning())
	  {
	  my @warnings = $graph->warnings();
	  }

See L<Graph::Easy::Base> for more details on error/warning message capture.

=head2 add_edge()

	my ($first, $second, $edge) = $graph->add_edge( 'node 1', 'node 2');

=head2 add_edge()

	my ($first, $second, $edge) = $graph->add_edge( 'node 1', 'node 2');
	my $edge = $graph->add_edge( $x, $y, $edge);
	$graph->add_edge( $x, $y);

Add an edge between nodes X and Y. The optional edge object defines
the style of the edge, if not present, a default object will be used.

When called in scalar context, will return C<$edge>. In array/list context
it will return the two nodes and the edge object.

C<$x> and C<$y> should be either plain scalars with the names of
the nodes, or objects of L<Graph::Easy::Node|Graph::Easy::Node>,
while the optional C<$edge> should be L<Graph::Easy::Edge|Graph::Easy::Edge>.

Note: C<Graph::Easy> graphs are multi-edged, and adding the same edge
twice will result in two edges going from C<$x> to C<$y>! See
C<add_edge_once()> on how to avoid that.

You can also use C<edge()> to check whether an edge from X to Y already exists
in the graph.
 
=head2 add_edge_once()

	my ($first, $second, $edge) = $graph->add_edge_once( 'node 1', 'node 2');
	my $edge = $graph->add_edge_once( $x, $y, $edge);
	$graph->add_edge_once( $x, $y);

	if (defined $edge)
	  {
	  # got added once, so do something with it
	  $edge->set_attribute('label','unique');
	  }

Adds an edge between nodes X and Y, unless there exists already
an edge between these two nodes. See C<add_edge()>.

Returns undef when an edge between X and Y already exists.

When called in scalar context, will return C<$edge>. In array/list context
it will return the two nodes and the edge object.

=head2 flip_edges()

	my $graph = Graph::Easy->new();
	$graph->add_edge('Bonn','Berlin');
	$graph->add_edge('Berlin','Bonn');

	print $graph->as_ascii();

	#   +--------------+
	#   v              |
	# +--------+     +------+
	# | Berlin | --> | Bonn |
	# +--------+     +------+

	$graph->flip_edges('Bonn', 'Berlin');

	print $graph->as_ascii();

	#   +--------------+
	#   |              v
	# +--------+     +------+
	# | Berlin | --> | Bonn |
	# +--------+     +------+

Turn around (transpose) all edges that are going from the first node to the
second node.

X<transpose>

=head2 add_node()

	my $node = $graph->add_node( 'Node 1' );
	# or if you already have a Graph::Easy::Node object:
	$graph->add_node( $x );

Add a single node X to the graph. C<$x> should be either a
C<Graph::Easy::Node> object, or a unique name for the node. Will do
nothing if the node already exists in the graph.

It returns an L<Graph::Easy::Node> object.

=head2 add_anon_node()

	my $anon_node = $graph->add_anon_node( );

Creates a single, anonymous node and adds it to the graph, returning the
C<Graph::Easy::Node::Anon> object.

The created node is equal to one created via C< [ ] > in the Graph::Easy
text description.

=head2 add_nodes()

	my @nodes = $graph->add_nodes( 'Node 1', 'Node 2' );

Add all the given nodes to the graph. The arguments should be either a
C<Graph::Easy::Node> object, or a unique name for the node. Will do
nothing if the node already exists in the graph.

It returns a list of L<Graph::Easy::Node> objects.

=head2 rename_node()

	$node = $graph->rename_node($node, $new_name);

Changes the name of a node. If the passed node is not part of
this graph or just a string, it will be added with the new
name to this graph.

If the node was part of another graph, it will be deleted there and added
to this graph with the new name, effectively moving the node from the old
to the new graph and renaming it at the same time.

=head2 del_node()

	$graph->del_node('Node name');
	$graph->del_node($node);

Delete the node with the given name from the graph.

=head2 del_edge()

	$graph->del_edge($edge);

Delete the given edge object from the graph. You can use C<edge()> to find
an edge from Node A to B:

	$graph->del_edge( $graph->edge('A','B') );

=head2 merge_nodes()

	$graph->merge_nodes( $first_node, $second_node );
	$graph->merge_nodes( $first_node, $second_node, $joiner );

Merge two nodes. Will delete all connections between the two nodes, then
move over any connection to/from the second node to the first, then delete
the second node from the graph.

Any attributes on the second node will be lost.

If present, the optional C<< $joiner >> argument will be used to join
the label of the second node to the label of the first node. If not
present, the label of the second node will be dropped along with all
the other attributes:

	my $graph = Graph::Easy->new('[A]->[B]->[C]->[D]');

	# this produces "[A]->[C]->[D]"
	$graph->merge_nodes( 'A', 'B' );

	# this produces "[A C]->[D]"
	$graph->merge_nodes( 'A', 'C', ' ' );

	# this produces "[A C \n D]", note single quotes on the third argument!
	$graph->merge_nodes( 'A', 'C', ' \n ' );

=head2 get_attribute()

	my $value = $graph->get_attribute( $class, $name );

Return the value of attribute C<$name> from class C<$class>.

Example:

	my $color = $graph->attribute( 'node', 'color' );

You can also call all the various attribute related methods on members of the
graph directly, for instance:

	$node->get_attribute('label');
	$edge->get_attribute('color');
	$group->get_attribute('fill');

=head2 attribute()

	my $value = $graph->attribute( $class, $name );

Is an alias for L<get_attribute>.

=head2 color_attribute()

	# returns f.i. #ff0000
	my $color = $graph->get_color_attribute( 'node', 'color' );

Just like L<get_attribute()>, but only for colors, and returns them as hex,
using the current colorscheme.

=head2 get_color_attribute()

Is an alias for L<color_attribute()>.

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

	my $att = $object->raw_attributes();

Return all set attributes on this object (graph, node, group or edge) as
an anonymous hash ref. Thus you get all the locally active attributes
for this object.

Inheritance is respected, e.g. attributes that have the value "inherit"
and are inheritable, will be inherited from the base class.

But default values for unset attributes are skipped. Here is an example:

	node { color: red; }

	[ A ] { class: foo; color: inherit; }

This will return:

	{ class => foo, color => red }

As you can see, attributes like C<background> etc. are not included, while
the color value was inherited properly.

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

=head2 raw_attribute()

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

=head2 raw_attributes()

	my $att = $object->raw_attributes();

Returns a hash with all the raw attributes of that object.
Attributes that are no set on the object itself, but on
the class this object belongs to are B<not> included.

This method respects inheritance, so an attribute value of 'inherit'
on an object will make the method return the inherited value.

=head2 set_attribute()

	# Set the attribute on the given class.
	$graph->set_attribute( $class, $name, $val );

	# Set the attribute on the graph itself. This is synonymous
	# to using 'graph' as class in the form above.
	$graph->set_attribute( $name, $val );

Sets a given attribute named C<$name> to the new value C<$val> in the class
specified in C<$class>.

Example:

	$graph->set_attribute( 'graph', 'gid', '123' );

The class can be one of C<graph>, C<edge>, C<node> or C<group>. The last
three can also have subclasses like in C<node.subclassname>.

You can also call the various attribute related methods on members of the
graph directly, for instance:

	$node->set_attribute('label', 'my node');
	$edge->set_attribute('color', 'red');
	$group->set_attribute('fill', 'green');

=head2 set_attributes()

	$graph->set_attributes( $class, $att );

Given a class name in C<$class> and a hash of mappings between attribute names
and values in C<$att>, will set all these attributes.

The class can be one of C<graph>, C<edge>, C<node> or C<group>. The last
three can also have subclasses like in C<node.subclassname>.

Example:

	$graph->set_attributes( 'node', { color => 'red', background => 'none' } );

=head2 del_attribute()

	$graph->del_attribute('border');

Delete the attribute with the given name from the object.

You can also call the various attribute related methods on members of the
graph directly, for instance:

	$node->del_attribute('label');
	$edge->del_attribute('color');
	$group->del_attribute('fill');

=head2 unquote_attribute()

	# returns '"Hello World!"'
	my $value = $self->unquote_attribute('node','label','"Hello World!"');
	# returns 'red'
	my $color = $self->unquote_attribute('node','color','"red"');

Return the attribute unquoted except for labels and titles, that is it removes
double quotes at the start and the end of the string, unless these are
escaped with a backslash.

=head2 border_attribute()

  	my $border = $graph->border_attribute();

Return the combined border attribute like "1px solid red" from the
border(style|color|width) attributes.

=head2 split_border_attributes()

  	my ($style,$width,$color) = $graph->split_border_attribute($border);

Split the border attribute (like "1px solid red") into the three different parts.

=head2 quoted_comment()

	my $cmt = $node->comment();

Comment of this object, quoted suitable as to be embedded into HTML/SVG.
Returns the empty string if this object doesn't have a comment set.

=head2 flow()

	my $flow = $graph->flow();

Returns the flow of the graph, as absolute number in degress.

=head2 source_nodes()

	my @roots = $graph->source_nodes();

Returns all nodes that have only outgoing edges, e.g. are the root of a tree,
in no particular order.

Isolated nodes (no edges at all) will B<not> be included, see
L<predecessorless_nodes()> to get these, too.

In scalar context, returns the number of source nodes.

=head2 predecessorless_nodes()

	my @roots = $graph->predecessorless_nodes();

Returns all nodes that have no incoming edges, regardless of whether
they have outgoing edges or not, in no particular order.

Isolated nodes (no edges at all) B<will> be included in the list.

See also L<source_nodes()>.

In scalar context, returns the number of predecessorless nodes.

=head2 root_node()

	my $root = $graph->root_node();

Return the root node as L<Graph::Easy::Node> object, if it was
set with the 'root' attribute.

=head2 timeout()

	print $graph->timeout(), " seconds timeout for layouts.\n";
	$graph->timeout(12);

Get/set the timeout for layouts in seconds. If the layout process did not
finish after that time, it will be stopped and a warning will be printed.

The default timeout is 5 seconds.

=head2 strict()

	print "Graph has strict checking\n" if $graph->strict();
	$graph->strict(undef);		# disable strict attribute checks

Get/set the strict option. When set to a true value, all attribute names and
values will be strictly checked and unknown/invalid one will be rejected.

This option is on by default.

=head2 type()

	print "Graph is " . $graph->type() . "\n";

Returns the type of the graph as string, either "directed" or "undirected".

=head2 layout()

	$graph->layout();
	$graph->layout( type => 'force', timeout => 60 );

Creates the internal structures to layout the graph. 

This method will be called automatically when you call any of the
C<as_FOO> methods or C<output()> as described below.

The options are:

	type		the type of the layout, possible values:
			'force'		- force based layouter
			'adhoc'		- the default layouter
	timeout		timeout in seconds

See also: L<timeout()>.

=head2 output_format()

	$graph->output_format('html');

Set the outputformat. One of 'html', 'ascii', 'graphviz', 'svg' or 'txt'.
See also L<output()>.

=head2 output()

	my $out = $graph->output();

Output the graph in the format set by C<output_format()>.

=head2 as_ascii()

	print $graph->as_ascii();

Return the graph layout in ASCII art, in utf-8.

=head2 as_ascii_file()

	print $graph->as_ascii_file();

Is an alias for L<as_ascii>.

=head2 as_ascii_html()

	print $graph->as_ascii_html();

Return the graph layout in ASCII art, suitable to be embedded into an HTML
page. Basically it wraps the output from L<as_ascii()> into
C<< <pre> </pre> >> and inserts real HTML links. The returned
string is in utf-8.

=head2 as_boxart()

	print $graph->as_box();

Return the graph layout as box drawing using Unicode characters (in utf-8,
as always).

=head2 as_boxart_file()

	print $graph->as_boxart_file();

Is an alias for C<as_box>.

=head2 as_boxart_html()

	print $graph->as_boxart_html();

Return the graph layout as box drawing using Unicode characters,
as chunk that can be embedded into an HTML page.

Basically it wraps the output from L<as_boxart()> into
C<< <pre> </pre> >> and inserts real HTML links. The returned
string is in utf-8.

=head2 as_boxart_html_file()

	print $graph->as_boxart_html_file();

Return the graph layout as box drawing using Unicode characters,
as a full HTML page complete with header and footer.

=head2 as_html()

	print $graph->as_html();

Return the graph layout as HTML section. See L<css()> to get the
CSS section to go with that HTML code. If you want a complete HTML page
then use L<as_html_file()>.

=head2 as_html_page()

	print $graph->as_html_page();

Is an alias for C<as_html_file>.

=head2 as_html_file()

	print $graph->as_html_file();

Return the graph layout as HTML complete with headers, CSS section and
footer. Can be viewed in the browser of your choice.

=head2 add_group()

	my $group = $graph->add_group('Group name');

Add a group to the graph and return it as L<Graph::Easy::Group> object.

=head2 group()

	my $group = $graph->group('Name');

Returns the group with the name C<Name> as L<Graph::Easy::Group> object.

=head2 rename_group()

	$group = $graph->rename_group($group, $new_name);

Changes the name of the given group. If the passed group is not part of
this graph or just a string, it will be added with the new
name to this graph.

If the group was part of another graph, it will be deleted there and added
to this graph with the new name, effectively moving the group from the old
to the new graph and renaming it at the same time.

=head2 groups()

	my @groups = $graph->groups();

Returns the groups of the graph as L<Graph::Easy::Group> objects,
in arbitrary order.
  
=head2 groups_within()

	# equivalent to $graph->groups():
	my @groups = $graph->groups_within();		# all
	my @toplevel_groups = $graph->groups_within(0);	# level 0 only

Return the groups that are inside this graph, up to the specified level,
in arbitrary order.

The default level is -1, indicating no bounds and thus all contained
groups are returned.

A level of 0 means only the direct children, and hence only the toplevel
groups will be returned. A level 1 means the toplevel groups and their
toplevel children, and so on.

=head2 anon_groups()

	my $anon_groups = $graph->anon_groups();

In scalar context, returns the number of anon groups (aka
L<Graph::Easy::Group::Anon>) the graph has.

In list context, returns all anon groups as objects, in arbitrary order.

=head2 del_group()

	$graph->del_group($name);

Delete the group with the given name.

=head2 edges(), edges_within()

	my @edges = $graph->edges();

Returns the edges of the graph as L<Graph::Easy::Edge> objects,
in arbitrary order.

L<edges_within()> is an alias for C<edges()>.

=head2 is_simple_graph(), is_simple()

	if ($graph->is_simple())
	  {
	  }

Returns true if the graph does not have multiedges, e.g. if it
does not have more than one edge going from any node to any other
node or group.

Since this method has to look at all edges, it is costly in terms of
both CPU and memory.

=head2 is_directed()

	if ($graph->is_directed())
	  {
	  }

Returns true if the graph is directed.

=head2 is_undirected()

	if ($graph->is_undirected())
	  {
	  }

Returns true if the graph is undirected.

=head2 parent()

	my $parent = $graph->parent();

Returns the parent graph, for graphs this is undef.

=head2 label()

	my $label = $graph->label();

Returns the label of the graph.

=head2 title()

	my $title = $graph->title();

Returns the (mouseover) title of the graph.

=head2 link()

	my $link = $graph->link();

Return a potential link (for the graphs label), build from the attributes C<linkbase>
and C<link> (or autolink). Returns '' if there is no link.

=head2 as_graphviz()

	print $graph->as_graphviz();

Return the graph as graphviz code, suitable to be feed to a program like
C<dot> etc.

=head2 as_graphviz_file()

	print $graph->as_graphviz_file();

Is an alias for L<as_graphviz()>.

=head2 angle()

        my $degrees = Graph::Easy->angle( 'south' );
        my $degrees = Graph::Easy->angle( 120 );

Check an angle for being valid and return a value between -359 and 359
degrees. The special values C<south>, C<north>, C<west>, C<east>, C<up>
and C<down> are also valid and converted to degrees.

=head2 nodes()

	my $nodes = $graph->nodes();

In scalar context, returns the number of nodes/vertices the graph has.

In list context, returns all nodes as objects, in arbitrary order.

=head2 anon_nodes()

	my $anon_nodes = $graph->anon_nodes();

In scalar context, returns the number of anon nodes (aka
L<Graph::Easy::Node::Anon>) the graph has.

In list context, returns all anon nodes as objects, in arbitrary order.

=head2 html_page_header()

	my $header = $graph->html_page_header();
	my $header = $graph->html_page_header($css);

Return the header of an HTML page. Used together with L<html_page_footer>
by L<as_html_page> to construct a complete HTML page.

Takes an optional parameter with the CSS styles to be inserted into the
header. If C<$css> is not defined, embedds the result of C<< $self->css() >>.

=head2 html_page_footer()

	my $footer = $graph->html_page_footer();

Return the footer of an HTML page. Used together with L<html_page_header>
by L<as_html_page> to construct a complete HTML page.

=head2 css()

	my $css = $graph->css();

Return CSS code for that graph. See L<as_html()>.

=head2 as_txt()

	print $graph->as_txt();

Return the graph as a normalized textual representation, that can be
parsed with L<Graph::Easy::Parser> back to the same graph.

This does not call L<layout()> since the actual text representation
is just a dump of the graph.

=head2 as_txt_file()

	print $graph->as_txt_file();

Is an alias for L<as_txt()>.

=head2 as_svg()

	print $graph->as_svg();

Return the graph as SVG (Scalable Vector Graphics), which can be
embedded into HTML pages. You need to install
L<Graph::Easy::As_svg> first to make this work.

See also L<as_svg_file()>.

B<Note:> You need L<Graph::Easy::As_svg> installed for this to work!

=head2 as_svg_file()

	print $graph->as_svg_file();

Returns SVG just like C<as_svg()>, but this time as standalone SVG,
suitable for storing it in a file and referencing it externally.

After calling C<as_svg_file()> or C<as_svg()>, you can retrieve
some SVG information, notable C<width> and C<height> via
C<svg_information>.

B<Note:> You need L<Graph::Easy::As_svg> installed for this to work!

=head2 svg_information()

	my $info = $graph->svg_information();

	print "Size: $info->{width}, $info->{height}\n";

Return information about the graph created by the last
C<as_svg()> or C<as_svg_file()> call.

The following fields are set:

	width		width of the SVG in pixels
	height		height of the SVG in pixels

B<Note:> You need L<Graph::Easy::As_svg> installed for this to work!

=head2 as_vcg()

	print $graph->as_vcg();

Return the graph as VCG text. VCG is a subset of GDL (Graph Description
Language).

This does not call L<layout()> since the actual text representation
is just a dump of the graph.

=head2 as_vcg_file()

	print $graph->as_vcg_file();

Is an alias for L<as_vcg()>.

=head2 as_gdl()

	print $graph->as_gdl();

Return the graph as GDL (Graph Description Language) text. GDL is a superset
of VCG.

This does not call L<layout()> since the actual text representation
is just a dump of the graph.

=head2 as_gdl_file()

	print $graph->as_gdl_file();

Is an alias for L<as_gdl()>.

=head2 as_graphml()

	print $graph->as_graphml();

Return the graph as a GraphML representation.

This does not call L<layout()> since the actual text representation
is just a dump of the graph.

The output contains only the set attributes, e.g. default attribute values
are not specifically mentioned. The attribute names and values are the
in the format that C<Graph::Easy> defines.

=head2 as_graphml_file()

	print $graph->as_graphml_file();

Is an alias for L<as_graphml()>.

=head2 sorted_nodes()

	my $nodes =
	 $graph->sorted_nodes( );		# default sort on 'id'
	my $nodes = 
	 $graph->sorted_nodes( 'name' );	# sort on 'name'
	my $nodes = 
	 $graph->sorted_nodes( 'layer', 'id' );	# sort on 'layer', then on 'id'

In scalar context, returns the number of nodes/vertices the graph has.
In list context returns a list of all the node objects (as reference),
sorted by their attribute(s) given as arguments. The default is 'id',
e.g. their internal ID number, which amounts more or less to the order
they have been inserted.

This routine will sort the nodes by their group first, so the requested
sort order will be only valid if there are no groups or inside each
group.

=head2 as_debug()

	print $graph->as_debug();

Return debugging information like version numbers of used modules,
and a textual representation of the graph.

This does not call L<layout()> since the actual text representation
is more a dump of the graph, than a certain layout.

=head2 node()

	my $node = $graph->node('node name');

Return node by unique name (case sensitive). Returns undef if the node
does not exist in the graph.

=head2 edge()

	my $edge = $graph->edge( $x, $y );

Returns the edge objects between nodes C<$x> and C<$y>. Both C<$x> and C<$y>
can be either scalars with names or C<Graph::Easy::Node> objects.

Returns undef if the edge does not yet exist.

In list context it will return all edges from C<$x> to C<$y>, in
scalar context it will return only one (arbitrary) edge.

=head2 id()

	my $graph_id = $graph->id();
	$graph->id('123');

Returns the id of the graph. You can also set a new ID with this routine. The
default is ''.

The graph's ID is used to generate unique CSS classes for each graph, in the
case you want to have more than one graph in an HTML page.

=head2 seed()

	my $seed = $graph->seed();
	$graph->seed(2);

Get/set the random seed for the graph object. See L<randomize()>
for a method to set a random seed.

The seed is used to create random numbers for the layouter. For
the same graph, the same seed will always lead to the same layout.

=head2 randomize()

	$graph->randomize();

Set a random seed for the graph object. See L<seed()>.

=head2 debug()

	my $debug = $graph->debug();	# get
	$graph->debug(1);		# enable
	$graph->debug(0);		# disable

Enable, disable or read out the debug status. When the debug status is true,
additional debug messages will be printed on STDERR.

=head2 score()

	my $score = $graph->score();

Returns the score of the graph, or undef if L<layout()> has not yet been called.

Higher scores are better, although you cannot compare scores for different
graphs. The score should only be used to compare different layouts of the same
graph against each other:

	my $max = undef;

	$graph->randomize();
	my $seed = $graph->seed(); 

	$graph->layout();
	$max = $graph->score(); 

	for (1..10)
	  {
	  $graph->randomize();			# select random seed
	  $graph->layout();			# layout with that seed
	  if ($graph->score() > $max)
	    {
	    $max = $graph->score();		# store the new max store
	    $seed = $graph->seed();		# and it's seed
	    }
	  }

	# redo the best layout
	if ($seed ne $graph->seed())
	  {
	  $graph->seed($seed);
	  $graph->layout();
	  }
	# output graph:
	print $graph->as_ascii();		# or as_html() etc

=head2 valid_attribute()

	my $graph = Graph::Easy->new();
	my $new_value =
	  $graph->valid_attribute( $name, $value, $class );

	if (ref($new_value) eq 'ARRAY' && @$new_value == 0)
	  {
	  # throw error
          die ("'$name' is not a valid attribute name for '$class'")
		if $self->{_warn_on_unused_attributes};
	  }
	elsif (!defined $new_value)
	  {
	  # throw error
          die ("'$value' is no valid '$name' for '$class'");
	  }

Deprecated, please use L<validate_attribute()>.

Check that a C<$name,$value> pair is a valid attribute in class C<$class>,
and returns a new value.

It returns an array ref if the attribute name is invalid, and undef if the
value is invalid.

The return value can differ from the passed in value, f.i.:

	print $graph->valid_attribute( 'color', 'red' );

This would print '#ff0000';

=head2 validate_attribute()

	my $graph = Graph::Easy->new();
	my ($rc,$new_name, $new_value) =
	  $graph->validate_attribute( $name, $value, $class );

Checks a given attribute name and value (or values, in case of a
value like "red|green") for being valid. It returns a new
attribute name (in case of "font-color" => "fontcolor") and
either a single new attribute, or a list of attribute values
as array ref.

If C<$rc> is defined, it is the error number:

	1			unknown attribute name
	2			invalid attribute value
	4			found multiple attributes, but these arent
				allowed at this place

=head2 color_as_hex()

	my $hexred   = Graph::Easy->color_as_hex( 'red' );
	my $hexblue  = Graph::Easy->color_as_hex( '#0000ff' );
	my $hexcyan  = Graph::Easy->color_as_hex( '#f0f' );
	my $hexgreen = Graph::Easy->color_as_hex( 'rgb(0,255,0)' );

Takes a valid color name or definition (hex, short hex, or RGB) and returns the
color in hex like C<#ff00ff>.

=head2 color_value($color_name, $color_scheme)

	my $color = Graph::Easy->color_name( 'red' );	# #ff0000
	print Graph::Easy->color_name( '#ff0000' );	# #ff0000

	print Graph::Easy->color_name( 'snow', 'x11' );

Given a color name, returns the color in hex. See L<color_name>
for a list of possible values for the optional C<$color_scheme>
parameter.

=head2 color_name($color_value, $color_scheme)

	my $color = Graph::Easy->color_name( 'red' );	# red
	print Graph::Easy->color_name( '#ff0000' );	# red

	print Graph::Easy->color_name( 'snow', 'x11' );

Takes a hex color value and returns the name of the color.

The optional parameter is the color scheme, where the following
values are possible:

 w3c			(the default)
 x11			(what graphviz uses as default)

Plus the following ColorBrewer schemes are supported, see the
online manual for examples and their usage:

 accent3 accent4 accent5 accent6 accent7 accent8

 blues3 blues4 blues5 blues6 blues7 blues8 blues9

 brbg3 brbg4 brbg5 brbg6 brbg7 brbg8 brbg9 brbg10 brbg11

 bugn3 bugn4 bugn5 bugn6 bugn7 bugn8 bugn9 bupu3 bupu4 bupu5 bupu6 bupu7
 bupu8 bupu9

 dark23 dark24 dark25 dark26 dark27 dark28

 gnbu3 gnbu4 gnbu5 gnbu6 gnbu7 gnbu8 gnbu9

 greens3 greens4 greens5 greens6 greens7 greens8 greens9

 greys3 greys4 greys5 greys6 greys7 greys8 greys9

 oranges3 oranges4 oranges5 oranges6 oranges7 oranges8 oranges9

 orrd3 orrd4 orrd5 orrd6 orrd7 orrd8 orrd9

 paired3 paired4 paired5 paired6 paired7 paired8 paired9 paired10 paired11
 paired12 pastel13 pastel14 pastel15 pastel16 pastel17 pastel18 pastel19

 pastel23 pastel24 pastel25 pastel26 pastel27 pastel28

 piyg3 piyg4 piyg5 piyg6 piyg7 piyg8 piyg9 piyg10 piyg11

 prgn3 prgn4 prgn5 prgn6 prgn7 prgn8 prgn9 prgn10 prgn11

 pubu3 pubu4 pubu5 pubu6 pubu7 pubu8 pubu9

 pubugn3 pubugn4 pubugn5 pubugn6 pubugn7 pubugn8 pubugn9

 puor3 puor4 puor5 puor6 puor7 puor8 puor9 purd3 purd4 purd5 purd6 purd7 purd8
 purd9 puor10 puor11

 purples3 purples4 purples5 purples6 purples7 purples8 purples9

 rdbu10 rdbu11 rdbu3 rdbu4 rdbu5 rdbu6 rdbu7 rdbu8 rdbu9 rdgy3 rdgy4 rdgy5 rdgy6

 rdgy7 rdgy8 rdgy9 rdpu3 rdpu4 rdpu5 rdpu6 rdpu7 rdpu8 rdpu9 rdgy10 rdgy11

 rdylbu3 rdylbu4 rdylbu5 rdylbu6 rdylbu7 rdylbu8 rdylbu9 rdylbu10 rdylbu11

 rdylgn3 rdylgn4 rdylgn5 rdylgn6 rdylgn7 rdylgn8 rdylgn9 rdylgn10 rdylgn11

 reds3 reds4 reds5 reds6 reds7 reds8 reds9

 set13 set14 set15 set16 set17 set18 set19 set23 set24 set25 set26 set27 set28
 set33 set34 set35 set36 set37 set38 set39

 set310 set311 set312

 spectral3 spectral4 spectral5 spectral6 spectral7 spectral8 spectral9
 spectral10spectral11

 ylgn3 ylgn4 ylgn5 ylgn6 ylgn7 ylgn8 ylgn9

 ylgnbu3 ylgnbu4 ylgnbu5 ylgnbu6 ylgnbu7 ylgnbu8 ylgnbu9

 ylorbr3 ylorbr4 ylorbr5 ylorbr6 ylorbr7 ylorbr8 ylorbr9

 ylorrd3 ylorrd4 ylorrd5 ylorrd6 ylorrd7 ylorrd8 ylorrd9

=head2 color_names()

	my $names = Graph::Easy->color_names();

Return a hash with name => value mapping for all known colors.

=head2 text_style()

	if ($graph->text_style('bold, italic'))
	  {
	  ...
	  }

Checks the given style list for being valid.

=head2 text_styles()

	my $styles = $graph->text_styles();	# or $edge->text_styles() etc.

	if ($styles->{'italic'})
	  {
	  print 'is italic\n';
	  }

Return a hash with the given text-style properties, aka 'underline', 'bold' etc.

=head2 text_styles_as_css()

	my $styles = $graph->text_styles_as_css();	# or $edge->...() etc.

Return the text styles as a chunk of CSS styling that can be embedded into
a C< style="" > parameter.

=head2 use_class()

	$graph->use_class('node', 'Graph::Easy::MyNode');

Override the class to be used to constructs objects when calling
C<add_edge()>, C<add_group()> or C<add_node()>.

The first parameter can be one of the following:

	node
	edge
	group

Please see the documentation about C<use_class()> in C<Graph::Easy::Parser>
for examples and details.

=head2 animation_as_graph()

	my $graph_2 = $graph->animation_as_graph();
	print $graph_2->as_ascii();

Returns the animation of C<$graph> as a graph describing the flow of the
animation. Useful for debugging animation flows.

=head2 add_cycle()

	$graph->add_cycle('A','B','C');		# A -> B -> C -> A

Compatibility method for Graph, adds the edges between each node
and back from the last node to the first. Returns the graph.

=head2 add_path()

	$graph->add_path('A','B','C');		# A -> B -> C

Compatibility method for Graph, adds the edges between each node.
Returns the graph.

=head2 add_vertex()

	$graph->add_vertex('A');

Compatibility method for Graph, adds the node and returns the graph.

=head2 add_vertices()

	$graph->add_vertices('A','B');

Compatibility method for Graph, adds these nodes and returns the graph.

=head2 has_edge()

	$graph->has_edge('A','B');

Compatibility method for Graph, returns true if at least one edge between
A and B exists.

=head2 vertices()

Compatibility method for Graph, returns in scalar context the number
of nodes this graph has, in list context a (arbitrarily sorted) list
of node objects.

=head2 set_vertex_attribute()

	$graph->set_vertex_attribute( 'A', 'fill', '#deadff' );

Compatibility method for Graph, set the named vertex attribute.

Please note that this routine will only accept Graph::Easy attribute
names and values. If you want to attach custom attributes, you need to
start their name with 'x-':

	$graph->set_vertex_attribute( 'A', 'x-foo', 'bar' );

=head2 get_vertex_attribute()

	my $fill = $graph->get_vertex_attribute( 'A', 'fill' );

Compatibility method for Graph, get the named vertex attribute.

Please note that this routine will only accept Graph::Easy attribute
names. See L<set_vertex_attribute()>.

=head1 EXPORT

Exports nothing.

=head1 SEE ALSO

L<Graph>, L<Graph::Convert>, L<Graph::Easy::As_svg>, L<Graph::Easy::Manual> and
L<Graph::Easy::Parser>.

=head2 Related Projects

L<Graph::Layout::Aesthetic>, L<Graph> and L<Text::Flowchart>.

There is also an very old, unrelated project from ca. 1995, which does something similar.
See L<http://rw4.cs.uni-sb.de/users/sander/html/gsvcg1.html>.

Testcases and more examples under:

L<http://bloodgate.com/perl/graph/>.

=head1 LIMITATIONS

This module is now quite complete, but there are still some limitations.
Hopefully further development will lift these.

=head2 Scoring

Scoring is not yet implemented, each generated graph will be the same regardless
of the random seed.

=head2 Layouter

The layouter can not yet handle links between groups (or between
a group and a node, or vice versa). These links will thus only
appear in L<as_graphviz()> or L<as_txt()> output.

=head2 Paths

=over 2

=item No optimizations

In complex graphs, non-optimal layout part like this one might appear:

	+------+     +--------+
	| Bonn | --> | Berlin | --> ...
	+------+     +--------+
	               ^
	               |
	               |
	+---------+    |
	| Kassel  | ---+
	+---------+

A second-stage optimizer that simplifies these layouts is not yet implemented.

In addition the general placement/processing strategy as well as the local
strategy might be improved.

=item attributes

The following attributes are currently ignored by the layouter:

	undirected graphs
	autosplit/autojoin for edges
	tail/head label/title/link for edges

=item groups

The layouter is not fully recursive yet, so groups do not properly nest.

In addition, links to/from groups are missing, too.

=back

=head2 Output formats

Some output formats are not yet complete in their
implementation. Please see the online manual at
L<http://bloodgate.com/perl/graph/manual> under "Output" for
details.

X<graph>
X<manual>
X<online>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the terms of the GPL 2.0 or a later version.

See the LICENSE file for a copy of the GPL.

This product includes color specifications and designs developed by Cynthia
Brewer (http://colorbrewer.org/). See the LICENSE file for the full license
text that applies to these color schemes.

X<gpl>
X<apache-style>
X<cynthia>
X<brewer>
X<colorscheme>
X<license>

=head1 NAME CHANGE

The package was formerly known as C<Graph::Simple>. The name was changed
for two reasons:

=over 2

=item *

In graph theory, a C<simple> graph is a special type of graph. This software,
however, supports more than simple graphs.

=item *

Creating graphs should be easy even when the graphs are quite complex.

=back

=head1 AUTHOR

Copyright (C) 2004 - 2008 by Tels L<http://bloodgate.com>

X<tels>

=cut
