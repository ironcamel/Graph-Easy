#############################################################################
# Parse graphviz/dot text into a Graph::Easy object
#
#############################################################################

package Graph::Easy::Parser::Graphviz;

$VERSION = '0.17';
use Graph::Easy::Parser;
@ISA = qw/Graph::Easy::Parser/;

use strict;
use utf8;
use constant NO_MULTIPLES => 1;

sub _init
  {
  my $self = shift;

  $self->SUPER::_init(@_);
  $self->{attr_sep} = '=';
  # remove " <p1> " from autosplit (shape=record) labels
  $self->{_qr_part_clean} = qr/\s*<([^>]*)>/;

  $self;
  }

sub reset
  {
  my $self = shift;

  $self->SUPER::reset(@_);

  # set some default attributes on the graph object, because graphviz has
  # different defaults as Graph::Easy
  my $g = $self->{_graph};

  $g->set_attribute('colorscheme','x11');
  $g->set_attribute('flow','south');
  $g->set_attribute('edge','arrow-style', 'filled');
  $g->set_attribute('group','align', 'center');
  $g->set_attribute('group','fill', 'inherit');

  $self->{scope_stack} = [];

  # allow some temp. values during parsing
  $g->_allow_special_attributes(
    {
    node => {
      shape => [
       "",
        [ qw/ circle diamond edge ellipse hexagon house invisible
		invhouse invtrapezium invtriangle octagon parallelogram pentagon
		point triangle trapezium septagon rect rounded none img record/ ],
       '',
       '',
       undef,
      ],
    },
    } );

  $g->{_warn_on_unknown_attributes} = 1;

  $self;
  }

# map "&tilde;" to "~" 
my %entities = (
  'amp'    => '&',
  'quot'   => '"',
  'lt'     => '<',
  'gt'     => '>',
  'nbsp'   => ' ',		# this is a non-break-space between '' here!
  'iexcl'  => '¡',
  'cent'   => '¢',
  'pound'  => '£',
  'curren' => '¤',
  'yen'    => '¥',
  'brvbar' => '¦',
  'sect'   => '§',
  'uml'    => '¨',
  'copy'   => '©',
  'ordf'   => 'ª',
  'ordf'   => 'ª',
  'laquo'  => '«',
  'not'    => '¬',
  'shy'    => "\x{00AD}",		# soft-hyphen
  'reg'    => '®',
  'macr'   => '¯',
  'deg'    => '°',
  'plusmn' => '±',
  'sup2'   => '²',
  'sup3'   => '³',
  'acute'  => '´',
  'micro'  => 'µ',
  'para'   => '¶',
  'midot'  => '·',
  'cedil'  => '¸',
  'sup1'   => '¹',
  'ordm'   => 'º',
  'raquo'  => '»',
  'frac14' => '¼',
  'frac12' => '½',
  'frac34' => '¾',
  'iquest' => '¿',
  'Agrave' => 'À',
  'Aacute' => 'Á',
  'Acirc'  => 'Â',
  'Atilde' => 'Ã',
  'Auml'   => 'Ä',
  'Aring'  => 'Å',
  'Aelig'  => 'Æ',
  'Ccedil' => 'Ç',
  'Egrave' => 'È',
  'Eacute' => 'É',
  'Ecirc'  => 'Ê',
  'Euml'   => 'Ë',
  'Igrave' => 'Ì',
  'Iacute' => 'Í',
  'Icirc'  => 'Î',
  'Iuml'   => 'Ï',
  'ETH'    => 'Ð',
  'Ntilde' => 'Ñ',
  'Ograve' => 'Ò',
  'Oacute' => 'Ó',
  'Ocirc'  => 'Ô',
  'Otilde' => 'Õ',
  'Ouml'   => 'Ö',
  'times'  => '×',
  'Oslash' => 'Ø',
  'Ugrave' => 'Ù',
  'Uacute' => 'Ù',
  'Ucirc'  => 'Û',
  'Uuml'   => 'Ü',
  'Yacute' => 'Ý',
  'THORN'  => 'Þ',
  'szlig'  => 'ß',
  'agrave' => 'à',
  'aacute' => 'á',
  'acirc'  => 'â',
  'atilde' => 'ã',
  'auml'   => 'ä',
  'aring'  => 'å',
  'aelig'  => 'æ',
  'ccedil' => 'ç',
  'egrave' => 'è',
  'eacute' => 'é',
  'ecirc'  => 'ê',
  'euml'   => 'ë',
  'igrave' => 'ì',
  'iacute' => 'í',
  'icirc'  => 'î',
  'iuml'   => 'ï',
  'eth'    => 'ð',
  'ntilde' => 'ñ',
  'ograve' => 'ò',
  'oacute' => 'ó',
  'ocirc'  => 'ô',
  'otilde' => 'õ',
  'ouml'   => 'ö',
  'divide' => '÷',
  'oslash' => 'ø',
  'ugrave' => 'ù',
  'uacute' => 'ú',
  'ucirc'  => 'û',
  'uuml'   => 'ü',
  'yacute' => 'ý',
  'thorn'  => 'þ',
  'yuml'   => 'ÿ',
  'Oelig'  => 'Œ',
  'oelig'  => 'œ',
  'Scaron' => 'Š',
  'scaron' => 'š',
  'Yuml'   => 'Ÿ',
  'fnof'   => 'ƒ',
  'circ'   => '^',
  'tilde'  => '~',
  'Alpha'  => 'Α',
  'Beta'   => 'Β',
  'Gamma'  => 'Γ',
  'Delta'  => 'Δ',
  'Epsilon'=> 'Ε',
  'Zeta'   => 'Ζ',
  'Eta'    => 'Η',
  'Theta'  => 'Θ',
  'Iota'   => 'Ι',
  'Kappa'  => 'Κ',
  'Lambda' => 'Λ',
  'Mu'     => 'Μ',
  'Nu'     => 'Ν',
  'Xi'     => 'Ξ',
  'Omicron'=> 'Ο',
  'Pi'     => 'Π',
  'Rho'    => 'Ρ',
  'Sigma'  => 'Σ',
  'Tau'    => 'Τ',
  'Upsilon'=> 'Υ',
  'Phi'    => 'Φ',
  'Chi'    => 'Χ',
  'Psi'    => 'Ψ',
  'Omega'  => 'Ω',
  'alpha'  => 'α',
  'beta'   => 'β',
  'gamma'  => 'γ',
  'delta'  => 'δ',
  'epsilon'=> 'ε',
  'zeta'   => 'ζ',
  'eta'    => 'η',
  'theta'  => 'θ',
  'iota'   => 'ι',
  'kappa'  => 'κ',
  'lambda' => 'λ',
  'mu'     => 'μ',
  'nu'     => 'ν',
  'xi'     => 'ξ',
  'omicron'=> 'ο',
  'pi'     => 'π',
  'rho'    => 'ρ',
  'sigma'  => 'σ',
  'tau'    => 'τ',
  'upsilon'=> 'υ',
  'phi'    => 'φ',
  'chi'    => 'χ',
  'psi'    => 'ψ',
  'omega'  => 'ω',
  'thetasym'=>'ϑ',
  'upsih'  => 'ϒ',
  'piv'    => 'ϖ',
  'ensp'   => "\x{2003}",	# normal wide space
  'emsp'   => "\x{2004}",	# wide space
  'thinsp' => "\x{2009}",	# very thin space
  'zwnj'   => "\x{200c}",	# zero-width-non-joiner
  'zwj'    => "\x{200d}",	# zero-width-joiner
  'lrm'    => "\x{200e}",	# left-to-right
  'rlm'    => "\x{200f}",	# right-to-left
  'ndash'  => '–',
  'mdash'  => '—',
  'lsquo'  => '‘',
  'rsquo'  => '’',
  'sbquo'  => '‚',
  'ldquo'  => '“',
  'rdquo'  => '”',
  'bdquo'  => '„',
  'dagger' => '†',
  'Dagger' => '‡',
  'bull'   => '•',
  'hellip' => '…',
  'permil' => '‰',
  'prime'  => '′',
  'Prime'  => '′',
  'lsaquo' => '‹',
  'rsaquo' => '›',
  'oline'  => '‾',
  'frasl'  => '⁄',
  'euro'   => '€',
  'image'  => 'ℑ',
  'weierp' => '℘',
  'real'   => 'ℜ',
  'trade'  => '™',
  'alefsym'=> 'ℵ',
  'larr'   => '←',
  'uarr'   => '↑',
  'rarr'   => '→',
  'darr'   => '↓',
  'harr'   => '↔',
  'crarr'  => '↵',
  'lArr'   => '⇐',
  'uArr'   => '⇑',
  'rArr'   => '⇒',
  'dArr'   => '⇓',
  'hArr'   => '⇔',
  'forall' => '∀',
  'part'   => '∂',
  'exist'  => '∃',
  'empty'  => '∅',
  'nabla'  => '∇',
  'isin'   => '∈',
  'notin'  => '∉',
  'ni'     => '∋',
  'prod'   => '∏',
  'sum'    => '∑',
  'minus'  => '−',
  'lowast' => '∗',
  'radic'  => '√',
  'prop'   => '∝',
  'infin'  => '∞',
  'ang'    => '∠',
  'and'    => '∧',
  'or'     => '∨',
  'cap'    => '∩',
  'cup'    => '∪',
  'int'    => '∫',
  'there4' => '∴',
  'sim'    => '∼',
  'cong'   => '≅',
  'asymp'  => '≃',
  'ne'     => '≠',
  'eq'     => '=',
  'le'     => '≤',
  'ge'     => '≥',
  'sub'    => '⊂',
  'sup'    => '⊃',
  'nsub'   => '⊄',
  'nsup'   => '⊅',
  'sube'   => '⊆',
  'supe'   => '⊇',
  'oplus'  => '⊕',
  'otimes' => '⊗',
  'perp'   => '⊥',
  'sdot'   => '⋅',
  'lceil'  => '⌈',
  'rceil'  => '⌉',
  'lfloor' => '⌊',
  'rfloor' => '⌋',
  'lang'   => '〈',
  'rang'   => '〉',
  'roz'    => '◊',
  'spades' => '♠',
  'clubs'  => '♣',
  'diamonds'=>'♦',
  'hearts' => '♥',
  );

sub _unquote_attribute
  {
  my ($self,$name,$val) = @_;

  my $html_like = 0;
  if ($name eq 'label')
    {
    $html_like = 1 if $val =~ /^\s*<\s*</;
    # '< >' => ' ', ' < a > ' => ' a '
    if ($html_like == 0 && $val =~ /\s*<(.*)>\s*\z/)
      {
      $val = $1; $val = ' ' if $val eq '';
      }
    }
  
  my $v = $self->_unquote($val);

  # Now HTML labels always start with "<", while non-HTML labels
  # start with " <" or anything else.
  if ($html_like == 0)
    {
    $v = ' ' . $v if $v =~ /^</;
    }
  else
    {
    $v =~ s/^\s*//; $v =~ s/\s*\z//;
    }

  $v;
  }

sub _unquote
  {
  my ($self, $name) = @_;

  $name = '' unless defined $name;

  # string concat
  # "foo" + " bar" => "foo bar"
  $name =~ s/^
    "((?:\\"|[^"])*)"			# "foo"
    \s*\+\s*"((?:\\"|[^"])*)"		# followed by ' + "bar"'
    /"$1$2"/x
  while $name =~ /^
    "(?:\\"|[^"])*"			# "foo"
    \s*\+\s*"(?:\\"|[^"])*"		# followed by ' + "bar"'
    /x;

  # map "&!;" to "!"
  $name =~ s/&(.);/$1/g;

  # map "&amp;" to "&"
  $name =~ s/&([^;]+);/$entities{$1} || '';/eg;

  # "foo bar" => foo bar
  $name =~ s/^"\s*//; 		# remove left-over quotes
  $name =~ s/\s*"\z//; 

  # unquote special chars
  $name =~ s/\\([\[\(\{\}\]\)#"])/$1/g;

  $name;
  }

sub _clean_line
  { 
  # do some cleanups on a line before handling it
  my ($self,$line) = @_;

  chomp($line);

  # collapse white space at start
  $line =~ s/^\s+//;
  # line ending in '\' means a continuation
  $line =~ s/\\\z//;

  $line;
  }

sub _line_insert
  {
  # "a1 -> a2\na3 -> a4" => "a1 -> a2 a3 -> a4"
  ' ';
  }

#############################################################################

sub _match_boolean
  {
  # not used yet, match a boolean value
  qr/(true|false|\d+)/;
  }

sub _match_comment
  {
  # match the start of a comment

  # // comment
  qr#(:[^\\]|)//#;
  }

sub _match_multi_line_comment
  {
  # match a multi line comment

  # /* * comment * */
  qr#(?:\s*/\*.*?\*/\s*)+#;
  }

sub _match_optional_multi_line_comment
  {
  # match a multi line comment

  # "/* * comment * */" or /* a */ /* b */ or ""
  qr#(?:(?:\s*/\*.*?\*/\s*)*|\s+)#;
  }

sub _match_name
  {
  # Return a regexp that matches an ID in the DOT language.
  # See http://www.graphviz.org/doc/info/lang.html for reference.

  # "node", "graph", "edge", "digraph", "subgraph" and "strict" are reserved:
  qr/\s*
    (
	# double quoted string
      "(?:\\"|[^"])*"			# "foo"
      (?:\s*\+\s*"(?:\\"|[^"])*")*	# followed by 0 or more ' + "bar"'
    |
	# number
     -?					# optional minus sign
	(?:				# non-capture group
	\.[0-9]+				# .00019
	|				 # or
	[0-9]+(?:\.[0-9]*)?			# 123 or 123.1
	)
    |
	# plain node name (a-z0-9_+)
     (?!(?i:node|edge|digraph|subgraph|graph|strict)\s)[\w]+
    )/xi;
  }

sub _match_node
  {
  # Return a regexp that matches something like '"bonn"' or 'bonn' or 'bonn:f1'
  my $self = shift;

  my $qr_n = $self->_match_name();

  # Examples: "bonn", "Bonn":f1, "Bonn":"f1", "Bonn":"port":"w", Bonn:port:w
  qr/
	$qr_n				# node name (see _match_name)
	(?:
	  :$qr_n
	  (?: :(n|ne|e|se|s|sw|w|nw) )?	# :port:compass_direction
	  |
	  :(n|ne|e|se|s|sw|w|nw)	# :compass_direction
	  )?				# optional
    /x;
  }

sub _match_group_start
  {
  # match a subgraph at the beginning (f.i. "graph { ")
  my $self = shift;
  my $qr_n = $self->_match_name();

  qr/^\s*(?:strict\s+)?(?:(?i)digraph|subgraph|graph)\s+$qr_n\s*\{/i;
  }

sub _match_pseudo_group_start_at_beginning
  {
  # match an anonymous group start at the beginning (aka " { ")
  qr/^\s*\{/;
  }

sub _match_pseudo_group_start
  {
  # match an anonymous group start (aka " { ")
  qr/\s*\{/;
  }

sub _match_group_end
  {
  # return a regexp that matches something like " }" or "} ;".
  qr/^\s*\}\s*;?\s*/;
  }

sub _match_edge
  {
  # Matches an edge
  qr/\s*(->|--)/;
  }

sub _match_html_regexps
  {
  # Return hash with regexps matching different parts of an HTML label.
  my $qr = 
  {
    # BORDER="2"
    attribute 	=> qr/\s*([A-Za-z]+)\s*=\s*"((?:\\"|[^"])*)"/,
    # BORDER="2" COLSPAN="2"
    attributes 	=> qr/(?:\s+(?:[A-Za-z]+)\s*=\s*"(?:\\"|[^"])*")*/,
    text	=> qr/.*?/,
    tr		=> qr/\s*<TR>/i,
    tr_end	=> qr/\s*<\/TR>/i,
    td		=> qr/\s*<TD[^>]*>/i,
    td_tag	=> qr/\s*<TD\s*/i,
    td_end	=> qr/\s*<\/TD>/i,
    table	=> qr/\s*<TABLE[^>]*>/i,
    table_tag	=> qr/\s*<TABLE\s*/i,
    table_end	=> qr/\s*<\/TABLE>/i,
  };
  $qr->{row} = qr/$qr->{tr}(?:$qr->{td}$qr->{text}$qr->{td_end})*$qr->{tr_end}/;

  $qr;
  }

sub _match_html
  {
  # build a giant regular expression that matches an HTML label

#    label=<
#    <TABLE BORDER="2" CELLBORDER="1" CELLSPACING="0" BGCOLOR="#ffffff">
#      <TR><TD PORT="portname" COLSPAN="3" BGCOLOR="#aabbcc" ALIGN="CENTER">port</TD></TR>
#      <TR><TD PORT="port2" COLSPAN="2" ALIGN="LEFT">port2</TD><TD PORT="port3" ALIGN="LEFT">port3</TD></TR>
#    </TABLE>>

  my $qr = _match_html_regexps();

  # < <TABLE> .. </TABLE> >
  qr/<$qr->{table}(?:$qr->{row})*$qr->{table_end}\s*>/;
  }
  
sub _match_single_attribute
  {
  my $qr_html = _match_html();

  qr/\s*(\w+)\s*=\s*		# the attribute name (label=")
    (
      "(?:\\"|[^"])*"			# "foo"
      (?:\s*\+\s*"(?:\\"|[^"])*")*	# followed by 0 or more ' + "bar"'
    |
      $qr_html				# or < <TABLE>..<\/TABLE> >
    |
      <[^>]*>				# or something like < a >
    |
      [^<][^,\]\}\n\s;]*		# or simple 'fooobar'
    )
    [,\]\n\}\s;]?\s*/x;		# possible ",", "\n" etc.
  }

sub _match_special_attribute
  {
  # match boolean attributes, these can appear without a value
  qr/\s*(
  center|
  compound|
  concentrate|
  constraint|
  decorate|
  diredgeconstraints|
  fixedsize|
  headclip|
  labelfloat|
  landscape|
  mosek|
  nojustify|
  normalize|
  overlap|
  pack|
  pin|
  regular|
  remincross|
  root|
  splines|
  tailclip|
  truecolor
  )[,;\s]?\s*/x;
  }

sub _match_attributes
  {
  # return a regexp that matches something like " [ color=red; ]" and returns
  # the inner text without the []

  my $qr_att = _match_single_attribute();
  my $qr_satt = _match_special_attribute();
  my $qr_cmt = _match_multi_line_comment();
 
  qr/\s*\[\s*((?:$qr_att|$qr_satt|$qr_cmt)*)\s*\];?/;
  }

sub _match_graph_attribute
  {
  # return a regexp that matches something like " color=red; " for attributes
  # that apply to a graph/subgraph
  qr/^\s*(\w+\s*=\s*("[^"]+"|[^;\n\s]+))([;\n\s]\s*|\z)/;
  }

sub _match_optional_attributes
  {
  # return a regexp that matches something like " [ color=red; ]" and returns
  # the inner text with the []

  my $qr_att = _match_single_attribute();
  my $qr_satt = _match_special_attribute();
  my $qr_cmt = _match_multi_line_comment();
 
  qr/\s*(\[\s*((?:$qr_att|$qr_satt|$qr_cmt)*)\s*\])?;?/;
  }

sub _clean_attributes
  {
  my ($self,$text) = @_;

  $text =~ s/^\s*\[\s*//;		# remove left-over "[" and spaces
  $text =~ s/\s*;?\s*\]\s*\z//;		# remove left-over "]" and spaces

  $text;
  }

#############################################################################

sub _new_scope
  {
  # create a new scope, with attributes from current scope
  my ($self, $is_group) = @_;

  my $scope = {};

  if (@{$self->{scope_stack}} > 0)
    {
    my $old_scope = $self->{scope_stack}->[-1];

    # make a copy of the old scope's attributes
    for my $t (keys %$old_scope)
      {
      next if $t =~ /^_/;
      my $s = $old_scope->{$t};
      $scope->{$t} = {} unless ref $scope->{$t}; my $sc = $scope->{$t};
      for my $k (keys %$s)
        {
	# skip things like "_is_group"
        $sc->{$k} = $s->{$k} unless $k =~ /^_/;
        }
      }
    }
  $scope->{_is_group} = 1 if defined $is_group;

  push @{$self->{scope_stack}}, $scope;
  $scope;
  }

sub _add_group_match
  {
  # register handlers for group start/end
  my $self = shift;

  my $qr_pseudo_group_start = $self->_match_pseudo_group_start_at_beginning();
  my $qr_group_start = $self->_match_group_start();
  my $qr_group_end   = $self->_match_group_end();
  my $qr_edge  = $self->_match_edge();
  my $qr_ocmt  = $self->_match_optional_multi_line_comment();

  # "subgraph G {"
  $self->_register_handler( $qr_group_start,
    sub
      {
      my $self = shift;
      my $graph = $self->{_graph};
      my $gn = $self->_unquote($1);
      print STDERR "# Parser: found subcluster '$gn'\n" if $self->{debug};
      push @{$self->{group_stack}}, $self->_new_group($gn);
      $self->_new_scope( 1 );
      1;
      } );
  
  # "{ "
  $self->_register_handler( $qr_pseudo_group_start,
    sub
      {
      my $self = shift;
      print STDERR "# Parser: Creating new scope\n" if $self->{debug};
      $self->_new_scope();
      # forget the left side
      $self->{left_edge} = undef;
      $self->{left_stack} = [ ];
      1;
      } );

  # "} -> " group/cluster/scope end with an edge
  $self->_register_handler( qr/$qr_group_end$qr_ocmt$qr_edge/,
    sub
      {
      my $self = shift;

      my $scope = pop @{$self->{scope_stack}};
      return $self->parse_error(0) if !defined $scope;

      if ($scope->{_is_group} && @{$self->{group_stack}})
        {
        print STDERR "# Parser: end subcluster '$self->{group_stack}->[-1]->{name}'\n" if $self->{debug};
        pop @{$self->{group_stack}};
        }
      else { print STDERR "# Parser: end scope\n" if $self->{debug}; }

      1;
      }, 
    sub
      {
      my ($self, $line) = @_;
      $line =~ qr/$qr_group_end$qr_edge/;
      $1 . ' ';
      } );

  # "}" group/cluster/scope end
  $self->_register_handler( $qr_group_end,
    sub
      {
      my $self = shift;
 
      my $scope = pop @{$self->{scope_stack}};
      return $self->parse_error(0) if !defined $scope;

      if ($scope->{_is_group} && @{$self->{group_stack}})
        {
        print STDERR "# Parser: end subcluster '$self->{group_stack}->[-1]->{name}'\n" if $self->{debug};
        pop @{$self->{group_stack}};
        }
      # always reset the stack
      $self->{stack} = [ ];
      1;
      } );
  }

sub _edge_style
  {
  # To convert "--" or "->" we simple do nothing, since the edge style in
  # Graphviz can only be set via the attribute "style"
  my ($self, $ed) = @_;

  'solid';
  }

sub _new_nodes
  {
  my ($self, $name, $group_stack, $att, $port, $stack) = @_;

  $port = '' unless defined $port;
  my @rc = ();
  # "name1" => "name1"
  if ($port ne '')
    {
    # create a special node
    $name =~ s/^"//; $name =~ s/"\z//;
    $port =~ s/^"//; $port =~ s/"\z//;
    # XXX TODO: find unique name?
    @rc = $self->_new_node ($self->{_graph}, "$name:$port", $group_stack, $att, $stack);
    my $node = $rc[0];
    $node->{_graphviz_portlet} = $port;
    $node->{_graphviz_basename} = $name;
    }
  else
    {
    @rc = $self->_new_node ($self->{_graph}, $name, $group_stack, $att, $stack);
    }
  @rc;
  }

sub _build_match_stack
  {
  my $self = shift;

  my $qr_node  = $self->_match_node();
  my $qr_name  = $self->_match_name();
  my $qr_cmt   = $self->_match_multi_line_comment();
  my $qr_ocmt  = $self->_match_optional_multi_line_comment();
  my $qr_attr  = $self->_match_attributes();
  my $qr_gatr  = $self->_match_graph_attribute();
  my $qr_oatr  = $self->_match_optional_attributes();
  my $qr_edge  = $self->_match_edge();
  my $qr_pgr = $self->_match_pseudo_group_start();

  # remove multi line comments /* comment */
  $self->_register_handler( qr/^$qr_cmt/, undef );
  
  # remove single line comment // comment
  $self->_register_handler( qr/^\s*\/\/.*/, undef );
  
  # simple remove the graph start, but remember that we did this
  $self->_register_handler( qr/^\s*((?i)strict)?$qr_ocmt((?i)digraph|graph)$qr_ocmt$qr_node$qr_ocmt\{/, 
    sub 
      {
      my $self = shift;
      return $self->parse_error(6) if @{$self->{scope_stack}} > 0; 
      $self->{_graphviz_graph_name} = $3; 
      $self->_new_scope(1);
      $self->{_graph}->set_attribute('type','undirected') if lc($2) eq 'graph';
      1;
      } );

  # simple remove the graph start, but remember that we did this
  $self->_register_handler( qr/^\s*(strict)?$qr_ocmt(di)?graph$qr_ocmt\{/i, 
    sub 
      {
      my $self = shift;
      return $self->parse_error(6) if @{$self->{scope_stack}} > 0; 
      $self->{_graphviz_graph_name} = 'unnamed'; 
      $self->_new_scope(1);
      $self->{_graph}->set_attribute('type','undirected') if lc($2) ne 'di';
      1;
      } );

  # end-of-statement
  $self->_register_handler( qr/^\s*;/, undef );

  # cluster/subgraph "subgraph G { .. }"
  # scope (dummy group): "{ .. }" 
  # scope/group/subgraph end: "}"
  $self->_add_group_match();

  # node [ color="red" ] etc.
  # The "(?i)" makes the keywords match case-insensitive. 
  $self->_register_handler( qr/^\s*((?i)node|graph|edge)$qr_ocmt$qr_attr/,
    sub
      {
      my $self = shift;
      my $type = lc($1 || '');
      my $att = $self->_parse_attributes($2 || '', $type, NO_MULTIPLES );
      return undef unless defined $att;		# error in attributes?

      if ($type ne 'graph')
	{
	# apply the attributes to the current scope
	my $scope = $self->{scope_stack}->[-1];
        $scope->{$type} = {} unless ref $scope->{$type};
	my $s = $scope->{$type};
	for my $k (keys %$att)
	  {
          $s->{$k} = $att->{$k}; 
	  }
	}
      else
	{
	my $graph = $self->{_graph};
	$graph->set_attributes ($type, $att);
	}

      # forget stacks
      $self->{stack} = [];
      $self->{left_edge} = undef;
      $self->{left_stack} = [];
      1;
      } );

  # color=red; (for graphs or subgraphs)
  $self->_register_attribute_handler($qr_gatr, 'parent');
  # [ color=red; ] (for nodes/edges)
  $self->_register_attribute_handler($qr_attr);

  # node chain continued like "-> { ... "
  $self->_register_handler( qr/^$qr_edge$qr_ocmt$qr_pgr/,
    sub
      {
      my $self = shift;

      return if @{$self->{stack}} == 0;	# only match this if stack non-empty

      my $graph = $self->{_graph};
      my $eg = $1;					# entire edge ("->" etc)

      my $edge_un = 0; $edge_un = 1 if $eg eq '--';	# undirected edge?

      # need to defer edge attribute parsing until the edge exists
      # if inside a scope, set the scope attributes, too:
      my $scope = $self->{scope_stack}->[-1] || {};
      my $edge_atr = $scope->{edge} || {};

      # create a new scope
      $self->_new_scope();

      # remember the left side
      $self->{left_edge} = [ 'solid', '', $edge_atr, 0, $edge_un ];
      $self->{left_stack} = $self->{stack};

      # forget stack and remember the right side instead
      $self->{stack} = [];

      1;
      } );

  # "Berlin"
  $self->_register_handler( qr/^$qr_node/,
    sub
      {
      my $self = shift;
      my $graph = $self->{_graph};

      # only match this inside a "{ }" (normal, non-group) scope
      return if exists $self->{scope_stack}->[-1]->{_is_group};

      my $n1 = $1;
      my $port = $2;
      push @{$self->{stack}},
        $self->_new_nodes ($n1, $self->{group_stack}, {}, $port, $self->{stack}); 

      if (defined $self->{left_edge})
        {
        my $e = $self->{use_class}->{edge};
        my ($style, $edge_label, $edge_atr, $edge_bd, $edge_un) = @{$self->{left_edge}};

        foreach my $node (@{$self->{left_stack}})
          {
          my $edge = $e->new( { style => $style, name => $edge_label } );

	  # if inside a scope, set the scope attributes, too:
	  my $scope = $self->{scope_stack}->[-1];
          $edge->set_attributes($scope->{edge}) if $scope;

	  # override with the local attributes 
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
	    my $out = $self->_parse_attributes($a, $edge, NO_MULTIPLES);
            return undef unless defined $out;		# error in attributes?
	    $edge->set_attributes($out);
	    }
	  }

          # "<--->": bidirectional
          $edge->bidirectional(1) if $edge_bd;
          $edge->undirected(1) if $edge_un;
          $graph->add_edge ( $node, $self->{stack}->[-1], $edge );
          }
        }
      1;
      } );

  # "Berlin" [ color=red ] or "Bonn":"a" [ color=red ]
  $self->_register_handler( qr/^$qr_node$qr_oatr/,
    sub
      {
      my $self = shift;
      my $name = $1;
      my $port = $2;
      my $compass = $4 || ''; $port .= ":$compass" if $compass;

      $self->{stack} = [ $self->_new_nodes ($name, $self->{group_stack}, {}, $port ) ];

      # defer attribute parsing until object exists
      my $node = $self->{stack}->[0];
      my $a1 = $self->_parse_attributes($5||'', $node);
      return undef if $self->{error};
      $node->set_attributes($a1);

      # forget left stack
      $self->{left_edge} = undef;
      $self->{left_stack} = [];
      1;
      } );

  # Things like ' "Node" ' will be consumed before, so we do not need a case
  # for '"Bonn" -> "Berlin"'

  # node chain continued like "-> "Kassel" [ ... ]"
  $self->_register_handler( qr/^$qr_edge$qr_ocmt$qr_node$qr_ocmt$qr_oatr/,
    sub
      {
      my $self = shift;

      return if @{$self->{stack}} == 0;	# only match this if stack non-empty

      my $graph = $self->{_graph};
      my $eg = $1;					# entire edge ("->" etc)
      my $n = $2;					# node name
      my $port = $3;
      my $compass = $4 || $5 || ''; $port .= ":$compass" if $compass;

      my $edge_un = 0; $edge_un = 1 if $eg eq '--';	# undirected edge?

      my $scope = $self->{scope_stack}->[-1] || {};

      # need to defer edge attribute parsing until the edge exists
      my $edge_atr = [ $6||'', $scope->{edge} || {} ];

      # the right side nodes:
      my $nodes_b = [ $self->_new_nodes ($n, $self->{group_stack}, {}, $port) ];

      my $style = $self->_link_lists( $self->{stack}, $nodes_b,
	'--', '', $edge_atr, 0, $edge_un);

      # remember the left side
      $self->{left_edge} = [ $style, '', $edge_atr, 0, $edge_un ];
      $self->{left_stack} = $self->{stack};

      # forget stack and remember the right side instead
      $self->{stack} = $nodes_b;
      1;
      } );

  $self;
  }

sub _add_node
  {
  # add a node to the graph, overridable by subclasses
  my ($self, $graph, $name) = @_;

  # "a -- clusterB" should not create a spurious node named "clusterB"
  my @groups = $graph->groups();
  for my $g (@groups)
    {
    return $g if $g->{name} eq $name;
    }

  my $node = $graph->node($name);
 
  if (!defined $node)
    {
    $node = $graph->add_node($name);		# add

    # apply attributes from the current scope (only for new nodes)
    my $scope = $self->{scope_stack}->[-1];
    return $self->error("Scope stack is empty!") unless defined $scope;
  
    my $is_group = $scope->{_is_group};
    delete $scope->{_is_group};
    $node->set_attributes($scope->{node});
    $scope->{_is_group} = $is_group if $is_group;
    }

  $node;
  }

#############################################################################
# attribute remapping

# undef => drop that attribute
# not listed attributes will result in "x-dot-$attribute" and a warning

my $remap = {
  'node' => {
    'distortion' => 'x-dot-distortion',

    'fixedsize' => undef,
    'group' => 'x-dot-group',
    'height' => 'x-dot-height',

    # XXX TODO: ignore non-node attributes set in a scope
    'dir' => undef,

    'layer' => 'x-dot-layer',
    'margin' => 'x-dot-margin',
    'orientation' => \&_from_graphviz_node_orientation,
    'peripheries' => \&_from_graphviz_node_peripheries,
    'pin' => 'x-dot-pin',
    'pos' => 'x-dot-pos',
    # XXX TODO: rank=0 should make that node the root node
#   'rank' => undef,
    'rects' => 'x-dot-rects',
    'regular' => 'x-dot-regular',
#    'root' => undef,
    'sides' => 'x-dot-sides',
    'shapefile' => 'x-dot-shapefile',
    'shape' => \&_from_graphviz_node_shape,
    'skew' => 'x-dot-skew',
    'style' => \&_from_graphviz_style,
    'width' => 'x-dot-width',
    'z' => 'x-dot-z',
    },

  'edge' => {
    'arrowsize' => 'x-dot-arrowsize',
    'arrowhead' => \&_from_graphviz_arrow_style,
    'arrowtail' => 'x-dot-arrowtail',
     # important for color lists like "red:red" => double edge
    'color' => \&_from_graphviz_edge_color,
    'constraint' => 'x-dot-constraint',
    'dir' => \&_from_graphviz_edge_dir,
    'decorate' => 'x-dot-decorate',
    'f' => 'x-dot-f',
    'headclip' => 'x-dot-headclip',
    'headhref' => 'headlink',
    'headurl' => 'headlink',
    'headport' => \&_from_graphviz_headport,
    'headlabel' => 'headlabel',
    'headtarget' => 'x-dot-headtarget',
    'headtooltip' => 'headtitle',
    'labelangle' => 'x-dot-labelangle',
    'labeldistance' => 'x-dot-labeldistance',
    'labelfloat' => 'x-dot-labelfloat',
    'labelfontcolor' => \&_from_graphviz_color,
    'labelfontname' => 'font',
    'labelfontsize' => 'font-size',
    'layer' => 'x-dot-layer',
    'len' => 'x-dot-len',
    'lhead' => 'x-dot-lhead',
    'ltail' => 'x-dot-tail',
    'minlen' => \&_from_graphviz_edge_minlen,
    'pos' => 'x-dot-pos',
    'samehead' => 'x-dot-samehead',
    'samearrowhead' => 'x-dot-samearrowhead',
    'sametail' => 'x-dot-sametail',
    'style' => \&_from_graphviz_edge_style,
    'tailclip' => 'x-dot-tailclip',
    'tailhref' => 'taillink',
    'tailurl' => 'taillink',
    'tailport' => \&_from_graphviz_tailport,
    'taillabel' => 'taillabel',
    'tailtarget' => 'x-dot-tailtarget',
    'tailtooltip' => 'tailtitle',
    'weight' => 'x-dot-weight',
    },

  'graph' => {
    'damping' => 'x-dot-damping',
    'K' => 'x-dot-k',
    'bb' => 'x-dot-bb',
    'center' => 'x-dot-center',
    # will be handled automatically:
    'charset' => undef,
    'clusterrank' => 'x-dot-clusterrank',
    'compound' => 'x-dot-compound',
    'concentrate' => 'x-dot-concentrate',
    'defaultdist' => 'x-dot-defaultdist',
    'dim' => 'x-dot-dim',
    'dpi' => 'x-dot-dpi',
    'epsilon' => 'x-dot-epsilon',
    'esep' => 'x-dot-esep',
    'fontpath' => 'x-dot-fontpath',
    'labeljust' => \&_from_graphviz_graph_labeljust,
    'labelloc' => \&_from_graphviz_labelloc,
    'landscape' => 'x-dot-landscape',
    'layers' => 'x-dot-layers',
    'layersep' => 'x-dot-layersep',
    'levelsgap' => 'x-dot-levelsgap',
    'margin' => 'x-dot-margin',
    'maxiter' => 'x-dot-maxiter',
    'mclimit' => 'x-dot-mclimit',
    'mindist' => 'x-dot-mindist',
    'minquit' => 'x-dot-minquit',
    'mode' => 'x-dot-mode',
    'model' => 'x-dot-model',
    'nodesep' => 'x-dot-nodesep',
    'normalize' => 'x-dot-normalize',
    'nslimit' => 'x-dot-nslimit',
    'nslimit1' => 'x-dot-nslimit1',
    'ordering' => 'x-dot-ordering',
    'orientation' => 'x-dot-orientation',
    'output' => 'output',
    'outputorder' => 'x-dot-outputorder',
    'overlap' => 'x-dot-overlap',
    'pack' => 'x-dot-pack',
    'packmode' => 'x-dot-packmode',
    'page' => 'x-dot-page',
    'pagedir' => 'x-dot-pagedir',
    'pencolor' => \&_from_graphviz_color,
    'quantum' => 'x-dot-quantum',
    'rankdir' => \&_from_graphviz_graph_rankdir,
    'ranksep' => 'x-dot-ranksep',
    'ratio' => 'x-dot-ratio',
    'remincross' => 'x-dot-remincross',
    'resolution' => 'x-dot-resolution',
    'rotate' => 'x-dot-rotate',
    'samplepoints' => 'x-dot-samplepoints',
    'searchsize' => 'x-dot-searchsize',
    'sep' => 'x-dot-sep',
    'size' => 'x-dot-size',
    'splines' => 'x-dot-splines',
    'start' => 'x-dot-start',
    'style' => \&_from_graphviz_style,
    'stylesheet' => 'x-dot-stylesheet',
    'truecolor' => 'x-dot-truecolor',
    'viewport' => 'x-dot-viewport',
    'voro-margin' => 'x-dot-voro-margin',
    },

  'group' => {
    'labeljust' => \&_from_graphviz_graph_labeljust,
    'labelloc' => \&_from_graphviz_labelloc,
    'pencolor' => \&_from_graphviz_color,
    'style' => \&_from_graphviz_style,
    'K' => 'x-dot-k',
    },

  'all' => {
    'color' => \&_from_graphviz_color,
    'colorscheme' => 'x-colorscheme',
    'bgcolor' => \&_from_graphviz_color,
    'fillcolor' => \&_from_graphviz_color,
    'fontsize' => \&_from_graphviz_font_size,
    'fontcolor' => \&_from_graphviz_color,
    'fontname' => 'font',
    'lp' => 'x-dot-lp',
    'nojustify' => 'x-dot-nojustify',
    'rank' => 'x-dot-rank',
    'showboxes' => 'x-dot-showboxes',
    'target' => 'x-dot-target',
    'tooltip' => 'title',
    'URL' => 'link',
    'href' => 'link',
    },
  };

sub _remap { $remap; }

my $rankdir = {
  'LR' => 'east',
  'RL' => 'west',
  'TB' => 'south',
  'BT' => 'north',
  };

sub _from_graphviz_graph_rankdir
  {
  my ($self, $name, $dir, $object) = @_;

  my $d = $rankdir->{$dir} || 'east';

  ('flow', $d);
  }

my $shapes = {
  box => 'rect',
  polygon => 'rect',
  egg => 'rect',
  rectangle => 'rect',
  mdiamond => 'diamond',
  msquare => 'rect',
  plaintext => 'none',
  none => 'none',
  };

sub _from_graphviz_node_shape
  {
  my ($self, $name, $shape) = @_;

  my @rc;
  my $s = lc($shape);
  if ($s =~ /^(triple|double)/)
    {
    $s =~ s/^(triple|double)//;
    push @rc, ('border-style','double');
    }

  # map the name to what Graph::Easy expects (ellipse stays as ellipse f.i.)
  $s = $shapes->{$s} || $s;

  (@rc, $name, $s);
  }

sub _from_graphviz_style
  {
  my ($self, $name, $style, $class) = @_;

  my @styles = split /\s*,\s*/, $style;

  my $is_node = 0;
  $is_node = 1 if ref($class) && !$class->isa('Graph::Easy::Group');
  $is_node = 1 if !ref($class) && defined $class && $class eq 'node';

  my @rc;
  for my $s (@styles)
    {
    @rc = ('shape', 'rounded') if $s eq 'rounded';
    @rc = ('shape', 'invisible') if $s eq 'invis';
    @rc = ('border', 'black ' . $1) if $s =~ /^(bold|dotted|dashed)\z/;
    if ($is_node != 0)
      {	
      @rc = ('shape', 'rect') if $s eq 'filled';
      }
    # convert "setlinewidth(12)" => 
    if ($s =~ /setlinewidth\((\d+|\d*\.\d+)\)/)
      {
      my $width = abs($1 || 1);
      my $style = '';
      $style = 'wide';			# > 11
      $style = 'solid' if $width < 3;
      $style = 'bold' if $width >= 3 && $width < 5;
      $style = 'broad' if $width >= 5 && $width < 11;
      push @rc, ('borderstyle',$style);
      }
    }

  @rc;
  }

sub _from_graphviz_node_orientation
  {
  my ($self, $name, $o) = @_;

  my $r = int($o);
  
  return (undef,undef) if $r == 0;

  # 1.0 => 1
  ('rotate', $r);
  }

my $port_remap = {
  n => 'north',
  e => 'east',
  w => 'west',
  s => 'south',
  };

sub _from_graphviz_headport
  {
  my ($self, $name, $compass) = @_;

  # XXX TODO
  # handle "port:compass" too

  # one of "n","ne","e","se","s","sw","w","nw
  # "ne => n"
  my $c = $port_remap->{ substr(lc($compass),0,1) } || 'east';
 
  ('end', $c);
  }

sub _from_graphviz_tailport
  {
  my ($self, $name, $compass) = @_;

  # XXX TODO
  # handle "port:compass" too

  # one of "n","ne","e","se","s","sw","w","nw
  # "ne => n" => "north"
  my $c = $port_remap->{ substr(lc($compass),0,1) } || 'east';
  
  ('start', $c);
  }

sub _from_graphviz_node_peripheries
  {
  my ($self, $name, $cnt) = @_;

  return (undef,undef) if $cnt < 2;

  # peripheries = 2 => double border
  ('border-style', 'double');
  }

sub _from_graphviz_edge_minlen
  {
  my ($self, $name, $len) = @_;

  # 1 => 1, 2 => 3, 3 => 5 etc
  $len = $len * 2 - 1;
  ($name, $len);
  }

sub _from_graphviz_font_size
  {
  my ($self, $f, $size) = @_;

  # 20 => 20px
  $size = $size . 'px' if $size =~ /^\d+(\.\d+)?\z/;

  ('fontsize', $size);
  }

sub _from_graphviz_labelloc
  {
  my ($self, $name, $loc) = @_;

  my $l = 'top';
  $l = 'bottom' if $loc =~ /^b/;

  ('labelpos', $l);
  }

sub _from_graphviz_edge_dir
  {
  my ($self, $name, $dir, $edge) = @_;

  # Modify the edge, depending on dir
  if (ref($edge))
    {
    # "forward" is the default and ignored
    $edge->flip() if $dir eq 'back';
    $edge->bidirectional(1) if $dir eq 'both';
    $edge->undirected(1) if $dir eq 'none';
    }

  (undef, undef);
  }

sub _from_graphviz_edge_style
  {
  my ($self, $name, $style, $object) = @_;

  # input: solid dashed dotted bold invis
  $style = 'invisible' if $style eq 'invis';

  # although "normal" is not documented, it occurs in the wild
  $style = 'solid' if $style eq 'normal';

  # convert "setlinewidth(12)" => 
  if ($style =~ /setlinewidth\((\d+|\d*\.\d+)\)/)
    {
    my $width = abs($1 || 1);
    $style = 'wide';			# > 11
    $style = 'solid' if $width < 3;
    $style = 'bold' if $width >= 3 && $width < 5;
    $style = 'broad' if $width >= 5 && $width < 11;
    }

  ($name, $style);
  }

sub _from_graphviz_arrow_style
  {
  my ($self, $name, $shape, $object) = @_;

  my $style = 'open';

  $style = 'closed' if $shape =~ /^(empty|onormal)\z/;
  $style = 'filled' if $shape eq 'normal' || $shape eq 'normalnormal';
  $style = 'open' if $shape eq 'vee' || $shape eq 'veevee';
  $style = 'none' if $shape eq 'none' || $shape eq 'nonenone';

  ('arrow-style', $style);
  }

my $color_atr_map = {
  fontcolor => 'color',
  bgcolor => 'background',
  fillcolor => 'fill',
  pencolor => 'bordercolor',
  labelfontcolor => 'labelcolor',
  color => 'color',
  };

sub _from_graphviz_color
  {
  # Remap the color name and value
  my ($self, $name, $color) = @_;

  # "//red" => "red"
  $color =~ s/^\/\///;

  my $colorscheme = 'x11';
  if ($color =~ /^\//)
    {
    # "/set9/red" => "red"
    $color =~ s/^\/([^\/]+)\///;
    $colorscheme = $1;
    # map the color to the right color according to the colorscheme
    $color = Graph::Easy->color_value($color,$colorscheme) || 'black';
    }

  # "#AA BB CC => "#AABBCC"
  $color =~ s/\s+//g if $color =~ /^#/;

  # "0.1 0.4 0.5" => "hsv(0.1,0.4,0.5)"
  $color =~ s/\s+/,/g if $color =~ /\s/;
  $color = 'hsv(' . $color . ')' if $color =~ /,/;

  ($color_atr_map->{$name}, $color);
  }

sub _from_graphviz_edge_color
  {
  # remap the color name and value
  my ($self, $name, $color) = @_;

  my @colors = split /:/, $color;

  for my $c (@colors)
    {
    $c = Graph::Easy::Parser::Graphviz::_from_graphviz_color($self,$name,$c);
    }

  my @rc;
  if (@colors > 1)
    {
    # 'red:blue' => "style: double; color: red"
    push @rc, 'style', 'double';
    }

  (@rc, $color_atr_map->{$name}, $colors[0]);
  }

sub _from_graphviz_graph_labeljust
  {
  my ($self, $name, $l) = @_;

  # input: "l" "r" or "c", output "left", "right" or "center"
  my $a = 'center';
  $a = 'left' if $l eq 'l';
  $a = 'right' if $l eq 'r';

  ('align', $a);
  }

#############################################################################

sub _remap_attributes
  {
  my ($self, $att, $object, $r) = @_;

  if ($self->{debug})
    {
    my $o = ''; $o = " for $object" if $object;
    print STDERR "# remapping attributes '$att'$o\n";
    require Data::Dumper; print STDERR "#" , Data::Dumper::Dumper($att),"\n";
    }

  $r = $self->_remap() unless defined $r;

  $self->{_graph}->_remap_attributes($object, $att, $r, 'noquote', undef, undef);
  }

#############################################################################

my $html_remap = {
  'table' => {
    'align' => 'align',
    'balign' => undef,
    'bgcolor' => 'fill',
    'border' => 'border',
    # XXX TODO
    'cellborder' => 'border',
    'cellspacing' => undef,
    'cellpadding' => undef,
    'fixedsize' => undef,
    'height' => undef,
    'href' => 'link',
    'port' => undef,
    'target' => undef,
    'title' => 'title',
    'tooltip' => 'title',
    'valign' => undef,
    'width' => undef,
    },
  'td' => {
    'align' => 'align',
    'balign' => undef,
    'bgcolor' => 'fill',
    'border' => 'border',
    'cellspacing' => undef,
    'cellpadding' => undef,
    'colspan' => 'columns',
    'fixedsize' => undef,
    'height' => undef,
    'href' => 'link',
    'port' => undef,
    'rowspan' => 'rows',
    'target' => undef,
    'title' => 'title',
    'tooltip' => 'title',
    'valign' => undef,
    'width' => undef,
    },
  };

sub _parse_html_attributes
  {
  my ($self, $text, $qr, $tag) = @_;

  # "<TD ...>" => " ..."
  $text =~ s/^$qr->{td_tag}//;
  $text =~ s/\s*>\z//;

  my $attr = {};
  while ($text ne '')
    {

    return $self->error("HTML-like attribute '$text' doesn't look valid to me.")
      unless $text =~ s/^($qr->{attribute})//;

    my $name = lc($2); my $value = $3;

    $self->_unquote($value);
    $value = lc($value) if $name eq 'align';
    $self->error ("Unknown attribute '$name' in HTML-like label") unless exists $html_remap->{$tag}->{$name};
    # filter out attributes we do not yet support
    $attr->{$name} = $value if defined $html_remap->{$tag}->{$name};
    }

  $attr;
  }

sub _html_per_table
  {
  # take the HTML-like attributes found per TABLE and create a hash with them
  # so they can be applied as default to each node
  my ($self, $attributes) = @_;

  $self->_remap_attributes($attributes,'table',$html_remap);
  }

sub _html_per_node
  {
  # take the HTML-like attributes found per TD and apply them to the node
  my ($self, $attr, $node) = @_;

  my $c = $attr->{colspan} || 1;
  $node->set_attribute('columns',$c) if $c != 1;

  my $r = $attr->{rowspan} || 1;
  $node->set_attribute('rows',$r) if $r != 1;

  $node->{autosplit_portname} = $attr->{port} if exists $attr->{port};

  for my $k (qw/port colspan rowspan/)
    {
    delete $attr->{$k};
    }

  my $att = $self->_remap_attributes($attr,$node,$html_remap);
 
  $node->set_attributes($att);

  $self;
  }

sub _parse_html
  {
  # Given an HTML label, parses that into the individual parts. Returns a
  # list of nodes.
  my ($self, $n, $qr) = @_;

  my $graph = $self->{_graph};

  my $label = $n->label(1); $label = '' unless defined $label;
  my $org_label = $label;

#  print STDERR "# 1 HTML-like label is now: $label\n";

  # "unquote" the HTML-like label
  $label =~ s/^<\s*//;
  $label =~ s/\s*>\z//;

#  print STDERR "# 2 HTML-like label is now: $label\n";

  # remove the table end (at the end)
  $label =~ s/$qr->{table_end}\s*\z//;
#  print STDERR "# 2.a HTML-like label is now: $label\n";
  # remove the table start
  $label =~ s/($qr->{table})//;

#  print STDERR "# 3 HTML-like label is now: $label\n";

  my $table_tag = $1 || ''; 
  $table_tag =~ /$qr->{table_tag}(.*?)>/;
  my $table_attr = $self->_parse_html_attributes($1 || '', $qr, 'table');

#  use Data::Dumper;
#  print STDERR "# 3 HTML-like table-tag attributes are: ", Dumper($table_attr),"\n";

  # generate the base name from the actual graphviz node name to allow links to
  # it
  my $base_name = $n->{name};

  my $class = $self->{use_class}->{node};

  my $raw_attributes = $n->raw_attributes();
  delete $raw_attributes->{label};
  delete $raw_attributes->{shape};

  my @rc; my $first_in_row;
  my $x = 0; my $y = 0; my $idx = 0;
  while ($label ne '')
    {
    $label =~ s/^\s*($qr->{row})//;
  
    return $self->error ("Cannot parse HTML-like label: '$label'")
      unless defined $1;

    # we now got one row:
    my $row = $1;

#  print STDERR "# 3 HTML-like row is $row\n";

    # remove <TR>
    $row =~ s/^\s*$qr->{tr}\s*//; 
    # remove </TR>
    $row =~ s/\s*$qr->{tr_end}\s*\z//;

    my $first = 1;
    while ($row ne '')
      {
      # remove one TD from the current row text
      $row =~ s/^($qr->{td})($qr->{text})$qr->{td_end}//;
      return $self->error ("Cannot parse HTML-like row: '$row'")
        unless defined $1;

      my $node_label = $2;
      my $attr_txt = $1;

      # convert "<BR/>" etc. to line breaks
      # XXX TODO apply here the default of BALIGN
      $node_label =~ s/<BR\s*\/?>/\\n/gi;

      # if the font covers the entire node, set "font" attribute
      my $font_face = undef;
      if ($node_label =~ /^[ ]*<FONT FACE="([^"]+)">(.*)<\/FONT>[ ]*\z/i)
        {
        $node_label = $2; $font_face = $1;
        }
      # XXX TODO if not, allow inline font changes
      $node_label =~ s/<FONT[^>]+>(.*)<\/FONT>/$1/ig;

      my $node_name = $base_name . '.' . $idx;

      # if it doesn't exist, add it, otherwise retrieve node object to $node

      my $node = $graph->node($node_name);
      if (!defined $node)
	{
	# create node object from the correct class
	$node = $class->new($node_name);
        $graph->add_node($node);
	$node->set_attributes($raw_attributes);
        $node->{autosplit_portname} = $idx;		# some sensible default
	}

      # apply the default attributes from the table
      $node->set_attributes($table_attr);
      # if found a global font attribute, override the font attribute with it
      $node->set_attribute('font',$font_face) if defined $font_face;

      # parse the attributes and apply them to the node
      $self->_html_per_node( $self->_parse_html_attributes($attr_txt,$qr,'td'), $node );

#     print STDERR "# Created $node_name\n";
 
      $node->{autosplit_label} = $node_label;
      $node->{autosplit_basename} = $base_name;

      push @rc, $node;
      if (@rc == 1)
        {
        # for correct as_txt output
        $node->{autosplit} = $org_label;
        $node->{autosplit} =~ s/\s+\z//;	# strip trailing spaces
        $node->{autosplit} =~ s/^\s+//;		# strip leading spaces
        $first_in_row = $node;
        }
      else
        {
        # second, third etc. get previous as origin
        my ($sx,$sy) = (1,0);
        my $origin = $rc[-2];
	# the first node in one row is relative to the first node in the
	# prev row
	if ($first == 1)
          {
          ($sx,$sy) = (0,1); $origin = $first_in_row;
          $first_in_row = $node;
	  $first = 0;
          } 
        $node->relative_to($origin,$sx,$sy);
	# suppress as_txt output for other parts
	$node->{autosplit} = undef;
        }	
      # nec. for border-collapse
      $node->{autosplit_xy} = "$x,$y";

      $idx++;						# next node ID
      $x++;
      }

    # next row
    $y++;
    }

  # return created nodes
  @rc;
  }

#############################################################################

sub _parser_cleanup
  {
  # After initial parsing, do cleanup, e.g. autosplit nodes with shape record,
  # parse HTML-like labels, re-connect edges to the parts etc.
  my ($self) = @_;

  print STDERR "# Parser cleanup pass\n" if $self->{debug};

  my $g = $self->{_graph};
  my @nodes = $g->nodes();

  # For all nodes that have a shape of "record", break down their label into
  # parts and create these as autosplit nodes.
  # For all nodes that have a label starting with "<", parse it as HTML.

  # keep a record of all nodes to be deleted later:
  my $delete = {};

  my $html_regexps = $self->_match_html_regexps();
  my $graph_flow = $g->attribute('flow');
  for my $n (@nodes)
    {
    my $label = $n->label(1);
    # we can get away with a direct lookup, since DOT does not have classes
    my $shape = $n->{att}->{shape} || 'rect';

    if ($shape ne 'record' && $label =~ /^<\s*<.*>\z/)
      {
      print STDERR "# HTML-like label found: $label\n" if $self->{debug};
      my @nodes = $self->_parse_html($n, $html_regexps);
      # remove the temp. and spurious node
      $delete->{$n->{name}} = undef;
      my @edges = $n->edges();
      # reconnect the found edges to the new autosplit parts
      for my $e (@edges)
        {
        # XXX TODO: connect to better suited parts based on flow?
        $e->start_at($nodes[0]) if ($e->{from} == $n);
        $e->end_at($nodes[0]) if ($e->{to} == $n);
        }
      $g->del_node($n);
      next;
      }

    if ($shape eq 'record' && $label =~ /\|/)
      {
      my $att = {};
      # create basename only when node name differes from label
      $att->{basename} = $n->{name};
      if ($n->{name} ne $label)
	{
	$att->{basename} = $n->{name};
	}
      # XXX TODO: autosplit needs to handle nesting like "{}".

      # Replace "{ ... | ... |  ... }" with "...|| ... || ...." as a cheat
      # to fix some common cases
      if ($label =~ /^\s*\{[^\{\}]+\}\s*\z/)
	{
        $label =~ s/[\{\}]//g;	# {..|..} => ..|..
        # if flow up/down:    {A||B} => "[ A||  ||  B ]"
        $label =~ s/\|/\|\|  /g	# ..|.. => ..||  ..
	  if ($graph_flow =~ /^(east|west)/);
        # if flow left/right: {A||B} => "[ A|  |B ]"
        $label =~ s/\|\|/\|  \|/g	# ..|.. => ..|  |..
	  if ($graph_flow =~ /^(north|south)/);
	}
      my @rc = $self->_autosplit_node($g, $label, $att, 0 );
      my $group = $n->group();
      $n->del_attribute('label');

      my $qr_clean = $self->{_qr_part_clean};
      # clean the base name of ports:
      #  "<f1> test | <f2> test" => "test|test"
      $rc[0]->{autosplit} =~ s/(^|\|)$qr_clean/$1/g;
      $rc[0]->{att}->{basename} =~ s/(^|\|)$qr_clean/$1/g;
      $rc[0]->{autosplit} =~ s/^\s*//;
      $rc[0]->{att}->{basename} =~ s/^\s*//;
      # '| |' => '|  |' to avoid empty parts via as_txt() => as_ascii()
      $rc[0]->{autosplit} =~ s/\|\s\|/\|  \|/g;
      $rc[0]->{att}->{basename} =~ s/\|\s\|/\|  \|/g;
      $rc[0]->{autosplit} =~ s/\|\s\|/\|  \|/g;
      $rc[0]->{att}->{basename} =~ s/\|\s\|/\|  \|/g;
      delete $rc[0]->{att}->{basename} if $rc[0]->{att}->{basename} eq $rc[0]->{autosplit};

      for my $n1 (@rc)
	{
	$n1->add_to_group($group) if $group;
	$n1->set_attributes($n->{att});
	# remove the temp. "shape=record"
	$n1->del_attribute('shape');
	}

      # If the helper node has edges, reconnect them to the first
      # part of the autosplit node (dot seems to render them arbitrarily
      # on the autosplit node):

      for my $e (values %{$n->{edges}})
	{
        $e->start_at($rc[0]) if $e->{from} == $n;
        $e->end_at($rc[0]) if $e->{to} == $n;
	}
      # remove the temp. and spurious node
      $delete->{$n->{name}} = undef;
      $g->del_node($n);
      }
    }

  # During parsing, "bonn:f1" -> "berlin:f2" results in "bonn:f1" and
  # "berlin:f2" as nodes, plus an edge connecting them

  # We find all of these nodes, move the edges to the freshly created
  # autosplit parts above, then delete the superflous temporary nodes.

  # if we looked up "Bonn:f1", remember it here to save time:
  my $node_cache = {};

  my @edges = $g->edges();
  @nodes = $g->nodes();		# get a fresh list of nodes after split
  for my $e (@edges)
    {
    # do this for both the "from" and "to" side of the edge:
    for my $side ('from','to')
      {
      my $n = $e->{$side};
      next unless defined $n->{_graphviz_portlet};

      my $port = $n->{_graphviz_portlet};
      my $base = $n->{_graphviz_basename};

      my $compass = '';
      if ($port =~ s/:(n|ne|e|se|s|sw|w|nw)\z//)
	{
        $compass = $1;
	}
      # "Bonn:w" is port "w", and only "west" when that port doesnt exist	

      # look it up in the cache first
      my $node = $node_cache->{"$base:$port"};

      my $p = undef;
      if (!defined $node)
	{
	# go thru all nodes and for see if we find one with the right port name
	for my $na (@nodes)
	  {
	  next unless exists $na->{autosplit_portname} && exists $na->{autosplit_basename};
	  next unless $na->{autosplit_basename} eq $base;
	  next unless $na->{autosplit_portname} eq $port;
	  # cache result
          $node_cache->{"$base:$port"} = $na;
          $node = $na;
          $p = $port_remap->{substr($compass,0,1)} if $compass;		# ne => n => north
	  }
	}

      if (!defined $node)
	{
	# Still not defined?
        # port looks like a compass node?
	if ($port =~ /^(n|ne|e|se|s|sw|w|nw)\z/)
	  {
	  # get the first node matching the base
	  for my $na (@nodes)
	    {
	    #print STDERR "# evaluating $na ($na->{name} $na->{autosplit_basename}) ($base)\n";
	    next unless exists $na->{autosplit_basename};
	    next unless $na->{autosplit_basename} eq $base;
	    # cache result
	    $node_cache->{"$base:$port"} = $na;
	    $node = $na;
	    }
	  if (!defined $node)
	    {
	    return $self->error("Cannot find autosplit node for $base:$port on edge $e->{id}");
	    }
          $p = $port_remap->{substr($port,0,1)};		# ne => n => north
	  }
	else
	  {
	  # uhoh...
	  return $self->error("Cannot find autosplit node for $base:$port on edge $e->{id}");
	  }
 	}

      if ($side eq 'from')
	{
        $delete->{$e->{from}->{name}} = undef;
  	print STDERR "# Setting new edge start point to $node->{name}\n" if $self->{debug};
	$e->start_at($node);
  	print STDERR "# Setting new edge end point to start at $p\n" if $self->{debug} && $p;
	$e->set_attribute('start', $p) if $p;
	}
      else
	{
        $delete->{$e->{to}->{name}} = undef;
  	print STDERR "# Setting new edge end point to $node->{name}\n" if $self->{debug};
	$e->end_at($node);
  	print STDERR "# Setting new edge end point to end at $p\n" if $self->{debug} && $p;
	$e->set_attribute('end', $p) if $p;
	}

      } # end for side "from" and "to"
    # we have reconnected this edge
    }

  # after reconnecting all edges, we can delete temp. nodes: 
  for my $n (@nodes)
    {
    next unless exists $n->{_graphviz_portlet};
    # "c:w" => "c"
    my $name = $n->{name}; $name =~ s/:.*?\z//;
    # add "c" unless we should delete the base node (this deletes record
    # and autosplit nodes, but keeps loners like "c:w" around as "c":
    $g->add_node($name) unless exists $delete->{$name};
    # delete "c:w"
    $g->del_node($n); 
    }

  # if the graph doesn't have a title, set the graph name as title
  $g->set_attribute('title', $self->{_graphviz_graph_name})
    unless defined $g->raw_attribute('title');
  
  # cleanup if there are no groups
  if ($g->groups() == 0)
    {
    $g->del_attribute('group', 'align');
    $g->del_attribute('group', 'fill');
    }
  $g->{_warn_on_unknown_attributes} = 0;	# reset to die again

  $self;
  }

1;
__END__

=head1 NAME

Graph::Easy::Parser::Graphviz - Parse Graphviz text into Graph::Easy

=head1 SYNOPSIS

        # creating a graph from a textual description

        use Graph::Easy::Parser::Graphviz;
        my $parser = Graph::Easy::Parser::Graphviz->new();

        my $graph = $parser->from_text(
                "digraph MyGraph { \n" .
	 	"	Bonn -> \"Berlin\" \n }"
        );
        print $graph->as_ascii();

	print $parser->from_file('mygraph.dot')->as_ascii();

=head1 DESCRIPTION

C<Graph::Easy::Parser::Graphviz> parses the text format from the DOT language
use by Graphviz and constructs a C<Graph::Easy> object from it.

The resulting object can than be used to layout and output the graph
in various formats.

Please see the Graphviz manual for a full description of the syntax
rules of the DOT language.

=head2 Output

The output will be a L<Graph::Easy|Graph::Easy> object (unless overrriden
with C<use_class()>), see the documentation for Graph::Easy what you can do
with it.

=head2 Attributes

Attributes will be remapped to the proper Graph::Easy attribute names and
values, as much as possible.

Anything else will be converted to custom attributes starting with "x-dot-".
So "ranksep: 2" will become "x-dot-ranksep: 2".

=head1 METHODS

C<Graph::Easy::Parser::Graphviz> supports the same methods
as its parent class C<Graph::Easy::Parser>:

=head2 new()

	use Graph::Easy::Parser::Graphviz;
	my $parser = Graph::Easy::Parser::Graphviz->new();

Creates a new parser object. There are two valid parameters:

	debug
	fatal_errors

Both take either a false or a true value.

	my $parser = Graph::Easy::Parser::Graphviz->new( debug => 1 );
	$parser->from_text('digraph G { A -> B }');

=head2 reset()

	$parser->reset();

Reset the status of the parser, clear errors etc. Automatically called
when you call any of the C<from_XXX()> methods below.

=head2 use_class()

	$parser->use_class('node', 'Graph::Easy::MyNode');

Override the class to be used to constructs objects while parsing.

See L<Graph::Easy::Parser> for further information.

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

The second calling style will create a temporary parser object,
parse the file and return the resulting C<Graph::Easy> object.

Returns undef for error, you can find out what the error was
with L<error()> when using the first calling style.

=head2 error()

	my $error = $parser->error();

Returns the last error, or the empty string if no error occured.

=head2 parse_error()

	$parser->parse_error( $msg_nr, @params);

Sets an error message from a message number and replaces embedded
templates like C<##param1##> with the passed parameters.

=head1 CAVEATS

The parser has problems with the following things:

=over 12

=item encoding and charset attribute

The parser assumes the input to be C<utf-8>. Input files in <code>Latin1</code>
are not parsed properly, even when they have the charset attribute set.

=item shape=record

Nodes with shape record are only parsed properly when the label does not
contain groups delimited by "{" and "}", so the following is parsed
wrongly:

	node1 [ shape=record, label="A|{B|C}" ]

=item default shape

The default shape for a node is 'rect', opposed to 'circle' as dot renders
nodes.

=item attributes

Some attributes are B<not> remapped properly to what Graph::Easy expects, thus
losing information, either because Graph::Easy doesn't support this feature
yet, or because the mapping is incomplete.

Some attributes meant only for nodes or edges etc. might be incorrectly applied
to other objects, resulting in unnec. warnings while parsing.

Attributes not valid in the original DOT language are silently ignored by dot,
but result in a warning when parsing under Graph::Easy. This helps catching all
these pesky misspellings, but it's not yet possible to disable these warnings.

=item comments

Comments written in the source code itself are discarded. If you want to have
comments on the graph, clusters, nodes or edges, use the attribute C<comment>.
These are correctly read in and stored, and then output into the different
formats, too.

=back

=head1 EXPORT

Exports nothing.

=head1 SEE ALSO

L<Graph::Easy>, L<Graph::Reader::Dot>.

=head1 AUTHOR

Copyright (C) 2005 - 2007 by Tels L<http://bloodgate.com>

See the LICENSE file for information.

=cut
