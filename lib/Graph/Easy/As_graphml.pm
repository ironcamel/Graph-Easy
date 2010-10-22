#############################################################################
# Output an Graph::Easy object as GraphML text
#
#############################################################################

package Graph::Easy::As_graphml;

$VERSION = '0.03';

#############################################################################
#############################################################################

package Graph::Easy;

use strict;

use Graph::Easy::Attributes;

# map the Graph::Easy attribute types to a GraphML name:
my $attr_type_to_name =
  {
  ATTR_STRING()	=> 'string',
  ATTR_COLOR()	=> 'string',
  ATTR_ANGLE()	=> 'double',
  ATTR_PORT()	=> 'string',
  ATTR_UINT()	=> 'integer',
  ATTR_URL()	=> 'string',

  ATTR_LIST()	=> 'string',
  ATTR_LCTEXT()	=> 'string',
  ATTR_TEXT()	=> 'string',
  };

sub _graphml_attr_keys
  {
  my ($self, $tpl, $tpl_no_default, $class, $att, $ids, $id) = @_;

  my $base_class = $class; $base_class =~ s/\..*//;
  $base_class = 'graph' if $base_class =~ /group/;
  $ids->{$base_class} = {} unless ref $ids->{$base_class};

  my $txt = '';
  for my $name (sort keys %$att)
    {
    my $entry = $self->_attribute_entry($class,$name);
    # get a fresh template
    my $t = $tpl;
    $t = $tpl_no_default unless defined $entry->[ ATTR_DEFAULT_SLOT ];

    # only keep it once
    next if exists $ids->{$base_class}->{$name};

    $t =~ s/##id##/$$id/;

    # node.foo => node, group.bar => graph
    $t =~ s/##class##/$base_class/;
    $t =~ s/##name##/$name/;
    $t =~ s/##type##/$attr_type_to_name->{ $entry->[ ATTR_TYPE_SLOT ] || ATTR_COLOR }/eg;

    # will only be there and thus replaced if we have a default
    if ($t =~ /##default##/)
      {
      my $def = $entry->[ ATTR_DEFAULT_SLOT ];
      # not a simple value?
      $def = $self->default_attribute($name) if ref $def;
      $t =~ s/##default##/$def/;
      }

    # remember name => ID
    $ids->{$base_class}->{$name} = $$id; $$id++;
    # append the definition
    $txt .= $t;
    }
  $txt;
  }

# yED example:

# <data key="d0">
#  <y:ShapeNode>
#    <y:Geometry height="30.0" width="30.0" x="277.0" y="96.0"/>
#    <y:Fill color="#FFCC00" transparent="false"/>
#    <y:BorderStyle color="#000000" type="line" width="1.0"/>
#    <y:NodeLabel alignment="center" autoSizePolicy="content" fontFamily="Dialog" fontSize="12" fontStyle="plain" hasBackgroundColor="false" hasLineColor="false" height="18.701171875" modelName="internal" modelPosition="c" textColor="#000000" visible="true" width="11.0" x="9.5" y="5.6494140625">1</y:NodeLabel>
#    <y:Shape type="ellipse"/>
#   </y:ShapeNode>
# </data>

sub _as_graphml
  {
  my $self = shift;

  my $args = $_[0];
  $args = { name => $_[0] } if ref($args) ne 'HASH' && @_ == 1;
  $args = { @_ } if ref($args) ne 'HASH' && @_ > 1;
  
  $args->{format} = 'graph-easy' unless defined $args->{format};

  if ($args->{format} !~ /^(graph-easy|Graph::Easy|yED)\z/i)
    {
    return $self->error("Format '$args->{format}' not understood by as_graphml.");
    }
  my $format = $args->{format};

  # Convert the graph to a textual representation - does not need layout().

  my $schema = "http://graphml.graphdrawing.org/xmlns/1.0/graphml.xsd";
  $schema = "http://www.yworks.com/xml/schema/graphml/1.0/ygraphml.xsd" if $format eq 'yED';
  my $y_schema = '';
  $y_schema = "\n    xmlns:y=\"http://www.yworks.com/xml/graphml\"" if $format eq 'yED';

  my $txt = <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<graphml xmlns="http://graphml.graphdrawing.org/xmlns"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"##Y##
    xsi:schemaLocation="http://graphml.graphdrawing.org/xmlns
     ##SCHEMA##">

  <!-- Created by Graph::Easy v##VERSION## at ##DATE## -->

EOF
;
	  
  $txt =~ s/##DATE##/scalar localtime()/e;
  $txt =~ s/##VERSION##/$Graph::Easy::VERSION/;
  $txt =~ s/##SCHEMA##/$schema/;
  $txt =~ s/##Y##/$y_schema/;

  # <key id="d0" for="node" attr.name="color" attr.type="string">
  #   <default>yellow</default>
  # </key>
  # <key id="d1" for="edge" attr.name="weight" attr.type="double"/>

  # First gather all possible attributes, then add defines for them. This
  # avoids lengthy re-definitions of attributes that aren't used:

  my %keys;

  my $tpl = '  <key id="##id##" for="##class##" attr.name="##name##" attr.type="##type##">'
      ."\n    <default>##default##</default>\n"
      ."  </key>\n";
  my $tpl_no_default = '  <key id="##id##" for="##class##" attr.name="##name##" attr.type="##type##"/>'."\n";

  # for yED:
  # <key for="node" id="d0" yfiles.type="nodegraphics"/>
  # <key attr.name="description" attr.type="string" for="node" id="d1"/>
  # <key for="edge" id="d2" yfiles.type="edgegraphics"/>
  # <key attr.name="description" attr.type="string" for="edge" id="d3"/>
  # <key for="graphml" id="d4" yfiles.type="resources"/>

  # we need to remember the mapping between attribute name and ID:
  my $ids = {};
  my $id = 'd0';

  ###########################################################################
  # first the class attributes
  for my $class (sort keys %{$self->{att}})
    {
    my $att =  $self->{att}->{$class};

    $txt .=
	$self->_graphml_attr_keys( $tpl, $tpl_no_default, $class, $att, $ids, \$id);

    }

  my @nodes = $self->sorted_nodes('name','id');

  ###########################################################################
  # now the attributes on the objects:
  for my $o (@nodes, values %{$self->{edges}})
    {
    $txt .=
	$self->_graphml_attr_keys( $tpl, $tpl_no_default, $o->class(),
				   $o->raw_attributes(), $ids, \$id);
    }
  $txt .= "\n" unless $id eq 'd0';

  my $indent = '  ';
  $txt .= $indent . '<graph id="G" edgedefault="' . $self->type() . "\">\n";

  # output graph attributes:
  $txt .= $self->_attributes_as_graphml($self,'  ',$ids->{graph});

  # output groups recursively
  my @groups = $self->groups_within(0);
  foreach my $g (@groups)
    {
    $txt .= $g->as_graphml($indent.'  ',$ids);			# marks nodes as processed if nec.
    }
 
  $indent = '    ';		
  foreach my $n (@nodes)
    {
    next if $n->{group};				# already done in a group
    $txt .= $n->as_graphml($indent,$ids);		# <node id="..." ...>
    }

  $txt .= "\n";

  foreach my $n (@nodes)
    {
    next if $n->{group};				# already done in a group

    my @out = $n->sorted_successors();
    # for all outgoing connections
    foreach my $other (@out)
      {
      # in case there exists more than one edge from $n --> $other
      my @edges = $n->edges_to($other);
      for my $edge (sort { $a->{id} <=> $b->{id} } @edges)
        {
        $txt .= $edge->as_graphml($indent,$ids);	# <edge id="..." ...>
        }
      }
    }

  $txt .= "  </graph>\n</graphml>\n";
  $txt;
  }

sub _safe_xml
  {
  # make a text XML safe
  my ($self,$txt) = @_;

  $txt =~ s/&/&amp;/g;			# quote &
  $txt =~ s/>/&gt;/g;			# quote >
  $txt =~ s/</&lt;/g;			# quote <
  $txt =~ s/"/&quot;/g;			# quote "
  $txt =~ s/'/&apos;/g;			# quote '
  $txt =~ s/\\\\/\\/g;			# "\\" to "\"

  $txt;
  }

sub _attributes_as_graphml
  {
  # output the attributes of an object
  my ($graph, $self, $indent, $ids) = @_;

  my $tpl = "$indent  <data key=\"##id##\">##value##</data>\n";
  my $att = $self->get_attributes();
  my $txt = '';
  for my $n (sort keys %$att)
    {
    next unless exists $ids->{$n};
    my $def = $self->default_attribute($n);
    next if defined $def && $def eq $att->{$n};
    my $t = $tpl;
    $t =~ s/##id##/$ids->{$n}/;
    $t =~ s/##value##/$graph->_safe_xml($att->{$n})/e;
    $txt .= $t;
    }
  $txt;
  }

#############################################################################

package Graph::Easy::Group;

use strict;

sub as_graphml
  {
  my ($self, $indent, $ids) = @_;

  my $txt = $indent . '<graph id="' . $self->_safe_xml($self->{name}) . '" edgedefault="' .
	$self->{graph}->type() . "\">\n";
  $txt .= $self->{graph}->_attributes_as_graphml($self, $indent, $ids->{graph});

  foreach my $n (values %{$self->{nodes}})
    {
    my @out = $n->sorted_successors();

    $txt .= $n->as_graphml($indent.'  ', $ids); 		# <node id="..." ...>

    # for all outgoing connections
    foreach my $other (@out)
      {
      # in case there exists more than one edge from $n --> $other
      my @edges = $n->edges_to($other);
      for my $edge (sort { $a->{id} <=> $b->{id} } @edges)
        {
        $txt .= $edge->as_graphml($indent.'  ',$ids);
        }
      $txt .= "\n" if @edges > 0;
      }
    }

  # output groups recursively
  my @groups = $self->groups_within(0);
  foreach my $g (@groups)
    {
    $txt .= $g->_as_graphml($indent.'  ',$ids);		# marks nodes as processed if nec.
    }

  # XXX TODO: edges from/to this group

  # close this group
  $txt .= $indent . "</graph>";

  $txt;
  }

#############################################################################

package Graph::Easy::Node;

use strict;

sub as_graphml
  {
  my ($self, $indent, $ids) = @_;

  my $g = $self->{graph};
  my $txt = $indent . '<node id="' . $g->_safe_xml($self->{name}) . "\">\n";

  $txt .= $g->_attributes_as_graphml($self, $indent, $ids->{node});

  $txt .= "$indent</node>\n";

  return $txt;
  }

#############################################################################

package Graph::Easy::Edge;

use strict;

sub as_graphml
  {
  my ($self, $indent, $ids) = @_;

  my $g = $self->{graph};
  my $txt = $indent . '<edge source="' . $g->_safe_xml($self->{from}->{name}) . 
		     '" target="' . $g->_safe_xml($self->{to}->{name}) . "\">\n";

  $txt .= $g->_attributes_as_graphml($self, $indent, $ids->{edge});

  $txt .= "$indent</edge>\n";

  $txt;
  }
 
1;
__END__

=head1 NAME

Graph::Easy::As_graphml - Generate a GraphML text from a Graph::Easy object

=head1 SYNOPSIS

	use Graph::Easy;
	
	my $graph = Graph::Easy->new();

	$graph->add_edge ('Bonn', 'Berlin');

	print $graph->as_graphml();

=head1 DESCRIPTION

C<Graph::Easy::As_graphml> contains just the code for converting a
L<Graph::Easy|Graph::Easy> object to a GraphML text.

=head2 Attributes

Attributes are output in the format that C<Graph::Easy> specifies. More
details about the valid attributes and their default values can be found
in the Graph::Easy online manual:

L<http://bloodgate.com/perl/graph/manual/>.

=head1 EXPORT

Exports nothing.

=head1 SEE ALSO

L<Graph::Easy>, L<http://graphml.graphdrawing.org/>.

=head1 AUTHOR

Copyright (C) 2004 - 2008 by Tels L<http://bloodgate.com>

See the LICENSE file for information.

=cut

