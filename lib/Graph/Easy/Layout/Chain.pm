#############################################################################
# One chain of nodes in a Graph::Easy - used internally for layouts.
#
# (c) by Tels 2004-2006. Part of Graph::Easy
#############################################################################

package Graph::Easy::Layout::Chain;

use Graph::Easy::Base;
$VERSION = '0.09';
@ISA = qw/Graph::Easy::Base/;

use strict;

use constant {
  _ACTION_NODE  => 0, # place node somewhere
  _ACTION_TRACE => 1, # trace path from src to dest
  _ACTION_CHAIN => 2, # place node in chain (with parent)
  _ACTION_EDGES => 3, # trace all edges (shortes connect. first)
  };

#############################################################################

sub _init
  {
  # Generic init routine, to be overriden in subclasses.
  my ($self,$args) = @_;
  
  foreach my $k (keys %$args)
    {
    if ($k !~ /^(start|graph)\z/)
      {
      require Carp;
      Carp::confess ("Invalid argument '$k' passed to __PACKAGE__->new()");
      }
    $self->{$k} = $args->{$k};
    }
 
  $self->{end} = $self->{start};
 
  # store chain at node (to lookup node => chain info)
  $self->{start}->{_chain} = $self;
  $self->{start}->{_next} = undef;

  $self->{len} = 1;

  $self;
  }

sub start
  {
  # return first node in the chain
  my $self = shift;

  $self->{start};
  }

sub end
  {
  # return last node in the chain
  my $self = shift;

  $self->{end};
  }

sub add_node
  {
  # add a node at the end of the chain
  my ($self, $node) = @_;

  # store at end
  $self->{end}->{_next} = $node;
  $self->{end} = $node;

  # store chain at node (to lookup node => chain info)
  $node->{_chain} = $self;
  $node->{_next} = undef;
  
  $self->{len} ++;

  $self;
  }

sub length
  {
  # Return the length of the chain in nodes. Takes optional
  # node from where to calculate length.
  my ($self, $node) = @_;

  return $self->{len} unless defined $node;

  my $len = 0;
  while (defined $node)
    {
    $len++; $node = $node->{_next};
    }

  $len;
  }

sub nodes
  {
  # return all the nodes in the chain as a list, in order.
  my $self = shift;

  my @nodes = ();
  my $n = $self->{start};
  while (defined $n)
    {
    push @nodes, $n;
    $n = $n->{_next};
    }

  @nodes;
  }

sub layout
  {
  # Return an action stack containing the nec. actions to
  # lay out the nodes in the chain, plus any connections between
  # them.
  my ($self, $edge) = @_;

  # prevent doing it twice 
  return [] if $self->{_done}; $self->{_done} = 1;

  my @TODO = ();

  my $g = $self->{graph};

  # first, layout all the nodes in the chain:

  # start with first node
  my $pre = $self->{start}; my $n = $pre->{_next};
  if (exists $pre->{_todo})
    {
    # edges with a flow attribute must be handled differently
    # XXX TODO: the test for attribute('flow') might be wrong (raw_attribute()?)
    if ($edge && ($edge->{to} == $pre) && ($edge->attribute('flow') || $edge->has_ports()))
      {
      push @TODO, $g->_action( _ACTION_CHAIN, $pre, 0, $edge->{from}, $edge);
      }
    else
      {
      push @TODO, $g->_action( _ACTION_NODE, $pre, 0, $edge );
      }
    }

  print STDERR "# Stack after first:\n" if $g->{debug};
  $g->_dump_stack(@TODO) if $g->{debug};

  while (defined $n)
    {
    if (exists $n->{_todo})
      {
      # CHAIN means if $n isn't placed yet, it will be done with
      # $pre as parent:

      # in case there are multiple edges to the target node, use the first
      # one to determine the flow:
      my @edges = $g->edge($pre,$n);

      push @TODO, $g->_action( _ACTION_CHAIN, $n, 0, $pre, $edges[0] );
      }
    $pre = $n;
    $n = $n->{_next};
    }

  print STDERR "# Stack after chaining:\n" if $g->{debug};
  $g->_dump_stack(@TODO) if $g->{debug};

  # link from each node to the next
  $pre = $self->{start}; $n = $pre->{_next};
  while (defined $n)
    {
    # first do edges going from P to N
    #for my $e (sort { $a->{to}->{name} cmp $b->{to}->{name} } values %{$pre->{edges}})
    for my $e (values %{$pre->{edges}})
      {
      # skip selfloops and backward links, these will be done later
      next if $e->{to} != $n;

      next unless exists $e->{_todo};

      # skip links from/to groups
      next if $e->{to}->isa('Graph::Easy::Group') ||
              $e->{from}->isa('Graph::Easy::Group');

#      # skip edges with a flow
#      next if exists $e->{att}->{start} || exist $e->{att}->{end};

      push @TODO, [ _ACTION_TRACE, $e ];
      delete $e->{_todo};
      }

    } continue { $pre = $n; $n = $n->{_next}; }

  print STDERR "# Stack after chain-linking:\n" if $g->{debug};
  $g->_dump_stack(@TODO) if $g->{debug};

  # Do all other links inside the chain (backwards, going forward more than
  # one node etc)

  $n = $self->{start};
  while (defined $n)
    {
    my @edges;

    my @count;

    print STDERR "# inter-chain link from $n->{name}\n" if $g->{debug};

    # gather all edges starting at $n, but do the ones with a flow first
#    for my $e (sort { $a->{to}->{name} cmp $b->{to}->{name} } values %{$n->{edges}})
    for my $e (values %{$n->{edges}})
      {
      # skip selfloops, these will be done later
      next if $e->{to} == $n;

      next if !ref($e->{to}->{_chain});
      next if !ref($e->{from}->{_chain});

      next if $e->has_ports();

      # skip links from/to groups
      next if $e->{to}->isa('Graph::Easy::Group') ||
              $e->{from}->isa('Graph::Easy::Group');

      print STDERR "# inter-chain link from $n->{name} to $e->{to}->{name}\n" if $g->{debug};

      # leaving the chain?
      next if $e->{to}->{_chain} != $self;

#      print STDERR "#    trying for $n->{name}:\t $e->{from}->{name} to $e->{to}->{name}\n";
      next unless exists $e->{_todo};

      # calculate for this edge, how far it goes
      my $count = 0;
      my $curr = $n;
      while (defined $curr && $curr != $e->{to})
        {
        $curr = $curr->{_next}; $count ++;
        }
      if (!defined $curr)
        {
        # edge goes backward

        # start at $to
        $curr = $e->{to};
        $count = 0;
        while (defined $curr && $curr != $e->{from})
          {
          $curr = $curr->{_next}; $count ++;
          }
        $count = 100000 if !defined $curr;	# should not happen
        }
      push @edges, [ $count, $e ];
      push @count, [ $count, $e->{from}->{name}, $e->{to}->{name} ];
      }

#    use Data::Dumper; print STDERR "count\n", Dumper(@count);

    # do edges, shortest first 
    for my $e (sort { $a->[0] <=> $b->[0] } @edges)
      {
      push @TODO, [ _ACTION_TRACE, $e->[1] ];
      delete $e->[1]->{_todo};
      }

    $n = $n->{_next};
    }
 
  # also do all selfloops on $n
  $n = $self->{start};
  while (defined $n)
    {
#    for my $e (sort { $a->{to}->{name} cmp $b->{to}->{name} } values %{$n->{edges}})
    for my $e (values %{$n->{edges}})
      {
      next unless exists $e->{_todo};

#      print STDERR "# $e->{from}->{name} to $e->{to}->{name} on $n->{name}\n";
#      print STDERR "# ne $e->{to} $n $e->{id}\n" 
#       if $e->{from} != $n || $e->{to} != $n;		# no selfloop?

      next if $e->{from} != $n || $e->{to} != $n;	# no selfloop?

      push @TODO, [ _ACTION_TRACE, $e ];
      delete $e->{_todo};
      }
    $n = $n->{_next};
    }

  print STDERR "# Stack after self-loops:\n" if $g->{debug};
  $g->_dump_stack(@TODO) if $g->{debug};

  # XXX TODO
  # now we should do any links that start or end at this chain, recursively

  $n = $self->{start};
  while (defined $n)
    {

    # all chains that start at this node
    for my $e (sort { $a->{to}->{name} cmp $b->{to}->{name} } values %{$n->{edges}})
      {
      my $to = $e->{to};

      # skip links to groups
      next if $to->isa('Graph::Easy::Group');

#      print STDERR "# chain-tracking to: $to->{name} $to->{_chain}\n";

      next unless exists $to->{_chain} && ref($to->{_chain}) =~ /Chain/;
      my $chain = $to->{_chain};
      next if $chain->{_done};

#      print STDERR "# chain-tracking to: $to->{name}\n";

      # pass the edge along, in case it has a flow
#      my @pass = ();
#      push @pass, $e if $chain->{_first} && $e->{to} == $chain->{_first};
      push @TODO, @{ $chain->layout($e) } unless $chain->{_done};

      # link the edges to $to
      next unless exists $e->{_todo};	# was already done above?

      # next if $e->has_ports();

      push @TODO, [ _ACTION_TRACE, $e ];
      delete $e->{_todo};
      }
    $n = $n->{_next};
    }
 
  \@TODO;
  }

sub dump
  {
  # dump the chain to STDERR
  my ($self, $indent) = @_;

  $indent = '' unless defined $indent;

  print STDERR "#$indent chain id $self->{id} (len $self->{len}):\n";
  print STDERR "#$indent is empty\n" and return if $self->{len} == 0;

  my $n = $self->{start};
  while (defined $n)
    {
    print STDERR "#$indent  $n->{name} (chain id: $n->{_chain}->{id})\n";
    $n = $n->{_next};
    }
  $self;
  }

sub merge
  {
  # take another chain, and merge it into ourselves. If $where is defined,
  # absorb only the nodes from $where onwards (instead of all of them).
  my ($self, $other, $where) = @_;

  my $g = $self->{graph};

  print STDERR "# panik: ", join(" \n",caller()),"\n" if !defined $other;

  print STDERR 
   "# Merging chain $other->{id} (len $other->{len}) into $self->{id} (len $self->{len})\n"
     if $g->{debug};

  print STDERR 
   "# Merging from $where->{name} onwards\n"
     if $g->{debug} && ref($where);
 
  # cannot merge myself into myself (without allocating infinitely memory)
  return if $self == $other;

  # start at start as default
  $where = undef unless ref($where) && exists $where->{_chain} && $where->{_chain} == $other;

  $where = $other->{start} unless defined $where;
  
  # make all nodes from chain #1 belong to it (to detect loops)
  my $n = $self->{start};
  while (defined $n)
    {
    $n->{_chain} = $self;
    $n = $n->{_next};
    }

  print STDERR "# changed nodes\n" if $g->{debug};
  $self->dump() if $g->{debug};

  # terminate at $where
  $self->{end}->{_next} = $where;
  $self->{end} = $other->{end};

  # start at joiner
  $n = $where;
  while (ref($n))
    {
    $n->{_chain} = $self;
    my $pre = $n;
    $n = $n->{_next};

#    sleep(1);
#    print "# at $n->{name} $n->{_chain}\n" if ref($n);
    if (ref($n) && defined $n->{_chain} && $n->{_chain} == $self)	# already points into ourself?
      {
#      sleep(1);
#      print "# pre $pre->{name} $pre->{_chain}\n";
      $pre->{_next} = undef;	# terminate
      $self->{end} = $pre;
      last;
      }
    }

  # could speed this up
  $self->{len} = 0; $n = $self->{start};
  while (defined $n)
    {
    $self->{len}++; $n = $n->{_next};
    }

#  print "done merging, dumping result:\n";
#  $self->dump(); sleep(10);

  if (defined $other->{start} && $where == $other->{start})
    {
    # we absorbed the other chain completely, so drop it
    $other->{end} = undef;
    $other->{start} = undef;
    $other->{len} = 0;
    # caller is responsible for cleaning it up
    }

  print STDERR "# after merging\n" if $g->{debug};
  $self->dump() if $g->{debug};

  $self;
  }

1;
__END__

=head1 NAME

Graph::Easy::Layout::Chain - Chain of nodes for layouter

=head1 SYNOPSIS

	# used internally, do not use directly

        use Graph::Easy;
        use Graph::Easy::Layout::Chain;

	my $graph = Graph::Easy->new( );
	my ($node, $node2) = $graph->add_edge( 'A', 'B' );

	my $chain = Graph::Easy::Layout::Chain->new(
		start => $node,
		graph => $graph, );

	$chain->add_node( $node2 );

=head1 DESCRIPTION

A C<Graph::Easy::Layout::Chain> object represents a chain of nodes
for the layouter.

=head1 METHODS

=head2 new()

        my $chain = Graph::Easy::Layout::Chain->new( start => $node );

Create a new chain and set its starting node to C<$node>.

=head2 length()

	my $len = $chain->length();

Return the length of the chain, in nodes.

	my $len = $chain->length( $node );

Given an optional C<$node> as argument, returns the length
from that node onwards. For the chain with the three nodes
A, B and C would return 3, 2, and 1 for A, B and C, respectively.

Returns 0 if the passed node is not part of this chain.

=head2 nodes()

	my @nodes = $chain->nodes();

Return all the node objects in the chain as list, in order.

=head2 add_node()

	$chain->add_node( $node );

Add C<$node> to the end of the chain.

=head2 start()

	my $node = $chain->start();

Return first node in the chain.

=head2 end()

	my $node = $chain->end();

Return last node in the chain.

=head2 layout()

	my $todo = $chain->layout();

Return an action stack as array ref, containing the nec. actions to 
layout the chain (nodes, plus interlinks in the chain).

Will recursively traverse all chains linked to this chain.

=head2 merge()

	my $chain->merge ( $other_chain );
	my $chain->merge ( $other_chain, $where );

Merge the other chain into ourselves, adding its nodes at our end.
The other chain is emptied and must be deleted by the caller.
  
If C<$where> is defined and a member of C<$other_chain>, absorb only the
nodes from C<$where> onwards, instead of all of them.

=head2 error()

	$last_error = $node->error();

	$node->error($error);			# set new messags
	$node->error('');			# clear error

Returns the last error message, or '' for no error.

=head2 dump()

	$chain->dump();

Dump the chain to STDERR, to aid debugging.

=head1 EXPORT

None by default.

=head1 SEE ALSO

L<Graph::Easy>, L<Graph::Easy::Layout>.

=head1 AUTHOR

Copyright (C) 2004 - 2006 by Tels L<http://bloodgate.com>.

See the LICENSE file for more details.

=cut
