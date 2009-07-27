#############################################################################
# Parse text definition into a Graph::Easy object
#
#############################################################################

package Graph::Easy::Parser;

use Graph::Easy;

$VERSION = '0.35';
use Graph::Easy::Base;
@ISA = qw/Graph::Easy::Base/;
use Scalar::Util qw/weaken/;

use strict;
use constant NO_MULTIPLES => 1;

sub _init
  {
  my ($self,$args) = @_;

  $self->{error} = '';
  $self->{debug} = 0;
  $self->{fatal_errors} = 1;
  
  foreach my $k (keys %$args)
    {
    if ($k !~ /^(debug|fatal_errors)\z/)
      {
      require Carp;
      my $class = ref($self);
      Carp::confess ("Invalid argument '$k' passed to $class" . '->new()');
      }
    $self->{$k} = $args->{$k};
    }

  # what to replace the matched text with
  $self->{replace} = '';
  $self->{attr_sep} = ':';
  # An optional regexp to remove parts of an autosplit label, used by Graphviz
  # to remove " <p1> ":
  $self->{_qr_part_clean} = undef;

  # setup default class names for generated objects
  $self->{use_class} = {
    edge  => 'Graph::Easy::Edge',
    group => 'Graph::Easy::Group',
    graph => 'Graph::Easy',
    node  => 'Graph::Easy::Node',
  };

  $self;
  }

sub reset
  {
  # reset the status of the parser, clear errors etc.
  my $self = shift;

  $self->{error} = '';
  $self->{anon_id} = 0;
  $self->{cluster_id} = '';		# each cluster gets a unique ID
  $self->{line_nr} = -1;
  $self->{match_stack} = [];		# patterns and their handlers

  $self->{clusters} = {};		# cluster names we already created

  Graph::Easy::Base::_reset_id();	# start with the same set of IDs
  
  # After "[ 1 ] -> [ 2 ]" we push "2" on the stack and when we encounter
  # " -> [ 3 ]" treat the stack as a node-list left of "3".
  # In addition, for " [ 1 ], [ 2 ] => [ 3 ]", the stack will contain
  # "1" and "2" when we encounter "3".
  $self->{stack} = [];

  $self->{group_stack} = [];	# all the (nested) groups we are currently in
  $self->{left_stack} = [];	# stack for the left side for "[]->[],[],..."
  $self->{left_edge} = undef;	# for -> [A], [B] continuations

  Graph::Easy->_drop_special_attributes();

  $self->{_graph} = $self->{use_class}->{graph}->new( {
      debug => $self->{debug},
      strict => 0,
      fatal_errors => $self->{fatal_errors},
    } );

  $self;
  }

sub from_file
  {
  # read in entire file and call from_text() on the contents
  my ($self,$file) = @_;

  $self = $self->new() unless ref $self;

  my $doc;
  local $/ = undef;			# slurp mode
  # if given a reference, assume it is a glob, or something like that
  if (ref($file))
    {
    binmode $file, ':utf8' or die ("binmode '$file', ':utf8' failed: $!");
    $doc = <$file>;
    }
  else
    {
    open my $PARSER_FILE, $file or die (ref($self).": Cannot read $file: $!");
    binmode $PARSER_FILE, ':utf8' or die ("binmode '$file', ':utf8' failed: $!");
    $doc = <$PARSER_FILE>;		# read entire file
    close $PARSER_FILE;
    }

  $self->from_text($doc);
  }

sub use_class
  {
  # use the provided class for generating objects of the type $object
  my ($self, $object, $class) = @_;

  $self->_croak("Expected one of node, edge, group or graph, but got $object")
    unless $object =~ /^(node|group|graph|edge)\z/;

  $self->{use_class}->{$object} = $class;

  $self;  
  }

sub _register_handler
  {
  # register a pattern and a handler for it
  my $self = shift;

  push @{$self->{match_stack}}, [ @_ ];

  $self;
  }

sub _register_attribute_handler
  {
  # register a handler for attributes like "{ color: red; }"
  my ($self, $qr_attr, $target) = @_;

  # $object is either undef (for Graph::Easy, meaning "node", or "parent" for Graphviz)

  # { attributes }
  $self->_register_handler( qr/^$qr_attr/,
    sub
      {
      my $self = shift;
      # This happens in the case of "[ Test ]\n { ... }", the node is consumed
      # first, and the attributes are left over:

      my $stack = $self->{stack}; $stack = $self->{group_stack} if @{$self->{stack}} == 0;

      my $object = $target;
      if ($target && $target eq 'parent')
        {
        # for Graphviz, stray attributes always apply to the parent
        $stack = $self->{group_stack};

        $object = $stack->[-1] if ref $stack;
        if (!defined $object)
          {
          # try the scope stack next:
          $stack = $self->{scope_stack};
	  $object = $self->{_graph};
          if (!$stack || @$stack <= 1)
	    {
	    $object = $self->{_graph};
	    $stack = [ $self->{_graph} ];
	    }
          }
        }
      my ($a, $max_idx) = $self->_parse_attributes($1||'', $object);
      return undef if $self->{error};	# wrong attributes or empty stack?

      if (ref($stack->[-1]) eq 'HASH')
	{
	# stack is a scope stack
	# XXX TODO: Find out wether the attribute goes to graph, node or edge
	for my $k (keys %$a)
	  {
	  $stack->[-1]->{graph}->{$k} = $a->{$k};
	  }
	return 1;
	}

      print STDERR "max_idx = $max_idx, stack contains ", join (" , ", @$stack),"\n"
	if $self->{debug} && $self->{debug} > 1;
      if ($max_idx != 1)
	{
	my $i = 0;
        for my $n (@$stack)
	  {
	  $n->set_attributes($a, $i++);
	  }
	}
      else
	{
        # set attributes on all nodes/groups on stack
        for my $n (@$stack) { $n->set_attributes($a); }
	}
      # This happens in the case of "[ a | b ]\n { ... }", the node is consumed
      # first, and the attributes are left over. And if we encounter a basename
      # attribute here, the node-parts will already have been created with the
      # wrong basename, so correct this:
      if (defined $a->{basename})
        {
        for my $s (@$stack)
          {
          # for every node on the stack that is the primary one
          $self->_set_new_basename($s, $a->{basename}) if exists $s->{autosplit_parts};
          }
        }
      1;
      } );
  }

sub _register_node_attribute_handler
  {
  # register a handler for attributes like "[ A ] { ... }"
  my ($self, $qr_node, $qr_oatr) = @_;

  $self->_register_handler( qr/^$qr_node$qr_oatr/,
    sub
      {
      my $self = shift;
      my $n1 = $1;
      my $a1 = $self->_parse_attributes($2||'');
      return undef if $self->{error};
 
      $self->{stack} = [ $self->_new_node ($self->{_graph}, $n1, $self->{group_stack}, $a1) ];

      # forget left stack
      $self->{left_edge} = undef;
      $self->{left_stack} = [];
      1;
      } );
  }

sub _new_group
  {
  # create a new (possible anonymous) group
  my ($self, $name) = @_;

  $name = '' unless defined $name;

  my $gr = $self->{use_class}->{group};

  my $group;

  if ($name eq '')
    {
    print STDERR "# Creating new anon group.\n" if $self->{debug};
    $gr .= '::Anon';
    $group = $gr->new();
    }
  else
    {
    $name = $self->_unquote($name);
    print STDERR "# Creating new group '$name'.\n" if $self->{debug};
    $group = $gr->new( name => $name );
    }

  $self->{_graph}->add_group($group);

  my $group_stack = $self->{group_stack};
  if (@$group_stack > 0)
    {
    $group->set_attribute('group', $group_stack->[-1]->{name});
    }

  $group;
  }

sub _add_group_match
  {
  # register two handlers for group start/end
  my $self = shift;

  my $qr_group_start = $self->_match_group_start();
  my $qr_group_end   = $self->_match_group_end();
  my $qr_oatr  = $self->_match_optional_attributes();

  # "( group start [" or empty group like "( Group )"
  $self->_register_handler( qr/^$qr_group_start/,
    sub
      {
      my $self = shift;
      my $graph = $self->{_graph};

      my $end = $2; $end = '' unless defined $end;

      # repair the start of the next node/group
      $self->{replace} = '[' if $end eq '[';
      $self->{replace} = '(' if $end eq '(';

      # create the new group
      my $group = $self->_new_group($1);

      if ($end eq ')')
        {
        # we matched an empty group like "()", or "( group name )"
        $self->{stack} = [ $group ]; 
         print STDERR "# Seen end of group '$group->{name}'.\n" if $self->{debug};
        }
      else
        {
	# only put the group on the stack if it is still open
        push @{$self->{group_stack}}, $group;
        }

      1;
      } );

  # ") { }" # group end (with optional attributes)
  $self->_register_handler( qr/^$qr_group_end$qr_oatr/,
    sub
      {
      my $self = shift;

      my $group = pop @{$self->{group_stack}};
      return $self->parse_error(0) if !defined $group;

      print STDERR "# Seen end of group '$group->{name}'.\n" if $self->{debug};

      my $a1 = $self->_parse_attributes($1||'', 'group', NO_MULTIPLES);
      return undef if $self->{error};

      $group->set_attributes($a1);

      # the new left side is the group itself
      $self->{stack} = [ $group ];
      1;
      } );

  }

sub _build_match_stack
  {
  # put all known patterns and their handlers on the match stack
  my $self = shift;

  # regexps for the different parts
  my $qr_node  = $self->_match_node();
  my $qr_attr  = $self->_match_attributes();
  my $qr_oatr  = $self->_match_optional_attributes();
  my $qr_edge  = $self->_match_edge();
  my $qr_comma = $self->_match_comma();
  my $qr_class = $self->_match_class_selector();

  my $e = $self->{use_class}->{edge};

  # node { color: red; } 
  # node.graph { ... }
  # .foo { ... }
  # .foo, node, edge.red { ... }
  $self->_register_handler( qr/^\s*$qr_class$qr_attr/,
    sub
      {
      my $self = shift;
      my $class = lc($1 || '');
      my $att = $self->_parse_attributes($2 || '', $class, NO_MULTIPLES );

      return undef unless defined $att;		# error in attributes?

      my $graph = $self->{_graph};
      $graph->set_attributes ( $class, $att);

      # forget stacks
      $self->{stack} = [];
      $self->{left_edge} = undef;
      $self->{left_stack} = [];
      1;
      } );

  $self->_add_group_match();

  $self->_register_attribute_handler($qr_attr);
  $self->_register_node_attribute_handler($qr_node,$qr_oatr);

  # , [ Berlin ] { color: red; }
  $self->_register_handler( qr/^$qr_comma$qr_node$qr_oatr/,
    sub
      {
      my $self = shift;
      my $graph = $self->{_graph};
      my $n1 = $1;
      my $a1 = $self->_parse_attributes($2||'');
      return undef if $self->{error};

      push @{$self->{stack}}, 
        $self->_new_node ($graph, $n1, $self->{group_stack}, $a1, $self->{stack});

      if (defined $self->{left_edge})
	{
	my ($style, $edge_label, $edge_atr, $edge_bd, $edge_un) = @{$self->{left_edge}};

	foreach my $node (@{$self->{left_stack}})
          {
	  my $edge = $e->new( { style => $style, name => $edge_label } );
	  $edge->set_attributes($edge_atr);
	  # "<--->": bidirectional
	  $edge->bidirectional(1) if $edge_bd;
	  $edge->undirected(1) if $edge_un;
	  $graph->add_edge ( $node, $self->{stack}->[-1], $edge );
          }
	}
      1;
      } );

  # Things like "[ Node ]" will be consumed before, so we do not need a case
  # for "[ A ] -> [ B ]":
  # node chain continued like "-> { ... } [ Kassel ] { ... }"
  $self->_register_handler( qr/^$qr_edge$qr_oatr$qr_node$qr_oatr/,
    sub
      {
      my $self = shift;

      return if @{$self->{stack}} == 0;	# only match this if stack non-empty

      my $graph = $self->{_graph};
      my $eg = $1;					# entire edge ("-- label -->" etc)

      my $edge_bd = $2 || $4;				# bidirectional edge ('<') ?
      my $edge_un = 0;					# undirected edge?
      $edge_un = 1 if !defined $2 && !defined $5;

      # optional edge label
      my $edge_label = $7;
      my $ed = $3 || $5 || $1;				# edge pattern/style ("--")

      my $edge_atr = $11 || '';				# save edge attributes

      my $n = $12;					# node name
      my $a1 = $self->_parse_attributes($13||'');	# node attributes

      $edge_atr = $self->_parse_attributes($edge_atr, 'edge');
      return undef if $self->{error};

      # allow undefined edge labels for setting them from the class
      # strip trailing spaces and convert \[ => [
      $edge_label = $self->_unquote($edge_label) if defined $edge_label;
      # strip trailing spaces
      $edge_label =~ s/\s+\z// if defined $edge_label;

      # the right side node(s) (multiple in case of autosplit)
      my $nodes_b = [ $self->_new_node ($self->{_graph}, $n, $self->{group_stack}, $a1) ];

      my $style = $self->_link_lists( $self->{stack}, $nodes_b,
	$ed, $edge_label, $edge_atr, $edge_bd, $edge_un);

      # remember the left side
      $self->{left_edge} = [ $style, $edge_label, $edge_atr, $edge_bd, $edge_un ];
      $self->{left_stack} = $self->{stack};

      # forget stack and remember the right side instead
      $self->{stack} = $nodes_b;
      1;
      } );

  my $qr_group_start = $self->_match_group_start();

  # Things like ")" will be consumed before, so we do not need a case
  # for ") -> { ... } ( Group [ B ]":
  # edge to a group like "-> { ... } ( Group ["
  $self->_register_handler( qr/^$qr_edge$qr_oatr$qr_group_start/,
    sub
      {
      my $self = shift;

      return if @{$self->{stack}} == 0;	# only match this if stack non-empty

      my $eg = $1;					# entire edge ("-- label -->" etc)

      my $edge_bd = $2 || $4;				# bidirectional edge ('<') ?
      my $edge_un = 0;					# undirected edge?
      $edge_un = 1 if !defined $2 && !defined $5;

      # optional edge label
      my $edge_label = $7;
      my $ed = $3 || $5 || $1;				# edge pattern/style ("--")

      my $edge_atr = $11 || '';				# save edge attributes

      my $gn = $12; 
      # matched "-> ( Group [" or "-> ( Group ("
      $self->{replace} = '[' if defined $13 && $13 eq '[';
      $self->{replace} = '(' if defined $13 && $13 eq '(';

      $edge_atr = $self->_parse_attributes($edge_atr, 'edge');
      return undef if $self->{error};

      # get the last group of the stack, lest the new one gets nested in it
      pop @{$self->{group_stack}};

      $self->{group_stack} = [ $self->_new_group($gn) ];

      # allow undefined edge labels for setting them from the class
      $edge_label = $self->_unquote($edge_label) if $edge_label;
      # strip trailing spaces
      $edge_label =~ s/\s+\z// if $edge_label;

      my $style = $self->_link_lists( $self->{stack}, $self->{group_stack},
	$ed, $edge_label, $edge_atr, $edge_bd, $edge_un);

      # remember the left side
      $self->{left_edge} = [ $style, $edge_label, $edge_atr, $edge_bd, $edge_un ];
      $self->{left_stack} = $self->{stack};
      # forget stack
      $self->{stack} = [];
      # matched "->()" so remember the group on the stack
      $self->{stack} = [ $self->{group_stack}->[-1] ] if defined $13 && $13 eq ')';

      1;
      } );
  }

sub _line_insert
  {
  # what to insert between two lines, '' for Graph::Easy, ' ' for Graphviz;
  '';
  }

sub _clean_line
  { 
  # do some cleanups on a line before handling it
  my ($self,$line) = @_;

  chomp($line);

  # convert #808080 into \#808080, and "#fff" into "\#fff"
  my $sep = $self->{attr_sep};
  $line =~ s/$sep\s*("?)(#(?:[a-fA-F0-9]{6}|[a-fA-F0-9]{3}))("?)/$sep $1\\$2$3/g;

  # remove comment at end of line (but leave \# alone):
  $line =~ s/(:[^\\]|)$self->{qr_comment}.*/$1/;

  # remove white space at end (but not at the start, to keep "  ||" intact
  $line =~ s/\s+\z//;

#  print STDERR "# at line '$line' stack: ", join(",",@{ $self->{stack}}),"\n";

  $line;
  }

sub from_text
  {
  my ($self,$txt) = @_;

  # matches a multi-line comment
  my $o_cmt = qr#((\s*/\*.*?\*/\s*)*\s*|\s+)#;

  if ((ref($self)||$self) eq 'Graph::Easy::Parser' && 
    # contains "digraph GRAPH {" or something similiar
     ( $txt =~ /^(\s*|\s*\/\*.*?\*\/\s*)(strict)?$o_cmt(di)?graph$o_cmt("[^"]*"|[\w_]+)$o_cmt\{/im ||
    # contains "digraph {" or something similiar	
      $txt =~ /^(\s*|\s*\/\*.*?\*\/\s*)(strict)?${o_cmt}digraph$o_cmt\{/im || 
    # contains "strict graph {" or something similiar	
      $txt =~ /^(\s*|\s*\/\*.*?\*\/\s*)strict${o_cmt}(di)?graph$o_cmt\{/im)) 
    {
    require Graph::Easy::Parser::Graphviz;
    # recreate ourselfes, and pass our arguments along
    my $debug = 0;
    my $old_self = $self;
    if (ref($self))
      {
      $debug = $self->{debug};
      $self->{fatal_errors} = 0;
      }
    $self = Graph::Easy::Parser::Graphviz->new( debug => $debug, fatal_errors => 0 );
    $self->reset();
    $self->{_old_self} = $old_self if ref($self);
    }

  if ((ref($self)||$self) eq 'Graph::Easy::Parser' && 
    # contains "graph: {"
      $txt =~ /^([\s\n\t]*|\s*\/\*.*?\*\/\s*)graph\s*:\s*\{/m) 
    {
    require Graph::Easy::Parser::VCG;
    # recreate ourselfes, and pass our arguments along
    my $debug = 0;
    my $old_self = $self;
    if (ref($self))
      {
      $debug = $self->{debug};
      $self->{fatal_errors} = 0;
      }
    $self = Graph::Easy::Parser::VCG->new( debug => $debug, fatal_errors => 0 );
    $self->reset();
    $self->{_old_self} = $old_self if ref($self);
    }

  $self = $self->new() unless ref $self;
  $self->reset();

  my $graph = $self->{_graph};
  return $graph if !defined $txt || $txt =~ /^\s*\z/;		# empty text?
 
  my $uc = $self->{use_class};

  # instruct the graph to use the custom classes, too
  for my $o (keys %$uc)
    {
    $graph->use_class($o, $uc->{$o}) unless $o eq 'graph';	# group, node and edge
    }

  my @lines = split /(\r\n|\n|\r)/, $txt;

  my $backbuffer = '';	# left over fragments to be combined with next line

  my $qr_comment = $self->_match_commented_line();
  $self->{qr_comment} = $self->_match_comment();
  # cache the value of this since it can be expensive to construct:
  $self->{_match_single_attribute} = $self->_match_single_attribute();

  $self->_build_match_stack();

  ###########################################################################
  # main parsing loop

  my $handled = 0;		# did we handle a fragment?
  my $line;

#  my $counts = {};
  LINE:
  while (@lines > 0 || $backbuffer ne '')
    {
    # only accumulate more text if we didn't handle a fragment
    if (@lines > 0 && $handled == 0)
      {
      $self->{line_nr}++;
      my $curline = shift @lines;

      # discard empty lines, or completely commented out lines
      next if $curline =~ $qr_comment;

      # convert tabs to spaces (the regexps don't expect tabs)
      $curline =~ tr/\t/ /d;

      # combine backbuffer, what to insert between two lines and next line:
      $line = $backbuffer . $self->_line_insert() . $self->_clean_line($curline);
      }

  print STDERR "# Line is '$line'\n" if $self->{debug} && $self->{debug} > 2;
  print STDERR "#  Backbuffer is '$backbuffer'\n" if $self->{debug} && $self->{debug} > 2;

    $handled = 0;
#debug my $count = 0;
    PATTERN:
    for my $entry (@{$self->{match_stack}})
      {
      # nothing to match against?
      last PATTERN if $line eq '';

      $self->{replace} = '';	# as default just remove the matched text
      my ($pattern, $handler, $replace) = @$entry;

  print STDERR "# Matching against $pattern\n" if $self->{debug} && $self->{debug} > 3;

      if ($line =~ $pattern)
        {
#debug $counts->{$count}++;
  print STDERR "# Matched, calling handler\n" if $self->{debug} && $self->{debug} > 2;
        my $rc = 1;
        $rc = &$handler($self) if defined $handler;
        if ($rc)
	  {
          $replace = $self->{replace} unless defined $replace;
	  $replace = &$replace($self,$line) if ref($replace);
  print STDERR "# Handled it successfully.\n" if $self->{debug} && $self->{debug} > 2;
          $line =~ s/$pattern/$replace/;
  print STDERR "# Line is now '$line' (replaced with '$replace')\n" if $self->{debug} && $self->{debug} > 2;
          $handled++; last PATTERN;
          }
        }
#debug $count ++;

      }

#debug    if ($handled == 0) { $counts->{'-1'}++; }
    # couldn't handle that fragement, so accumulate it and try again
    $backbuffer = $line;

    # stop at the very last line
    last LINE if $handled == 0 && @lines == 0;

    # stop at parsing errors
    last LINE if $self->{error};
    }

  $self->error("'$backbuffer' not recognized by " . ref($self)) if $backbuffer ne '';

  # if something was left on the stack, file ended unexpectedly
  $self->parse_error(7) if !$self->{error} && $self->{scope_stack} && @{$self->{scope_stack}} > 0;

  return undef if $self->{error} && $self->{fatal_errors};

#debug  use Data::Dumper; print Dumper($counts);

  print STDERR "# Parsing done.\n" if $graph->{debug};

  # Do final cleanup (for parsing Graphviz)
  $self->_parser_cleanup() if $self->can('_parser_cleanup');
  $graph->_drop_special_attributes();

  # turn on strict checking on returned graph
  $graph->strict(1);
  $graph->fatal_errors(1);

  $graph;
  }

#############################################################################
# internal routines

sub _edge_style
  {
  my ($self, $ed) = @_;

  my $style = undef;			# default is "inherit from class"
  $style = 'double-dash' if $ed =~ /^(= )+\z/; 
  $style = 'double' if $ed =~ /^=+\z/; 
  $style = 'dotted' if $ed =~ /^\.+\z/; 
  $style = 'dashed' if $ed =~ /^(- )+\z/; 
  $style = 'dot-dot-dash' if $ed =~ /^(..-)+\z/; 
  $style = 'dot-dash' if $ed =~ /^(\.-)+\z/; 
  $style = 'wave' if $ed =~ /^\~+\z/; 
  $style = 'bold' if $ed =~ /^#+\z/; 

  $style;
  }

sub _link_lists
  {
  # Given two node lists and an edge style, links each node from list
  # one to list two.
  my ($self, $left, $right, $ed, $label, $edge_atr, $edge_bd, $edge_un) = @_;

  my $graph = $self->{_graph};
 
  my $style = $self->_edge_style($ed);
  my $e = $self->{use_class}->{edge};

  # add edges for all nodes in the left list
  for my $node (@$left)
    {
    for my $node_b (@$right)
      {
      my $edge = $e->new( { style => $style, name => $label } );

      $graph->add_edge ( $node, $node_b, $edge );

      # 'string' => [ 'string' ]
      # [ { hash }, 'string' ] => [ { hash }, 'string' ]
      my $e = $edge_atr; $e = [ $edge_atr ] unless ref($e) eq 'ARRAY';

      for my $a (@$e)
	{
	if (ref $a)
	  {
	  $edge->set_attributes($a);
	  }
	else
	  {
	  # deferred parsing with the object as param:
	  my $out = $self->_parse_attributes($a, $edge);
	  return undef if $self->{error};
	  $edge->set_attributes($out);
	  }
	}

      # "<--->": bidirectional
      $edge->bidirectional(1) if $edge_bd;
      $edge->undirected(1) if $edge_un;
      }
    }

  $style;
  }

sub _unquote_attribute
  {
  my ($self,$name,$value) = @_;

  $self->_unquote($value);
  }

sub _unquote
  {
  my ($self, $name, $no_collapse) = @_;

  $name = '' unless defined $name;

  # unquote special chars
  $name =~ s/\\([\[\(\{\}\]\)#<>\-\.\=])/$1/g;

  # collapse multiple spaces
  $name =~ s/\s+/ /g unless $no_collapse;

  $name;
  }

sub _add_node
  {
  # add a node to the graph, overidable by subclasses
  my ($self, $graph, $name) = @_;

  $graph->add_node($name);		# add unless exists
  }

sub _get_cluster_name
  {
  # create a unique name for an autosplit node
  my ($self, $base_name) = @_;

  # Try to find a unique cluster name in case some one get's creative and names the
  # last part "-1":

  # does work without cluster-id?
  if (exists $self->{clusters}->{$base_name})
    {
    my $g = 1;
    while ($g == 1)
      {
      my $base_try = $base_name; $base_try .= '-' . $self->{cluster_id} if $self->{cluster_id};
      last if !exists $self->{clusters}->{$base_try};
      $self->{cluster_id}++;
      }
    $base_name .= '-' . $self->{cluster_id} if $self->{cluster_id}; $self->{cluster_id}++;
    }

  $self->{clusters}->{$base_name} = undef;	# reserve this name

  $base_name;
  }

sub _set_new_basename
  {
  # when encountering something like:
  #   [ a | b ]
  #   { basename: foo; }
  # the Parser will create two nodes, ab.0 and ab.1, and then later see
  # the "basename: foo". Sowe need to rename the already created nodes
  # due to the changed basename:
  my ($self, $node, $new_basename) = @_;

  # nothing changes?
  return if $node->{autosplit_basename} eq $new_basename;

  my $g = $node->{graph};

  my @parts = @{$node->{autosplit_parts}};
  my $nr = 0;
  for my $part ($node, @parts)
    {
    print STDERR "# Setting new basename $new_basename for node $part->{name}\n"
      if $self->{debug} > 1;

    $part->{autosplit_basename} = $new_basename;
    $part->set_attribute('basename', $new_basename);
  
    # delete it from the list of nodes
    delete $g->{nodes}->{$part->{name}};
    $part->{name} = $new_basename . '.' . $nr; $nr++;
    # and re-insert it with the right name
    $g->{nodes}->{$part->{name}} = $part;

    # we do not need to care for edges here, as they are stored with refs
    # to the nodes and not the node names itself
    }
  }

sub _autosplit_node
  {
  # Takes a node name like "a|b||c" and splits it into "a", "b", and "c".
  # Returns the individual parts.
  my ($self, $graph, $name, $att, $allow_empty) = @_;
 
  # Default is to have empty parts. Graphviz sets this to true;
  $allow_empty = 1 unless defined $allow_empty;

  my @rc;
  my $uc = $self->{use_class};
  my $qr_clean = $self->{_qr_part_clean};

  # build base name: "A|B |C||D" => "ABCD"
  my $base_name = $name; $base_name =~ s/\s*\|\|?\s*//g;

  # use user-provided base name
  $base_name = $att->{basename} if exists $att->{basename};

  # strip trailing/leading spaces on basename
  $base_name =~ s/\s+\z//;
  $base_name =~ s/^\s+//;

  # first one gets: "ABC", second one "ABC.1" and so on
  $base_name = $self->_get_cluster_name($base_name);

  print STDERR "# Parser: Autosplitting node with basename '$base_name'\n" if $graph->{debug};

  my $first_in_row;			# for relative placement of new row
  my $x = 0; my $y = 0; my $idx = 0;
  my $remaining = $name; my $sep; my $last_sep = '';
  my $add = 0;
  while ($remaining ne '')
    {
    # XXX TODO: parsing of "\|" and "|" in one node
    $remaining =~ s/^((\\\||[^\|])*)(\|\|?|\z)//;
    my $part = $1 || ' ';
    $sep = $3;
    my $port_name = '';

    # possible cleanup for this part
    if ($qr_clean)
      {
      $part =~ s/^$qr_clean//; $port_name = $1;
      }

    # fix [|G|] to have one empty part as last part
    if ($add == 0 && $remaining eq '' && $sep =~ /\|\|?/)
      {
      $add++;				# only do it once
      $remaining .= '|' 
      }

    print STDERR "# Parser: Found autosplit part '$part'\n" if $graph->{debug};

    my $class = $uc->{node};
    if ($allow_empty && $part eq ' ')
      {
      # create an empty node with no border
      $class .= "::Empty";
      }
    elsif ($part =~ /^[ ]{2,}\z/)
      {
      # create an empty node with border
      $part = ' ';
      }
    else
      {
      $part =~ s/^\s+//;	# rem spaces at front
      $part =~ s/\s+\z//;	# rem spaces at end
      }

    my $node_name = "$base_name.$idx";

    if ($graph->{debug})
      {
      my $empty = '';
      $empty = ' empty' if $class ne $self->{use_class}->{node};
      print STDERR "# Parser:  Creating$empty autosplit part '$part'\n" if $graph->{debug};
      }

    # if it doesn't exist, add it, otherwise retrieve node object to $node
    if ($class =~ /::Empty/)
      {
      my $node = $graph->node($node_name);
      if (!defined $node)
	{
	# create node object from the correct class
	$node = $class->new($node_name);
        $graph->add_node($node);
	}
      }

    my $node = $graph->add_node($node_name);
    $node->{autosplit_label} = $part;
    # remember these two for Graphviz
    $node->{autosplit_portname} = $port_name;
    $node->{autosplit_basename} = $base_name;

    push @rc, $node;
    if (@rc == 1)
      {
      # for correct as_txt output
      $node->{autosplit} = $name;
      $node->{autosplit} =~ s/\s+\z//;		# strip trailing spaces
      $node->{autosplit} =~ s/^\s+//;		# strip leading spaces
      $node->{autosplit} =~ s/([^\|])\s+\|/$1 \|/g;	# 'foo  |' => 'foo |'
      $node->{autosplit} =~ s/\|\s+([^\|])/\| $1/g;	# '|  foo' => '| foo'
      $node->set_attribute('basename', $att->{basename}) if defined $att->{basename};
      # list of all autosplit parts so as_txt() can find them easily again
      $node->{autosplit_parts} = [ ];
      $first_in_row = $node;
      }
    else
      {
      # second, third etc. get previous as origin
      my ($sx,$sy) = (1,0);
      my $origin = $rc[-2];
      if ($last_sep eq '||')
        {
        ($sx,$sy) = (0,1); $origin = $first_in_row;
        $first_in_row = $node;
        }
      $node->relative_to($origin,$sx,$sy);
      push @{$rc[0]->{autosplit_parts}}, $node;
      weaken @{$rc[0]->{autosplit_parts}}[-1];

      # suppress as_txt output for other parts
      $node->{autosplit} = undef;
      }	
    # nec. for border-collapse
    $node->{autosplit_xy} = "$x,$y";

    $idx++;						# next node ID
    $last_sep = $sep;
    $x++;
    # || starts a new row:
    if ($sep eq '||')
      {
      $x = 0; $y++;
      }
    }  # end for all parts

  @rc;	# return all created nodes
  }

sub _new_node
  {
  # Create a new node unless it doesn't already exist. If the group stack
  # contains entries, the new node appears first in this/these group(s), so
  # add it to these groups. If the newly created node contains "|", we auto
  # split it up into several nodes and cluster these together.
  my ($self, $graph, $name, $group_stack, $att, $stack) = @_;

  print STDERR "# Parser: new node '$name'\n" if $graph->{debug};

  $name = $self->_unquote($name, 'no_collapse');

  my $autosplit;
  my $uc = $self->{use_class};

  my @rc = ();

  if ($name =~ /^\s*\z/)
    {
    print STDERR "# Parser: Creating anon node\n" if $graph->{debug};
    # create a new anon node and add it to the graph
    my $class = $uc->{node} . '::Anon';
    my $node = $class->new();
    @rc = ( $graph->add_node($node) );
    }
  # nodes to be autosplit will be done in a sep. pass for Graphviz
  elsif ((ref($self) eq 'Graph::Easy::Parser') && $name =~ /[^\\]\|/)
    {
    $autosplit = 1;
    @rc = $self->_autosplit_node($graph, $name, $att);
    }
  else
    {
    # strip trailing and leading spaces
    $name =~ s/\s+\z//; 
    $name =~ s/^\s+//; 

    # collapse multiple spaces
    $name =~ s/\s+/ /g;

    # unquote \|
    $name =~ s/\\\|/\|/g;

    if ($self->{debug})
      {
      if (!$graph->node($name))
	{
	print STDERR "# Parser: Creating normal node from name '$name'.\n";
	}
      else
	{
	print STDERR "# Parser: Found node '$name' already in graph.\n";
	}
      }
    @rc = ( $self->_add_node($graph, $name) ); 	# add to graph, unless exists
    }

  $self->parse_error(5) if exists $att->{basename} && !$autosplit;

  my $b = $att->{basename};
  delete $att->{basename};

  # on a node list "[A],[B] { ... }" set attributes on all nodes
  # encountered so far, too:
  if (defined $stack)
    {
    for my $node (@$stack)
      {
      $node->set_attributes ($att, 0);
      }
    }
  my $index = 0;
  my $group = $self->{group_stack}->[-1];

  for my $node (@rc)
    {
    $node->add_to_group($group) if $group;
    $node->set_attributes ($att, $index);
    $index++;
    }
  
  $att->{basename} = $b if defined $b;

  # return list of created nodes (usually one, but more for "A|B")
  @rc;
  }

sub _match_comma
  {
  # return a regexp that matches something like " , " like in:
  # "[ Bonn ], [ Berlin ] => [ Hamburg ]"
  qr/\s*,\s*/;
  }

sub _match_comment
  {
  # match the start of a comment
  qr/(^|[^\\])#/;
  }

sub _match_commented_line
  {
  # match empty lines or a completely commented out line
  qr/^\s*(#|\z)/;
  }

sub _match_attributes
  {
  # return a regexp that matches something like " { color: red; }" and returns
  # the inner text without the {}
  qr/\s*\{\s*([^\}]+?)\s*\}/;
  }

sub _match_optional_attributes
  {
  # return a regexp that matches something like " { color: red; }" and returns
  # the inner text with the {}
  qr/(\s*\{[^\}]+?\})?/;
  }

sub _match_node
  {
  # return a regexp that matches something like " [ bonn ]" and returns
  # the inner text without the [] (might leave some spaces)

  qr/\s*\[				#  '[' start of the node
    (
     (?:				# non-capturing group
      \\.				# either '\]' or '\N' etc.
      |					#  or
      [^\]\\]				# not ']' and not '\'
     )*					# 0 times for '[]'
    )
    \]/x;				# followed by ']'
  }

sub _match_class_selector
  {
  my $class = qr/(?:\.\w+|graph|(?:edge|group|node)(?:\.\w+)?)/;
  qr/($class(?:\s*,\s*$class)*)/;
  }

sub _match_single_attribute
  {
  qr/\s*([^:]+?)\s*:\s*("(?:\\"|[^"])+"|(?:\\;|[^;])+?)(?:\s*;\s*|\s*\z)/;	# "name: value"
  }

sub _match_group_start
  {
  # Return a regexp that matches something like " ( group [" and returns
  # the text between "(" and "[". Also matches empty groups like "( group )"
  # or even "()":
  qr/\s*\(\s*([^\[\)\(]*?)\s*([\[\)\(])/;
  }

sub _match_group_end
  {
  # return a regexp that matches something like " )".
  qr/\s*\)\s*/;
  }

sub _match_edge
  {
  # Matches all possible edge variants like:
  # -->, ---->, ==> etc
  # <-->, <---->, <==>, <..> etc
  # <-- label -->, <.- label .-> etc  
  # -- label -->, .- label .-> etc  

  # "- " must come before "-"!
  # likewise, "..-" must come before ".-" must come before "."

  # XXX TODO: convert the first group into a non-matching group

  qr/\s*
     (					# egde without label ("-->")
       (<?) 				 # optional left "<"
       (=\s|=|-\s|-|\.\.-|\.-|\.|~)+>	 # pattern (style) of edge
     |					# edge with label ("-- label -->")
       (<?) 				 # optional left "<"
       ((=\s|=|-\s|-|\.\.-|\.-|\.|~)+)	 # pattern (style) of edge
       \s+				 # followed by at least a space
       ((?:\\.|[^>\[\{])*?)		 # either \\, \[ etc, or not ">", "[", "{"
       (\s+\5)>				 # a space and pattern before ">"

# inserting this needs mucking with all the code that access $5 etc
#     |					# undirected edge (without arrows, but with label)
#       ((=\s|=|-\s|-|\.\.-|\.-|\.|~)+)	 # pattern (style) of edge
#       \s+				 # followed by at least a space
#       ((?:\\.|[^>\[\{])*?)		 # either \\, \[ etc, or not ">", "[", "{"
#       (\s+\10)				 # a space and pattern

     |					# undirected edge (without arrows and label)
       (\.\.-|\.-)+			 # pattern (style) of edge (at least once)
     |
       (=\s|=|-\s|-|\.|~){2,}		 # these at least two times
     )
     /x;
   }

sub _clean_attributes
  {
  my ($self,$text) = @_;

  $text =~ s/^\s*\{\s*//;	# remove left-over "{" and spaces
  $text =~ s/\s*\}\s*\z//;	# remove left-over "}" and spaces

  $text;
  }

sub _parse_attributes
  {
  # Takes a text like "attribute: value;  attribute2 : value2;" and
  # returns a hash with the attributes. $class defaults to 'node'.
  # In list context, also returns a flag that is maxlevel-1 when one
  # of the attributes was a multiple one (aka 2 for "red|green", 1 for "red");
  my ($self, $text, $object, $no_multiples) = @_;

  my $class = $object;
  $class = $object->{class} if ref($object);
  $class = 'node' unless defined $class;
  $class =~ s/\..*//;				# remove subclass

  my $out;
  my $att = {};
  my $multiples = 0;

  $text = $self->_clean_attributes($text);
  my $qr_att  = $self->{_match_single_attribute};
  my $qr_cmt;  $qr_cmt  = $self->_match_multi_line_comment()
   if $self->can('_match_multi_line_comment');
  my $qr_satt; $qr_satt = $self->_match_special_attribute() 
   if $self->can('_match_special_attribute');

  return {} if $text =~ /^\s*\z/;

  print STDERR "attr parsing: matching\n '$text'\n against $qr_att\n" if $self->{debug} > 3;    

  while ($text ne '')
    {
    print STDERR "attr parsing: matching '$text'\n" if $self->{debug} > 3;    

    # remove a possible comment
    $text =~ s/^$qr_cmt//g if $qr_cmt;

    # if the last part was a comment, we end up with an empty text here:
    last if $text =~ /^\s*\z/;

    # match and remove "name: value"
    my $done = ($text =~ s/^$qr_att//) || 0;

    # match and remove "name" if "name: value;" didn't match
    $done++ if $done == 0 && $qr_satt && ($text =~ s/^$qr_satt//);

    return $self->error ("Error in attribute: '$text' doesn't look valid to me.")
      if $done == 0;

    my $name = $1;
    my $v = $2; $v = '' unless defined $v;	# for special attributes w/o value

    # unquote and store
    $out->{$name} = $self->_unquote_attribute($name,$v);
    }

  if ($self->{debug} && $self->{debug} > 1)
    {
    require Data::Dumper;
    print STDERR "# ", join (" ", caller),"\n";
    print STDERR "# Parsed attributes into:\n", Data::Dumper::Dumper($out),"\n";
    }
  # possible remap attributes (for parsing Graphviz)
  $out = $self->_remap_attributes($out, $object) if $self->can('_remap_attributes');

  my $g = $self->{_graph};
  # check for being valid and finally create hash with name => value pairs
  for my $name (sort keys %$out)
    {
    my ($rc, $newname, $v) = $g->validate_attribute($name,$out->{$name},$class,$no_multiples);

    $self->error($g->{error}) if defined $rc;

    $multiples = scalar @$v if ref($v) eq 'ARRAY';

    $att->{$newname} = $v if defined $v;	# undef => ignore attribute
    }

  return $att unless wantarray;

  ($att, $multiples || 1);
  }

sub parse_error
  {
  # take a msg number, plus params, and throws an exception
  my $self = shift;
  my $msg_nr = shift;

  # XXX TODO: should really use the msg nr mapping
  my $msg = "Found unexpected group end";						# 0
  $msg = "Error in attribute: '##param2##' is not a valid attribute for a ##param3##"	# 1
        if $msg_nr == 1;
  $msg = "Error in attribute: '##param1##' is not a valid ##param2## for a ##param3##"
	if $msg_nr == 2;								# 2
  $msg = "Error: Found attributes, but expected group or node start"
	if $msg_nr == 3;								# 3
  $msg = "Error in attribute: multi-attribute '##param1##' not allowed here"
	if $msg_nr == 4;								# 4
  $msg = "Error in attribute: basename not allowed for non-autosplit nodes"
	if $msg_nr == 5;								# 5
  # for graphviz parsing
  $msg = "Error: Already seen graph start"
	if $msg_nr == 6;								# 6
  $msg = "Error: Expected '}', but found file end"
	if $msg_nr == 7;								# 7

  my $i = 1;
  foreach my $p (@_)
    {
    $msg =~ s/##param$i##/$p/g; $i++;
    }

  $self->error($msg . ' at line ' . $self->{line_nr});
  }

sub _parser_cleanup
  {
  # After initial parsing, do a cleanup pass.
  my ($self) = @_;

  my $g = $self->{_graph};
  
  for my $n (values %{$g->{nodes}})
    {
    next if $n->{autosplit};
    $self->warn("Node '" . $self->_quote($n->{name}) . "' has an offset but no origin")
      if (($n->attribute('offset') ne '0,0') && $n->attribute('origin') eq '');
    }

  $self;
  }

sub _quote
  {
  # make a node name safe for error message output
  my ($self,$n) = @_;

  $n =~ s/'/\\'/g;

  $n;
  }

1;
__END__

=head1 NAME

Graph::Easy::Parser - Parse Graph::Easy from textual description

=head1 SYNOPSIS

        # creating a graph from a textual description
        use Graph::Easy::Parser;
        my $parser = Graph::Easy::Parser->new();

        my $graph = $parser->from_text(
                '[ Bonn ] => [ Berlin ]'.
                '[ Berlin ] => [ Rostock ]'.
        );
        print $graph->as_ascii();

        print $parser->from_file('mygraph.txt')->as_ascii();

	# Also works automatically on graphviz code:
        print Graph::Easy::Parser->from_file('mygraph.dot')->as_ascii();

=head1 DESCRIPTION

C<Graph::Easy::Parser> lets you parse simple textual descriptions
of graphs, and constructs a C<Graph::Easy> object from them.

The resulting object can than be used to layout and output the graph.

=head2 Input

The input consists of text describing the graph, encoded in UTF-8.

Example:

	[ Bonn ]      --> [ Berlin ]
	[ Frankfurt ] <=> [ Dresden ]
	[ Bonn ]      --> [ Frankfurt ]
	[ Bonn ]      = > [ Frankfurt ]

=head3 Graphviz

In addition there is a bit of magic that detects graphviz code, so
input of the following form will also work:

	digraph Graph1 {
		"Bonn" -> "Berlin"
	}

Note that the magic detection only works for B<named> graphs or graph
with "digraph" at their start, so the following will not be detected as
graphviz code because it looks exactly like valid Graph::Easy code
at the start:

	graph {
		"Bonn" -> "Berlin"
	}

See L<Graph::Easy::Parser::Graphviz> for more information about parsing
graphs in the DOT language.

=head3 VCG

In addition there is a bit of magic that detects VCG code, so
input of the following form will also work:

	graph: {
		node: { title: Bonn; }
		node: { title: Berlin; }
		edge: { sourcename: Bonn; targetname: Berlin; }
	}

See L<Graph::Easy::Parser::VCG> for more information about parsing
graphs in the VCG language.

=head2 Input Syntax

This is a B<very> brief description of the syntax for the Graph::Easy
language, for a full specification, please see L<Graph::Easy::Manual>.

=over 2

=item nodes

Nodes are rendered (or "quoted", if you wish) with enclosing square brackets:

	[ Single node ]
	[ Node A ] --> [ Node B ]

Anonymous nodes do not have a name and cannot be refered to again:

	[ ] -> [ Bonn ] -> [ ]

This creates three nodes, two of them anonymous.

=item edges

The edges between the nodes can have the following styles:

	->		solid
	=>		double
	.>		dotted
	~>		wave

	- >		dashed
	.->		dot-dash
	..->		dot-dot-dash
	= >		double-dash

There are also the styles C<bold>, C<wide> and C<broad>. Unlike the others,
these can only be set via the (optional) edge attributes:

	[ AB ] --> { style: bold; } [ ABC ]

You can repeat each of the style-patterns as much as you like:

	--->
	==>
	=>
	~~~~~>
	..-..-..->

Note that in patterns longer than one character, the entire
pattern must be repeated e.g. all characters of the pattern must be
present. Thus:

	..-..-..->	# valid dot-dot-dash
	..-..-..>	# invalid!

	.-.-.->		# valid dot-dash
	.-.->		# invalid!

In additon to the styles, the following two directions are possible:

	 --		edge without arrow heads
	 -->		arrow at target node (end point)
	<-->		arrow on both the source and target node
			(end and start point)

Of course you can combine all directions with all styles. However,
note that edges without arrows cannot use the shortcuts for styles:

	---		# valid
	.-.-		# valid
	.-		# invalid!
	-		# invalid!
	~		# invalid!

Just remember to use at least two repititions of the full pattern
for arrow-less edges.

You can also give edges a label, either by inlining it into the style,
or by setting it via the attributes:

	[ AB ] --> { style: bold; label: foo; } [ ABC ]

	-- foo -->
	... baz ...>

	-- solid -->
	== double ==>
	.. dotted ..>
	~~ wave ~~>

	-  dashed - >
	=  double-dash = >
	.- dot-dash .->
	..- dot-dot-dash ..->

Note that the two patterns on the left and right of the label must be
the same, and that there is a space between the left pattern and the
label, as well as the label and the right pattern.

You may use inline label only with edges that have an arrow. Thus:

	<-- label -->	# valid
	-- label -->	# valid

	-- label --	# invalid!

To use a label with an edge without arrow heads, use the attributes:

	[ AB ] -- { label: edgelabel; } [ CD ]

=item groups

Round brackets are used to group nodes together:

	( Cities:

		[ Bonn ] -> [ Berlin ]
	)

Anonymous groups do not have a name and cannot be refered to again:

	( [ Bonn ] ) -> [ Berlin ]

This creates an anonymous group with the node C<Bonn> in it, and
links it to the node C<Berlin>.

=back

Please see L<Graph::Easy::Manual> for a full description of the syntax rules.

=head2 Output

The output will be a L<Graph::Easy|Graph::Easy> object (unless overrriden
with C<use_class()>), see the documentation for Graph::Easy what you can do
with it.

=head1 EXAMPLES

See L<Graph::Easy> for an extensive list of examples.

=head1 METHODS

C<Graph::Easy::Parser> supports the following methods:

=head2 new()

	use Graph::Easy::Parser;
	my $parser = Graph::Easy::Parser->new();

Creates a new parser object. The valid parameters are:

	debug
	fatal_errors

The first will enable debug output to STDERR:

	my $parser = Graph::Easy::Parser->new( debug => 1 );
	$parser->from_text('[A] -> [ B ]');

Setting C<fatal_errors> to 0 will make parsing errors not die, but
just set an error string, which can be retrieved with L<error()>.

	my $parser = Graph::Easy::Parser->new( fatal_errors => 0 );
	$parser->from_text(' foo ' );
	print $parser->error();

See also L<catch_messages()> for how to catch errors and warnings.

=head2 reset()

	$parser->reset();

Reset the status of the parser, clear errors etc. Automatically called
when you call any of the C<from_XXX()> methods below.

=head2 use_class()

	$parser->use_class('node', 'Graph::Easy::MyNode');

Override the class to be used to constructs objects while parsing. The
first parameter can be one of the following:

	node
	edge
	graph
	group

The second parameter should be a class that is a subclass of the
appropriate base class:

	package Graph::Easy::MyNode;

	use base qw/Graph::Easy::Node/;

	# override here methods for your node class

	######################################################
	# when overriding nodes, we also need ::Anon

	package Graph::Easy::MyNode::Anon;

	use base qw/Graph::Easy::MyNode/;
	use base qw/Graph::Easy::Node::Anon/;

	######################################################
	# and :::Empty

	package Graph::Easy::MyNode::Empty;

	use base qw/Graph::Easy::MyNode/;

	######################################################
	package main;
	
	use Graph::Easy::Parser;
	use Graph::Easy;

	use Graph::Easy::MyNode;
	use Graph::Easy::MyNode::Anon;
	use Graph::Easy::MyNode::Empty;

	my $parser = Graph::Easy::Parser;

	$parser->use_class('node', 'Graph::Easy::MyNode');

	my $graph = $parser->from_text(...);

The object C<$graph> will now contain nodes that are of your
custom class instead of plain C<Graph::Easy::Node>.

When overriding nodes, you also should provide subclasses
for C<Graph::Easy::Node::Anon> and C<Graph::Easy::Node::Empty>,
and make these subclasses of your custom node class as shown
above. For edges, groups and graphs, you need just one subclass.

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
	my $graph = Graph::Easy::Parser->from_file( $filename );

Creates a L<Graph::Easy|Graph::Easy> object from the textual description in the file
C<$filename>.

The second calling style will create a temporary C<Graph::Easy::Parser> object,
parse the file and return the resulting C<Graph::Easy> object.

Returns undef for error, you can find out what the error was
with L<error()> when using the first calling style.

=head2 error()

	my $error = $parser->error();

Returns the last error, or the empty string if no error occured.

If you want to catch warnings from the parser, enable catching
of warnings or errors:

	$parser->catch_messages(1);

	# Or individually:
	# $parser->catch_warnings(1);
	# $parser->catch_errors(1);

	# something which warns or throws an error:
	...

	if ($parser->error())
	  {
	  my @errors = $parser->errors();
	  }
	if ($parser->warning())
	  {
	  my @warnings = $parser->warnings();
	  }

See L<Graph::Easy::Base> for more details on error/warning message capture.

=head2 parse_error()

	$parser->parse_error( $msg_nr, @params);

Sets an error message from a message number and replaces embedded
templates like C<##param1##> with the passed parameters.

=head2 _parse_attributes()

	my $attributes = $parser->_parse_attributes( $txt, $class );
	my ($att, $multiples) = $parser->_parse_attributes( $txt, $class );
  
B<Internal usage only>. Takes a text like this:

	attribute: value;  attribute2 : value2;

and returns a hash with the attributes.

In list context, also returns the max count of multiple attributes, e.g.
3 when it encounters something like C<< red|green|blue >>. When

=head1 EXPORT

Exports nothing.

=head1 SEE ALSO

L<Graph::Easy>. L<Graph::Easy::Parser::Graphviz> and L<Graph::Easy::Parser::VCG>.

=head1 AUTHOR

Copyright (C) 2004 - 2007 by Tels L<http://bloodgate.com>

See the LICENSE file for information.

=cut
