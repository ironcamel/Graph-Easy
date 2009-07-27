#############################################################################
# Layout directed graphs on a flat plane. Part of Graph::Easy.
#
# (c) by Tels 2004-2008.
#############################################################################

package Graph::Easy::Layout;

$VERSION = '0.29';

#############################################################################
#############################################################################

package Graph::Easy;

use strict;
require Graph::Easy::Node::Cell;
use Graph::Easy::Edge::Cell qw/
  EDGE_HOR EDGE_VER
  EDGE_CROSS
  EDGE_TYPE_MASK EDGE_MISC_MASK EDGE_NO_M_MASK
  EDGE_SHORT_CELL
 /;

use constant {
  ACTION_NODE	=> 0,	# place node somewhere
  ACTION_TRACE	=> 1,	# trace path from src to dest
  ACTION_CHAIN	=> 2,	# place node in chain (with parent)
  ACTION_EDGES	=> 3,	# trace all edges (shortes connect. first)
  ACTION_SPLICE	=> 4,	# splice in the group fillers
  };

require Graph::Easy::Layout::Chain;		# chain management
use Graph::Easy::Layout::Scout;			# pathfinding
use Graph::Easy::Layout::Repair;		# group cells and splicing/repair
use Graph::Easy::Layout::Path;			# path management

#############################################################################

sub _assign_ranks
  {
  # Assign a rank to each node/group.

  # Afterwards, every node has a rank, these range from 1..infinite for
  # user supplied ranks, and -1..-infinite for automatically found ranks.
  # This lets us later distinguish between autoranks and userranks, while
  # still being able to sort nodes based on their (absolute) rank.
  my $self = shift;

  # a Heap to keep the todo-nodes (aka rank auto or explicit)
  my $todo = Graph::Easy::Heap->new();
  # sort entries based on absolute value
  $todo->sort_sub( sub ($$) { abs($_[0]) <=> abs($_[1]) } );

  # a list of all other nodes
  my @also;

  # XXX TODO:
  # gather elements todo:
  # graph: contained groups, plus non-grouped nodes
  # groups: contained groups, contained nodes

  # sort nodes on their ID to get some basic order
  my @N = $self->sorted_nodes('id');
  push @N, $self->groups();

  my $root = $self->root_node();

  $todo->add([$root->{rank} = -1,$root]) if ref $root;

  # Gather all nodes that have outgoing connections, but no incoming:
  for my $n (@N)
    {
    # we already handled the root node above
    next if $root && $n == $root;

    # if no rank set, use 0 as default
    my $rank_att = $n->raw_attribute('rank');

    $rank_att = undef if defined $rank_att && $rank_att eq 'auto';
    # XXX TODO: this should not happen, the parser should assign an
    # automatic rank ID
    $rank_att = 0 if defined $rank_att && $rank_att eq 'same';

    # user defined ranks range from 1..inf
    $rank_att++ if defined $rank_att;

    # assign undef or 0, 1 etc
    $n->{rank} = $rank_att;

    # user defined ranks are "1..inf", while auto ranks are -1..-inf
    $n->{rank} = -1 if !defined $n->{rank} && $n->predecessors() == 0;

    # push "rank: X;" nodes, or nodes without predecessors
    $todo->add([$n->{rank},$n]) if defined $n->{rank};
    push @also, $n unless defined $n->{rank};
    }

#  print STDERR "# Ranking:\n";
#  for my $n (@{$todo->{_heap}})
#    {
#    print STDERR "# $n->[1]->{name} $n->[0] $n->[1]->{rank}:\n";
#    }
#  print STDERR "# Leftovers in \@also:\n";
#  for my $n (@also)
#    {
#    print STDERR "# $n->{name}:\n";
#    }

  # The above step will create a list of todo nodes that start a chain, but
  # it will miss circular chains like CDEC (e.g. only A appears in todo):
  # A -> B;  C -> D -> E -> C;
  # We fix this as last step

  while ((@also != 0) || $todo->elements() != 0)
    {
    # while we still have nodes to follow
    while (my $elem = $todo->extract_top())
      {
      my ($rank,$n) = @$elem;

      my $l = $n->{rank};

      # If the rank comes from a user-supplied rank, make the next node
      # have an automatic rank (e.g. 4 => -4)
      $l = -$l if $l > 0; 
      # -4 > -5
      $l--;

      for my $o ($n->successors())
        {
        if (!defined $o->{rank})
          {
#	  print STDERR "# set rank $l for $o->{name}\n";
          $o->{rank} = $l;
	  $todo->add([$l,$o]);
          }
        }
      }

    last unless @also;

    while (@also)
      {
      my $n = shift @also;
      # already done? so skip it
      next if defined $n->{rank};

      $n->{rank} = -1; 
      $todo->add([-1, $n]);
      # leave the others for later
      last;
      }

    } # while still something todo

#  print STDERR "# Final ranking:\n";
#  for my $n (@N)
#    {
#    print STDERR "# $n->{name} $n->{rank}:\n";
#    }

  $self;
  }

sub _follow_chain
  {
  # follow the chain from the node
  my ($node) = @_;

  my $self = $node->{graph};

  no warnings 'recursion';

  my $indent = ' ' x (($node->{_chain}->{id} || 0) + 1);
  print STDERR "#$indent Tracking chain from $node->{name}\n" if $self->{debug};

  # create a new chain and point it to the start node
  my $chain = Graph::Easy::Layout::Chain->new( start => $node, graph => $self );
  $self->{chains}->{ $chain->{id} } = $chain;

  my $first_node = $node;
  my $done = 1;				# how many nodes did we process?
 NODE:
  while (3 < 5)
    {
    # Count "unique" successsors, ignoring selfloops, multiedges and nodes
    # in the same chain.

    my $c = $node->{_chain};

    local $node->{_c} = 1;		# stop back-ward loops

    my %suc;

    for my $e (values %{$node->{edges}})
      {
      my $to = $e->{to};

      # ignore self-loops
      next if $e->{from} == $e->{to};

      # XXX TODO
      # skip links from/to groups
      next if $e->{to}->isa('Graph::Easy::Group') ||
              $e->{from}->isa('Graph::Easy::Group');

#      print STDERR "# bidi $e->{from}->{name} to $e->{to}->{name}\n" if $e->{bidirectional} && $to == $node;

      # if it is bidirectional, and points the "wrong" way, turn it around
      $to = $e->{from} if $e->{bidirectional} && $to == $node;

      # edge leads to this node instead from it?
      next if $to == $node;

#      print STDERR "# edge_flow for edge $e", $e->edge_flow() || 'undef' ,"\n";
#      print STDERR "# flow for edge $e", $e->flow() ,"\n";

      # If any of the leading out edges has a flow, stop the chain here
      # This prevents a chain on an edge w/o a flow to be longer and thus
      # come first instead of a flow-edge. But don't stop if there is only
      # one edge:

      if (defined $e->edge_flow())
	{
        %suc = ( $to->{name} => $to );		# empy any possible chain info
        last;
        }

      next if exists $to->{_c};		# backloop into current branch?

      next if defined $to->{_chain} &&	# ignore if it points to the same
		$to->{_chain} == $c; 	# chain (backloop)

      # if the next node's grandparent is the same as ours, it depends on us
      next if $to->find_grandparent() == $node->find_grandparent();

					# ignore multi-edges by dropping
      $suc{$to->{name}} = $to;		# duplicates
      }

    last if keys %suc == 0;		# the chain stopped here

    if (scalar keys %suc == 1)		# have only one unique successor?
      {
      my $s = $suc{ each %suc };

      if (!defined $s->{_chain})	# chain already done?
        {
        $c->add_node( $s );

        $node = $s;			# next node

        print STDERR "#$indent Skipping ahead to $node->{name}\n" if $self->{debug};

        $done++;			# one more
        next NODE;			# skip recursion
        }
      }

    # Select the longest chain from the list of successors
    # and join it with the current one:

    my $max = -1;
    my $next;				# successor
    my $next_chain = undef;

    print STDERR "#$indent $node->{name} successors: \n" if $self->{debug};

    my @rc;

    # for all successors
    #for my $s (sort { $a->{name} cmp $b->{name} || $a->{id} <=> $b->{id} }  values %suc)
    for my $s (values %suc)
      {
      print STDERR "# suc $s->{name} chain ", $s->{_chain} || 'undef',"\n" if $self->{debug};

      $done += _follow_chain($s) 	# track chain
       if !defined $s->{_chain};	# if not already done

      next if $s->{_chain} == $c;	# skip backlinks

      my $ch = $s->{_chain};

      push @rc, [ $ch, $s ];
      # point node to new next node
      ($next_chain, $max, $next) = 
	($ch, $ch->{len}, $s) if $ch->{len} > $max;
      }

    if (defined $next_chain && $self->{debug})
      {
      print STDERR "#   results of tracking successors:\n";
      for my $ch (@rc)
        {
        my ($c,$s) = @$ch;
        my $len = $c->length($s);
        print STDERR "#    chain $c->{id} starting at $c->{start}->{name} (len $c->{len}) ".
                     " pointing to node $s->{name} (len from there: $len)\n";
        }
      print STDERR "# Max chain length is $max (chain id $next_chain->{id})\n";
      }

    if (defined $next_chain)
      {
      print STDERR "#$indent $node->{name} next: " . $next_chain->start()->{name} . "\n" if $self->{debug};

      if ($self->{debug})
	{
	print STDERR "# merging chains\n";
	$c->dump(); $next_chain->dump();
	}

      $c->merge($next_chain, $next)		# merge the two chains
	unless $next == $self->{_root}		# except if the next chain starts with
						# the root node (bug until v0.46)
;#	 || $next_chain->{start} == $self->{_root}; # or the first chain already starts
						# with the root node (bug until v0.47)

      delete $self->{chains}->{$next_chain->{id}} if $next_chain->{len} == 0;
      }

    last;
    }
  
  print STDERR "#$indent Chain $node->{_chain} ended at $node->{name}\n" if $self->{debug};

  $done;				# return nr of done nodes
  }

sub _find_chains
  {
  # Track all node chains (A->B->C etc), trying to find the longest possible
  # node chain. Returns (one of) the root node(s) of the graph.
  my $self = shift;

  print STDERR "# Tracking chains\n" if $self->{debug};

  # drop all old chain info
  $self->{_chains} = { };
  $self->{_chain} = 0;					# new chain ID

  # For all not-done-yet nodes, track the chain starting with that node.

  # compute predecessors for all nodes: O(1)
  my $p;
  my $has_origin = 0;
  foreach my $n (values %{$self->{nodes}}, values %{$self->{groups}})
#  for my $n (values %{$self->{nodes}})
    {
    $n->{_chain} = undef;				# reset chain info
    $has_origin = 0;
    $has_origin = 1 if defined $n->{origin} && $n->{origin} != $n;
    $p->{$n->{name}} = [ $n->has_predecessors(), $has_origin, abs($n->{rank}) ];
    }

  my $done = 0; my $todo = scalar keys %{$self->{nodes}};

  # the node where the layout should start, as name
  my $root_name = $self->{attr}->{root};
  $self->{_root} = undef;				# as ref to a Node object

  # Start at nodes with no predecessors (starting points) and then do the rest:
  for my $name ($root_name, sort {
    my $aa = $p->{$a};
    my $bb = $p->{$b};

    # sort first on rank
    $aa->[2] <=> $bb->[2] ||
    # nodes that have an origin come last
    $aa->[1] <=> $bb->[1] ||
    # nodes with no predecessorts are to be prefered 
    $aa->[0] <=> $bb->[0] ||
    # last resort, alphabetically sorted
    $a cmp $b 
   } keys %$p)
    {
    next unless defined $name;		# in case no root was set, first entry
					# will be undef and must be skipped
    my $n = $self->{nodes}->{$name};

#    print STDERR "# tracing chain from $name (", join(", ", @{$p->{$name}}),")\n";

    # store root node unless already found, is accessed in _follow_chain()
    $self->{_root} = $n unless defined $self->{_root};

    last if $done == $todo;			# already processed all nodes?

    # track the chain unless already done and count number of nodes done
    $done += _follow_chain($n) unless defined $n->{_chain};
    }

  print STDERR "# Oops - done only $done nodes, but should have done $todo.\n" if $done != $todo && $self->{debug};
  print STDERR "# Done all $todo nodes.\n" if $done == $todo && $self->{debug};

  $self->{_root};
  }

#############################################################################
# debug

sub _dump_stack
  {
  my ($self, @todo) = @_;

  print STDERR "# Action stack contains ", scalar @todo, " steps:\n";
  for my $action (@todo)
    {
    my $action_type = $action->[0];
    if ($action_type == ACTION_NODE)
      {
      my ($at,$node,$try,$edge) = @$action;
      my $e = ''; $e = " on edge $edge->{id}" if defined $edge;
      print STDERR "#  place '$node->{name}' with try $try$e\n";
      }
    elsif ($action_type == ACTION_CHAIN)
      {
      my ($at, $node, $try, $parent, $edge) = @$action;
      my $id = 'unknown'; $id = $edge->{id} if ref($edge);
      print STDERR
       "#  chain '$node->{name}' from parent '$parent->{name}' with try $try (for edge id $id)'\n";
      }
    elsif ($action_type == ACTION_TRACE)
      {
      my ($at,$edge) = @$action;
      my ($src,$dst) = ($edge->{from}, $edge->{to});
      print STDERR
       "#  trace '$src->{name}' to '$dst->{name}' via edge $edge->{id}\n";
      }
    elsif ($action_type == ACTION_EDGES)
      {
      my $at = shift @$action;
      print STDERR
       "#  tracing the following edges, shortest and with flow first:\n";

      }
    elsif ($action_type == ACTION_SPLICE)
      {
      my ($at) = @$action;
      print STDERR
       "#  splicing in group filler cells\n";
      }
    }
  }

sub _action
  {
  # generate an action for the action stack toplace a node
  my ($self, $action, $node, @params) = @_;

  # mark the node as already done
  delete $node->{_todo};

  # mark all children of $node as processed, too, because they will be
  # placed at the same time:
  $node->_mark_as_placed() if keys %{$node->{children}} > 0;

  [ $action, $node, @params ];
  }

#############################################################################
# layout the graph

# The general layout routine for the entire graph:

sub layout
  {
  my $self = shift;

  # ( { type => 'force' } )
  my $args = $_[0];
  # ( type => 'force' )
  $args = { @_ } if @_ > 1;

  my $type = 'adhoc';
  $type = 'force' if $args->{type} && $args->{type} eq 'force';

  # protect the layout with a timeout, unless run under the debugger:
  eval {
    local $SIG{ALRM} = sub { die "layout did not finish in time\n" };
    alarm(abs( $args->{timeout} || $self->{timeout} || 5))
	unless defined $DB::single; # no timeout under the debugger

    print STDERR "#\n# Starting $type-based layout.\n" if $self->{debug};

    # Reset the sequence of the random generator, so that for the same
    # seed, the same layout will occur. Both for testing and repeatable
    # layouts based on max score.
    srand($self->{seed});

    if ($type eq 'force')
      {
      require Graph::Easy::Layout::Force;
      $self->error("Force-directed layouts are not yet implemented.");
      $self->_layout_force();
      }
    else
      {
      $self->_edges_into_groups();

      $self->_layout();
      }

    };					# eval {}; -- end of timeout protected code

  alarm(0);				# disable alarm

  # cleanup
  $self->{chains} = undef;		# drop chain info
  foreach my $n (values %{$self->{nodes}}, values %{$self->{groups}})
    {
    # drop old chain info
    $n->{_next} = undef;
    delete $n->{_chain};
    delete $n->{_c};
    }

  delete $self->{_root};

  die $@ if $@;				# propagate errors
  }

sub _drop_caches
  {
  # before the layout phase, we drop cached information from the last run
  my $self = shift;

  for my $n (values %{$self->{nodes}})
    {
    # XXX after we laid out the individual groups:    
    # skip nodes that are not part of the current group
    #next if $n->{group} && !$self->{graph};

    # empty the cache of computed values (flow, label, border etc)
    $n->{cache} = {};

    $n->{x} = undef; $n->{y} = undef;	# mark every node as not placed yet
    $n->{w} = undef;			# force size recalculation
    $n->{_todo} = undef;		# mark as todo
    }
  for my $g (values %{$self->{groups}})
    {
    $g->{x} = undef; $g->{y} = undef;	# mark every group as not placed yet
    $g->{_todo} = undef;		# mark as todo
    }
  }

sub _layout
  {
  my $self = shift;

  ###########################################################################
  # do some assorted stuff beforehand

  print STDERR "# Doing layout for ", 
	(defined $self->{name} ? 'group ' . $self->{name} : 'main graph'),
	"\n" if $self->{debug};

  # XXX TODO: 
  # for each primary group
#  my @groups = $self->groups_within(0);
#
#  if (@groups > 0 && $self->{debug})
#    {
#    print STDERR "# Found the following top-level groups:\n";
#    for my $g (@groups)
#      {
#      print STDERR "# $g $g->{name}\n";
#      }
#    }
#
#  # layout each group on its own, recursively:
#  foreach my $g (@groups)
#    {
#    $g->_layout();
#    }

  # finally assembly everything together

  $self->_drop_caches();

  local $_; $_->_grow() for values %{$self->{nodes}};

  $self->_assign_ranks();

  # find (longest possible) chains of nodes to "straighten" graph
  my $root = $self->_find_chains();

  ###########################################################################
  # prepare our stack of things we need to do before we are finished

  # action stack, place root 1st if it is known
  my @todo = $self->_action( ACTION_NODE, $root, 0 ) if ref $root;

  if ($self->{debug})
    {
    print STDERR "#  Generated the following chains:\n";
    for my $chain (
     sort { $a->{len} <=> $b->{len} || $a->{start}->{name} cmp $b->{start}->{name} }
      values %{$self->{chains}})
      {
      $chain->dump('  ');
      }
    }

  # mark all edges as unprocessed, so that we do not process them twice
  for my $edge (values %{$self->{edges}})
    { 
    $edge->_clear_cells();
    $edge->{_todo} = undef;		# mark as todo
    }

  # XXX TODO:
  # put all chains on heap (based on their len)
  # take longest chain, resolve it and all "connected" chains, repeat until
  # heap is empty

  for my $chain (sort { 

     # chain starting at root first
     (($b->{start} == $root) <=> ($a->{start} == $root)) ||

     # longest chains first
     ($b->{len} <=> $a->{len}) ||

     # chains on nodes that do have an origin come later
     (defined($a->{start}->{origin}) <=> defined ($b->{start}->{origin})) ||

     # last resort, sort on name of the first node in chain
     ($a->{start}->{name} cmp $b->{start}->{name}) 

     } values %{$self->{chains}})
    {
    print STDERR "# laying out chain $chain->{id} (len $chain->{len})\n" if $self->{debug};

    # layout the chain nodes, then resolve inter-chain links, then traverse
    # chains recursively
    push @todo, @{ $chain->layout() } unless $chain->{_done};
    }

  print STDERR "# Done laying out all chains, doing left-overs:\n" if $self->{debug};

  $self->_dump_stack(@todo) if $self->{debug};

  # After laying out all chained nodes and their links, we need to resolve
  # left-over edges and links. We do this for each node, and then for each of
  # its edges, but do the edges shortest-first.
 
  for my $n (values %{$self->{nodes}})
    {
    push @todo, $self->_action( ACTION_NODE, $n, 0 ); # if exists $n->{_todo};

    # gather to-do edges
    my @edges = ();
    for my $e (sort { $a->{to}->{name} cmp $b->{to}->{name} } values %{$n->{edges}})
#    for my $e (values %{$n->{edges}})
      {
      # edge already done?
      next unless exists $e->{_todo};

      # skip links from/to groups
      next if $e->{to}->isa('Graph::Easy::Group') ||
              $e->{from}->isa('Graph::Easy::Group');

      push @edges, $e;
      delete $e->{_todo};
      }
    # XXX TODO: This does not work, since the nodes are not yet laid out
    # sort them on their shortest distances
#    @edges = sort { $b->_distance() <=> $a->_distance() } @edges;

    # put them on the action stack in that order
    for my $e (@edges)
      {
      push @todo, [ ACTION_TRACE, $e ];
#      print STDERR "do $e->{from}->{name} to $e->{to}->{name} ($e->{id} " . $e->_distance().")\n";
#      push @todo, [ ACTION_CHAIN, $e->{to}, 0, $n, $e ];
      }
    }

  print STDERR "# Done laying out left-overs.\n" if $self->{debug};

  # after laying out all inter-group nodes and their edges, we need to splice in the
  # group cells
  if (scalar $self->groups() > 0)
    {
    push @todo, [ ACTION_SPLICE ] if scalar $self->groups();

    # now do all group-to-group and node-to-group and group-to-node links:
    for my $n (values %{$self->{groups}})
      {
      }
    }

  $self->_dump_stack(@todo) if $self->{debug};

  ###########################################################################
  # prepare main backtracking-loop

  my $score = 0;			# overall score
  $self->{cells} = { };			# cell array (0..x,0..y)
  my $cells = $self->{cells};

  print STDERR "# Start\n" if $self->{debug};

  $self->{padding_cells} = 0;		# set to false (no filler cells yet)

  my @done = ();			# stack with already done actions
  my $step = 0;
  my $tries = 16;

  # store for each rank the initial row/coluumn
  $self->{_rank_pos} = {};
  # does rank_pos store rows or columns?
  $self->{_rank_coord} = 'y';
  my $flow = $self->flow();
  $self->{_rank_coord} = 'x' if $flow == 0 || $flow == 180;

  TRY:
  while (@todo > 0)			# all actions on stack done?
    {
    $step ++;

    if ($self->{debug} && ($step % 1)==0)
      {
      my ($nodes,$e_nodes,$edges,$e_edges) = $self->_count_done_things();
      print STDERR "# Done $nodes nodes and $edges edges.\n";
      #$self->{debug} = 2 if $nodes > 243;
      return if ($nodes > 230);
      }

    # pop one action and mark it as done
    my $action = shift @todo; push @done, $action;

    # get the action type (ACTION_NODE etc)
    my $action_type = $action->[0];

    my ($src, $dst, $mod, $edge);

    if ($action_type == ACTION_NODE)
      {
      my (undef, $node,$try,$edge) = @$action;
      print STDERR "# step $step: action place '$node->{name}' (try $try)\n" if $self->{debug};

      $mod = 0 if defined $node->{x};
      # $action is node to be placed, generic placement at "random" location
      $mod = $self->_find_node_place( $node, $try, undef, $edge) unless defined $node->{x};
      }
    elsif ($action_type == ACTION_CHAIN)
      {
      my (undef, $node,$try,$parent, $edge) = @$action;
      print STDERR "# step $step: action chain '$node->{name}' from parent '$parent->{name}'\n" if $self->{debug};

      $mod = 0 if defined $node->{x};
      $mod = $self->_find_node_place( $node, $try, $parent, $edge ) unless defined $node->{x};
      }
    elsif ($action_type == ACTION_TRACE)
      {
      # find a path to the target node
      ($action_type,$edge) = @$action;

      $src = $edge->{from}; $dst = $edge->{to};

      print STDERR "# step $step: action trace '$src->{name}' => '$dst->{name}'\n" if $self->{debug};

      if (!defined $dst->{x})
        {
#	warn ("Target node $dst->{name} not yet placed");
        $mod = $self->_find_node_place( $dst, 0, undef, $edge );
	}        
      if (!defined $src->{x})
        {
#	warn ("Source node $src->{name} not yet placed");
        $mod = $self->_find_node_place( $src, 0, undef, $edge );
	}        

      # find path (mod is score modifier, or undef if no path exists)
      $mod = $self->_trace_path( $src, $dst, $edge );
      }
    elsif ($action_type == ACTION_SPLICE)
      {
      # fill in group info and return
      $self->_fill_group_cells($cells) unless $self->{error};
      $mod = 0;
      }
    else
      {
      require Carp;
      Carp::confess ("Illegal action $action->[0] on TODO stack");
      }

    if (!defined $mod)
      {
      # rewind stack
      if (($action_type == ACTION_NODE || $action_type == ACTION_CHAIN))
        { 
        print STDERR "# Step $step: Rewind stack for $action->[1]->{name}\n" if $self->{debug};

        # undo node placement and free all cells
        $action->[1]->_unplace() if defined $action->[1]->{x};
        $action->[2]++;		# increment try for placing
        $tries--;
	last TRY if $tries == 0;
        }
      else
        {
        print STDERR "# Step $step: Rewind stack for path from $src->{name} to $dst->{name}\n" if $self->{debug};
    
        # if we couldn't find a path, we need to rewind one more action (just
	# redoing the path would would fail again!)

#        unshift @todo, pop @done;
#        unshift @todo, pop @done;

#        $action = $todo[0];
#        $action_type = $action->[0];

#        $self->_dump_stack(@todo);
#
#        if (($action_type == ACTION_NODE || $action_type == ACTION_CHAIN))
#          {
#          # undo node placement
#          $action->[1]->_unplace();
#          $action->[2]++;		# increment try for placing
#          }
  	$tries--;
	last TRY if $tries == 0;
        next TRY;
        } 
      unshift @todo, $action;
      next TRY;
      } 

    $score += $mod;
    print STDERR "# Step $step: Score is $score\n\n" if $self->{debug};
    }

    $self->{score} = $score;			# overall score

#  if ($tries == 0)
    {
    my ($nodes,$e_nodes,$edges,$e_edges) = $self->_count_done_things();
    if  ( ($nodes != $e_nodes) ||
          ($edges != $e_edges) )
      {
      $self->warn( "Layouter could only place $nodes nodes/$edges edges out of $e_nodes/$e_edges - giving up");
      }
     else
      {
      $self->_optimize_layout();
      }
    }
    # all things on the stack were done, or we encountered an error
  }

sub _count_done_things
  {
  my $self = shift;

  # count placed nodes
  my $nodes = 0;
  my $i = 1;
  for my $n (values %{$self->{nodes}})
    {
    $nodes++ if defined $n->{x};
    }
  my $edges = 0;
  $i = 1;
  # count fully routed edges
  for my $e (values %{$self->{edges}})
    {
    $edges++ if scalar @{$e->{cells}} > 0 && !exists $e->{_todo};
    }
  my $e_nodes = scalar keys %{$self->{nodes}};
  my $e_edges = scalar keys %{$self->{edges}};
  return ($nodes,$e_nodes,$edges,$e_edges);
  }

my $size_name = {
  EDGE_HOR() => [ 'cx', 'x' ],
  EDGE_VER() => [ 'cy', 'y' ]
  };

sub _optimize_layout
  {
  my $self = shift;

  # optimize the finished layout

  my $all_cells = $self->{cells};

  ###########################################################################
  # for each edge, compact HOR and VER stretches of cells
  for my $e (values %{$self->{edges}})
    {
    my $cells = $e->{cells};

    # there need to be at least two cells for us to be able to combine them
    next if @$cells < 2;

    print STDERR "# Compacting edge $e->{from}->{name} to $e->{to}->{name}\n"
      if $self->{debug};

    my $f = $cells->[0]; my $i = 1;
    my ($px, $py);		# coordinates of the placeholder cell
    while ($i < @$cells)
      {
      my $c = $cells->[$i++];

#      print STDERR "#  at $f->{type} $f->{x},$f->{y}  (next: $c->{type} $c->{x},$c->{y})\n";

      my $t1 = $f->{type} & EDGE_NO_M_MASK;
      my $t2 = $c->{type} & EDGE_NO_M_MASK;

      # > 0: delete that cell: 1 => reverse order, 2 => with hole
      my $delete = 0;

      # compare $first to $c
      if ($t1 == $t2 && ($t1 == EDGE_HOR || $t1 == EDGE_VER))
        {
#	print STDERR "#  $i: Combining them.\n";

	# check that both pieces are continues (e.g. with a cross section,
	# the other edge has a hole in the cell array)

	# if the second cell has a misc (label, short) flag, carry it over
        $f->{type} += $c->{type} & EDGE_MISC_MASK;

        # which size/coordinate to modify
	my ($m,$co) = @{ $size_name->{$t1} };

#	print STDERR "# Combining edge cells $f->{x},$f->{y} and $c->{x},$c->{y}\n";

	# new width/height is the combined size
	$f->{$m} = ($f->{$m} || 1) + ($c->{$m} || 1);

#	print STDERR "# Result $f->{x},$f->{y} ",$f->{cx}||1," ", $f->{cy}||1,"\n";

	# drop the reference from the $cells array for $c
	delete $all_cells->{ "$c->{x},$c->{y}" };

        ($px, $py) = ($c->{x}, $c->{y});
	if ($f->{$co} > $c->{$co})
	  {
	  # remember coordinate of the moved cell for the placeholder
          ($px, $py) = ($f->{x}, $f->{y});

	  # move $f to the new place if it was modified
	  delete $all_cells->{ "$f->{x},$f->{y}" };
	  # correct start coordinate for reversed order
	  $f->{$co} -= ($c->{$m} || 1);

	  $all_cells->{ "$f->{x},$f->{y}" } = $f;
	  }

	$delete = 1;				# delete $c
	}

      # remove that cell, but start combining at next
#      print STDERR "# found hole at $i\n" if $c->{type} == EDGE_HOLE;

      $delete = 2 if $c->{type} == EDGE_HOLE;
      if ($delete)
	{
        splice (@{$e->{cells}}, $i-1, 1);		# remove from the edge
	if ($delete == 1)
	  {
	  my $xy = "$px,$py";
	  # replace with placeholder (important for HTML output)
	  $all_cells->{$xy} = Graph::Easy::Edge::Cell::Empty->new (
	    x => $px, y => $py,
	  ) unless $all_cells->{$xy};	

          $i--; $c = $f;				# for the next statement
	  }
	else { $c = $cells->[$i-1]; }
        }
      $f = $c;
      }

#   $i = 0;
#   while ($i < @$cells)
#     {
#     my $c = $cells->[$i];
#     print STDERR "#   $i: At $c->{type} $c->{x},$c->{y}  ", $c->{cx}||1, " ", $c->{cy} || 1,"\n";
#     $i++;
#     }

    }
  print STDERR "# Done compacting edges.\n" if $self->{debug};

  }

1;
__END__

=head1 NAME

Graph::Easy::Layout - Layout the graph from Graph::Easy

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

	$graph->layout();

	print $graph->as_ascii( );

	# prints:

	# +------+     +--------+
	# | Bonn | --> | Berlin |
	# +------+     +--------+

=head1 DESCRIPTION

C<Graph::Easy::Layout> contains just the actual layout code for
L<Graph::Easy|Graph::Easy>.

=head1 METHODS

C<Graph::Easy::Layout> injects the following methods into the C<Graph::Easy>
namespace:

=head2 layout()

	$graph->layout();

Layout the actual graph.

=head2 _assign_ranks()

	$graph->_assign_ranks();

Used by C<layout()> to assign each node a rank, so they can be sorted
and grouped on these.

=head2 _optimize_layout

Used by C<layout()> to optimize the layout as a last step.

=head1 EXPORT

Exports nothing.

=head1 SEE ALSO

L<Graph::Easy>.

=head1 AUTHOR

Copyright (C) 2004 - 2008 by Tels L<http://bloodgate.com>

See the LICENSE file for information.

=cut
