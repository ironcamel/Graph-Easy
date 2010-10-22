#############################################################################
# Output an Graph::Easy object as textual description
#

package Graph::Easy::As_txt;

$VERSION = '0.15';

#############################################################################
#############################################################################

package Graph::Easy;

use strict;

sub _as_txt
  {
  my ($self) = @_;

  # Convert the graph to a textual representation - does not need layout().
  $self->_assign_ranks();

  # generate the class attributes first
  my $txt = '';
  my $att =  $self->{att};
  for my $class (sort keys %$att)
    {

    my $out = $self->_remap_attributes(
     $class, $att->{$class}, {}, 'noquote', 'encode' );

    my $att = '';
    for my $atr (sort keys %$out)
      {
      # border is handled special below
      next if $atr =~ /^border/;
      $att .= "  $atr: $out->{$atr};\n";
      }

    # edges do not have a border
    if ($class !~ /^edge/)
      {
      my $border = $self->border_attribute($class) || '';

      # 'solid 1px #000000' =~ /^solid/;
      # 'solid 1px #000000' =~ /^solid 1px #000000/;
      $border = '' if $self->default_attribute($class,'border') =~ /^$border/;

      $att .= "  border: $border;\n" if $border ne '';
      }

    if ($att ne '')
      {
      # the following makes short, single definitions to fit on one line
      if ($att !~ /\n.*\n/ && length($att) < 40)
        {
        $att =~ s/\n/ /; $att =~ s/^  / /;
        }
      else
        {
        $att = "\n$att";
        }
      $txt .= "$class {$att}\n";
      }
    }

  $txt .= "\n" if $txt ne '';		# insert newline

  my @nodes = $self->sorted_nodes('name','id');

  my $count = 0;
  # output nodes with attributes first, sorted by their name
  foreach my $n (@nodes)
    {
    $n->{_p} = undef;			# mark as not yet processed
    my $att = $n->attributes_as_txt();
    if ($att ne '')
      {
      $n->{_p} = 1;			# mark as processed
      $count++;
      $txt .= $n->as_pure_txt() . $att . "\n"; 
      }
    }
 
  $txt .= "\n" if $count > 0;		# insert a newline

  # output groups first, with their nodes
  foreach my $gn (sort keys %{$self->{groups}})
    {
    my $group = $self->{groups}->{$gn};
    $txt .= $group->as_txt();		# marks nodes as processed if nec.
    $count++;
    }

  # XXX TODO:
  # Output all nodes with rank=0 first, and also follow their successors
  # What is left will then be done next, with rank=1 etc.
  # This output order let's us output node chains in compact form as:
  # [A]->[B]->[C]->[D]
  # [B]->[E]
  # instead of having:
  # [A]->[B]
  # [B]->[E]
  # [B]->[C] etc
 
  @nodes = $self->sorted_nodes('rank','name');
  foreach my $n (@nodes)
    {
    my @out = $n->sorted_successors();
    my $first = $n->as_pure_txt(); 		# [ A | B ]
    if ( defined $n->{autosplit} || ((@out == 0) && ( (scalar $n->predecessors() || 0) == 0)))
      {
      # single node without any connections (unless already output)
      next if exists $n->{autosplit} && !defined $n->{autosplit};
      $txt .= $first . "\n" unless defined $n->{_p};
      }

    $first = $n->_as_part_txt();		# [ A.0 ]
    # for all outgoing connections
    foreach my $other (@out)
      {
      # in case there exists more than one edge from $n --> $other
      my @edges = $n->edges_to($other);
      for my $edge (sort { $a->{id} <=> $b->{id} } @edges)
        {
        $txt .= $first . $edge->as_txt() . $other->_as_part_txt() . "\n";
        }
      }
    }

  foreach my $n (@nodes)
    {
    delete $n->{_p};			# clean up
    }

  $txt;
  }

#############################################################################

package Graph::Easy::Group;

use strict;

sub as_txt
  {
  my $self = shift;

  my $n = '';
  if (!$self->isa('Graph::Easy::Group::Anon'))
    {
    $n = $self->{name};
    # quote special chars in name
    $n =~ s/([\[\]\(\)\{\}\#])/\\$1/g;
    $n = ' ' . $n;
    }

  my $txt = "($n";

  $n = $self->{nodes};

  $txt .= (keys %$n > 0 ? "\n" : ' ');
  for my $name ( sort keys %$n )
    {
    $n->{$name}->{_p} = 1;                              # mark as processed
    $txt .= '  ' . $n->{$name}->as_pure_txt() . "\n";
    }
  $txt .= ")" . $self->attributes_as_txt() . "\n\n";

  # insert all the edges of the group

  #
  $txt;
  }

#############################################################################

package Graph::Easy::Node;

use strict;

sub attributes_as_txt
  {
  # return the attributes of this node as text description
  my ($self, $remap) = @_;

  # nodes that were autosplit
  if (exists $self->{autosplit})
    {
    # other nodes are invisible in as_txt: 
    return '' unless defined $self->{autosplit};
    # the first one might have had a label set
    }

  my $att = '';
  my $class = $self->class();
  my $g = $self->{graph};

  # XXX TODO: remove atttributes that are simple the default attributes

  my $attributes = $self->{att};
  if (exists $self->{autosplit})
    {
    # for the first node in a row of autosplit nodes, we need to create
    # the correct attributes, e.g. "silver|red|" instead of just silver:
    my $basename = $self->{autosplit_basename};
    $attributes = { };

    my $parts = $self->{autosplit_parts};
    # gather all possible attribute names, otherwise an attribute set
    # on only one part (like via "color: |red;" would not show up:
    my $names = {};
    for my $child ($self, @$parts)
      {
      for my $k (keys %{$child->{att}})
        {
        $names->{$k} = undef;
        }
      }

    for my $k (keys %$names)
      {
      next if $k eq 'basename';
      my $val = $self->{att}->{$k};
      $val = '' unless defined $val;
      my $first = $val; my $not_equal = 0;
      $val .= '|';
      for my $child (@$parts)
        {
        # only consider our own autosplit parts (check should not be nec.)
#        next if !exists $child->{autosplit_basename} ||
#                        $child->{autosplit_basename} ne $basename;

        my $v = $child->{att}->{$k}; $v = '' if !defined $v;
        $not_equal ++ if $v ne $first;
        $val .= $v . '|';
        }
      # all parts equal, so do "red|red|red" => "red"
      $val = $first if $not_equal == 0;

      $val =~ s/\|+\z/\|/;				# "silver|||" => "silver|"
      $val =~ s/\|\z// if $val =~ /\|.*\|/;		# "silver|" => "silver|"
      							# but "red|blue|" => "red|blue"
      $attributes->{$k} = $val unless $val eq '|';	# skip '|'
      }
    $attributes->{basename} = $self->{att}->{basename} if defined $self->{att}->{basename};
    }

  my $new = $g->_remap_attributes( $self, $attributes, $remap, 'noquote', 'encode' );

  # For nodes, we do not output their group attribute, since they simple appear
  # at the right place in the txt:
  delete $new->{group};

  # for groups inside groups, insert their group attribute
  $new->{group} = $self->{group}->{name} 
    if $self->isa('Graph::Easy::Group') && exists $self->{group};

  if (defined $self->{origin})
    {
    $new->{origin} = $self->{origin}->{name};
    $new->{offset} = join(',', $self->offset());
    }

  # shorten output for multi-celled nodes
  # for "rows: 2;" still output "rows: 2;", because it is shorter
  if (exists $new->{columns})
    {
    $new->{size} = ($new->{columns}||1) . ',' . ($new->{rows}||1);
    delete $new->{rows};
    delete $new->{columns};
    # don't output the default size
    delete $new->{size} if $new->{size} eq '1,1';
    } 

  for my $atr (sort keys %$new)
    {
    next if $atr =~ /^border/;                  # handled special

    $att .= "$atr: $new->{$atr}; ";
    }

  if (!$self->isa_cell())
    {
    my $border;
    if (!exists $self->{autosplit})
      {
      $border = $self->border_attribute();
      }
    else
      {
      $border = Graph::Easy::_border_attribute(
	$attributes->{borderstyle}||'',
	$attributes->{borderwidth}||'',
	$attributes->{bordercolor}||'');
      }

    # XXX TODO: should do this for all attributes, not only for border
    # XXX TODO: this seems wrong anyway

    # don't include default border
    $border = '' if ref $g && $g->attribute($class,'border') eq $border;
    $att .= "border: $border; " if $border ne '';
    }

  # if we have a subclass, we probably need to include it
  my $c = '';
  $c = $1 if $class =~ /\.(\w+)/;

  # but we do not need to include it if our group has a nodeclass attribute
  $c = '' if ref($self->{group}) && $self->{group}->attribute('nodeclass') eq $c;

  # include our subclass as attribute
  $att .= "class: $c; " if $c ne '' && $c ne 'anon';

  # generate attribute text if nec.
  $att = ' { ' . $att . '}' if $att ne '';

  $att;
  }

sub _as_part_txt
  {
  # for edges, we need the name of the part of the first part, not the entire
  # autosplit text
  my $self = shift;

  my $name = $self->{name};

  # quote special chars in name
  $name =~ s/([\[\]\|\{\}\#])/\\$1/g;

  '[ ' .  $name . ' ]';
  }

sub as_pure_txt
  {
  my $self = shift;

  if (exists $self->{autosplit} && defined $self->{autosplit})
    {
    my $name = $self->{autosplit};

    # quote special chars in name (but not |)
    $name =~ s/([\[\]\{\}\#])/\\$1/g;
 
    return '[ '. $name .' ]' 
    }

  my $name = $self->{name};

  # quote special chars in name
  $name =~ s/([\[\]\|\{\}\#])/\\$1/g;

  '[ ' .  $name . ' ]';
  }

sub as_txt
  {
  my $self = shift;

  if (exists $self->{autosplit})
    {
    return '' unless defined $self->{autosplit};
    my $name = $self->{autosplit};
    # quote special chars in name (but not |)
    $name =~ s/([\[\]\{\}\#])/\\$1/g;
    return '[ ' . $name . ' ]' 
    }

  my $name = $self->{name};

  # quote special chars in name
  $name =~ s/([\[\]\|\{\}\#])/\\$1/g;

  '[ ' .  $name . ' ]' . $self->attributes_as_txt();
  }

#############################################################################

package Graph::Easy::Edge;

my $styles = {
  solid => '--',
  dotted => '..',
  double => '==',
  'double-dash' => '= ',
  dashed => '- ',
  'dot-dash' => '.-',
  'dot-dot-dash' => '..-',
  wave => '~~',
  };

sub _as_txt
  {
  my $self = shift;

  # '- Name ' or ''
  my $n = $self->{att}->{label}; $n = '' unless defined $n;

  my $left = ' '; $left = ' <' if $self->{bidirectional};
  my $right = '> '; $right = ' ' if $self->{undirected};
  
  my $s = $self->style() || 'solid';

  my $style = '--';

  # suppress border on edges
  my $suppress = { all => { label => undef } };
  if ($s =~ /^(bold|bold-dash|broad|wide|invisible)\z/)
    {
    # output "--> { style: XXX; }"
    $style = '--';
    }
  else
    {
    # output "-->" or "..>" etc
    $suppress->{all}->{style} = undef;

    $style = $styles->{ $s };
    if (!defined $style)
      {
      require Carp;
      Carp::confess ("Unknown edge style '$s'\n");
      }
    }
 
  $n = $style . " $n " if $n ne '';

  # make " -  " into " - -  "
  $style = $style . $style if $self->{undirected} && substr($style,1,1) eq ' ';

  # ' - Name -->' or ' --> ' or ' -- '
  my $a = $self->attributes_as_txt($suppress) . ' '; $a =~ s/^\s//;
  $left . $n . $style . $right . $a;
  }

1;
__END__

=head1 NAME

Graph::Easy::As_txt - Generate textual description from graph object

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

	print $graph->as_txt();

	# prints something like:

	# [ Bonn ] -> [ Berlin ]

=head1 DESCRIPTION

C<Graph::Easy::As_txt> contains just the code for converting a
L<Graph::Easy|Graph::Easy> object to a human-readable textual description.

=head1 EXPORT

Exports nothing.

=head1 SEE ALSO

L<Graph::Easy>.

=head1 AUTHOR

Copyright (C) 2004 - 2007 by Tels L<http://bloodgate.com>

See the LICENSE file for information.

=cut

