#############################################################################
# (c) by Tels 2004. Part of Graph::Easy. An anonymous (invisible) node.
#
#############################################################################

package Graph::Easy::Node::Anon;

use Graph::Easy::Node;

@ISA = qw/Graph::Easy::Node/;
$VERSION = '0.11';

use strict;

sub _init
  {
  my $self = shift;

  $self->SUPER::_init(@_);

  $self->{name} = '#' . $self->{id};
  $self->{class} = 'node.anon';

  $self->{att}->{label} = ' ';

  $self;
  }

sub _correct_size
  {
  my $self = shift;

  $self->{w} = 3;
  $self->{h} = 3;

  $self;
  }

sub attributes_as_txt
  {
  my $self = shift;

  $self->SUPER::attributes_as_txt( {
     node => {
       label => undef,
       shape => undef,
       class => undef,
       } } );
  }

sub as_pure_txt
  {
  '[ ]';
  }

sub _as_part_txt
  {
  '[ ]';
  }

sub as_txt
  {
  my $self = shift;

  '[ ]' . $self->attributes_as_txt();
  }

sub text_styles_as_css
  {
  '';
  }

sub is_anon
  {
  # is an anon node
  1;
  }

1;
__END__

=head1 NAME

Graph::Easy::Node::Anon - An anonymous, invisible node in Graph::Easy

=head1 SYNOPSIS

	use Graph::Easy::Node::Anon;

	my $anon = Graph::Easy::Node::Anon->new();

=head1 DESCRIPTION

A C<Graph::Easy::Node::Anon> represents an anonymous, invisible node.
These can be used to let edges start and end "nowhere".

The syntax in the Graph::Easy textual description language looks like this:

	[ ] -> [ Bonn ] -> [ ]

=head1 EXPORT

None by default.

=head1 SEE ALSO

L<Graph::Easy::Node>.

=head1 AUTHOR

Copyright (C) 2004 - 2006 by Tels L<http://bloodgate.com>.

See the LICENSE file for more details.

=cut
