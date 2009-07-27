#############################################################################
# An empty, borderless cell. Part of Graph::Easy.
#
#############################################################################

package Graph::Easy::Node::Empty;

use Graph::Easy::Node;

@ISA = qw/Graph::Easy::Node/;
$VERSION = '0.06';

use strict;

#############################################################################

sub _init
  {
  # generic init, override in subclasses
  my ($self,$args) = @_;

  $self->SUPER::_init($args);
  
  $self->{class} = 'node.empty';

  $self;
  }

sub _correct_size
  {
  my $self = shift;

  $self->{w} = 3;
  $self->{h} = 3;

  $self;
  }

1;
__END__

=head1 NAME

Graph::Easy::Node::Empty - An empty, borderless cell in a node cluster

=head1 SYNOPSIS

	my $cell = Graph::Easy::Node::Empty->new();

=head1 DESCRIPTION

A C<Graph::Easy::Node::Empty> represents a borderless, empty cell in
a node cluster. It is mainly used to have an object to render collapsed
borders in ASCII output.

You should not need to use this class directly.

=head1 SEE ALSO

L<Graph::Easy::Node>.

=head1 AUTHOR

Copyright (C) 2004 - 2007 by Tels L<http://bloodgate.com>.

See the LICENSE file for more details.

=cut
