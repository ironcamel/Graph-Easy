#############################################################################
# (c) by Tels 2004. Part of Graph::Easy. An anonymous group.
#
#############################################################################

package Graph::Easy::Group::Anon;

use Graph::Easy::Group;

@ISA = qw/Graph::Easy::Group/;
$VERSION = '0.02';

use strict;

sub _init
  {
  my $self = shift;

  $self->SUPER::_init(@_);

  $self->{name} = 'Group #' . $self->{id};
  $self->{class} = 'group.anon';

  $self->{att}->{label} = '';

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
  '( )';
  }

sub _as_part_txt
  {
  '( )';
  }

sub as_graphviz_txt
  {
  my $self = shift;
  
  my $name = $self->{name};

  # quote special chars in name
  $name =~ s/([\[\]\(\)\{\}\#])/\\$1/g;

  '"' .  $name . '"';
  }

sub text_styles_as_css
  {
  '';
  }

sub is_anon
  {
  # is an anon group
  1;
  }

1;
__END__

=head1 NAME

Graph::Easy::Group::Anon - An anonymous group of nodes in Graph::Easy

=head1 SYNOPSIS

	use Graph::Easy::Group::Anon;

	my $anon = Graph::Easy::Group::Anon->new();

=head1 DESCRIPTION

A C<Graph::Easy::Group::Anon> represents an anonymous group of nodes,
e.g. a group without a name.

The syntax in the Graph::Easy textual description language looks like this:

	( [ Bonn ] -> [ Berlin ] )

This module is loaded and used automatically by Graph::Easy, so there is
no need to use it manually.

=head1 EXPORT

None by default.

=head1 SEE ALSO

L<Graph::Easy::Group>.

=head1 AUTHOR

Copyright (C) 2004 - 2006 by Tels L<http://bloodgate.com>.

See the LICENSE file for more details.

=cut
