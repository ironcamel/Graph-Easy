#############################################################################
# (c) by Tels 2004 - 2005. An empty filler cell. Part of Graph::Easy.
#
#############################################################################

package Graph::Easy::Node::Cell;

use Graph::Easy::Node;

@ISA = qw/Graph::Easy::Node/;
$VERSION = '0.10';

use strict;

#############################################################################

sub _init
  {
  # generic init, override in subclasses
  my ($self,$args) = @_;
  
  $self->{class} = '';
  $self->{name} = '';
  
  $self->{x} = 0;
  $self->{y} = 0;

  # default: belongs to no node
  $self->{node} = undef;

  foreach my $k (keys %$args)
    {
    if ($k !~ /^(node|graph|x|y)\z/)
      {
      require Carp;
      Carp::confess ("Invalid argument '$k' passed to Graph::Easy::Node::Cell->new()");
      }
    $self->{$k} = $args->{$k};
    }
 
  $self;
  }

sub _correct_size
  {
  my $self = shift;

  $self->{w} = 0;
  $self->{h} = 0;

  $self;
  }

sub node
  {
  # return the node this cell belongs to
  my $self = shift;

  $self->{node};
  }

sub as_ascii
  {
  '';
  }

sub as_html
  {
  '';
  }

sub group
  {
  my $self = shift;

  $self->{node}->group();
  }

1;
__END__

=head1 NAME

Graph::Easy::Node::Cell - An empty filler cell

=head1 SYNOPSIS

        use Graph::Easy;
        use Graph::Easy::Edge;

	my $graph = Graph::Easy->new();

	my $node = $graph->add_node('A');

	my $path = Graph::Easy::Node::Cell->new(
	  graph => $graph, node => $node,
	);

	...

	print $graph->as_ascii();

=head1 DESCRIPTION

A C<Graph::Easy::Node::Cell> is used to reserve a cell in the grid for nodes
that occupy more than one cell.

You should not need to use this class directly.

=head1 METHODS

=head2 error()

	$last_error = $cell->error();

	$cvt->error($error);			# set new messags
	$cvt->error('');			# clear error

Returns the last error message, or '' for no error.

=head2 node()

	my $node = $cell->node();

Returns the node this filler cell belongs to.

=head1 SEE ALSO

L<Graph::Easy>.

=head1 AUTHOR

Copyright (C) 2004 - 2005 by Tels L<http://bloodgate.com>.

See the LICENSE file for more details.

=cut
