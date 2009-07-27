#############################################################################
# Define and check attributes for a Graph::Easy textual description.
#
#############################################################################

package Graph::Easy::Attributes;

$VERSION = '0.32';

package Graph::Easy;

use strict;
use utf8;		# for examples like "Fähre"

# to make it easier to remember the attribute names:
my $att_aliases = {
  'auto-label' => 'autolabel',
  'auto-link' => 'autolink',
  'auto-title' => 'autotitle',
  'arrow-style' => 'arrowstyle',
  'arrow-shape' => 'arrowshape',
  'border-color' => 'bordercolor',
  'border-style' => 'borderstyle',
  'border-width' => 'borderwidth',
  'font-size' => 'fontsize',
  'label-color' => 'labelcolor',
  'label-pos' => 'labelpos',
  'text-style' => 'textstyle',
  'text-wrap' => 'textwrap',
  'point-style' => 'pointstyle',
  'point-shape' => 'pointshape',
  };

sub _att_aliases { $att_aliases; }

#############################################################################
# color handling

# The W3C/SVG/CSS color scheme

my $color_names = {
  w3c =>
  {
  inherit		=> 'inherit',
  aliceblue             => '#f0f8ff',
  antiquewhite          => '#faebd7',
  aquamarine            => '#7fffd4',
  aqua                  => '#00ffff',
  azure                 => '#f0ffff',
  beige                 => '#f5f5dc',
  bisque                => '#ffe4c4',
  black                 => '#000000',
  blanchedalmond        => '#ffebcd',
  blue                  => '#0000ff',
  blueviolet            => '#8a2be2',
  brown                 => '#a52a2a',
  burlywood             => '#deb887',
  cadetblue             => '#5f9ea0',
  chartreuse            => '#7fff00',
  chocolate             => '#d2691e',
  coral                 => '#ff7f50',
  cornflowerblue        => '#6495ed',
  cornsilk              => '#fff8dc',
  crimson               => '#dc143c',
  cyan                  => '#00ffff',
  darkblue              => '#00008b',
  darkcyan              => '#008b8b',
  darkgoldenrod         => '#b8860b',
  darkgray              => '#a9a9a9',
  darkgreen             => '#006400',
  darkgrey              => '#a9a9a9',
  darkkhaki             => '#bdb76b',
  darkmagenta           => '#8b008b',
  darkolivegreen        => '#556b2f',
  darkorange            => '#ff8c00',
  darkorchid            => '#9932cc',
  darkred               => '#8b0000',
  darksalmon            => '#e9967a',
  darkseagreen          => '#8fbc8f',
  darkslateblue         => '#483d8b',
  darkslategray         => '#2f4f4f',
  darkslategrey         => '#2f4f4f',
  darkturquoise         => '#00ced1',
  darkviolet            => '#9400d3',
  deeppink              => '#ff1493',
  deepskyblue           => '#00bfff',
  dimgray               => '#696969',
  dodgerblue            => '#1e90ff',
  firebrick             => '#b22222',
  floralwhite           => '#fffaf0',
  forestgreen           => '#228b22',
  fuchsia               => '#ff00ff',
  gainsboro             => '#dcdcdc',
  ghostwhite            => '#f8f8ff',
  goldenrod             => '#daa520',
  gold                  => '#ffd700',
  gray                  => '#808080',
  green                 => '#008000',
  greenyellow           => '#adff2f',
  grey                  => '#808080',
  honeydew              => '#f0fff0',
  hotpink               => '#ff69b4',
  indianred             => '#cd5c5c',
  indigo                => '#4b0082',
  ivory                 => '#fffff0',
  khaki                 => '#f0e68c',
  lavenderblush         => '#fff0f5',
  lavender              => '#e6e6fa',
  lawngreen             => '#7cfc00',
  lemonchiffon          => '#fffacd',
  lightblue             => '#add8e6',
  lightcoral            => '#f08080',
  lightcyan             => '#e0ffff',
  lightgoldenrodyellow  => '#fafad2',
  lightgray             => '#d3d3d3',
  lightgreen            => '#90ee90',
  lightgrey             => '#d3d3d3',
  lightpink             => '#ffb6c1',
  lightsalmon           => '#ffa07a',
  lightseagreen         => '#20b2aa',
  lightskyblue          => '#87cefa',
  lightslategray        => '#778899',
  lightslategrey        => '#778899',
  lightsteelblue        => '#b0c4de',
  lightyellow           => '#ffffe0',
  limegreen             => '#32cd32',
  lime			=> '#00ff00',
  linen                 => '#faf0e6',
  magenta               => '#ff00ff',
  maroon                => '#800000',
  mediumaquamarine      => '#66cdaa',
  mediumblue            => '#0000cd',
  mediumorchid          => '#ba55d3',
  mediumpurple          => '#9370db',
  mediumseagreen        => '#3cb371',
  mediumslateblue       => '#7b68ee',
  mediumspringgreen     => '#00fa9a',
  mediumturquoise       => '#48d1cc',
  mediumvioletred       => '#c71585',
  midnightblue          => '#191970',
  mintcream             => '#f5fffa',
  mistyrose             => '#ffe4e1',
  moccasin              => '#ffe4b5',
  navajowhite           => '#ffdead',
  navy                  => '#000080',
  oldlace               => '#fdf5e6',
  olivedrab             => '#6b8e23',
  olive                 => '#808000',
  orangered             => '#ff4500',
  orange                => '#ffa500',
  orchid                => '#da70d6',
  palegoldenrod         => '#eee8aa',
  palegreen             => '#98fb98',
  paleturquoise         => '#afeeee',
  palevioletred         => '#db7093',
  papayawhip            => '#ffefd5',
  peachpuff             => '#ffdab9',
  peru                  => '#cd853f',
  pink                  => '#ffc0cb',
  plum                  => '#dda0dd',
  powderblue            => '#b0e0e6',
  purple                => '#800080',
  red                   => '#ff0000',
  rosybrown             => '#bc8f8f',
  royalblue             => '#4169e1',
  saddlebrown           => '#8b4513',
  salmon                => '#fa8072',
  sandybrown            => '#f4a460',
  seagreen              => '#2e8b57',
  seashell              => '#fff5ee',
  sienna                => '#a0522d',
  silver                => '#c0c0c0',
  skyblue               => '#87ceeb',
  slateblue             => '#6a5acd',
  slategray             => '#708090',
  slategrey             => '#708090',
  snow                  => '#fffafa',
  springgreen           => '#00ff7f',
  steelblue             => '#4682b4',
  tan                   => '#d2b48c',
  teal                  => '#008080',
  thistle               => '#d8bfd8',
  tomato                => '#ff6347',
  turquoise             => '#40e0d0',
  violet                => '#ee82ee',
  wheat                 => '#f5deb3',
  white                 => '#ffffff',
  whitesmoke            => '#f5f5f5',
  yellowgreen           => '#9acd32',
  yellow                => '#ffff00',
  },

  x11 => {
    inherit		=> 'inherit',
    aliceblue		=> '#f0f8ff',
    antiquewhite	=> '#faebd7',
    antiquewhite1	=> '#ffefdb',
    antiquewhite2	=> '#eedfcc',
    antiquewhite3	=> '#cdc0b0',
    antiquewhite4	=> '#8b8378',
    aquamarine		=> '#7fffd4',
    aquamarine1		=> '#7fffd4',
    aquamarine2		=> '#76eec6',
    aquamarine3		=> '#66cdaa',
    aquamarine4		=> '#458b74',
    azure		=> '#f0ffff',
    azure1		=> '#f0ffff',
    azure2		=> '#e0eeee',
    azure3		=> '#c1cdcd',
    azure4		=> '#838b8b',
    beige		=> '#f5f5dc',
    bisque		=> '#ffe4c4',
    bisque1		=> '#ffe4c4',
    bisque2		=> '#eed5b7',
    bisque3		=> '#cdb79e',
    bisque4		=> '#8b7d6b',
    black		=> '#000000',
    blanchedalmond	=> '#ffebcd',
    blue		=> '#0000ff',
    blue1		=> '#0000ff',
    blue2		=> '#0000ee',
    blue3		=> '#0000cd',
    blue4		=> '#00008b',
    blueviolet		=> '#8a2be2',
    brown		=> '#a52a2a',
    brown1		=> '#ff4040',
    brown2		=> '#ee3b3b',
    brown3		=> '#cd3333',
    brown4		=> '#8b2323',
    burlywood		=> '#deb887',
    burlywood1		=> '#ffd39b',
    burlywood2		=> '#eec591',
    burlywood3		=> '#cdaa7d',
    burlywood4		=> '#8b7355',
    cadetblue		=> '#5f9ea0',
    cadetblue1		=> '#98f5ff',
    cadetblue2		=> '#8ee5ee',
    cadetblue3		=> '#7ac5cd',
    cadetblue4		=> '#53868b',
    chartreuse		=> '#7fff00',
    chartreuse1		=> '#7fff00',
    chartreuse2		=> '#76ee00',
    chartreuse3		=> '#66cd00',
    chartreuse4		=> '#458b00',
    chocolate		=> '#d2691e',
    chocolate1		=> '#ff7f24',
    chocolate2		=> '#ee7621',
    chocolate3		=> '#cd661d',
    chocolate4		=> '#8b4513',
    coral		=> '#ff7f50',
    coral1		=> '#ff7256',
    coral2		=> '#ee6a50',
    coral3		=> '#cd5b45',
    coral4		=> '#8b3e2f',
    cornflowerblue	=> '#6495ed',
    cornsilk		=> '#fff8dc',
    cornsilk1		=> '#fff8dc',
    cornsilk2		=> '#eee8cd',
    cornsilk3		=> '#cdc8b1',
    cornsilk4		=> '#8b8878',
    crimson		=> '#dc143c',
    cyan		=> '#00ffff',
    cyan1		=> '#00ffff',
    cyan2		=> '#00eeee',
    cyan3		=> '#00cdcd',
    cyan4		=> '#008b8b',
    darkgoldenrod	=> '#b8860b',
    darkgoldenrod1	=> '#ffb90f',
    darkgoldenrod2	=> '#eead0e',
    darkgoldenrod3	=> '#cd950c',
    darkgoldenrod4	=> '#8b6508',
    darkgreen		=> '#006400',
    darkkhaki		=> '#bdb76b',
    darkolivegreen	=> '#556b2f',
    darkolivegreen1	=> '#caff70',
    darkolivegreen2	=> '#bcee68',
    darkolivegreen3	=> '#a2cd5a',
    darkolivegreen4	=> '#6e8b3d',
    darkorange		=> '#ff8c00',
    darkorange1		=> '#ff7f00',
    darkorange2		=> '#ee7600',
    darkorange3		=> '#cd6600',
    darkorange4		=> '#8b4500',
    darkorchid		=> '#9932cc',
    darkorchid1		=> '#bf3eff',
    darkorchid2		=> '#b23aee',
    darkorchid3		=> '#9a32cd',
    darkorchid4		=> '#68228b',
    darksalmon		=> '#e9967a',
    darkseagreen	=> '#8fbc8f',
    darkseagreen1	=> '#c1ffc1',
    darkseagreen2	=> '#b4eeb4',
    darkseagreen3	=> '#9bcd9b',
    darkseagreen4	=> '#698b69',
    darkslateblue	=> '#483d8b',
    darkslategray	=> '#2f4f4f',
    darkslategray1	=> '#97ffff',
    darkslategray2	=> '#8deeee',
    darkslategray3	=> '#79cdcd',
    darkslategray4	=> '#528b8b',
    darkslategrey	=> '#2f4f4f',
    darkturquoise	=> '#00ced1',
    darkviolet		=> '#9400d3',
    deeppink		=> '#ff1493',
    deeppink1		=> '#ff1493',
    deeppink2		=> '#ee1289',
    deeppink3		=> '#cd1076',
    deeppink4		=> '#8b0a50',
    deepskyblue		=> '#00bfff',
    deepskyblue1	=> '#00bfff',
    deepskyblue2	=> '#00b2ee',
    deepskyblue3	=> '#009acd',
    deepskyblue4	=> '#00688b',
    dimgray		=> '#696969',
    dimgrey		=> '#696969',
    dodgerblue		=> '#1e90ff',
    dodgerblue1		=> '#1e90ff',
    dodgerblue2		=> '#1c86ee',
    dodgerblue3		=> '#1874cd',
    dodgerblue4		=> '#104e8b',
    firebrick		=> '#b22222',
    firebrick1		=> '#ff3030',
    firebrick2		=> '#ee2c2c',
    firebrick3		=> '#cd2626',
    firebrick4		=> '#8b1a1a',
    floralwhite		=> '#fffaf0',
    forestgreen		=> '#228b22',
    gainsboro		=> '#dcdcdc',
    ghostwhite		=> '#f8f8ff',
    gold		=> '#ffd700',
    gold1		=> '#ffd700',
    gold2		=> '#eec900',
    gold3		=> '#cdad00',
    gold4		=> '#8b7500',
    goldenrod		=> '#daa520',
    goldenrod1		=> '#ffc125',
    goldenrod2		=> '#eeb422',
    goldenrod3		=> '#cd9b1d',
    goldenrod4		=> '#8b6914',
    gray		=> '#c0c0c0',
    gray0		=> '#000000',
    gray1		=> '#030303',
    gray2		=> '#050505',
    gray3		=> '#080808',
    gray4		=> '#0a0a0a',
    gray5		=> '#0d0d0d',
    gray6		=> '#0f0f0f',
    gray7		=> '#121212',
    gray8		=> '#141414',
    gray9		=> '#171717',
    gray10		=> '#1a1a1a',
    gray11		=> '#1c1c1c',
    gray12		=> '#1f1f1f',
    gray13		=> '#212121',
    gray14		=> '#242424',
    gray15		=> '#262626',
    gray16		=> '#292929',
    gray17		=> '#2b2b2b',
    gray18		=> '#2e2e2e',
    gray19		=> '#303030',
    gray20		=> '#333333',
    gray21		=> '#363636',
    gray22		=> '#383838',
    gray23		=> '#3b3b3b',
    gray24		=> '#3d3d3d',
    gray25		=> '#404040',
    gray26		=> '#424242',
    gray27		=> '#454545',
    gray28		=> '#474747',
    gray29		=> '#4a4a4a',
    gray30		=> '#4d4d4d',
    gray31		=> '#4f4f4f',
    gray32		=> '#525252',
    gray33		=> '#545454',
    gray34		=> '#575757',
    gray35		=> '#595959',
    gray36		=> '#5c5c5c',
    gray37		=> '#5e5e5e',
    gray38		=> '#616161',
    gray39		=> '#636363',
    gray40		=> '#666666',
    gray41		=> '#696969',
    gray42		=> '#6b6b6b',
    gray43		=> '#6e6e6e',
    gray44		=> '#707070',
    gray45		=> '#737373',
    gray46		=> '#757575',
    gray47		=> '#787878',
    gray48		=> '#7a7a7a',
    gray49		=> '#7d7d7d',
    gray50		=> '#7f7f7f',
    gray51		=> '#828282',
    gray52		=> '#858585',
    gray53		=> '#878787',
    gray54		=> '#8a8a8a',
    gray55		=> '#8c8c8c',
    gray56		=> '#8f8f8f',
    gray57		=> '#919191',
    gray58		=> '#949494',
    gray59		=> '#969696',
    gray60		=> '#999999',
    gray61		=> '#9c9c9c',
    gray62		=> '#9e9e9e',
    gray63		=> '#a1a1a1',
    gray64		=> '#a3a3a3',
    gray65		=> '#a6a6a6',
    gray66		=> '#a8a8a8',
    gray67		=> '#ababab',
    gray68		=> '#adadad',
    gray69		=> '#b0b0b0',
    gray70		=> '#b3b3b3',
    gray71		=> '#b5b5b5',
    gray72		=> '#b8b8b8',
    gray73		=> '#bababa',
    gray74		=> '#bdbdbd',
    gray75		=> '#bfbfbf',
    gray76		=> '#c2c2c2',
    gray77		=> '#c4c4c4',
    gray78		=> '#c7c7c7',
    gray79		=> '#c9c9c9',
    gray80		=> '#cccccc',
    gray81		=> '#cfcfcf',
    gray82		=> '#d1d1d1',
    gray83		=> '#d4d4d4',
    gray84		=> '#d6d6d6',
    gray85		=> '#d9d9d9',
    gray86		=> '#dbdbdb',
    gray87		=> '#dedede',
    gray88		=> '#e0e0e0',
    gray89		=> '#e3e3e3',
    gray90		=> '#e5e5e5',
    gray91		=> '#e8e8e8',
    gray92		=> '#ebebeb',
    gray93		=> '#ededed',
    gray94		=> '#f0f0f0',
    gray95		=> '#f2f2f2',
    gray96		=> '#f5f5f5',
    gray97		=> '#f7f7f7',
    gray98		=> '#fafafa',
    gray99		=> '#fcfcfc',
    gray100		=> '#ffffff',
    green		=> '#00ff00',
    green1		=> '#00ff00',
    green2		=> '#00ee00',
    green3		=> '#00cd00',
    green4		=> '#008b00',
    greenyellow		=> '#adff2f',
    grey		=> '#c0c0c0',
    grey0		=> '#000000',
    grey1		=> '#030303',
    grey2		=> '#050505',
    grey3		=> '#080808',
    grey4		=> '#0a0a0a',
    grey5		=> '#0d0d0d',
    grey6		=> '#0f0f0f',
    grey7		=> '#121212',
    grey8		=> '#141414',
    grey9		=> '#171717',
    grey10		=> '#1a1a1a',
    grey11		=> '#1c1c1c',
    grey12		=> '#1f1f1f',
    grey13		=> '#212121',
    grey14		=> '#242424',
    grey15		=> '#262626',
    grey16		=> '#292929',
    grey17		=> '#2b2b2b',
    grey18		=> '#2e2e2e',
    grey19		=> '#303030',
    grey20		=> '#333333',
    grey21		=> '#363636',
    grey22		=> '#383838',
    grey23		=> '#3b3b3b',
    grey24		=> '#3d3d3d',
    grey25		=> '#404040',
    grey26		=> '#424242',
    grey27		=> '#454545',
    grey28		=> '#474747',
    grey29		=> '#4a4a4a',
    grey30		=> '#4d4d4d',
    grey31		=> '#4f4f4f',
    grey32		=> '#525252',
    grey33		=> '#545454',
    grey34		=> '#575757',
    grey35		=> '#595959',
    grey36		=> '#5c5c5c',
    grey37		=> '#5e5e5e',
    grey38		=> '#616161',
    grey39		=> '#636363',
    grey40		=> '#666666',
    grey41		=> '#696969',
    grey42		=> '#6b6b6b',
    grey43		=> '#6e6e6e',
    grey44		=> '#707070',
    grey45		=> '#737373',
    grey46		=> '#757575',
    grey47		=> '#787878',
    grey48		=> '#7a7a7a',
    grey49		=> '#7d7d7d',
    grey50		=> '#7f7f7f',
    grey51		=> '#828282',
    grey52		=> '#858585',
    grey53		=> '#878787',
    grey54		=> '#8a8a8a',
    grey55		=> '#8c8c8c',
    grey56		=> '#8f8f8f',
    grey57		=> '#919191',
    grey58		=> '#949494',
    grey59		=> '#969696',
    grey60		=> '#999999',
    grey61		=> '#9c9c9c',
    grey62		=> '#9e9e9e',
    grey63		=> '#a1a1a1',
    grey64		=> '#a3a3a3',
    grey65		=> '#a6a6a6',
    grey66		=> '#a8a8a8',
    grey67		=> '#ababab',
    grey68		=> '#adadad',
    grey69		=> '#b0b0b0',
    grey70		=> '#b3b3b3',
    grey71		=> '#b5b5b5',
    grey72		=> '#b8b8b8',
    grey73		=> '#bababa',
    grey74		=> '#bdbdbd',
    grey75		=> '#bfbfbf',
    grey76		=> '#c2c2c2',
    grey77		=> '#c4c4c4',
    grey78		=> '#c7c7c7',
    grey79		=> '#c9c9c9',
    grey80		=> '#cccccc',
    grey81		=> '#cfcfcf',
    grey82		=> '#d1d1d1',
    grey83		=> '#d4d4d4',
    grey84		=> '#d6d6d6',
    grey85		=> '#d9d9d9',
    grey86		=> '#dbdbdb',
    grey87		=> '#dedede',
    grey88		=> '#e0e0e0',
    grey89		=> '#e3e3e3',
    grey90		=> '#e5e5e5',
    grey91		=> '#e8e8e8',
    grey92		=> '#ebebeb',
    grey93		=> '#ededed',
    grey94		=> '#f0f0f0',
    grey95		=> '#f2f2f2',
    grey96		=> '#f5f5f5',
    grey97		=> '#f7f7f7',
    grey98		=> '#fafafa',
    grey99		=> '#fcfcfc',
    grey100		=> '#ffffff',
    honeydew		=> '#f0fff0',
    honeydew1		=> '#f0fff0',
    honeydew2		=> '#e0eee0',
    honeydew3		=> '#c1cdc1',
    honeydew4		=> '#838b83',
    hotpink		=> '#ff69b4',
    hotpink1		=> '#ff6eb4',
    hotpink2		=> '#ee6aa7',
    hotpink3		=> '#cd6090',
    hotpink4		=> '#8b3a62',
    indianred		=> '#cd5c5c',
    indianred1		=> '#ff6a6a',
    indianred2		=> '#ee6363',
    indianred3		=> '#cd5555',
    indianred4		=> '#8b3a3a',
    indigo		=> '#4b0082',
    ivory		=> '#fffff0',
    ivory1		=> '#fffff0',
    ivory2		=> '#eeeee0',
    ivory3		=> '#cdcdc1',
    ivory4		=> '#8b8b83',
    khaki		=> '#f0e68c',
    khaki1		=> '#fff68f',
    khaki2		=> '#eee685',
    khaki3		=> '#cdc673',
    khaki4		=> '#8b864e',
    lavender		=> '#e6e6fa',
    lavenderblush	=> '#fff0f5',
    lavenderblush1	=> '#fff0f5',
    lavenderblush2	=> '#eee0e5',
    lavenderblush3	=> '#cdc1c5',
    lavenderblush4	=> '#8b8386',
    lawngreen		=> '#7cfc00',
    lemonchiffon	=> '#fffacd',
    lemonchiffon1	=> '#fffacd',
    lemonchiffon2	=> '#eee9bf',
    lemonchiffon3	=> '#cdc9a5',
    lemonchiffon4	=> '#8b8970',
    lightblue		=> '#add8e6',
    lightblue1		=> '#bfefff',
    lightblue2		=> '#b2dfee',
    lightblue3		=> '#9ac0cd',
    lightblue4		=> '#68838b',
    lightcoral		=> '#f08080',
    lightcyan		=> '#e0ffff',
    lightcyan1		=> '#e0ffff',
    lightcyan2		=> '#d1eeee',
    lightcyan3		=> '#b4cdcd',
    lightcyan4		=> '#7a8b8b',
    lightgoldenrod	=> '#eedd82',
    lightgoldenrod1	=> '#ffec8b',
    lightgoldenrod2	=> '#eedc82',
    lightgoldenrod3	=> '#cdbe70',
    lightgoldenrod4	=> '#8b814c',
    lightgoldenrodyellow	=> '#fafad2',
    lightgray		=> '#d3d3d3',
    lightgrey		=> '#d3d3d3',
    lightpink		=> '#ffb6c1',
    lightpink1		=> '#ffaeb9',
    lightpink2		=> '#eea2ad',
    lightpink3		=> '#cd8c95',
    lightpink4		=> '#8b5f65',
    lightsalmon		=> '#ffa07a',
    lightsalmon1	=> '#ffa07a',
    lightsalmon2	=> '#ee9572',
    lightsalmon3	=> '#cd8162',
    lightsalmon4	=> '#8b5742',
    lightseagreen	=> '#20b2aa',
    lightskyblue	=> '#87cefa',
    lightskyblue1	=> '#b0e2ff',
    lightskyblue2	=> '#a4d3ee',
    lightskyblue3	=> '#8db6cd',
    lightskyblue4	=> '#607b8b',
    lightslateblue	=> '#8470ff',
    lightslategray	=> '#778899',
    lightslategrey	=> '#778899',
    lightsteelblue	=> '#b0c4de',
    lightsteelblue1	=> '#cae1ff',
    lightsteelblue2	=> '#bcd2ee',
    lightsteelblue3	=> '#a2b5cd',
    lightsteelblue4	=> '#6e7b8b',
    lightyellow		=> '#ffffe0',
    lightyellow1	=> '#ffffe0',
    lightyellow2	=> '#eeeed1',
    lightyellow3	=> '#cdcdb4',
    lightyellow4	=> '#8b8b7a',
    limegreen		=> '#32cd32',
    linen		=> '#faf0e6',
    magenta		=> '#ff00ff',
    magenta1		=> '#ff00ff',
    magenta2		=> '#ee00ee',
    magenta3		=> '#cd00cd',
    magenta4		=> '#8b008b',
    maroon		=> '#b03060',
    maroon1		=> '#ff34b3',
    maroon2		=> '#ee30a7',
    maroon3		=> '#cd2990',
    maroon4		=> '#8b1c62',
    mediumaquamarine	=> '#66cdaa',
    mediumblue		=> '#0000cd',
    mediumorchid	=> '#ba55d3',
    mediumorchid1	=> '#e066ff',
    mediumorchid2	=> '#d15fee',
    mediumorchid3	=> '#b452cd',
    mediumorchid4	=> '#7a378b',
    mediumpurple	=> '#9370db',
    mediumpurple1	=> '#ab82ff',
    mediumpurple2	=> '#9f79ee',
    mediumpurple3	=> '#8968cd',
    mediumpurple4	=> '#5d478b',
    mediumseagreen	=> '#3cb371',
    mediumslateblue	=> '#7b68ee',
    mediumspringgreen	=> '#00fa9a',
    mediumturquoise	=> '#48d1cc',
    mediumvioletred	=> '#c71585',
    midnightblue	=> '#191970',
    mintcream		=> '#f5fffa',
    mistyrose		=> '#ffe4e1',
    mistyrose1		=> '#ffe4e1',
    mistyrose2		=> '#eed5d2',
    mistyrose3		=> '#cdb7b5',
    mistyrose4		=> '#8b7d7b',
    moccasin		=> '#ffe4b5',
    navajowhite		=> '#ffdead',
    navajowhite1	=> '#ffdead',
    navajowhite2	=> '#eecfa1',
    navajowhite3	=> '#cdb38b',
    navajowhite4	=> '#8b795e',
    navy		=> '#000080',
    navyblue		=> '#000080',
    oldlace		=> '#fdf5e6',
    olivedrab		=> '#6b8e23',
    olivedrab1		=> '#c0ff3e',
    olivedrab2		=> '#b3ee3a',
    olivedrab3		=> '#9acd32',
    olivedrab4		=> '#698b22',
    orange		=> '#ffa500',
    orange1		=> '#ffa500',
    orange2		=> '#ee9a00',
    orange3		=> '#cd8500',
    orange4		=> '#8b5a00',
    orangered		=> '#ff4500',
    orangered1		=> '#ff4500',
    orangered2		=> '#ee4000',
    orangered3		=> '#cd3700',
    orangered4		=> '#8b2500',
    orchid		=> '#da70d6',
    orchid1		=> '#ff83fa',
    orchid2		=> '#ee7ae9',
    orchid3		=> '#cd69c9',
    orchid4		=> '#8b4789',
    palegoldenrod	=> '#eee8aa',
    palegreen		=> '#98fb98',
    palegreen1		=> '#9aff9a',
    palegreen2		=> '#90ee90',
    palegreen3		=> '#7ccd7c',
    palegreen4		=> '#548b54',
    paleturquoise	=> '#afeeee',
    paleturquoise1	=> '#bbffff',
    paleturquoise2	=> '#aeeeee',
    paleturquoise3	=> '#96cdcd',
    paleturquoise4	=> '#668b8b',
    palevioletred	=> '#db7093',
    palevioletred1	=> '#ff82ab',
    palevioletred2	=> '#ee799f',
    palevioletred3	=> '#cd6889',
    palevioletred4	=> '#8b475d',
    papayawhip		=> '#ffefd5',
    peachpuff		=> '#ffdab9',
    peachpuff1		=> '#ffdab9',
    peachpuff2		=> '#eecbad',
    peachpuff3		=> '#cdaf95',
    peachpuff4		=> '#8b7765',
    peru		=> '#cd853f',
    pink		=> '#ffc0cb',
    pink1		=> '#ffb5c5',
    pink2		=> '#eea9b8',
    pink3		=> '#cd919e',
    pink4		=> '#8b636c',
    plum		=> '#dda0dd',
    plum1		=> '#ffbbff',
    plum2		=> '#eeaeee',
    plum3		=> '#cd96cd',
    plum4		=> '#8b668b',
    powderblue		=> '#b0e0e6',
    purple		=> '#a020f0',
    purple1		=> '#9b30ff',
    purple2		=> '#912cee',
    purple3		=> '#7d26cd',
    purple4		=> '#551a8b',
    red 		=> '#ff0000',
    red1		=> '#ff0000',
    red2		=> '#ee0000',
    red3		=> '#cd0000',
    red4		=> '#8b0000',
    rosybrown		=> '#bc8f8f',
    rosybrown1		=> '#ffc1c1',
    rosybrown2		=> '#eeb4b4',
    rosybrown3		=> '#cd9b9b',
    rosybrown4		=> '#8b6969',
    royalblue		=> '#4169e1',
    royalblue1		=> '#4876ff',
    royalblue2		=> '#436eee',
    royalblue3		=> '#3a5fcd',
    royalblue4		=> '#27408b',
    saddlebrown		=> '#8b4513',
    salmon		=> '#fa8072',
    salmon1		=> '#ff8c69',
    salmon2		=> '#ee8262',
    salmon3		=> '#cd7054',
    salmon4		=> '#8b4c39',
    sandybrown		=> '#f4a460',
    seagreen		=> '#2e8b57',
    seagreen1		=> '#54ff9f',
    seagreen2		=> '#4eee94',
    seagreen3		=> '#43cd80',
    seagreen4		=> '#2e8b57',
    seashell		=> '#fff5ee',
    seashell1		=> '#fff5ee',
    seashell2		=> '#eee5de',
    seashell3		=> '#cdc5bf',
    seashell4		=> '#8b8682',
    sienna		=> '#a0522d',
    sienna1		=> '#ff8247',
    sienna2		=> '#ee7942',
    sienna3		=> '#cd6839',
    sienna4		=> '#8b4726',
    skyblue		=> '#87ceeb',
    skyblue1		=> '#87ceff',
    skyblue2		=> '#7ec0ee',
    skyblue3		=> '#6ca6cd',
    skyblue4		=> '#4a708b',
    slateblue		=> '#6a5acd',
    slateblue1		=> '#836fff',
    slateblue2		=> '#7a67ee',
    slateblue3		=> '#6959cd',
    slateblue4		=> '#473c8b',
    slategray		=> '#708090',
    slategray1		=> '#c6e2ff',
    slategray2		=> '#b9d3ee',
    slategray3		=> '#9fb6cd',
    slategray4		=> '#6c7b8b',
    slategrey		=> '#708090',
    snow		=> '#fffafa',
    snow1		=> '#fffafa',
    snow2		=> '#eee9e9',
    snow3		=> '#cdc9c9',
    snow4		=> '#8b8989',
    springgreen		=> '#00ff7f',
    springgreen1	=> '#00ff7f',
    springgreen2	=> '#00ee76',
    springgreen3	=> '#00cd66',
    springgreen4	=> '#008b45',
    steelblue		=> '#4682b4',
    steelblue1		=> '#63b8ff',
    steelblue2		=> '#5cacee',
    steelblue3		=> '#4f94cd',
    steelblue4		=> '#36648b',
    tan 		=> '#d2b48c',
    tan1		=> '#ffa54f',
    tan2		=> '#ee9a49',
    tan3		=> '#cd853f',
    tan4		=> '#8b5a2b',
    thistle		=> '#d8bfd8',
    thistle1		=> '#ffe1ff',
    thistle2		=> '#eed2ee',
    thistle3		=> '#cdb5cd',
    thistle4		=> '#8b7b8b',
    tomato		=> '#ff6347',
    tomato1		=> '#ff6347',
    tomato2		=> '#ee5c42',
    tomato3		=> '#cd4f39',
    tomato4		=> '#8b3626',
    transparent		=> '#fffffe',
    turquoise		=> '#40e0d0',
    turquoise1		=> '#00f5ff',
    turquoise2		=> '#00e5ee',
    turquoise3		=> '#00c5cd',
    turquoise4		=> '#00868b',
    violet		=> '#ee82ee',
    violetred		=> '#d02090',
    violetred1		=> '#ff3e96',
    violetred2		=> '#ee3a8c',
    violetred3		=> '#cd3278',
    violetred4		=> '#8b2252',
    wheat		=> '#f5deb3',
    wheat1		=> '#ffe7ba',
    wheat2		=> '#eed8ae',
    wheat3		=> '#cdba96',
    wheat4		=> '#8b7e66',
    white		=> '#ffffff',
    whitesmoke		=> '#f5f5f5',
    yellow		=> '#ffff00',
    yellow1		=> '#ffff00',
    yellow2		=> '#eeee00',
    yellow3		=> '#cdcd00',
    yellow4		=> '#8b8b00',
    yellowgreen		=> '#9acd32',
    # The following 12 colors exist here so that a "color: 3; colorscheme: accent3"
    # will not report an "unknown color 3" from the Parser. As a side-effect
    # you will not get an error for a plain "color: 3".
    1  => '#a6cee3', 2  => '#1f78b4', 3  => '#b2df8a', 4  => '#33a02c', 
    5  => '#fb9a99', 6  => '#e31a1c', 7  => '#fdbf6f', 8  => '#ff7f00', 
    9  => '#cab2d6', 10  => '#6a3d9a', 11  => '#ffff99', 12  => '#b15928', 
  },
# The following color specifications were developed by:
#  Cynthia Brewer (http://colorbrewer.org/)
# See the LICENSE FILE for the full license that applies to them.

  accent3 => {
    1  => '#7fc97f', 2  => '#beaed4', 3  => '#fdc086', 
  },
  accent4 => {
    1  => '#7fc97f', 2  => '#beaed4', 3  => '#fdc086', 4  => '#ffff99', 
  },
  accent5 => {
    1  => '#7fc97f', 2  => '#beaed4', 3  => '#fdc086', 4  => '#ffff99', 
    5  => '#386cb0', 
  },
  accent6 => {
    1  => '#7fc97f', 2  => '#beaed4', 3  => '#fdc086', 4  => '#ffff99', 
    5  => '#386cb0', 6  => '#f0027f', 
  },
  accent7 => {
    1  => '#7fc97f', 2  => '#beaed4', 3  => '#fdc086', 4  => '#ffff99', 
    5  => '#386cb0', 6  => '#f0027f', 7  => '#bf5b17', 
  },
  accent8 => {
    1  => '#7fc97f', 2  => '#beaed4', 3  => '#fdc086', 4  => '#ffff99', 
    5  => '#386cb0', 6  => '#f0027f', 7  => '#bf5b17', 8  => '#666666', 
  },
  blues3 => {
    1  => '#deebf7', 2  => '#9ecae1', 3  => '#3182bd', 
  },
  blues4 => {
    1  => '#eff3ff', 2  => '#bdd7e7', 3  => '#6baed6', 4  => '#2171b5', 
  },
  blues5 => {
    1  => '#eff3ff', 2  => '#bdd7e7', 3  => '#6baed6', 4  => '#3182bd', 
    5  => '#08519c', 
  },
  blues6 => {
    1  => '#eff3ff', 2  => '#c6dbef', 3  => '#9ecae1', 4  => '#6baed6', 
    5  => '#3182bd', 6  => '#08519c', 
  },
  blues7 => {
    1  => '#eff3ff', 2  => '#c6dbef', 3  => '#9ecae1', 4  => '#6baed6', 
    5  => '#4292c6', 6  => '#2171b5', 7  => '#084594', 
  },
  blues8 => {
    1  => '#f7fbff', 2  => '#deebf7', 3  => '#c6dbef', 4  => '#9ecae1', 
    5  => '#6baed6', 6  => '#4292c6', 7  => '#2171b5', 8  => '#084594', 
  },
  blues9 => {
    1  => '#f7fbff', 2  => '#deebf7', 3  => '#c6dbef', 4  => '#9ecae1', 
    5  => '#6baed6', 6  => '#4292c6', 7  => '#2171b5', 8  => '#08519c', 
    9  => '#08306b', 
  },
  brbg3 => {
    1  => '#d8b365', 2  => '#f5f5f5', 3  => '#5ab4ac', 
  },
  brbg4 => {
    1  => '#a6611a', 2  => '#dfc27d', 3  => '#80cdc1', 4  => '#018571', 
  },
  brbg5 => {
    1  => '#a6611a', 2  => '#dfc27d', 3  => '#f5f5f5', 4  => '#80cdc1', 
    5  => '#018571', 
  },
  brbg6 => {
    1  => '#8c510a', 2  => '#d8b365', 3  => '#f6e8c3', 4  => '#c7eae5', 
    5  => '#5ab4ac', 6  => '#01665e', 
  },
  brbg7 => {
    1  => '#8c510a', 2  => '#d8b365', 3  => '#f6e8c3', 4  => '#f5f5f5', 
    5  => '#c7eae5', 6  => '#5ab4ac', 7  => '#01665e', 
  },
  brbg8 => {
    1  => '#8c510a', 2  => '#bf812d', 3  => '#dfc27d', 4  => '#f6e8c3', 
    5  => '#c7eae5', 6  => '#80cdc1', 7  => '#35978f', 8  => '#01665e', 
  },
  brbg9 => {
    1  => '#8c510a', 2  => '#bf812d', 3  => '#dfc27d', 4  => '#f6e8c3', 
    5  => '#f5f5f5', 6  => '#c7eae5', 7  => '#80cdc1', 8  => '#35978f', 
    9  => '#01665e', 
  },
  brbg10 => {
    1  => '#543005', 2  => '#8c510a', 3  => '#bf812d', 4  => '#dfc27d', 
    5  => '#f6e8c3', 6  => '#c7eae5', 7  => '#80cdc1', 8  => '#35978f', 
    9  => '#01665e', 10  => '#003c30', 
  },
  brbg11 => {
    1  => '#543005', 2  => '#8c510a', 3  => '#bf812d', 4  => '#dfc27d', 
    5  => '#f6e8c3', 6  => '#f5f5f5', 7  => '#c7eae5', 8  => '#80cdc1', 
    9  => '#35978f', 10  => '#01665e', 11  => '#003c30', 
  },
  bugn3 => {
    1  => '#e5f5f9', 2  => '#99d8c9', 3  => '#2ca25f', 
  },
  bugn4 => {
    1  => '#edf8fb', 2  => '#b2e2e2', 3  => '#66c2a4', 4  => '#238b45', 
  },
  bugn5 => {
    1  => '#edf8fb', 2  => '#b2e2e2', 3  => '#66c2a4', 4  => '#2ca25f', 
    5  => '#006d2c', 
  },
  bugn6 => {
    1  => '#edf8fb', 2  => '#ccece6', 3  => '#99d8c9', 4  => '#66c2a4', 
    5  => '#2ca25f', 6  => '#006d2c', 
  },
  bugn7 => {
    1  => '#edf8fb', 2  => '#ccece6', 3  => '#99d8c9', 4  => '#66c2a4', 
    5  => '#41ae76', 6  => '#238b45', 7  => '#005824', 
  },
  bugn8 => {
    1  => '#f7fcfd', 2  => '#e5f5f9', 3  => '#ccece6', 4  => '#99d8c9', 
    5  => '#66c2a4', 6  => '#41ae76', 7  => '#238b45', 8  => '#005824', 
  },
  bugn9 => {
    1  => '#f7fcfd', 2  => '#e5f5f9', 3  => '#ccece6', 4  => '#99d8c9', 
    5  => '#66c2a4', 6  => '#41ae76', 7  => '#238b45', 8  => '#006d2c', 
    9  => '#00441b', 
  },
  bupu3 => {
    1  => '#e0ecf4', 2  => '#9ebcda', 3  => '#8856a7', 
  },
  bupu4 => {
    1  => '#edf8fb', 2  => '#b3cde3', 3  => '#8c96c6', 4  => '#88419d', 
  },
  bupu5 => {
    1  => '#edf8fb', 2  => '#b3cde3', 3  => '#8c96c6', 4  => '#8856a7', 
    5  => '#810f7c', 
  },
  bupu6 => {
    1  => '#edf8fb', 2  => '#bfd3e6', 3  => '#9ebcda', 4  => '#8c96c6', 
    5  => '#8856a7', 6  => '#810f7c', 
  },
  bupu7 => {
    1  => '#edf8fb', 2  => '#bfd3e6', 3  => '#9ebcda', 4  => '#8c96c6', 
    5  => '#8c6bb1', 6  => '#88419d', 7  => '#6e016b', 
  },
  bupu8 => {
    1  => '#f7fcfd', 2  => '#e0ecf4', 3  => '#bfd3e6', 4  => '#9ebcda', 
    5  => '#8c96c6', 6  => '#8c6bb1', 7  => '#88419d', 8  => '#6e016b', 
  },
  bupu9 => {
    1  => '#f7fcfd', 2  => '#e0ecf4', 3  => '#bfd3e6', 4  => '#9ebcda', 
    5  => '#8c96c6', 6  => '#8c6bb1', 7  => '#88419d', 8  => '#810f7c', 
    9  => '#4d004b', 
  },
  dark23 => {
    1  => '#1b9e77', 2  => '#d95f02', 3  => '#7570b3', 
  },
  dark24 => {
    1  => '#1b9e77', 2  => '#d95f02', 3  => '#7570b3', 4  => '#e7298a', 
  },
  dark25 => {
    1  => '#1b9e77', 2  => '#d95f02', 3  => '#7570b3', 4  => '#e7298a', 
    5  => '#66a61e', 
  },
  dark26 => {
    1  => '#1b9e77', 2  => '#d95f02', 3  => '#7570b3', 4  => '#e7298a', 
    5  => '#66a61e', 6  => '#e6ab02', 
  },
  dark27 => {
    1  => '#1b9e77', 2  => '#d95f02', 3  => '#7570b3', 4  => '#e7298a', 
    5  => '#66a61e', 6  => '#e6ab02', 7  => '#a6761d', 
  },
  dark28 => {
    1  => '#1b9e77', 2  => '#d95f02', 3  => '#7570b3', 4  => '#e7298a', 
    5  => '#66a61e', 6  => '#e6ab02', 7  => '#a6761d', 8  => '#666666', 
  },
  gnbu3 => {
    1  => '#e0f3db', 2  => '#a8ddb5', 3  => '#43a2ca', 
  },
  gnbu4 => {
    1  => '#f0f9e8', 2  => '#bae4bc', 3  => '#7bccc4', 4  => '#2b8cbe', 
  },
  gnbu5 => {
    1  => '#f0f9e8', 2  => '#bae4bc', 3  => '#7bccc4', 4  => '#43a2ca', 
    5  => '#0868ac', 
  },
  gnbu6 => {
    1  => '#f0f9e8', 2  => '#ccebc5', 3  => '#a8ddb5', 4  => '#7bccc4', 
    5  => '#43a2ca', 6  => '#0868ac', 
  },
  gnbu7 => {
    1  => '#f0f9e8', 2  => '#ccebc5', 3  => '#a8ddb5', 4  => '#7bccc4', 
    5  => '#4eb3d3', 6  => '#2b8cbe', 7  => '#08589e', 
  },
  gnbu8 => {
    1  => '#f7fcf0', 2  => '#e0f3db', 3  => '#ccebc5', 4  => '#a8ddb5', 
    5  => '#7bccc4', 6  => '#4eb3d3', 7  => '#2b8cbe', 8  => '#08589e', 
  },
  gnbu9 => {
    1  => '#f7fcf0', 2  => '#e0f3db', 3  => '#ccebc5', 4  => '#a8ddb5', 
    5  => '#7bccc4', 6  => '#4eb3d3', 7  => '#2b8cbe', 8  => '#0868ac', 
    9  => '#084081', 
  },
  greens3 => {
    1  => '#e5f5e0', 2  => '#a1d99b', 3  => '#31a354', 
  },
  greens4 => {
    1  => '#edf8e9', 2  => '#bae4b3', 3  => '#74c476', 4  => '#238b45', 
  },
  greens5 => {
    1  => '#edf8e9', 2  => '#bae4b3', 3  => '#74c476', 4  => '#31a354', 
    5  => '#006d2c', 
  },
  greens6 => {
    1  => '#edf8e9', 2  => '#c7e9c0', 3  => '#a1d99b', 4  => '#74c476', 
    5  => '#31a354', 6  => '#006d2c', 
  },
  greens7 => {
    1  => '#edf8e9', 2  => '#c7e9c0', 3  => '#a1d99b', 4  => '#74c476', 
    5  => '#41ab5d', 6  => '#238b45', 7  => '#005a32', 
  },
  greens8 => {
    1  => '#f7fcf5', 2  => '#e5f5e0', 3  => '#c7e9c0', 4  => '#a1d99b', 
    5  => '#74c476', 6  => '#41ab5d', 7  => '#238b45', 8  => '#005a32', 
  },
  greens9 => {
    1  => '#f7fcf5', 2  => '#e5f5e0', 3  => '#c7e9c0', 4  => '#a1d99b', 
    5  => '#74c476', 6  => '#41ab5d', 7  => '#238b45', 8  => '#006d2c', 
    9  => '#00441b', 
  },
  greys3 => {
    1  => '#f0f0f0', 2  => '#bdbdbd', 3  => '#636363', 
  },
  greys4 => {
    1  => '#f7f7f7', 2  => '#cccccc', 3  => '#969696', 4  => '#525252', 
  },
  greys5 => {
    1  => '#f7f7f7', 2  => '#cccccc', 3  => '#969696', 4  => '#636363', 
    5  => '#252525', 
  },
  greys6 => {
    1  => '#f7f7f7', 2  => '#d9d9d9', 3  => '#bdbdbd', 4  => '#969696', 
    5  => '#636363', 6  => '#252525', 
  },
  greys7 => {
    1  => '#f7f7f7', 2  => '#d9d9d9', 3  => '#bdbdbd', 4  => '#969696', 
    5  => '#737373', 6  => '#525252', 7  => '#252525', 
  },
  greys8 => {
    1  => '#ffffff', 2  => '#f0f0f0', 3  => '#d9d9d9', 4  => '#bdbdbd', 
    5  => '#969696', 6  => '#737373', 7  => '#525252', 8  => '#252525', 
  },
  greys9 => {
    1  => '#ffffff', 2  => '#f0f0f0', 3  => '#d9d9d9', 4  => '#bdbdbd', 
    5  => '#969696', 6  => '#737373', 7  => '#525252', 8  => '#252525', 
    9  => '#000000', 
  },
  oranges3 => {
    1  => '#fee6ce', 2  => '#fdae6b', 3  => '#e6550d', 
  },
  oranges4 => {
    1  => '#feedde', 2  => '#fdbe85', 3  => '#fd8d3c', 4  => '#d94701', 
  },
  oranges5 => {
    1  => '#feedde', 2  => '#fdbe85', 3  => '#fd8d3c', 4  => '#e6550d', 
    5  => '#a63603', 
  },
  oranges6 => {
    1  => '#feedde', 2  => '#fdd0a2', 3  => '#fdae6b', 4  => '#fd8d3c', 
    5  => '#e6550d', 6  => '#a63603', 
  },
  oranges7 => {
    1  => '#feedde', 2  => '#fdd0a2', 3  => '#fdae6b', 4  => '#fd8d3c', 
    5  => '#f16913', 6  => '#d94801', 7  => '#8c2d04', 
  },
  oranges8 => {
    1  => '#fff5eb', 2  => '#fee6ce', 3  => '#fdd0a2', 4  => '#fdae6b', 
    5  => '#fd8d3c', 6  => '#f16913', 7  => '#d94801', 8  => '#8c2d04', 
  },
  oranges9 => {
    1  => '#fff5eb', 2  => '#fee6ce', 3  => '#fdd0a2', 4  => '#fdae6b', 
    5  => '#fd8d3c', 6  => '#f16913', 7  => '#d94801', 8  => '#a63603', 
    9  => '#7f2704', 
  },
  orrd3 => {
    1  => '#fee8c8', 2  => '#fdbb84', 3  => '#e34a33', 
  },
  orrd4 => {
    1  => '#fef0d9', 2  => '#fdcc8a', 3  => '#fc8d59', 4  => '#d7301f', 
  },
  orrd5 => {
    1  => '#fef0d9', 2  => '#fdcc8a', 3  => '#fc8d59', 4  => '#e34a33', 
    5  => '#b30000', 
  },
  orrd6 => {
    1  => '#fef0d9', 2  => '#fdd49e', 3  => '#fdbb84', 4  => '#fc8d59', 
    5  => '#e34a33', 6  => '#b30000', 
  },
  orrd7 => {
    1  => '#fef0d9', 2  => '#fdd49e', 3  => '#fdbb84', 4  => '#fc8d59', 
    5  => '#ef6548', 6  => '#d7301f', 7  => '#990000', 
  },
  orrd8 => {
    1  => '#fff7ec', 2  => '#fee8c8', 3  => '#fdd49e', 4  => '#fdbb84', 
    5  => '#fc8d59', 6  => '#ef6548', 7  => '#d7301f', 8  => '#990000', 
  },
  orrd9 => {
    1  => '#fff7ec', 2  => '#fee8c8', 3  => '#fdd49e', 4  => '#fdbb84', 
    5  => '#fc8d59', 6  => '#ef6548', 7  => '#d7301f', 8  => '#b30000', 
    9  => '#7f0000', 
  },
  paired3 => {
    1  => '#a6cee3', 2  => '#1f78b4', 3  => '#b2df8a', 
  },
  paired4 => {
    1  => '#a6cee3', 2  => '#1f78b4', 3  => '#b2df8a', 4  => '#33a02c', 
  },
  paired5 => {
    1  => '#a6cee3', 2  => '#1f78b4', 3  => '#b2df8a', 4  => '#33a02c', 
    5  => '#fb9a99', 
  },
  paired6 => {
    1  => '#a6cee3', 2  => '#1f78b4', 3  => '#b2df8a', 4  => '#33a02c', 
    5  => '#fb9a99', 6  => '#e31a1c', 
  },
  paired7 => {
    1  => '#a6cee3', 2  => '#1f78b4', 3  => '#b2df8a', 4  => '#33a02c', 
    5  => '#fb9a99', 6  => '#e31a1c', 7  => '#fdbf6f', 
  },
  paired8 => {
    1  => '#a6cee3', 2  => '#1f78b4', 3  => '#b2df8a', 4  => '#33a02c', 
    5  => '#fb9a99', 6  => '#e31a1c', 7  => '#fdbf6f', 8  => '#ff7f00', 
  },
  paired9 => {
    1  => '#a6cee3', 2  => '#1f78b4', 3  => '#b2df8a', 4  => '#33a02c', 
    5  => '#fb9a99', 6  => '#e31a1c', 7  => '#fdbf6f', 8  => '#ff7f00', 
    9  => '#cab2d6', 
  },
  paired10 => {
    1  => '#a6cee3', 2  => '#1f78b4', 3  => '#b2df8a', 4  => '#33a02c', 
    5  => '#fb9a99', 6  => '#e31a1c', 7  => '#fdbf6f', 8  => '#ff7f00', 
    9  => '#cab2d6', 10  => '#6a3d9a', 
  },
  paired11 => {
    1  => '#a6cee3', 2  => '#1f78b4', 3  => '#b2df8a', 4  => '#33a02c', 
    5  => '#fb9a99', 6  => '#e31a1c', 7  => '#fdbf6f', 8  => '#ff7f00', 
    9  => '#cab2d6', 10  => '#6a3d9a', 11  => '#ffff99', 
  },
  paired12 => {
    1  => '#a6cee3', 2  => '#1f78b4', 3  => '#b2df8a', 4  => '#33a02c', 
    5  => '#fb9a99', 6  => '#e31a1c', 7  => '#fdbf6f', 8  => '#ff7f00', 
    9  => '#cab2d6', 10  => '#6a3d9a', 11  => '#ffff99', 12  => '#b15928', 
  },
  pastel13 => {
    1  => '#fbb4ae', 2  => '#b3cde3', 3  => '#ccebc5', 
  },
  pastel14 => {
    1  => '#fbb4ae', 2  => '#b3cde3', 3  => '#ccebc5', 4  => '#decbe4', 
  },
  pastel15 => {
    1  => '#fbb4ae', 2  => '#b3cde3', 3  => '#ccebc5', 4  => '#decbe4', 
    5  => '#fed9a6', 
  },
  pastel16 => {
    1  => '#fbb4ae', 2  => '#b3cde3', 3  => '#ccebc5', 4  => '#decbe4', 
    5  => '#fed9a6', 6  => '#ffffcc', 
  },
  pastel17 => {
    1  => '#fbb4ae', 2  => '#b3cde3', 3  => '#ccebc5', 4  => '#decbe4', 
    5  => '#fed9a6', 6  => '#ffffcc', 7  => '#e5d8bd', 
  },
  pastel18 => {
    1  => '#fbb4ae', 2  => '#b3cde3', 3  => '#ccebc5', 4  => '#decbe4', 
    5  => '#fed9a6', 6  => '#ffffcc', 7  => '#e5d8bd', 8  => '#fddaec', 
  },
  pastel19 => {
    1  => '#fbb4ae', 2  => '#b3cde3', 3  => '#ccebc5', 4  => '#decbe4', 
    5  => '#fed9a6', 6  => '#ffffcc', 7  => '#e5d8bd', 8  => '#fddaec', 
    9  => '#f2f2f2', 
  },
  pastel23 => {
    1  => '#b3e2cd', 2  => '#fdcdac', 3  => '#cbd5e8', 
  },
  pastel24 => {
    1  => '#b3e2cd', 2  => '#fdcdac', 3  => '#cbd5e8', 4  => '#f4cae4', 
  },
  pastel25 => {
    1  => '#b3e2cd', 2  => '#fdcdac', 3  => '#cbd5e8', 4  => '#f4cae4', 
    5  => '#e6f5c9', 
  },
  pastel26 => {
    1  => '#b3e2cd', 2  => '#fdcdac', 3  => '#cbd5e8', 4  => '#f4cae4', 
    5  => '#e6f5c9', 6  => '#fff2ae', 
  },
  pastel27 => {
    1  => '#b3e2cd', 2  => '#fdcdac', 3  => '#cbd5e8', 4  => '#f4cae4', 
    5  => '#e6f5c9', 6  => '#fff2ae', 7  => '#f1e2cc', 
  },
  pastel28 => {
    1  => '#b3e2cd', 2  => '#fdcdac', 3  => '#cbd5e8', 4  => '#f4cae4', 
    5  => '#e6f5c9', 6  => '#fff2ae', 7  => '#f1e2cc', 8  => '#cccccc', 
  },
  piyg3 => {
    1  => '#e9a3c9', 2  => '#f7f7f7', 3  => '#a1d76a', 
  },
  piyg4 => {
    1  => '#d01c8b', 2  => '#f1b6da', 3  => '#b8e186', 4  => '#4dac26', 
  },
  piyg5 => {
    1  => '#d01c8b', 2  => '#f1b6da', 3  => '#f7f7f7', 4  => '#b8e186', 
    5  => '#4dac26', 
  },
  piyg6 => {
    1  => '#c51b7d', 2  => '#e9a3c9', 3  => '#fde0ef', 4  => '#e6f5d0', 
    5  => '#a1d76a', 6  => '#4d9221', 
  },
  piyg7 => {
    1  => '#c51b7d', 2  => '#e9a3c9', 3  => '#fde0ef', 4  => '#f7f7f7', 
    5  => '#e6f5d0', 6  => '#a1d76a', 7  => '#4d9221', 
  },
  piyg8 => {
    1  => '#c51b7d', 2  => '#de77ae', 3  => '#f1b6da', 4  => '#fde0ef', 
    5  => '#e6f5d0', 6  => '#b8e186', 7  => '#7fbc41', 8  => '#4d9221', 
  },
  piyg9 => {
    1  => '#c51b7d', 2  => '#de77ae', 3  => '#f1b6da', 4  => '#fde0ef', 
    5  => '#f7f7f7', 6  => '#e6f5d0', 7  => '#b8e186', 8  => '#7fbc41', 
    9  => '#4d9221', 
  },
  piyg10 => {
    1  => '#8e0152', 2  => '#c51b7d', 3  => '#de77ae', 4  => '#f1b6da', 
    5  => '#fde0ef', 6  => '#e6f5d0', 7  => '#b8e186', 8  => '#7fbc41', 
    9  => '#4d9221', 10  => '#276419', 
  },
  piyg11 => {
    1  => '#8e0152', 2  => '#c51b7d', 3  => '#de77ae', 4  => '#f1b6da', 
    5  => '#fde0ef', 6  => '#f7f7f7', 7  => '#e6f5d0', 8  => '#b8e186', 
    9  => '#7fbc41', 10  => '#4d9221', 11  => '#276419', 
  },
  prgn3 => {
    1  => '#af8dc3', 2  => '#f7f7f7', 3  => '#7fbf7b', 
  },
  prgn4 => {
    1  => '#7b3294', 2  => '#c2a5cf', 3  => '#a6dba0', 4  => '#008837', 
  },
  prgn5 => {
    1  => '#7b3294', 2  => '#c2a5cf', 3  => '#f7f7f7', 4  => '#a6dba0', 
    5  => '#008837', 
  },
  prgn6 => {
    1  => '#762a83', 2  => '#af8dc3', 3  => '#e7d4e8', 4  => '#d9f0d3', 
    5  => '#7fbf7b', 6  => '#1b7837', 
  },
  prgn7 => {
    1  => '#762a83', 2  => '#af8dc3', 3  => '#e7d4e8', 4  => '#f7f7f7', 
    5  => '#d9f0d3', 6  => '#7fbf7b', 7  => '#1b7837', 
  },
  prgn8 => {
    1  => '#762a83', 2  => '#9970ab', 3  => '#c2a5cf', 4  => '#e7d4e8', 
    5  => '#d9f0d3', 6  => '#a6dba0', 7  => '#5aae61', 8  => '#1b7837', 
  },
  prgn9 => {
    1  => '#762a83', 2  => '#9970ab', 3  => '#c2a5cf', 4  => '#e7d4e8', 
    5  => '#f7f7f7', 6  => '#d9f0d3', 7  => '#a6dba0', 8  => '#5aae61', 
    9  => '#1b7837', 
  },
  prgn10 => {
    1  => '#40004b', 2  => '#762a83', 3  => '#9970ab', 4  => '#c2a5cf', 
    5  => '#e7d4e8', 6  => '#d9f0d3', 7  => '#a6dba0', 8  => '#5aae61', 
    9  => '#1b7837', 10  => '#00441b', 
  },
  prgn11 => {
    1  => '#40004b', 2  => '#762a83', 3  => '#9970ab', 4  => '#c2a5cf', 
    5  => '#e7d4e8', 6  => '#f7f7f7', 7  => '#d9f0d3', 8  => '#a6dba0', 
    9  => '#5aae61', 10  => '#1b7837', 11  => '#00441b', 
  },
  pubu3 => {
    1  => '#ece7f2', 2  => '#a6bddb', 3  => '#2b8cbe', 
  },
  pubu4 => {
    1  => '#f1eef6', 2  => '#bdc9e1', 3  => '#74a9cf', 4  => '#0570b0', 
  },
  pubu5 => {
    1  => '#f1eef6', 2  => '#bdc9e1', 3  => '#74a9cf', 4  => '#2b8cbe', 
    5  => '#045a8d', 
  },
  pubu6 => {
    1  => '#f1eef6', 2  => '#d0d1e6', 3  => '#a6bddb', 4  => '#74a9cf', 
    5  => '#2b8cbe', 6  => '#045a8d', 
  },
  pubu7 => {
    1  => '#f1eef6', 2  => '#d0d1e6', 3  => '#a6bddb', 4  => '#74a9cf', 
    5  => '#3690c0', 6  => '#0570b0', 7  => '#034e7b', 
  },
  pubu8 => {
    1  => '#fff7fb', 2  => '#ece7f2', 3  => '#d0d1e6', 4  => '#a6bddb', 
    5  => '#74a9cf', 6  => '#3690c0', 7  => '#0570b0', 8  => '#034e7b', 
  },
  pubu9 => {
    1  => '#fff7fb', 2  => '#ece7f2', 3  => '#d0d1e6', 4  => '#a6bddb', 
    5  => '#74a9cf', 6  => '#3690c0', 7  => '#0570b0', 8  => '#045a8d', 
    9  => '#023858', 
  },
  pubugn3 => {
    1  => '#ece2f0', 2  => '#a6bddb', 3  => '#1c9099', 
  },
  pubugn4 => {
    1  => '#f6eff7', 2  => '#bdc9e1', 3  => '#67a9cf', 4  => '#02818a', 
  },
  pubugn5 => {
    1  => '#f6eff7', 2  => '#bdc9e1', 3  => '#67a9cf', 4  => '#1c9099', 
    5  => '#016c59', 
  },
  pubugn6 => {
    1  => '#f6eff7', 2  => '#d0d1e6', 3  => '#a6bddb', 4  => '#67a9cf', 
    5  => '#1c9099', 6  => '#016c59', 
  },
  pubugn7 => {
    1  => '#f6eff7', 2  => '#d0d1e6', 3  => '#a6bddb', 4  => '#67a9cf', 
    5  => '#3690c0', 6  => '#02818a', 7  => '#016450', 
  },
  pubugn8 => {
    1  => '#fff7fb', 2  => '#ece2f0', 3  => '#d0d1e6', 4  => '#a6bddb', 
    5  => '#67a9cf', 6  => '#3690c0', 7  => '#02818a', 8  => '#016450', 
  },
  pubugn9 => {
    1  => '#fff7fb', 2  => '#ece2f0', 3  => '#d0d1e6', 4  => '#a6bddb', 
    5  => '#67a9cf', 6  => '#3690c0', 7  => '#02818a', 8  => '#016c59', 
    9  => '#014636', 
  },
  puor3 => {
    1  => '#f1a340', 2  => '#f7f7f7', 3  => '#998ec3', 
  },
  puor4 => {
    1  => '#e66101', 2  => '#fdb863', 3  => '#b2abd2', 4  => '#5e3c99', 
  },
  puor5 => {
    1  => '#e66101', 2  => '#fdb863', 3  => '#f7f7f7', 4  => '#b2abd2', 
    5  => '#5e3c99', 
  },
  puor6 => {
    1  => '#b35806', 2  => '#f1a340', 3  => '#fee0b6', 4  => '#d8daeb', 
    5  => '#998ec3', 6  => '#542788', 
  },
  puor7 => {
    1  => '#b35806', 2  => '#f1a340', 3  => '#fee0b6', 4  => '#f7f7f7', 
    5  => '#d8daeb', 6  => '#998ec3', 7  => '#542788', 
  },
  puor8 => {
    1  => '#b35806', 2  => '#e08214', 3  => '#fdb863', 4  => '#fee0b6', 
    5  => '#d8daeb', 6  => '#b2abd2', 7  => '#8073ac', 8  => '#542788', 
  },
  puor9 => {
    1  => '#b35806', 2  => '#e08214', 3  => '#fdb863', 4  => '#fee0b6', 
    5  => '#f7f7f7', 6  => '#d8daeb', 7  => '#b2abd2', 8  => '#8073ac', 
    9  => '#542788', 
  },
  purd3 => {
    1  => '#e7e1ef', 2  => '#c994c7', 3  => '#dd1c77', 
  },
  purd4 => {
    1  => '#f1eef6', 2  => '#d7b5d8', 3  => '#df65b0', 4  => '#ce1256', 
  },
  purd5 => {
    1  => '#f1eef6', 2  => '#d7b5d8', 3  => '#df65b0', 4  => '#dd1c77', 
    5  => '#980043', 
  },
  purd6 => {
    1  => '#f1eef6', 2  => '#d4b9da', 3  => '#c994c7', 4  => '#df65b0', 
    5  => '#dd1c77', 6  => '#980043', 
  },
  purd7 => {
    1  => '#f1eef6', 2  => '#d4b9da', 3  => '#c994c7', 4  => '#df65b0', 
    5  => '#e7298a', 6  => '#ce1256', 7  => '#91003f', 
  },
  purd8 => {
    1  => '#f7f4f9', 2  => '#e7e1ef', 3  => '#d4b9da', 4  => '#c994c7', 
    5  => '#df65b0', 6  => '#e7298a', 7  => '#ce1256', 8  => '#91003f', 
  },
  purd9 => {
    1  => '#f7f4f9', 2  => '#e7e1ef', 3  => '#d4b9da', 4  => '#c994c7', 
    5  => '#df65b0', 6  => '#e7298a', 7  => '#ce1256', 8  => '#980043', 
    9  => '#67001f', 
  },
  puor10 => {
    1  => '#7f3b08', 2  => '#b35806', 3  => '#e08214', 4  => '#fdb863', 
    5  => '#fee0b6', 6  => '#d8daeb', 7  => '#b2abd2', 8  => '#8073ac', 
    9  => '#542788', 10  => '#2d004b', 
  },
  puor11 => {
    1  => '#7f3b08', 2  => '#b35806', 3  => '#e08214', 4  => '#fdb863', 
    5  => '#fee0b6', 6  => '#f7f7f7', 7  => '#d8daeb', 8  => '#b2abd2', 
    9  => '#8073ac', 10  => '#542788', 11  => '#2d004b', 
  },
  purples3 => {
    1  => '#efedf5', 2  => '#bcbddc', 3  => '#756bb1', 
  },
  purples4 => {
    1  => '#f2f0f7', 2  => '#cbc9e2', 3  => '#9e9ac8', 4  => '#6a51a3', 
  },
  purples5 => {
    1  => '#f2f0f7', 2  => '#cbc9e2', 3  => '#9e9ac8', 4  => '#756bb1', 
    5  => '#54278f', 
  },
  purples6 => {
    1  => '#f2f0f7', 2  => '#dadaeb', 3  => '#bcbddc', 4  => '#9e9ac8', 
    5  => '#756bb1', 6  => '#54278f', 
  },
  purples7 => {
    1  => '#f2f0f7', 2  => '#dadaeb', 3  => '#bcbddc', 4  => '#9e9ac8', 
    5  => '#807dba', 6  => '#6a51a3', 7  => '#4a1486', 
  },
  purples8 => {
    1  => '#fcfbfd', 2  => '#efedf5', 3  => '#dadaeb', 4  => '#bcbddc', 
    5  => '#9e9ac8', 6  => '#807dba', 7  => '#6a51a3', 8  => '#4a1486', 
  },
  purples9 => {
    1  => '#fcfbfd', 2  => '#efedf5', 3  => '#dadaeb', 4  => '#bcbddc', 
    5  => '#9e9ac8', 6  => '#807dba', 7  => '#6a51a3', 8  => '#54278f', 
    9  => '#3f007d', 
  },
  rdbu10 => {
    1  => '#67001f', 2  => '#b2182b', 3  => '#d6604d', 4  => '#f4a582', 
    5  => '#fddbc7', 6  => '#d1e5f0', 7  => '#92c5de', 8  => '#4393c3', 
    9  => '#2166ac', 10  => '#053061', 
  },
  rdbu11 => {
    1  => '#67001f', 2  => '#b2182b', 3  => '#d6604d', 4  => '#f4a582', 
    5  => '#fddbc7', 6  => '#f7f7f7', 7  => '#d1e5f0', 8  => '#92c5de', 
    9  => '#4393c3', 10  => '#2166ac', 11  => '#053061', 
  },
  rdbu3 => {
    1  => '#ef8a62', 2  => '#f7f7f7', 3  => '#67a9cf', 
  },
  rdbu4 => {
    1  => '#ca0020', 2  => '#f4a582', 3  => '#92c5de', 4  => '#0571b0', 
  },
  rdbu5 => {
    1  => '#ca0020', 2  => '#f4a582', 3  => '#f7f7f7', 4  => '#92c5de', 
    5  => '#0571b0', 
  },
  rdbu6 => {
    1  => '#b2182b', 2  => '#ef8a62', 3  => '#fddbc7', 4  => '#d1e5f0', 
    5  => '#67a9cf', 6  => '#2166ac', 
  },
  rdbu7 => {
    1  => '#b2182b', 2  => '#ef8a62', 3  => '#fddbc7', 4  => '#f7f7f7', 
    5  => '#d1e5f0', 6  => '#67a9cf', 7  => '#2166ac', 
  },
  rdbu8 => {
    1  => '#b2182b', 2  => '#d6604d', 3  => '#f4a582', 4  => '#fddbc7', 
    5  => '#d1e5f0', 6  => '#92c5de', 7  => '#4393c3', 8  => '#2166ac', 
  },
  rdbu9 => {
    1  => '#b2182b', 2  => '#d6604d', 3  => '#f4a582', 4  => '#fddbc7', 
    5  => '#f7f7f7', 6  => '#d1e5f0', 7  => '#92c5de', 8  => '#4393c3', 
    9  => '#2166ac', 
  },
  rdgy3 => {
    1  => '#ef8a62', 2  => '#ffffff', 3  => '#999999', 
  },
  rdgy4 => {
    1  => '#ca0020', 2  => '#f4a582', 3  => '#bababa', 4  => '#404040', 
  },
  rdgy5 => {
    1  => '#ca0020', 2  => '#f4a582', 3  => '#ffffff', 4  => '#bababa', 
    5  => '#404040', 
  },
  rdgy6 => {
    1  => '#b2182b', 2  => '#ef8a62', 3  => '#fddbc7', 4  => '#e0e0e0', 
    5  => '#999999', 6  => '#4d4d4d', 
  },
  rdgy7 => {
    1  => '#b2182b', 2  => '#ef8a62', 3  => '#fddbc7', 4  => '#ffffff', 
    5  => '#e0e0e0', 6  => '#999999', 7  => '#4d4d4d', 
  },
  rdgy8 => {
    1  => '#b2182b', 2  => '#d6604d', 3  => '#f4a582', 4  => '#fddbc7', 
    5  => '#e0e0e0', 6  => '#bababa', 7  => '#878787', 8  => '#4d4d4d', 
  },
  rdgy9 => {
    1  => '#b2182b', 2  => '#d6604d', 3  => '#f4a582', 4  => '#fddbc7', 
    5  => '#ffffff', 6  => '#e0e0e0', 7  => '#bababa', 8  => '#878787', 
    9  => '#4d4d4d', 
  },
  rdpu3 => {
    1  => '#fde0dd', 2  => '#fa9fb5', 3  => '#c51b8a', 
  },
  rdpu4 => {
    1  => '#feebe2', 2  => '#fbb4b9', 3  => '#f768a1', 4  => '#ae017e', 
  },
  rdpu5 => {
    1  => '#feebe2', 2  => '#fbb4b9', 3  => '#f768a1', 4  => '#c51b8a', 
    5  => '#7a0177', 
  },
  rdpu6 => {
    1  => '#feebe2', 2  => '#fcc5c0', 3  => '#fa9fb5', 4  => '#f768a1', 
    5  => '#c51b8a', 6  => '#7a0177', 
  },
  rdpu7 => {
    1  => '#feebe2', 2  => '#fcc5c0', 3  => '#fa9fb5', 4  => '#f768a1', 
    5  => '#dd3497', 6  => '#ae017e', 7  => '#7a0177', 
  },
  rdpu8 => {
    1  => '#fff7f3', 2  => '#fde0dd', 3  => '#fcc5c0', 4  => '#fa9fb5', 
    5  => '#f768a1', 6  => '#dd3497', 7  => '#ae017e', 8  => '#7a0177', 
  },
  rdpu9 => {
    1  => '#fff7f3', 2  => '#fde0dd', 3  => '#fcc5c0', 4  => '#fa9fb5', 
    5  => '#f768a1', 6  => '#dd3497', 7  => '#ae017e', 8  => '#7a0177', 
    9  => '#49006a', 
  },
  rdgy10 => {
    1  => '#67001f', 2  => '#b2182b', 3  => '#d6604d', 4  => '#f4a582', 
    5  => '#fddbc7', 6  => '#e0e0e0', 7  => '#bababa', 8  => '#878787', 
    9  => '#4d4d4d', 10  => '#1a1a1a', 
  },
  rdgy11 => {
    1  => '#67001f', 2  => '#b2182b', 3  => '#d6604d', 4  => '#f4a582', 
    5  => '#fddbc7', 6  => '#ffffff', 7  => '#e0e0e0', 8  => '#bababa', 
    9  => '#878787', 10  => '#4d4d4d', 11  => '#1a1a1a', 
  },
  rdylbu3 => {
    1  => '#fc8d59', 2  => '#ffffbf', 3  => '#91bfdb', 
  },
  rdylbu4 => {
    1  => '#d7191c', 2  => '#fdae61', 3  => '#abd9e9', 4  => '#2c7bb6', 
  },
  rdylbu5 => {
    1  => '#d7191c', 2  => '#fdae61', 3  => '#ffffbf', 4  => '#abd9e9', 
    5  => '#2c7bb6', 
  },
  rdylbu6 => {
    1  => '#d73027', 2  => '#fc8d59', 3  => '#fee090', 4  => '#e0f3f8', 
    5  => '#91bfdb', 6  => '#4575b4', 
  },
  rdylbu7 => {
    1  => '#d73027', 2  => '#fc8d59', 3  => '#fee090', 4  => '#ffffbf', 
    5  => '#e0f3f8', 6  => '#91bfdb', 7  => '#4575b4', 
  },
  rdylbu8 => {
    1  => '#d73027', 2  => '#f46d43', 3  => '#fdae61', 4  => '#fee090', 
    5  => '#e0f3f8', 6  => '#abd9e9', 7  => '#74add1', 8  => '#4575b4', 
  },
  rdylbu9 => {
    1  => '#d73027', 2  => '#f46d43', 3  => '#fdae61', 4  => '#fee090', 
    5  => '#ffffbf', 6  => '#e0f3f8', 7  => '#abd9e9', 8  => '#74add1', 
    9  => '#4575b4', 
  },
  rdylbu10 => {
    1  => '#a50026', 2  => '#d73027', 3  => '#f46d43', 4  => '#fdae61', 
    5  => '#fee090', 6  => '#e0f3f8', 7  => '#abd9e9', 8  => '#74add1', 
    9  => '#4575b4', 10  => '#313695', 
  },
  rdylbu11 => {
    1  => '#a50026', 2  => '#d73027', 3  => '#f46d43', 4  => '#fdae61', 
    5  => '#fee090', 6  => '#ffffbf', 7  => '#e0f3f8', 8  => '#abd9e9', 
    9  => '#74add1', 10  => '#4575b4', 11  => '#313695', 
  },
  rdylgn3 => {
    1  => '#fc8d59', 2  => '#ffffbf', 3  => '#91cf60', 
  },
  rdylgn4 => {
    1  => '#d7191c', 2  => '#fdae61', 3  => '#a6d96a', 4  => '#1a9641', 
  },
  rdylgn5 => {
    1  => '#d7191c', 2  => '#fdae61', 3  => '#ffffbf', 4  => '#a6d96a', 
    5  => '#1a9641', 
  },
  rdylgn6 => {
    1  => '#d73027', 2  => '#fc8d59', 3  => '#fee08b', 4  => '#d9ef8b', 
    5  => '#91cf60', 6  => '#1a9850', 
  },
  rdylgn7 => {
    1  => '#d73027', 2  => '#fc8d59', 3  => '#fee08b', 4  => '#ffffbf', 
    5  => '#d9ef8b', 6  => '#91cf60', 7  => '#1a9850', 
  },
  rdylgn8 => {
    1  => '#d73027', 2  => '#f46d43', 3  => '#fdae61', 4  => '#fee08b', 
    5  => '#d9ef8b', 6  => '#a6d96a', 7  => '#66bd63', 8  => '#1a9850', 
  },
  rdylgn9 => {
    1  => '#d73027', 2  => '#f46d43', 3  => '#fdae61', 4  => '#fee08b', 
    5  => '#ffffbf', 6  => '#d9ef8b', 7  => '#a6d96a', 8  => '#66bd63', 
    9  => '#1a9850', 
  },
  rdylgn10 => {
    1  => '#a50026', 2  => '#d73027', 3  => '#f46d43', 4  => '#fdae61', 
    5  => '#fee08b', 6  => '#d9ef8b', 7  => '#a6d96a', 8  => '#66bd63', 
    9  => '#1a9850', 10  => '#006837', 
  },
  rdylgn11 => {
    1  => '#a50026', 2  => '#d73027', 3  => '#f46d43', 4  => '#fdae61', 
    5  => '#fee08b', 6  => '#ffffbf', 7  => '#d9ef8b', 8  => '#a6d96a', 
    9  => '#66bd63', 10  => '#1a9850', 11  => '#006837', 
  },
  reds3 => {
    1  => '#fee0d2', 2  => '#fc9272', 3  => '#de2d26', 
  },
  reds4 => {
    1  => '#fee5d9', 2  => '#fcae91', 3  => '#fb6a4a', 4  => '#cb181d', 
  },
  reds5 => {
    1  => '#fee5d9', 2  => '#fcae91', 3  => '#fb6a4a', 4  => '#de2d26', 
    5  => '#a50f15', 
  },
  reds6 => {
    1  => '#fee5d9', 2  => '#fcbba1', 3  => '#fc9272', 4  => '#fb6a4a', 
    5  => '#de2d26', 6  => '#a50f15', 
  },
  reds7 => {
    1  => '#fee5d9', 2  => '#fcbba1', 3  => '#fc9272', 4  => '#fb6a4a', 
    5  => '#ef3b2c', 6  => '#cb181d', 7  => '#99000d', 
  },
  reds8 => {
    1  => '#fff5f0', 2  => '#fee0d2', 3  => '#fcbba1', 4  => '#fc9272', 
    5  => '#fb6a4a', 6  => '#ef3b2c', 7  => '#cb181d', 8  => '#99000d', 
  },
  reds9 => {
    1  => '#fff5f0', 2  => '#fee0d2', 3  => '#fcbba1', 4  => '#fc9272', 
    5  => '#fb6a4a', 6  => '#ef3b2c', 7  => '#cb181d', 8  => '#a50f15', 
    9  => '#67000d', 
  },
  set13 => {
    1  => '#e41a1c', 2  => '#377eb8', 3  => '#4daf4a', 
  },
  set14 => {
    1  => '#e41a1c', 2  => '#377eb8', 3  => '#4daf4a', 4  => '#984ea3', 
  },
  set15 => {
    1  => '#e41a1c', 2  => '#377eb8', 3  => '#4daf4a', 4  => '#984ea3', 
    5  => '#ff7f00', 
  },
  set16 => {
    1  => '#e41a1c', 2  => '#377eb8', 3  => '#4daf4a', 4  => '#984ea3', 
    5  => '#ff7f00', 6  => '#ffff33', 
  },
  set17 => {
    1  => '#e41a1c', 2  => '#377eb8', 3  => '#4daf4a', 4  => '#984ea3', 
    5  => '#ff7f00', 6  => '#ffff33', 7  => '#a65628', 
  },
  set18 => {
    1  => '#e41a1c', 2  => '#377eb8', 3  => '#4daf4a', 4  => '#984ea3', 
    5  => '#ff7f00', 6  => '#ffff33', 7  => '#a65628', 8  => '#f781bf', 
  },
  set19 => {
    1  => '#e41a1c', 2  => '#377eb8', 3  => '#4daf4a', 4  => '#984ea3', 
    5  => '#ff7f00', 6  => '#ffff33', 7  => '#a65628', 8  => '#f781bf', 
    9  => '#999999', 
  },
  set23 => {
    1  => '#66c2a5', 2  => '#fc8d62', 3  => '#8da0cb', 
  },
  set24 => {
    1  => '#66c2a5', 2  => '#fc8d62', 3  => '#8da0cb', 4  => '#e78ac3', 
  },
  set25 => {
    1  => '#66c2a5', 2  => '#fc8d62', 3  => '#8da0cb', 4  => '#e78ac3', 
    5  => '#a6d854', 
  },
  set26 => {
    1  => '#66c2a5', 2  => '#fc8d62', 3  => '#8da0cb', 4  => '#e78ac3', 
    5  => '#a6d854', 6  => '#ffd92f', 
  },
  set27 => {
    1  => '#66c2a5', 2  => '#fc8d62', 3  => '#8da0cb', 4  => '#e78ac3', 
    5  => '#a6d854', 6  => '#ffd92f', 7  => '#e5c494', 
  },
  set28 => {
    1  => '#66c2a5', 2  => '#fc8d62', 3  => '#8da0cb', 4  => '#e78ac3', 
    5  => '#a6d854', 6  => '#ffd92f', 7  => '#e5c494', 8  => '#b3b3b3', 
  },
  set33 => {
    1  => '#8dd3c7', 2  => '#ffffb3', 3  => '#bebada', 
  },
  set34 => {
    1  => '#8dd3c7', 2  => '#ffffb3', 3  => '#bebada', 4  => '#fb8072', 
  },
  set35 => {
    1  => '#8dd3c7', 2  => '#ffffb3', 3  => '#bebada', 4  => '#fb8072', 
    5  => '#80b1d3', 
  },
  set36 => {
    1  => '#8dd3c7', 2  => '#ffffb3', 3  => '#bebada', 4  => '#fb8072', 
    5  => '#80b1d3', 6  => '#fdb462', 
  },
  set37 => {
    1  => '#8dd3c7', 2  => '#ffffb3', 3  => '#bebada', 4  => '#fb8072', 
    5  => '#80b1d3', 6  => '#fdb462', 7  => '#b3de69', 
  },
  set38 => {
    1  => '#8dd3c7', 2  => '#ffffb3', 3  => '#bebada', 4  => '#fb8072', 
    5  => '#80b1d3', 6  => '#fdb462', 7  => '#b3de69', 8  => '#fccde5', 
  },
  set39 => {
    1  => '#8dd3c7', 2  => '#ffffb3', 3  => '#bebada', 4  => '#fb8072', 
    5  => '#80b1d3', 6  => '#fdb462', 7  => '#b3de69', 8  => '#fccde5', 
    9  => '#d9d9d9', 
  },
  set310 => {
    1  => '#8dd3c7', 2  => '#ffffb3', 3  => '#bebada', 4  => '#fb8072', 
    5  => '#80b1d3', 6  => '#fdb462', 7  => '#b3de69', 8  => '#fccde5', 
    9  => '#d9d9d9', 10  => '#bc80bd', 
  },
  set311 => {
    1  => '#8dd3c7', 2  => '#ffffb3', 3  => '#bebada', 4  => '#fb8072', 
    5  => '#80b1d3', 6  => '#fdb462', 7  => '#b3de69', 8  => '#fccde5', 
    9  => '#d9d9d9', 10  => '#bc80bd', 11  => '#ccebc5', 
  },
  set312 => {
    1  => '#8dd3c7', 2  => '#ffffb3', 3  => '#bebada', 4  => '#fb8072', 
    5  => '#80b1d3', 6  => '#fdb462', 7  => '#b3de69', 8  => '#fccde5', 
    9  => '#d9d9d9', 10  => '#bc80bd', 11  => '#ccebc5', 12  => '#ffed6f', 
  },
  spectral3 => {
    1  => '#fc8d59', 2  => '#ffffbf', 3  => '#99d594', 
  },
  spectral4 => {
    1  => '#d7191c', 2  => '#fdae61', 3  => '#abdda4', 4  => '#2b83ba', 
  },
  spectral5 => {
    1  => '#d7191c', 2  => '#fdae61', 3  => '#ffffbf', 4  => '#abdda4', 
    5  => '#2b83ba', 
  },
  spectral6 => {
    1  => '#d53e4f', 2  => '#fc8d59', 3  => '#fee08b', 4  => '#e6f598', 
    5  => '#99d594', 6  => '#3288bd', 
  },
  spectral7 => {
    1  => '#d53e4f', 2  => '#fc8d59', 3  => '#fee08b', 4  => '#ffffbf', 
    5  => '#e6f598', 6  => '#99d594', 7  => '#3288bd', 
  },
  spectral8 => {
    1  => '#d53e4f', 2  => '#f46d43', 3  => '#fdae61', 4  => '#fee08b', 
    5  => '#e6f598', 6  => '#abdda4', 7  => '#66c2a5', 8  => '#3288bd', 
  },
  spectral9 => {
    1  => '#d53e4f', 2  => '#f46d43', 3  => '#fdae61', 4  => '#fee08b', 
    5  => '#ffffbf', 6  => '#e6f598', 7  => '#abdda4', 8  => '#66c2a5', 
    9  => '#3288bd', 
  },
  spectral10 => {
    1  => '#9e0142', 2  => '#d53e4f', 3  => '#f46d43', 4  => '#fdae61', 
    5  => '#fee08b', 6  => '#e6f598', 7  => '#abdda4', 8  => '#66c2a5', 
    9  => '#3288bd', 10  => '#5e4fa2', 
  },
  spectral11 => {
    1  => '#9e0142', 2  => '#d53e4f', 3  => '#f46d43', 4  => '#fdae61', 
    5  => '#fee08b', 6  => '#ffffbf', 7  => '#e6f598', 8  => '#abdda4', 
    9  => '#66c2a5', 10  => '#3288bd', 11  => '#5e4fa2', 
  },
  ylgn3 => {
    1  => '#f7fcb9', 2  => '#addd8e', 3  => '#31a354', 
  },
  ylgn4 => {
    1  => '#ffffcc', 2  => '#c2e699', 3  => '#78c679', 4  => '#238443', 
  },
  ylgn5 => {
    1  => '#ffffcc', 2  => '#c2e699', 3  => '#78c679', 4  => '#31a354', 
    5  => '#006837', 
  },
  ylgn6 => {
    1  => '#ffffcc', 2  => '#d9f0a3', 3  => '#addd8e', 4  => '#78c679', 
    5  => '#31a354', 6  => '#006837', 
  },
  ylgn7 => {
    1  => '#ffffcc', 2  => '#d9f0a3', 3  => '#addd8e', 4  => '#78c679', 
    5  => '#41ab5d', 6  => '#238443', 7  => '#005a32', 
  },
  ylgn8 => {
    1  => '#ffffe5', 2  => '#f7fcb9', 3  => '#d9f0a3', 4  => '#addd8e', 
    5  => '#78c679', 6  => '#41ab5d', 7  => '#238443', 8  => '#005a32', 
  },
  ylgn9 => {
    1  => '#ffffe5', 2  => '#f7fcb9', 3  => '#d9f0a3', 4  => '#addd8e', 
    5  => '#78c679', 6  => '#41ab5d', 7  => '#238443', 8  => '#006837', 
    9  => '#004529', 
  },
  ylgnbu3 => {
    1  => '#edf8b1', 2  => '#7fcdbb', 3  => '#2c7fb8', 
  },
  ylgnbu4 => {
    1  => '#ffffcc', 2  => '#a1dab4', 3  => '#41b6c4', 4  => '#225ea8', 
  },
  ylgnbu5 => {
    1  => '#ffffcc', 2  => '#a1dab4', 3  => '#41b6c4', 4  => '#2c7fb8', 
    5  => '#253494', 
  },
  ylgnbu6 => {
    1  => '#ffffcc', 2  => '#c7e9b4', 3  => '#7fcdbb', 4  => '#41b6c4', 
    5  => '#2c7fb8', 6  => '#253494', 
  },
  ylgnbu7 => {
    1  => '#ffffcc', 2  => '#c7e9b4', 3  => '#7fcdbb', 4  => '#41b6c4', 
    5  => '#1d91c0', 6  => '#225ea8', 7  => '#0c2c84', 
  },
  ylgnbu8 => {
    1  => '#ffffd9', 2  => '#edf8b1', 3  => '#c7e9b4', 4  => '#7fcdbb', 
    5  => '#41b6c4', 6  => '#1d91c0', 7  => '#225ea8', 8  => '#0c2c84', 
  },
  ylgnbu9 => {
    1  => '#ffffd9', 2  => '#edf8b1', 3  => '#c7e9b4', 4  => '#7fcdbb', 
    5  => '#41b6c4', 6  => '#1d91c0', 7  => '#225ea8', 8  => '#253494', 
    9  => '#081d58', 
  },
  ylorbr3 => {
    1  => '#fff7bc', 2  => '#fec44f', 3  => '#d95f0e', 
  },
  ylorbr4 => {
    1  => '#ffffd4', 2  => '#fed98e', 3  => '#fe9929', 4  => '#cc4c02', 
  },
  ylorbr5 => {
    1  => '#ffffd4', 2  => '#fed98e', 3  => '#fe9929', 4  => '#d95f0e', 
    5  => '#993404', 
  },
  ylorbr6 => {
    1  => '#ffffd4', 2  => '#fee391', 3  => '#fec44f', 4  => '#fe9929', 
    5  => '#d95f0e', 6  => '#993404', 
  },
  ylorbr7 => {
    1  => '#ffffd4', 2  => '#fee391', 3  => '#fec44f', 4  => '#fe9929', 
    5  => '#ec7014', 6  => '#cc4c02', 7  => '#8c2d04', 
  },
  ylorbr8 => {
    1  => '#ffffe5', 2  => '#fff7bc', 3  => '#fee391', 4  => '#fec44f', 
    5  => '#fe9929', 6  => '#ec7014', 7  => '#cc4c02', 8  => '#8c2d04', 
  },
  ylorbr9 => {
    1  => '#ffffe5', 2  => '#fff7bc', 3  => '#fee391', 4  => '#fec44f', 
    5  => '#fe9929', 6  => '#ec7014', 7  => '#cc4c02', 8  => '#993404', 
    9  => '#662506', 
  },
  ylorrd3 => {
    1  => '#ffeda0', 2  => '#feb24c', 3  => '#f03b20', 
  },
  ylorrd4 => {
    1  => '#ffffb2', 2  => '#fecc5c', 3  => '#fd8d3c', 4  => '#e31a1c', 
  },
  ylorrd5 => {
    1  => '#ffffb2', 2  => '#fecc5c', 3  => '#fd8d3c', 4  => '#f03b20', 
    5  => '#bd0026', 
  },
  ylorrd6 => {
    1  => '#ffffb2', 2  => '#fed976', 3  => '#feb24c', 4  => '#fd8d3c', 
    5  => '#f03b20', 6  => '#bd0026', 
  },
  ylorrd7 => {
    1  => '#ffffb2', 2  => '#fed976', 3  => '#feb24c', 4  => '#fd8d3c', 
    5  => '#fc4e2a', 6  => '#e31a1c', 7  => '#b10026', 
  },
  ylorrd8 => {
    1  => '#ffffcc', 2  => '#ffeda0', 3  => '#fed976', 4  => '#feb24c', 
    5  => '#fd8d3c', 6  => '#fc4e2a', 7  => '#e31a1c', 8  => '#b10026', 
  },
  ylorrd9 => {
    1  => '#ffffcc', 2  => '#ffeda0', 3  => '#fed976', 4  => '#feb24c', 
    5  => '#fd8d3c', 6  => '#fc4e2a', 7  => '#e31a1c', 8  => '#bd0026', 
    9  => '#800026', 
  },
  };

# reverse mapping value => name
my $color_values = { };
my $all_color_names = { };

{
  # reverse mapping "#ff0000 => 'red'"
  # also build a list of all possible color names
  for my $n (keys %$color_names)
    {
    my $s = $color_names->{$n};
    $color_values->{ $n } = {};
    my $t = $color_values->{$n};
    # sort the names on their length
    for my $c (sort { length($a) <=> length($b) || $a cmp $b } keys %$s)
      {
      # don't add "blue1" if it is already set as "blue"
      $t->{ $s->{$c} } = $c unless exists $t->{ $s->{$c} };
      # mark as existing
      $all_color_names->{ $c } = undef;
      }
    }
}

our $qr_custom_attribute = qr/^x-([a-z_0-9]+-)*[a-z_0-9]+\z/;

sub color_names
  {
  $color_names;
  }

sub color_name
  {
  # return "red" for "#ff0000"
  my ($self,$color,$scheme) = @_;

  $scheme ||= 'w3c';
  $color_values->{$scheme}->{$color} || $color;
  }

sub color_value
  {
  # return "#ff0000" for "red"
  my ($self,$color,$scheme) = @_;

  $scheme ||= 'w3c';

  # 'w3c/red' => 'w3c', 'red'
  $scheme = $1 if $color =~ s/^([a-z0-9])\///;

  $color_names->{$scheme}->{$color} || $color;
  }

sub _color_scheme
  {
  # check that a given color scheme is valid
  my ($self, $scheme) = @_;

  return $scheme if $scheme eq 'inherit';
  exists $color_names->{ $scheme } ? $scheme : undef;
  }

sub _color
  {
  # Check that a given color name (like 'red'), or value (like '#ff0000')
  # or rgb(1,2,3) is valid. Used by valid_attribute().

  # Note that for color names, the color scheme is not known here, so we
  # can only look if the color name is potentially possible. F.i. under
  # the Brewer scheme ylorrd9, '1' is a valid color name, while 'red'
  # would not. To resolve such conflicts, we will fallback to 'x11'
  # (the largest of the schemes) if the color name doesn't exist in
  # the current scheme.
  my ($self, $org_color) = @_;

  $org_color = lc($org_color);		# color names are case insensitive
  $org_color =~ s/\s//g;		# remove spaces to unify format
  my $color = $org_color;

  if ($color =~ s/^(w3c|[a-z]+\d{0,2})\///)
    {
    my $scheme = $1;
    return $org_color if exists $color_names->{$scheme}->{$color};
    # if it didn't work, then fall back to x11
    $scheme = 'x11';
    return (exists $color_names->{$scheme}->{$color} ? $org_color : undef);
    }

  # scheme unknown, fall back to generic handling

  # red => red
  return $org_color if exists $all_color_names->{$color};

  # #ff0000 => #ff0000, rgb(1,2,3) => rgb(1,2,3)
  defined $self->color_as_hex($color) ? $org_color : undef;
  }

sub _hsv_to_rgb
  {
  # H=0..360, S=0..1.0, V=0..1.0
  my ($h, $s, $v) = @_;

  my $e = 0.0001;

  if ($s < $e)
    {
    $v = abs(int(256 * $v)); $v = 255 if $v > 255;
    return ($v,$v,$v);
    }

  my ($r,$g,$b);
  $h *= 360;

  my $h1 = int($h / 60);
  my $f = $h / 60 - $h1;
  my $p = $v * (1 - $s);
  my $q = $v * (1 - ($s * $f));
  my $t = $v * (1 - ($s * (1-$f)));

  if ($h1 == 0 || $h1 == 6)
    {
    $r = $v; $g = $t; $b = $p;
    }
  elsif ($h1 == 1)
    {
    $r = $q; $g = $v; $b = $p;
    }
  elsif ($h1 == 2)
    {
    $r = $p; $g = $v; $b = $t;
    }
  elsif ($h1 == 3)
    {
    $r = $p; $g = $q; $b = $v;
    }
  elsif ($h1 == 4)
    {
    $r = $t; $g = $p; $b = $v;
    }
  else
    {
    $r = $v; $g = $p; $b = $q;
    }
  # clamp values to 0.255
  $r = abs(int($r*256));
  $g = abs(int($g*256));
  $b = abs(int($b*256));
  $r = 255 if $r > 255;
  $g = 255 if $g > 255;
  $b = 255 if $b > 255;

  ($r,$g,$b);
  }

sub _hsl_to_rgb
  {
  # H=0..360, S=0..100, L=0..100
  my ($h, $s, $l) = @_;

  my $e = 0.0001;
  if ($s < $e)
    {
    # achromatic or grey
    $l = abs(int(256 * $l)); $l = 255 if $l > 255;
    return ($l,$l,$l);
    }

  my $t2;
  if ($l < 0.5)
    {
    $t2 = $l * ($s + 1);
    }
  else
    {
    $t2 = $l + $s - ($l * $s);
    }
  my $t1 = $l * 2 - $t2;

  my ($r,$g,$b);

  # 0..359
  $h %= 360 if $h >= 360;

  # $h = 0..1
  $h /= 360;

  my $tr = $h + 1/3;
  my $tg = $h;
  my $tb = $h - 1/3;

  $tr += 1 if $tr < 0; $tr -= 1 if $tr > 1;
  $tg += 1 if $tg < 0; $tg -= 1 if $tg > 1;
  $tb += 1 if $tb < 0; $tb -= 1 if $tb > 1;

  my $i = 0; my @temp3 = ($tr,$tg,$tb);
  my @rc;
  for my $c ($r,$g,$b)
    {
    my $t3 = $temp3[$i++];

    if ($t3 < 1/6)
      {
      $c = $t1 + ($t2 - $t1) * 6 * $t3;
      }
    elsif ($t3 < 1/2)
      {
      $c = $t2;
      }
    elsif ($t3 < 2/3)
      {
      $c = $t1 + ($t2 - $t1) * 6 * (2/3 - $t3);
      }
    else
      {
      $c = $t1;
      }
    $c = int($c * 256); $c = 255 if $c > 255;
    push @rc, $c;
    }

  @rc;
  }

my $factors = {
  'rgb' => [ 255, 255, 255, 255 ],
  'hsv' => [ 1, 1, 1, 255 ],
  'hsl' => [ 360, 1, 1, 255 ],
  };

sub color_as_hex
  {
  # Turn "red" or rgb(255,0,0) or "#f00" into "#ff0000". Return undef for
  # invalid colors.
  my ($self,$color,$scheme) = @_;

  $scheme ||= 'w3c';
  $color = lc($color);
  # 'w3c/red' => 'w3c', 'red'
  $scheme = $1 if $color =~ s/^([a-z0-9])\///;

  # convert "red" to "ffff00"
  return $color_names->{$scheme}->{$color} 
   if exists $color_names->{$scheme}->{$color};

  # fallback to x11 scheme if color doesn't exist
  return $color_names->{x11}->{$color} 
   if exists $color_names->{x11}->{$color};

  my $qr_num = qr/\s*
	((?:[0-9]{1,3}%?) |		# 12%, 10, 2 etc
	 (?:[0-9]?\.[0-9]{1,5}) )	# .1, 0.1, 2.5 etc
    /x;

  # rgb(255,100%,1.0) => '#ffffff'
  if ($color =~ /^(rgb|hsv|hsl)\($qr_num,$qr_num,$qr_num(?:,$qr_num)?\s*\)\z/)
    {
    my $r = $2; my $g = $3; my $b = $4; my $a = $5; $a = 255 unless defined $a;
    my $format = $1;

    my $i = 0;
    for my $c ($r,$g,$b,$a)
      {
      # for the first value in HSL or HSV, use 360, otherwise 100. For RGB, use 255
      my $factor = $factors->{$format}->[$i++];

      if ($c =~ /^([0-9]+)%\z/)				# 10% => 25.5
	{
        $c = $1 * $factor / 100; 
	}
      else
	{
        $c = $1 * $factor if $c =~ /^([0-9]+\.[0-9]+)\z/;		# 0.1, 1.0
        }
      }

    ($r,$g,$b) = Graph::Easy::_hsv_to_rgb($r,$g,$b) if $format eq 'hsv';
    ($r,$g,$b) = Graph::Easy::_hsl_to_rgb($r,$g,$b) if $format eq 'hsl';

    $a = int($a); $a = 255 if $a > 255;

    # #RRGGBB or #RRGGBBAA
    $color = sprintf("#%02x%02x%02x%02x", $r,$g,$b,$a);
    }

  # turn #ff0 into #ffff00
  $color = "#$1$1$2$2$3$3" if $color =~ /^#([a-f0-9])([a-f0-9])([a-f[0-9])\z/;

  # #RRGGBBff => #RRGGBB (alpha value of 255 is the default)
  $color =~ s/^(#......)ff\z/$1/i;

  # check final color value to be #RRGGBB or #RRGGBBAA
  return undef unless $color =~ /^#([a-f0-9]{6}|[a-f0-9]{8})\z/i;

  $color;
  }

sub text_style
  {
  # check whether the given list of textstyle attributes is valid
  my ($self, $style) = @_;

  return $style if $style =~ /^(normal|none|)\z/;

  my @styles = split /\s+/, $style;
  
  return undef if grep(!/^(underline|overline|line-through|italic|bold)\z/, @styles);

  $style;
  }

sub text_styles
  {
  # return a hash with the defined textstyles checked
  my ($self) = @_;

  my $style = $self->attribute('textstyle');

  return { none => 1 } if $style =~ /^(normal|none)\z/;
  return { } if $style eq '';

  my $styles = {};
  for my $key ( split /\s+/, $style )
    {
    $styles->{$key} = 1;
    }
  $styles;
  }

sub text_styles_as_css
  {
  my ($self, $align, $fontsize) = @_;

  my $style = '';
  my $ts = $self->text_styles();

  $style .= " font-style: italic;" if $ts->{italic};
  $style .= " font-weight: bold;" if $ts->{bold};

  if ($ts->{underline} || $ts->{none} || $ts->{overline} || $ts->{'line-through'})
    {
    # XXX TODO: HTML does seem to allow only one of them
    my @s;
    foreach my $k (qw/underline overline line-through none/)
      {
      push @s, $k if $ts->{$k};
      }
    my $s = join(' ', @s);
    $style .= " text-decoration: $s;" if $s;
    }

  my $fs = $self->raw_attribute('fontsize');

  $style .= " font-size: $fs;" if $fs;

  if (!$align)
    {
    # XXX TODO: raw_attribute()?
    my $al = $self->attribute('align');
    $style .= " text-align: $al;" if $al;
    }

  $style;
  }

sub _font_size_in_pixels
  {
  my ($self, $em, $val) = @_;
  
  my $fs = $val; $fs = $self->attribute('fontsize') || '' if !defined $val;
  return $em if $fs eq '';

  if ($fs =~ /^([\d.]+)em\z/)
    {
    $fs = $1 * $em;
    }
  elsif ($fs =~ /^([\d.]+)%\z/)
    {
    $fs = ($1 / 100) * $em;
    }
  # this is discouraged:
  elsif ($fs =~ /^([\d.]+)px\z/)
    {
    $fs = int($1 || 5);
    }
  else
    {
    $self->error("Illegal fontsize '$fs'");
    }
  $fs;
  }

# direction modifier in degrees
my $modifier = {
  forward => 0, front => 0, left => -90, right => +90, back => +180,
  };

# map absolute direction to degrees
my $dirs = {
  up => 0, north => 0, down => 180, south => 180, west => 270, east => 90,
  0 => 0, 180 => 180, 90 => 90, 270 => 270,
  };

# map absolute direction to side (south etc)
my $sides = {
  north => 'north', 
  south => 'south', 
  east => 'east', 
  west => 'west', 
  up => 'north', 
  down => 'south',
  0 => 'north',
  180 => 'south',
  90 => 'east',
  270 => 'west',
  };

sub _direction_as_number
  {
  my ($self,$dir) = @_;

  my $d = $dirs->{$dir};
  $self->_croak("$dir is not an absolut direction") unless defined $d;

  $d;
  }

sub _direction_as_side
  {
  my ($self,$dir) = @_;

  return unless exists $sides->{$dir};
  $sides->{$dir};
  }

sub _flow_as_direction
  {
  # Take a flow direction (0,90,180,270 etc), and a new direction (left|south etc)
  # and return the new flow. south et al will stay, while left|right etc depend
  # on the incoming flow.
  my ($self, $inflow, $dir) = @_;

  # in=south and dir=forward => south
  # in=south and dir=back => north etc
  # in=south and dir=east => east 

#  return 90 unless defined $dir;

  if ($dir =~ /^(south|north|west|east|up|down|0|90|180|270)\z/)
    {
    # new direction is absolut, so inflow doesn't play a role
    # return 0,90,180 or 270
    return $dirs->{$dir};
    }

  my $in = $dirs->{$inflow};
  my $modifier = $modifier->{$dir};

  $self->_croak("$inflow,$dir results in undefined inflow") unless defined $in;
  $self->_croak("$inflow,$dir results in undefined modifier") unless defined $modifier;

  my $out = $in + $modifier;
  $out -= 360 while $out >= 360;	# normalize to 0..359
  $out += 360 while $out < 0;		# normalize to 0..359
  
  $out;
  }

sub _flow_as_side
  {
  # Take a flow direction (0,90,180,270 etc), and a new direction (left|south etc)
  # and return the new flow. south et al will stay, while left|right etc depend
  # on the incoming flow.
  my ($self, $inflow, $dir) = @_;

  # in=south and dir=forward => south
  # in=south and dir=back => north etc
  # in=south and dir=east => east 

#  return 90 unless defined $dir;

  if ($dir =~ /^(south|north|west|east|up|down|0|90|180|270)\z/)
    {
    # new direction is absolut, so inflow doesn't play a role
    # return east, west etc
    return $sides->{$dir};
    }

  my $in = $dirs->{$inflow};
  my $modifier = $modifier->{$dir};

  $self->_croak("$inflow,$dir results in undefined inflow") unless defined $in;
  $self->_croak("$inflow,$dir results in undefined modifier") unless defined $modifier;

  my $out = $in + $modifier;
  $out -= 360 if $out >= 360;	# normalize to 0..359
  
  $sides->{$out};
  }

sub _direction
  {
  # check that a direction (south etc) is valid
  my ($self, $dir) = @_;

  $dir =~ /^(south|east|west|north|down|up|0|90|180|270|front|forward|back|left|right)\z/ ? $dir : undef;
  }

sub _border_attribute_as_html
  {
  # Return "solid 1px red" from the individual border(style|color|width)
  # attributes, mainly for HTML output.
  my ($style, $width, $color, $scheme) = @_;

  $style ||= '';
  $width = '' unless defined $width;
  $color = '' unless defined $color;

  $color = Graph::Easy->color_as_hex($color,$scheme)||'' if $color !~ /^#/;

  return $style if $style =~ /^(none|)\z/;

  # width: 2px for double would collapse to one line
  $width = '' if $style =~ /^double/;

  # convert the style and widths to something HTML can understand

  $width = '0.5em' if $style eq 'broad';
  $width = '4px' if $style =~ /^bold/;
  $width = '1em' if $style eq 'wide';
  $style = 'solid' if $style =~ /(broad|wide|bold)\z/;
  $style = 'dashed' if $style eq 'bold-dash';
  $style = 'double' if $style eq 'double-dash';

  $width = $width.'px' if $width =~ /^\s*\d+\s*\z/;

  return '' if $width eq '' && $style ne 'double';

  my $val = join(" ", $style, $width, $color);
  $val =~ s/^\s+//;
  $val =~ s/\s+\z//;

  $val;
  }

sub _border_attribute
  {
  # Return "solid 1px red" from the individual border(style|color|width)
  # attributes. Used by as_txt().
  my ($style, $width, $color) = @_;

  $style ||= '';
  $width = '' unless defined $width;
  $color = '' unless defined $color;

  return $style if $style =~ /^(none|)\z/;

  $width = $width.'px' if $width =~ /^\s*\d+\s*\z/;

  my $val = join(" ", $style, $width, $color);
  $val =~ s/^\s+//;
  $val =~ s/\s+\z//;

  $val;
  }

sub _border_width_in_pixels
  {
  my ($self, $em) = @_;
  
  my $bw = $self->attribute('borderwidth') || '0';
  return 0 if $bw eq '0';

  my $bs = $self->attribute('borderstyle') || 'none';

  return 0 if $bs eq 'none';
  return 3 if $bs =~ /^bold/;
  return $em / 2 if $bs =~ /^broad/;
  return $em if $bs =~ /^wide/;

  # width: 1 is 1px;
  return $bw if $bw =~ /^([\d.]+)\z/;

  if ($bw =~ /^([\d.]+)em\z/)
    {
    $bw = $1 * $em;
    }
  elsif ($bw =~ /^([\d.]+)%\z/)
    {
    $bw = ($1 / 100) * $em;
    }
  # this is discouraged:
  elsif ($bw =~ /^([\d.]+)px\z/)
    {
    $bw = $1;
    }
  else
    {
    $self->error("Illegal borderwidth '$bw'");
    }
  $bw;
  }

sub _angle
  {
  # check an angle for being valid
  my ($self, $angle) = @_;

  return undef unless $angle =~ /^([+-]?\d{1,3}|south|west|east|north|up|down|left|right|front|back|forward)\z/;

  $angle;
  }

sub _uint
  {
  # check a small unsigned integer for being valid
  my ($self, $val) = @_;

  return undef unless $val =~ /^\d+\z/;

  $val = abs(int($val));
  $val = 4 * 1024 if $val > 4 * 1024;

  $val;
  }

sub _font
  {
  # check a font-list for being valid
  my ($self, $font) = @_;

  $font;
  }

sub split_border_attributes
  {
  # split "1px solid black" or "red dotted" into style, width and color
  my ($self,$border) = @_;

  # special case
  return ('none', undef, undef) if $border eq '0';

  # extract style
  my $style;
  $border =~ 
   s/(solid|dotted|dot-dot-dash|dot-dash|dashed|double-dash|double|bold-dash|bold|broad|wide|wave|none)/$style=$1;''/eg;

  $style ||= 'solid';

  # extract width
  $border =~ s/(\d+(px|em|%))//g;

  my $width = $1 || '';
  $width =~ s/[^0-9]+//g;				# leave only digits

  $border =~ s/\s+//g;					# rem unnec. spaces

  # The left-over part must be a valid color. 
  my $color = $border;
  $color = Graph::Easy->_color($border) if $border ne '';

  $self->error("$border is not a valid bordercolor")
    unless defined $color;

  $width = undef if $width eq '';
  $color = undef if $color eq '';
  $style = undef if $style eq '';
  ($style,$width,$color);
  }

#############################################################################
# attribute checking

# different types of attributes with pre-defined handling
use constant {
  ATTR_STRING	=> 0,		# an arbitrary string
  ATTR_COLOR	=> 1,		# color name or value like rgb(1,1,1)
  ATTR_ANGLE	=> 2,		# 0 .. 359.99
  ATTR_PORT	=> 3,		# east, etc.
  ATTR_UINT	=> 4,		# a "small" unsigned integer
  ATTR_URL	=> 5,

# these cannot have "inherit", see ATTR_INHERIT_MIN
  ATTR_LIST	=> 6,		# a list of values
  ATTR_LCTEXT	=> 7,		# lowercase text (classname)
  ATTR_TEXT	=> 8,		# titles, links, labels etc

  ATTR_NO_INHERIT	=> 6,

  ATTR_DESC_SLOT	=> 0,
  ATTR_MATCH_SLOT	=> 1,
  ATTR_DEFAULT_SLOT	=> 2,
  ATTR_EXAMPLE_SLOT	=> 3,
  ATTR_TYPE_SLOT	=> 4,


  };

# Lists the attribute names along with
#   * a short description, 
#   * regexp or sub name to match valid attributes
#   * default value
#   * an short example value
#   * type
#   * graph examples

my $attributes = {
  all => {
    align => [
     "The alignment of the label text.",
     [ qw/center left right/ ],
     { default => 'center', group => 'left', edge => 'left' },
     'right',
     undef,
     "graph { align: left; label: My Graph; }\nnode {align: left;}\n ( Nodes:\n [ Right\\nAligned ] { align: right; } -- label\\n text -->\n { align: left; }\n [ Left\\naligned ] )",
     ],

    autolink => [
     "If set to something else than 'none', will use the appropriate attribute to automatically generate the L<link>, unless L<link> is already set. See the section about labels, titles, names and links for reference.",
     [ qw/label title name none inherit/ ],
     { default => 'inherit', graph => 'none' },
     'title',
     ],

    autotitle => [
     "If set to something else than 'none', will use the appropriate attribute to automatically generate the L<title>, unless L<title> is already set. See the section about labels, titles, names and links for reference.",
     [ qw/label name none link inherit/ ],
     { default => 'inherit', graph => 'none' },
     'label',
     ],

    autolabel => [
     "Will restrict the L<label> text to N characters. N must be greater than 10. See the section about labels, titles, names and links for reference.",
     # for compatibility with older versions (pre v0.49), also allow "name,N"
     qr/^(name\s*,\s*)?[\d]{2,5}\z/,
     { default => 'inherit', graph => '' },
     '20',
     undef,
     "graph { autolabel: 20; autotitle: name; }\n\n[ Bonn ]\n -- Acme Travels Incorporated -->\n  [ Frankfurt (Main) / Flughafen ]",
     ],

    background => [
     "The background color, e.g. the color B<outside> the shape. Do not confuse with L<fill>. If set to inherit, the object will inherit the L<fill> color (B<not> the background color!) of the parent e.g. the enclosing group or graph. See the section about color names and values for reference.",
     undef,
#     { default => 'inherit', graph => 'white', 'group.anon' => 'white', 'node.anon' => 'white' },
     'inherit',
     'rgb(255,0,0)',
     ATTR_COLOR,
     "[ Crimson ] { shape: circle; background: crimson; }\n -- Aqua Marine --> { background: #7fffd4; }\n [ Misty Rose ]\n  { background: white; fill: rgb(255,228,221); shape: ellipse; }",
     ],

    class => [
     'The subclass of the object. See the section about class names for reference.',
      qr/^(|[a-zA-Z][a-zA-Z0-9_]*)\z/,
     '',
     'mynodeclass',
     ATTR_LCTEXT,
     ],

    color => [
     'The foreground/text/label color. See the section about color names and values for reference.',
     undef,
     'black',
     'rgb(255,255,0)',
     ATTR_COLOR,
     "[ Lime ] { color: limegreen; }\n -- label --> { color: blue; labelcolor: red; }\n [ Dark Orange ] { color: rgb(255,50%,0.01); }",
     ],

    colorscheme => [
     "The colorscheme to use for all color values. See the section about color names and values for reference and a list of possible values.",
     '_color_scheme',
     { default => 'inherit', graph => 'w3c', },
     'x11',
     ATTR_STRING,
     "graph { colorscheme: accent8; } [ 1 ] { fill: 1; }\n"
        . " -> \n [ 3 ] { fill: 3; }\n" 
        . " -> \n [ 4 ] { fill: 4; }\n" 
        . " -> \n [ 5 ] { fill: 5; }\n" 
        . " -> \n [ 6 ] { fill: 6; }\n" 
        . " -> \n [ 7 ] { fill: 7; }\n" 
        . " -> \n [ 8 ] { fill: 8; }\n" ,
     ],

    comment => [
	"A free-form text field containing a comment on this object. This will be embedded into output formats if possible, e.g. in HTML, SVG and Graphviz, but not ASCII or Boxart.",
	undef,
	'',
	'(C) by Tels 2007. All rights reserved.',
	ATTR_STRING,
	"graph { comment: German capitals; }\n [ Bonn ] --> [ Berlin ]",
    ],

    fill => [
     "The fill color, e.g. the color inside the shape. For the graph, this is the background color for the label. For edges, defines the color inside the arrow shape. See also L<background>. See the section about color names and values for reference.",
     undef,
     { default => 'white', graph => 'inherit', edge => 'inherit', group => '#a0d0ff', 
	'group.anon' => 'white', 'node.anon' => 'inherit' },
     'rgb(255,0,0)',
     ATTR_COLOR,
     "[ Crimson ]\n  {\n  shape: circle;\n  background: yellow;\n  fill: red;\n  border: 3px solid blue;\n  }\n-- Aqua Marine -->\n  {\n  arrowstyle: filled;\n  fill: red;\n  }\n[ Two ]",
     ],

    'fontsize' => [
     "The size of the label text, best expressed in I<em> (1.0em, 0.5em etc) or percent (100%, 50% etc)",
     qr/^\d+(\.\d+)?(em|px|%)?\z/,
     { default => '0.8em', graph => '1em', node => '1em', },
     '50%',
     undef,
     "graph { fontsize: 200%; label: Sample; }\n\n ( Nodes:\n [ Big ] { fontsize: 1.5em; color: white; fill: darkred; }\n  -- Small -->\n { fontsize: 0.2em; }\n  [ Normal ] )",
     ],

    flow => [
     "The general direction in which edges will leave nodes first. On edges, influeces where the target node is place. Please see the section about <a href='hinting.html#flow'>flow control</a> for reference.",
     '_direction',
     { graph => 'east', default => 'inherit' },
     'south',
      undef,
      "graph { flow: up; }\n [ Enschede ] { flow: left; } -> [ Bielefeld ] -> [ Wolfsburg ]",
     ],

    font => [
     'A prioritized list of lower-case, unquoted values, separated by a comma. Values are either font family names (like "times", "arial" etc) or generic family names (like "serif", "cursive", "monospace"), the first recognized value will be used. Always offer a generic name as the last possibility.',
     '_font',
     { default => 'serif', edge => 'sans-serif' },
     'arial, helvetica, sans-serif',
     undef,
     "graph { font: vinque, georgia, utopia, serif; label: Sample; }" .
     "\n\n ( Nodes:\n [ Webdings ] { font: Dingbats, webdings; }\n".
     " -- FlatLine -->\n { font: flatline; }\n  [ Normal ] )",
     ],

    id => [
     "A unique identifier for this object, consisting only of letters, digits, or underscores.",
     qr/^[a-zA-Z0-9_]+\z/,
     '',
     'Bonn123',
     undef,
     "[ Bonn ] --> { id: 123; } [ Berlin ]",
     ],

    label => [
     "The text displayed as label. If not set, equals the name (for nodes) or no label (for edges, groups and the graph itself).",
     undef,
     undef,
     'My label',
     ATTR_TEXT,
     ],

    linkbase => [
     'The base URL prepended to all generated links. See the section about links for reference.',
     undef,
     { default => 'inherit', graph => '/wiki/index.php/', },
     'http://en.wikipedia.org/wiki/',
     ATTR_URL,
     ],

    link => [
     'The link part, appended onto L<linkbase>. See the section about links for reference.',
     undef,
     '',
     'Graph',
     ATTR_TEXT,
     <<LINK_EOF
node {
  autolink: name;
  textstyle: none;
  fontsize: 1.1em;
  }
graph {
  linkbase: http://de.wikipedia.org/wiki/;
  }
edge {
  textstyle: overline;
  }

[] --> [ Friedrichshafen ]
 -- Schiff --> { autolink: label; color: orange; title: Vrooom!; }
[ Immenstaad ] { color: green; } --> [ Hagnau ]
LINK_EOF
     ],

    title => [
     "The text displayed as mouse-over for nodes/edges, or as the title for the graph. If empty, no title will be generated unless L<autotitle> is set.",
     undef,
     '',
     'My title',
     ATTR_TEXT,
     ],

    format => [
     "The formatting language of the label. The default, C<none> means nothing special will be done. When set to C<pod>, formatting codes like <code>B&lt;bold&gt;</code> will change the formatting of the label. See the section about label text formatting for reference.",
     [ 'none', 'pod' ],
     'none',
     'pod',
     undef,
     <<EOF
graph {
  format: pod;
  label: I am B<bold> and I<italic>;
  }
node { format: pod; }
edge { format: pod; }

[ U<B<bold and underlined>> ]
--> { label: "S<Fähre>"; }
 [ O<Konstanz> ]
EOF
     ],

    textstyle => [
     "The style of the label text. Either 'none', or any combination (separated with spaces) of 'underline', 'overline', 'bold', 'italic', 'line-through'. 'none' disables underlines on links.",
     'text_style',
     '',
     'underline italic bold',
     undef,
     <<EOF
graph {
  fontsize: 150%;
  label: Verbindung;
  textstyle: bold italic;
  }
node {
  textstyle: underline bold;
  fill: #ffd080;
  }
edge {
  textstyle: italic bold overline;
  }

[ Meersburg ] { fontsize: 2em; }
 -- F\x{e4}hre --> { fontsize: 1.2em; color: red; }
 [ Konstanz ]
EOF
     ],

    textwrap => [
     "The default C<none> makes the label text appear exactly as it was written, with <a href='syntax.html'>manual line breaks</a> applied. When set to a positive number, the label text will be wrapped after this number of characters. When set to C<auto>, the label text will be wrapped to make the node size as small as possible, depending on output format this may even be dynamic. When not C<none>, manual line breaks and alignments on them are ignored.",
     qr/^(auto|none|\d{1,4})/,
     { default => 'inherit', graph => 'none' },
     'auto',
     undef,
     "node { textwrap: auto; }\n ( Nodes:\n [ Frankfurt (Oder) liegt an der\n   ostdeutschen Grenze und an der Oder ] -->\n [ Städte innerhalb der\n   Ost-Westfahlen Region mit sehr langen Namen] )",
     ],
   },

  node => {
    bordercolor => [
     'The color of the L<border>. See the section about color names and values for reference.',
     undef,
     { default => '#000000' },
     'rgb(255,255,0)',
     ATTR_COLOR,
     "node { border: black bold; }\n[ Black ]\n --> [ Red ]      { bordercolor: red; }\n --> [ Green ]    { bordercolor: green; }",
     ],

    borderstyle => [
     'The style of the L<border>. The special styles "bold", "broad", "wide", "double-dash" and "bold-dash" will set and override the L<borderwidth>.',
     [ qw/none solid dotted dashed dot-dash dot-dot-dash double wave bold bold-dash broad double-dash wide/ ],
     { default => 'none', 'node.anon' => 'none', 'group.anon' => 'none', node => 'solid', group => 'dashed' },
     'dotted',
     undef,
     "node { border: dotted; }\n[ Dotted ]\n --> [ Dashed ]      { borderstyle: dashed; }\n --> [ broad ]    { borderstyle: broad; }",
     ],

    borderwidth => [
     'The width of the L<border>. Certain L<border>-styles will override the width.',
     qr/^\d+(px|em)?\z/,
     '1',
     '2px',
     ],

    border => [
     'The border. Can be any combination of L<borderstyle>, L<bordercolor> and L<borderwidth>.',
     undef,
     { default => 'none', 'node.anon' => 'none', 'group.anon' => 'none', node => 'solid 1px #000000', group => 'dashed 1px #000000' },
     'dotted red',
     undef,
     "[ Normal ]\n --> [ Bold ]      { border: bold; }\n --> [ Broad ]     { border: broad; }\n --> [ Wide ]      { border: wide; }\n --> [ Bold-Dash ] { border: bold-dash; }",
     ],

    basename => [
     "Controls the base name of an autosplit node. Ignored for all other nodes. Unless set, it is generated automatically from the node parts. Please see the section about <a href='hinting.html#autosplit'>autosplit</a> for reference.",
     undef,
      '',
      '123',
       undef,
     "[ A|B|C ] { basename: A } [ 1 ] -> [ A.2 ]\n [ A|B|C ] [ 2 ] -> [ ABC.2 ]",
     ], 

    group => [
     "Puts the node into this group.",
     undef,
      '',
      'Cities',
       undef,
     "[ A ] { group: Cities:; } ( Cities: [ B ] ) [ A ] --> [ B ]",
     ], 

    size => [
     'The size of the node in columns and rows. Must be greater than 1 in each direction.',
     qr/^\d+\s*,\s*\d+\z/,
     '1,1',
     '3,2',
     ],
    rows => [
     'The size of the node in rows. See also L<size>.',
     qr/^\d+\z/,
     '1',
     '3',
     ],
    columns => [
     'The size of the node in columns. See also L<size>.',
     qr/^\d+\z/,
     '1',
     '2',
     ],

    offset => [
     'The offset of this node from the L<origin> node, in columns and rows. Only used if you also set the L<origin> node.',
     qr/^[+-]?\d+\s*,\s*[+-]?\d+\z/,
     '0,0',
     '3,2',
     undef,
     "[ A ] -> [ B ] { origin: A; offset: 2,2; }",
     ],

    origin => [
     'The name of the node, that this node is relativ to. See also L<offset>.',
     undef,
     '',
     'Cluster A',
     ],

    pointshape => [
     "Controls the style of a node that has a L<shape> of 'point'.",
     [ qw/star square dot circle cross diamond invisible x/ ],
      'star',
      'square',
      undef,
     "node { shape: point; }\n\n [ A ]".
     "\n -> [ B ] { pointshape: circle; }" .
     "\n -> [ C ] { pointshape: cross; }" . 
     "\n -> [ D ] { pointshape: diamond; }" . 
     "\n -> [ E ] { pointshape: dot; }" . 
     "\n -> [ F ] { pointshape: invisible; }" . 
     "\n -> [ G ] { pointshape: square; }" . 
     "\n -> [ H ] { pointshape: star; }" .
     "\n -> [ I ] { pointshape: x; }" .
     "\n -> [ ☯ ] { shape: none; }"
     ], 

    pointstyle => [
     "Controls the style of the L<pointshape> of a node that has a L<shape> of 'point'. " .
     "Note for backwards compatibility reasons, the shape names 'star', 'square', 'dot', 'circle', 'cross', 'diamond' and 'invisible' ".
     "are also supported, but should not be used here, instead set them via L<pointshape>.",
     [ qw/closed filled star square dot circle cross diamond invisible x/ ],
      'filled',
      'open',
      undef,
     "node { shape: point; pointstyle: closed; pointshape: diamond; }\n\n [ A ] --> [ B ] { pointstyle: filled; }",
     ], 

    rank => [
     "The rank of the node, used by the layouter to find the order and placement of nodes. " .
     "Set to C<auto> (the default), C<same> (usefull for node lists) or a positive number. " .
     "See the section about ranks for reference and more examples.",
       qr/^(auto|same|\d{1,6})\z/,
       'auto',
       'same',
       undef,
     "[ Bonn ], [ Berlin ] { rank: same; }\n [ Bonn ] -> [ Cottbus ] -> [ Berlin ]",
     ],

    rotate => [
     "The rotation of the node shape, either an absolute value (like C<south>, C<up>, C<down> or C<123>), or a relative value (like C<+12>, C<-90>, C<left>, C<right>). For relative angles, the rotation will be based on the node's L<flow>. Rotation is clockwise.",
       undef,
       '0',
       '180',
       ATTR_ANGLE,
     "[ Bonn ] { rotate: 45; } -- ICE --> \n [ Berlin ] { shape: triangle; rotate: -90; }",
     ],

    shape => [
     "The shape of the node. Nodes with shape 'point' (see L<pointshape>) have a fixed size and do not display their label. The border of such a node is the outline of the C<pointshape>, and the fill is the inside of the C<pointshape>. When the C<shape> is set to the value 'img', the L<label> will be interpreted as an external image resource to display. In this case attributes like L<color>, L<fontsize> etc. are ignored.",
       [ qw/ circle diamond edge ellipse hexagon house invisible invhouse invtrapezium invtriangle octagon parallelogram pentagon
             point triangle trapezium septagon rect rounded none img/ ],
      'rect',
      'circle',
      undef,
      "[ Bonn ] -> \n [ Berlin ] { shape: circle; }\n -> [ Regensburg ] { shape: rounded; }\n -> [ Ulm ] { shape: point; }\n -> [ Wasserburg ] { shape: invisible; }\n -> [ Augsburg ] { shape: triangle; }\n -> [ House ] { shape: img; label: img/house.png;\n          border: none; title: My House; fill: inherit; }",
     ],

  }, # node

  graph => {

    bordercolor => [
     'The color of the L<border>. See the section about color names and values for reference.',
     undef,
     { default => '#000000' },
     'rgb(255,255,0)',
     ATTR_COLOR,
     "node { border: black bold; }\n[ Black ]\n --> [ Red ]      { bordercolor: red; }\n --> [ Green ]    { bordercolor: green; }",
     ],

    borderstyle => [
     'The style of the L<border>. The special styles "bold", "broad", "wide", "double-dash" and "bold-dash" will set and override the L<borderwidth>.',
     [ qw/none solid dotted dashed dot-dash dot-dot-dash double wave bold bold-dash broad double-dash wide/ ],
     { default => 'none', 'node.anon' => 'none', 'group.anon' => 'none', node => 'solid', group => 'dashed' },
     'dotted',
     undef,
     "node { border: dotted; }\n[ Dotted ]\n --> [ Dashed ]      { borderstyle: dashed; }\n --> [ broad ]    { borderstyle: broad; }",
     ],

    borderwidth => [
     'The width of the L<border>. Certain L<border>-styles will override the width.',
     qr/^\d+(px|em)?\z/,
     '1',
     '2px',
     ],

    border => [
     'The border. Can be any combination of L<borderstyle>, L<bordercolor> and L<borderwidth>.',
     undef,
     { default => 'none', 'node.anon' => 'none', 'group.anon' => 'none', node => 'solid 1px #000000', group => 'dashed 1px #000000' },
     'dotted red',
     undef,
     "[ Normal ]\n --> [ Bold ]      { border: bold; }\n --> [ Broad ]     { border: broad; }\n --> [ Wide ]      { border: wide; }\n --> [ Bold-Dash ] { border: bold-dash; }",
     ],

    gid => [
	"A unique ID for the graph. Usefull if you want to include two graphs into one HTML page.",
	qr/^\d+\z/,
	'',
	'123',
     ],

    labelpos => [
	"The position of the graph label.",
	[ qw/top bottom/ ],
	'top',
	'bottom',
	ATTR_LIST,
        "graph { labelpos: bottom; label: My Graph; }\n\n [ Buxtehude ] -> [ Fuchsberg ]\n"
     ],

    output => [
	"The desired output format. Only used when calling Graph::Easy::output(), or by mediawiki-graph.",
	[ qw/ascii html svg graphviz boxart debug/ ],
	'',
	'ascii',
	ATTR_LIST,
        "graph { output: debug; }"
     ],

    root => [
	"The name of the root node, given as hint to the layouter to start the layout there. When not set, the layouter will pick a node at semi-random.",
	undef,
	'',
	'My Node',
	ATTR_TEXT,
	"graph { root: B; }\n # B will be at the left-most place\n [ A ] --> [ B ] --> [ C ] --> [ D ] --> [ A ]",
     ],

    type => [
	"The type of the graph, either undirected or directed.",
	[ qw/directed undirected/ ],
	'directed',
	'undirected',
	ATTR_LIST,
	"graph { type: undirected; }\n [ A ] --> [ B ]",
     ],

  }, # graph

  edge => {

    style => [
      'The line style of the edge. When set on the general edge class, this attribute changes only the style of all solid edges to the specified one.',
      [ qw/solid dotted dashed dot-dash dot-dot-dash bold bold-dash double-dash double wave broad wide invisible/], # broad-dash wide-dash/ ],
      'solid',
      'dotted',
      undef,
      "[ A ] -- solid --> [ B ]\n .. dotted ..> [ C ]\n -  dashed - > [ D ]\n -- bold --> { style: bold; } [ E ]\n -- broad --> { style: broad; } [ F ]\n -- wide --> { style: wide; } [ G ]",
     ],

    arrowstyle => [
      'The style of the arrow. Open arrows are vee-shaped and the bit inside the arrow has the color of the L<background>. Closed arrows are triangle shaped, with a background-color fill. Filled arrows are closed, too, but use the L<fill> color for the inside. If the fill color is not set, the L<color> attribute will be used instead. An C<arrowstyle> of none creates undirected edges just like "[A] -- [B]" would do.',
      [ qw/none open closed filled/ ],
      'open',
      'closed',
      undef,
      "[ A ] -- open --> [ B ]\n -- closed --> { arrowstyle: closed; } [ C ]\n -- filled --> { arrowstyle: filled; } [ D ]\n -- filled --> { arrowstyle: filled; fill: lime; } [ E ]\n -- none --> { arrowstyle: none; } [ F ]",
     ],

    arrowshape => [
      'The basic shape of the arrow. Can be combined with each of L<arrowstyle>.',
      [ qw/triangle box dot inv line diamond cross x/ ],
      'triangle',
      'box',
      undef,
      "[ A ] -- triangle --> [ B ]\n -- box --> { arrowshape: box; } [ C ]\n" .
      " -- inv --> { arrowshape: inv; } [ D ]\n -- diamond --> { arrowshape: diamond; } [ E ]\n" .
      " -- dot --> { arrowshape: dot; } [ F ]\n" .
      " -- line --> { arrowshape: line; } [ G ] \n" .
      " -- plus --> { arrowshape: cross; } [ H ] \n" .
      " -- x --> { arrowshape: x; } [ I ] \n\n" .
      "[ a ] -- triangle --> { arrowstyle: filled; } [ b ]\n".
      " -- box --> { arrowshape: box; arrowstyle: filled; } [ c ]\n" .
      " -- inv --> { arrowshape: inv; arrowstyle: filled; } [ d ]\n" .
      " -- diamond --> { arrowshape: diamond; arrowstyle: filled; } [ e ]\n" .
      " -- dot --> { arrowshape: dot; arrowstyle: filled; } [ f ]\n" .
      " -- line --> { arrowshape: line; arrowstyle: filled; } [ g ] \n" .
      " -- plus --> { arrowshape: cross; arrowstyle: filled; } [ h ] \n" .
      " -- x --> { arrowshape: x; arrowstyle: filled; } [ i ] \n",
     ],

    labelcolor => [
     'The text color for the label. If unspecified, will fall back to L<color>. See the section about color names and values for reference.',
     undef,
     'black',
     'rgb(255,255,0)',
     ATTR_COLOR,
     "[ Bonn ] -- ICE --> { labelcolor: blue; }\n [ Berlin ]",
     ],

    start => [
     'The starting port of this edge. See <a href="hinting.html#joints">the section about joints</a> for reference.',
     qr/^(south|north|east|west|left|right|front|back)(\s*,\s*-?\d{1,4})?\z/,
     '',
     'front, 0',
     ATTR_PORT,
     "[ Bonn ] -- NORTH --> { start: north; end: north; } [ Berlin ]",
     ],

    end => [
     'The ending port of this edge. See <a href="hinting.html#joints">the section about joints</a> for reference.',
     qr/^(south|north|east|west|right|left|front|back)(\s*,\s*-?\d{1,4})?\z/,
     '',
     'back, 0',
     ATTR_PORT,
     "[ Bonn ] -- NORTH --> { start: south; end: east; } [ Berlin ]",
     ],

    minlen => [
     'The minimum length of the edge, in cells. Defaults to 1. The minimum length is ' .
     'automatically increased for edges with joints.',
     undef,
     '1',
     '4',
     ATTR_UINT,
     "[ Bonn ] -- longer --> { minlen: 3; } [ Berlin ]\n[ Bonn ] --> [ Potsdam ] { origin: Bonn; offset: 2,2; }",
     ],

    autojoin => [
     'Controls whether the layouter can join this edge automatically with other edges leading to the same node. C<never> means this edge will never joined with another edge automatically, C<always> means always (if possible), even if the attributes on the edges do not match. C<equals> means only edges with the same set of attributes will be automatically joined together. See also C<autosplit>.',
     [qw/never always equals/],
     'never',
     'always',
     undef,
     "[ Bonn ], [ Aachen ]\n -- 1 --> { autojoin: equals; } [ Berlin ]",
     ],

    autosplit => [
     'Controls whether the layouter replace multiple edges leading from one node to other nodes with one edge splitting up. C<never> means this edge will never be part of such a split, C<always> means always (if possible), even if the attributes on the edges do not match. C<equals> means only edges with the same set of attributes will be automatically split up. See also C<autojoin>.',
     [qw/never always equals/],
     'never',
     'always',
     undef,
     "[ Bonn ]\n -- 1 --> { autosplit: equals; } [ Berlin ], [ Aachen ]",
     ],

   }, # edge

  group => {
    bordercolor => [
     'The color of the L<border>. See the section about color names and values for reference.',
     undef,
     { default => '#000000' },
     'rgb(255,255,0)',
     ATTR_COLOR,
     "node { border: black bold; }\n[ Black ]\n --> [ Red ]      { bordercolor: red; }\n --> [ Green ]    { bordercolor: green; }",
     ],

    borderstyle => [
     'The style of the L<border>. The special styles "bold", "broad", "wide", "double-dash" and "bold-dash" will set and override the L<borderwidth>.',
     [ qw/none solid dotted dashed dot-dash dot-dot-dash double wave bold bold-dash broad double-dash wide/ ],
     { default => 'none', 'node.anon' => 'none', 'group.anon' => 'none', node => 'solid', group => 'dashed' },
     'dotted',
     undef,
     "node { border: dotted; }\n[ Dotted ]\n --> [ Dashed ]      { borderstyle: dashed; }\n --> [ broad ]    { borderstyle: broad; }",
     ],

    borderwidth => [
     'The width of the L<border>. Certain L<border>-styles will override the width.',
     qr/^\d+(px|em)?\z/,
     '1',
     '2px',
     ],

    border => [
     'The border. Can be any combination of L<borderstyle>, L<bordercolor> and L<borderwidth>.',
     undef,
     { default => 'none', 'node.anon' => 'none', 'group.anon' => 'none', node => 'solid 1px #000000', group => 'dashed 1px #000000' },
     'dotted red',
     undef,
     "[ Normal ]\n --> [ Bold ]      { border: bold; }\n --> [ Broad ]     { border: broad; }\n --> [ Wide ]      { border: wide; }\n --> [ Bold-Dash ] { border: bold-dash; }",
     ],

    nodeclass => [
      'The class into which all nodes of this group are put.',
      qr/^(|[a-zA-Z][a-zA-Z0-9_]*)\z/,
      '',
      'cities',
     ],

    edgeclass => [
      'The class into which all edges defined in this group are put. This includes edges that run between two nodes belonging to the same group.',
      qr/^(|[a-zA-Z][a-zA-Z0-9_]*)\z/,
      '',
      'connections',
     ],

    rank => [
     "The rank of the group, used by the layouter to find the order and placement of group. " .
     "Set to C<auto> (the default), C<same> or a positive number. " .
     "See the section about ranks for reference and more examples.",
       qr/^(auto|same|\d{1,6})\z/,
       'auto',
       'same',
       undef,
     "( Cities: [ Bonn ], [ Berlin ] ) { rank: 0; } ( Rivers: [ Rhein ], [ Sieg ] ) { rank: 0; }",
     ],

    root => [
	"The name of the root node, given as hint to the layouter to start the layout there. When not set, the layouter will pick a node at semi-random.",
	undef,
	'',
	'My Node',
	ATTR_TEXT,
	"( Cities: [ A ] --> [ B ] --> [ C ] --> [ D ] --> [ A ] ) { root: B; }",
     ],

    group => [
     "Puts the group inside this group, nesting the two groups inside each other.",
     undef,
      '',
      'Cities',
       undef,
     "( Cities: [ Bonn ] ) ( Rivers: [ Rhein ] ) { group: Cities:; }",
     ], 

    labelpos => [
	"The position of the group label.",
	[ qw/top bottom/ ],
	'top',
	'bottom',
	ATTR_LIST,
        "group { labelpos: bottom; }\n\n ( My Group: [ Buxtehude ] -> [ Fuchsberg ] )\n"
     ],

   }, # group

  # These entries will be allowed temporarily during Graphviz parsing for
  # intermidiate values, like "shape=record".
  special => { },
  }; # end of attribute definitions

sub _allow_special_attributes
  {
  # store a hash with special temp. attributes
  my ($self, $att) = @_;
  $attributes->{special} = $att;
  }

sub _drop_special_attributes
  {
  # drop the hash with special temp. attributes
  my ($self) = @_;

  $attributes->{special} = {};
  }

sub _attribute_entries
  {
  # for building the manual page
  $attributes;
  }

sub border_attribute
  {
  # Return "1px solid red" from the border-(style|color|width) attributes,
  # mainly used by as_txt() output. Does not use colorscheme!
  my ($self, $class) = @_;

  my ($style,$width,$color);

  my $g = $self; $g = $self->{graph} if ref($self->{graph});

  my ($def_style, $def_color, $def_width);

  # XXX TODO need no_default_attribute()
  if (defined $class)
    {
    $style = $g->attribute($class, 'borderstyle');
    return $style if $style eq 'none';

    $def_style = $g->default_attribute('borderstyle');

    $width = $g->attribute($class,'borderwidth');
    $def_width = $g->default_attribute($class,'borderwidth');
    $width = '' if $def_width eq $width;

    $color = $g->attribute($class,'bordercolor');
    $def_color = $g->default_attribute($class,'bordercolor');
    $color = '' if $def_color eq $color;
    }
  else 
    {
    $style = $self->attribute('borderstyle');
    return $style if $style eq 'none';

    $def_style = $self->default_attribute('borderstyle');

    $width = $self->attribute('borderwidth');
    $def_width = $self->default_attribute('borderwidth');
    $width = '' if $def_width eq $width;

    $color = $self->attribute('bordercolor');
    $def_color = $self->default_attribute('bordercolor');
    $color = '' if $def_color eq $color;
    }

  return '' if $def_style eq $style and $color eq '' && $width eq '';

  Graph::Easy::_border_attribute($style, $width, $color);
  }

sub _unknown_attribute
  {
  # either just warn, or raise an error for unknown attributes
  my ($self, $name, $class) = @_;

  if ($self->{_warn_on_unknown_attributes})
    {
    $self->warn("Ignoring unknown attribute '$name' for class $class") 
    }
  else
    {
    $self->error("Error in attribute: '$name' is not a valid attribute name for a $class");
    }
  return;
  }

sub default_attribute
  {
  # Return the default value for the attribute.
  my ($self, $class, $name) = @_;

  # allow $self->default_attribute('fill');
  if (scalar @_ == 2)
    {
    $name = $class;
    $class = $self->{class} || 'graph';
    }

  # get the base class: node.foo => node
  my $base_class = $class; $base_class =~ s/\..*//;

  # Remap alias names without "-" to their hyphenated version:
  $name = $att_aliases->{$name} if exists $att_aliases->{$name};

  # "x-foo-bar" is a custom attribute, so allow it always. The name must
  # consist only of letters and hyphens, and end in a letter or number.
  # Hyphens must be separated by letters. Custom attributes do not have a default.
  return '' if $name =~ $qr_custom_attribute;

  # prevent ->{special}->{node} from springing into existance
  my $s = $attributes->{special}; $s = $s->{$class} if exists $s->{$class};

  my $entry =	$s->{$name} ||
		$attributes->{all}->{$name} ||
		$attributes->{$base_class}->{$name};

  # Didn't found an entry:
  return $self->_unknown_attribute($name,$class) unless ref($entry);

  # get the default attribute from the entry
  my $def = $entry->[ ATTR_DEFAULT_SLOT ]; my $val = $def;

  # "node.subclass" gets the default from "node", 'edge' from 'default':
  # " { default => 'foo', 'node.anon' => 'none', node => 'solid' }":
  if (ref $def)
    {
    $val = $def->{$class};
    $val = $def->{$base_class} unless defined $val;
    $val = $def->{default} unless defined $val;
    }

  $val;
  }

sub raw_attribute
  {
  # Return either the raw attribute set on an object (honoring inheritance),
  # or undef for when that specific attribute is not set. Does *not*
  # inspect class attributes.
  my ($self, $name) = @_;

  # Remap alias names without "-" to their hyphenated version:
  $name = $att_aliases->{$name} if exists $att_aliases->{$name};

  my $class = $self->{class} || 'graph';
  my $base_class = $class; $base_class =~ s/\..*//;

  # prevent ->{special}->{node} from springing into existance
  my $s = $attributes->{special}; $s = $s->{$class} if exists $s->{$class};

  my $entry =	$s->{$name} ||
		$attributes->{all}->{$name} ||
		$attributes->{$base_class}->{$name};

  # create a fake entry for custom attributes
  $entry = [ '', undef, '', '', ATTR_STRING, '' ]
    if $name =~ $qr_custom_attribute;

  # Didn't found an entry:
  return $self->_unknown_attribute($name,$class) unless ref($entry);

  my $type = $entry->[ ATTR_TYPE_SLOT ] || ATTR_STRING;

  my $val;

  ###########################################################################
  # Check the object directly first
  my $a = $self->{att};
  if (exists $a->{graph})
    {
    # for graphs, look directly in the class to save time:
    $val = $a->{graph}->{$name} 
	if exists $a->{graph}->{$name};
    }
  else
    {
    $val = $a->{$name} if exists $a->{$name};
    }

  # For "background", and objects that are in a group, we inherit "fill":
  $val = $self->{group}->color_attribute('fill')
    if $name eq 'background' && ref $self->{group};

  return $val if !defined $val || $val ne 'inherit' ||
    $name =~ /^x-([a-z_]+-)*[a-z_]+([0-9]*)\z/;

  # $val is defined, and "inherit" (and it is not a special attribute)

  # for graphs, there is nothing to inherit from
  return $val if $class eq 'graph';

  # we try classes in this order:
  # "node", "graph"

  my @tries = ();
  # if the class is already "node", skip it:
  if ($class =~ /\./)
    {
    my $parent_class = $class; $parent_class =~ s/\..*//;
    push @tries, $parent_class;
    }

  # If not part of a graph, we cannot have class attributes, but
  # we still can find default attributes. So fake a "graph":
  my $g = $self->{graph}; 			# for objects in a graph
  $g = { att => {} } unless ref($g);		# for objects not in a graph

  $val = undef;
  for my $try (@tries)
    {
#    print STDERR "# Trying class $try for attribute $name\n";

    my $att = $g->{att}->{$try};

    $val = $att->{$name} if exists $att->{$name};

    # value was not defined, so get the default value
    if (!defined $val)
      {
      my $def = $entry->[ ATTR_DEFAULT_SLOT ]; $val = $def;

      # "node.subclass" gets the default from "node", 'edge' from 'default':
      # " { default => 'foo', 'node.anon' => 'none', node => 'solid' }":
      if (ref $def)
	{
	$val = $def->{$try};
        if (!defined $val && $try =~ /\./)
	  {
	  my $base = $try; $base =~ s/\..*//;
	  $val = $def->{$base};
	  }
	$val = $def->{default} unless defined $val;
	}
      }
    # $val must now be defined, because default value must exist.

#    print STDERR "# Found '$val' for $try\n";

    if ($name ne 'label')
      {
      $self->warn("Uninitialized default for attribute '$name' on class '$try'\n")
        unless defined $val;
      }

    return $val if $type >= ATTR_NO_INHERIT;

    # got some value other than inherit or already at top of tree:
    return $val if defined $val && $val ne 'inherit';
  
    # try next class in inheritance tree
    $val = undef;
    }

  $val;
  }

sub color_attribute
  {
  # Just like get_attribute(), but for colors, and returns them as hex,
  # using the current colorscheme.
  my $self = shift;

  my $color = $self->attribute(@_);

  if ($color !~ /^#/ && $color ne '')
    {
    my $scheme = $self->attribute('colorscheme');
    $color = Graph::Easy->color_as_hex($color, $scheme);
    }

  $color;
  }

sub raw_color_attribute
  {
  # Just like raw_attribute(), but for colors, and returns them as hex,
  # using the current colorscheme.
  my $self = shift;

  my $color = $self->raw_attribute(@_);
  return undef unless defined $color;		# default to undef

  if ($color !~ /^#/ && $color ne '')
    {
    my $scheme = $self->attribute('colorscheme');
    $color = Graph::Easy->color_as_hex($color, $scheme);
    }

  $color;
  }

sub _attribute_entry
  {
  # return the entry defining an attribute, based on the attribute name
  my ($self, $class, $name) = @_;

  # font-size => fontsize
  $name = $att_aliases->{$name} if exists $att_aliases->{$name};

  my $base_class = $class; $base_class =~ s/\.(.*)//;

  # prevent ->{special}->{node} from springing into existance
  my $s = $attributes->{special}; $s = $s->{$class} if exists $s->{$class};
  my $entry =	$s->{$name} ||
		$attributes->{all}->{$name} ||
		$attributes->{$base_class}->{$name};

  $entry;
  }

sub attribute
  {
  my ($self, $class, $name) = @_;

  my $three_arg = 0;
  if (scalar @_ == 3)
    {
    # $self->attribute($class,$name) if only allowed on graphs
    return $self->error("Calling $self->attribute($class,$name) only allowed for graphs") 
      if exists $self->{graph};
  
   if ($class !~ /^(node|group|edge|graph\z)/)
      {
      return $self->error ("Illegal class '$class' when trying to get attribute '$name'");
      }
    $three_arg = 1;
    return $self->border_attribute($class) if $name eq 'border'; # virtual attribute
    }
  else
    {
    # allow calls of the style get_attribute('background');
    $name = $class;
    $class = $self->{class} || 'graph' if $name eq 'class';	# avoid deep recursion
    if ($name ne 'class')
      {
      $class = $self->{cache}->{class};
      $class = $self->class() unless defined $class;
      }

    return $self->border_attribute() if $name eq 'border'; # virtual attribute
    return join (",",$self->size()) if $name eq 'size'; # virtual attribute
    }

#  print STDERR "# called attribute($class,$name)\n";

  # font-size => fontsize
  $name = $att_aliases->{$name} if exists $att_aliases->{$name};
    
  my $base_class = $class; $base_class =~ s/\.(.*)//;
  my $sub_class = $1; $sub_class = '' unless defined $sub_class;
  if ($name eq 'class')
    {
    # "[A] { class: red; }" => "red"
    return $sub_class if $sub_class ne '';
    # "node { class: green; } [A]" => "green": fall through and let the code
    # below look up the attribute or fall back to the default '':
    }

  # prevent ->{special}->{node} from springing into existance
  my $s = $attributes->{special}; $s = $s->{$class} if exists $s->{$class};
  my $entry =	$s->{$name} ||
		$attributes->{all}->{$name} ||
		$attributes->{$base_class}->{$name};

  # create a fake entry for custom attributes
  $entry = [ '', undef, '', '', ATTR_STRING, '' ]
    if $name =~ $qr_custom_attribute;

  # Didn't found an entry:
  return $self->_unknown_attribute($name,$class) unless ref($entry);

  my $type = $entry->[ ATTR_TYPE_SLOT ] || ATTR_STRING;

  my $val;

  if ($three_arg == 0)
    {
    ###########################################################################
    # Check the object directly first
    my $a = $self->{att};
    if (exists $a->{graph})
      {
      # for graphs, look directly in the class to save time:
      $val = $a->{graph}->{$name} 
	if exists $a->{graph}->{$name};
      }
    else
      {
      $val = $a->{$name} if exists $a->{$name};
      }

    # For "background", and objects that are in a group, we inherit "fill":
    if ($name eq 'background' && $val && $val eq 'inherit')
      {
      my $parent = $self->parent();
      $val = $parent->color_attribute('fill') if $parent && $parent != $self;
      }

    # XXX BENCHMARK THIS
    return $val if defined $val && 
	# no inheritance ("inherit" is just a normal string value)
	($type >= ATTR_NO_INHERIT ||
	# no inheritance since value is something else like "red"
	 $val ne 'inherit' ||
	# for graphs, there is nothing to inherit from
	 $class eq 'graph'); 
    }

  # $val not defined, or 'inherit'

  ###########################################################################
  # Check the classes now

#  print STDERR "# Called self->attribute($class,$name) (#2)\n";

  # we try them in this order:
  # node.subclass, node, graph

#  print STDERR "# $self->{name} class=$class ", join(" ", caller),"\n" if $name eq 'align';

  my @tries = ();
  # skip "node.foo" if value is 'inherit'
  push @tries, $class unless defined $val;
  push @tries, $base_class if $class =~ /\./;
  push @tries, 'graph' unless @tries && $tries[-1] eq 'graph';

  # If not part of a graph, we cannot have class attributes, but
  # we still can find default attributes. So fake a "graph":
  my $g = $self->{graph}; 			# for objects in a graph
  $g = { att => {} } unless ref($g);		# for objects not in a graph

  # XXX TODO should not happen
  $g = $self if $self->{class} eq 'graph';	# for the graph itself

  $val = undef;
  TRY:
   for my $try (@tries)
    {
#    print STDERR "# Trying class $try for attribute $name\n" if $name eq 'align';

    my $att = $g->{att}->{$try};

    $val = $att->{$name} if exists $att->{$name};

    # value was not defined, so get the default value (but not for subclasses!)
    if (!defined $val)
      {
      my $def = $entry->[ ATTR_DEFAULT_SLOT ]; $val = $def;

      # "node.subclass" gets the default from "node", 'edge' from 'default':
      # " { default => 'foo', 'node.anon' => 'none', node => 'solid' }":
      if (ref $def)
	{
	$val = $def->{$try};
        if (!defined $val && $try =~ /\./)
	  {
	  my $base = $try; $base =~ s/\..*//;
	  $val = $def->{$base};
	  }
        # if this is not a subclass, get the default value
        next TRY if !defined $val && $try =~ /\./;
        
	$val = $def->{default} unless defined $val;
	}
      }
    # $val must now be defined, because default value must exist.

#    print STDERR "# Found '$val' for $try ($class)\n" if $name eq 'color';

    if ($name ne 'label')
      {
      $self->warn("Uninitialized default for attribute '$name' on class '$try'\n")
        unless defined $val;
      }

    return $val if $type >= ATTR_NO_INHERIT;

    # got some value other than inherit or already at top of tree:
    last if defined $val && ($val ne 'inherit' || $try eq 'graph');

    # try next class in inheritance tree
    $val = undef;
    }

  # For "background", and objects that are in a group, we inherit "fill":
  if ($name eq 'background' && $val && $val eq 'inherit')
    {
    my $parent = $self->parent();
    $val = $parent->color_attribute('fill') if $parent && $parent != $self;
    }

  # If we fell through here, $val is 'inherit' for graph. That happens
  # for instance for 'background':
  $val;
  }

sub unquote_attribute
  {
  # The parser leaves quotes and escapes in the attribute, these things
  # are only removed upon storing the attribute at the object/class.
  # Return the attribute unquoted (remove quotes on labels, links etc).
  my ($self,$class,$name,$val) = @_;

  # clean quoted strings
  # XXX TODO
  # $val =~ s/^["'](.*[^\\])["']\z/$1/;
  $val =~ s/^["'](.*)["']\z/$1/;

  $val =~ s/\\([#"';\\])/$1/g;		# reverse backslashed chars

  # remove any %00-%1f, %7f and high-bit chars to avoid exploits and problems
  $val =~ s/%[^2-7][a-fA-F0-9]|%7f//g;

  # decode %XX entities
  $val =~ s/%([2-7][a-fA-F0-9])/sprintf("%c",hex($1))/eg;

  $val;
  }

sub valid_attribute
  {
  # Only for compatibility, use validate_attribute()!

  # Check that an name/value pair is an valid attribute, returns:
  # scalar value:	valid, new attribute
  # undef:	 	not valid
  # []:			unknown attribute (might also warn)
  my ($self, $name, $value, $class) = @_;

  my ($error,$newname,$v) = $self->validate_attribute($name,$value,$class);

  return [] if defined $error && $error == 1;
  return undef if defined $error && $error == 2;
  $v;
  }

sub validate_attribute
  {
  # Check that an name/value pair is an valid attribute, returns:
  # $error, $newname, @values

  # A possible new name is in $newname, this is f.i. used to convert
  # "font-size" # to "fontsize".

  # Upon errors, $error contains the error code:
  # undef:	 	all went well
  # 1			unknown attribute name
  # 2			invalid attribute value 
  # 4			found multiple attributes, but these aren't
  #			allowed at this place

  my ($self, $name, $value, $class, $no_multiples) = @_;

  $self->error("Got reference $value as value, but expected scalar") if ref($value);
  $self->error("Got reference $name as name, but expected scalar") if ref($name);

  # "x-foo-bar" is a custom attribute, so allow it always. The name must
  # consist only of letters and hyphens, and end in a letter. Hyphens
  # must be separated by letters.
  return (undef, $name, $value) if $name =~ $qr_custom_attribute;

  $class = 'all' unless defined $class;
  $class =~ s/\..*\z//;		# remove subclasses

  # Remap alias names without "-" to their hyphenated version:
  $name = $att_aliases->{$name} if exists $att_aliases->{$name};

  # prevent ->{special}->{node} from springing into existance
  my $s = $attributes->{special}; $s = $s->{$class} if exists $s->{$class};

  my $entry = $s->{$name} ||
	      $attributes->{all}->{$name} || $attributes->{$class}->{$name};

  # Didn't found an entry:
  return (1,undef,$self->_unknown_attribute($name,$class)) unless ref($entry);

  my $check = $entry->[ATTR_MATCH_SLOT];
  my $type = $entry->[ATTR_TYPE_SLOT] || ATTR_STRING;

  $check = '_color' if $type == ATTR_COLOR;
  $check = '_angle' if $type == ATTR_ANGLE;
  $check = '_uint' if $type == ATTR_UINT;

  my @values = ($value);

  # split on "|", but not on "\|"
  # XXX TODO:
  # This will not work in case of mixed " $i \|\| 0| $a = 1;"

  # When special attributes are set, we are parsing Graphviz, and do
  # not allow/use multiple attributes. So skip the split.
  if (keys %{$attributes->{special}} == 0)
     {
     @values = split (/\s*\|\s*/, $value, -1) if $value =~ /(^|[^\\])\|/;
     }

  my $multiples = 0; $multiples = 1 if @values > 1;
  return (4) if $no_multiples && $multiples; 		# | and no multiples => error

  # check each part on it's own
  my @rc;
  for my $v (@values)
    {
    # don't check empty parts for being valid
    push @rc, undef and next if $multiples && $v eq '';

    if (defined $check && !ref($check))
      {
      no strict 'refs';
      my $checked = $self->$check($v, $name);
      if (!defined $checked)
	{
        $self->error("Error in attribute: '$v' is not a valid $name for a $class");
        return (2);
        }
      push @rc, $checked;
      }
    elsif ($check)
      {
      if (ref($check) eq 'ARRAY')
        {
        # build a regexp from the list of words
        my $list = 'qr/^(' . join ('|', @$check) . ')\z/;';
        $entry->[1] = eval($list);
        $check = $entry->[1];
        }
      if ($v !~ $check)				# invalid?
	{
        $self->error("Error in attribute: '$v' is not a valid $name for a $class");
	return (2);
	}

      push @rc, $v;				# valid
      }
    # entry found, but no specific check => anything goes as value
    else { push @rc, $v; }

    # "ClAss" => "class" for LCTEXT entries
    $rc[-1] = lc($rc[-1]) if $type == ATTR_LCTEXT;
    }

  # only one value ('green')
  return (undef, $name, $rc[0]) unless $multiples;

  # multiple values ('green|red')
  (undef, $name, \@rc);
  }

###########################################################################
###########################################################################

sub _remap_attributes
  {
  # Take a hash with:
  # {
  #   class => {
  #     color => 'red'
  #   }
  # }
  # and remap it according to the given remap hash (similiar structured).
  # Also encode/quote the value. Suppresses default attributes.
  my ($self, $object, $att, $remap, $noquote, $encode, $color_remap ) = @_;

  my $out = {};

  my $class = $object || 'node';
  $class = $object->{class} || 'graph' if ref($object);
  $class =~ s/\..*//;				# remove subclass

  my $r = $remap->{$class};
  my $ra = $remap->{all};
  my $ral = $remap->{always};
  my $x = $remap->{x};

  # This loop does also handle the individual "bordercolor" attributes.
  # If the output should contain only "border", but not "bordercolor", then
  # the caller must filter them out.

  # do these attributes
  my @keys = keys %$att;

  my $color_scheme = 'w3c';
  $color_scheme = $object->attribute('colorscheme') if ref($object);
  $color_scheme = $self->get_attribute($object,'colorscheme')
    if defined $object && !ref($object);

  $color_scheme = $self->get_attribute('graph','colorscheme')
    if defined $color_scheme && $color_scheme eq 'inherit';

  for my $atr (@keys)
    {
    my $val = $att->{$atr};

    # Only for objects (not for classes like "node"), and not if
    # always says we need to always call the CODE handler:

    if (!ref($object) && !exists $ral->{$atr})
      {
      # attribute not defined
      next if !defined $val || $val eq '' ||
      # or $remap says we should suppress it
         (exists $r->{$atr} && !defined $r->{$atr}) ||
         (exists $ra->{$atr} && !defined $ra->{$atr});
      }

    my $entry = $attributes->{all}->{$atr} || $attributes->{$class}->{$atr};

    if ($color_remap && defined $entry && defined $val)
      {
      # look up whether attribute is a color
      # if yes, convert to hex
      $val = $self->color_as_hex($val,$color_scheme)
        if ($entry->[ ATTR_TYPE_SLOT ]||ATTR_STRING) == ATTR_COLOR;
      }

    my $temp = { $atr => $val };

    # see if there is a handler for custom attributes
    if (exists $r->{$atr} || exists $ra->{$atr} || (defined $x && $atr =~ /^x-/))
      {
      my $rc = $r->{$atr}; $rc = $ra->{$atr} unless defined $rc;
      $rc = $x unless defined $rc;

      # if given a code ref, call it to remap name and/or value
      if (ref($rc) eq 'CODE')
        {
        my @rc = &{$rc}($self,$atr,$val,$object);
        $temp = {};
        while (@rc)
          {
          my $a = shift @rc; my $v = shift @rc;
          $temp->{ $a } = $v if defined $a && defined $v;
          }
        }
      else
        {
        # otherwise, rename the attribute name if nec.
        $temp = { };
        $temp = { $rc => $val } if defined $val && defined $rc;
        }
      }

    for my $at (keys %$temp)
      {
      my $v = $temp->{$at};

      next if !defined $at || !defined $v || $v eq '';

      # encode critical characters (including "), but only if the value actually
      # contains anything else than '%' (so rgb(10%,0,0) stays as it is)

      $v =~ s/([;"%\x00-\x1f])/sprintf("%%%02x",ord($1))/eg 
        if $encode && $v =~ /[;"\x00-\x1f]/;
      # quote if nec.
      $v = '"' . $v . '"' unless $noquote;

      $out->{$at} = $v;
      }
    }

  $out;
  }

sub raw_attributes
  {
  # return all set attributes on this object (graph/node/group/edge) as
  # an anonymous hash ref
  my $self = shift;

  my $class = $self->{class} || 'graph';

  my $att = $self->{att};
  $att = $self->{att}->{graph} if $class eq 'graph';

  my $g = $self->{graph} || $self;

  my $out = {};
  if (!$g->{strict})
    {
    for my $name (keys %$att)
      {
      my $val = $att->{$name};
      next unless defined $val;			# set to undef?

      $out->{$name} = $val;
      }
    return $out;
    }

  my $base_class = $class; $base_class =~ s/\..*//;
  for my $name (keys %$att)
    {
    my $val = $att->{$name};
    next unless defined $val;			# set to undef?

    $out->{$name} = $val;
 
    next unless $val eq 'inherit';
 
    # prevent ->{special}->{node} from springing into existance
    my $s = $attributes->{special}; $s = $s->{$class} if exists $s->{$class};
    my $entry =	$s->{$name} ||
		$attributes->{all}->{$name} ||
		$attributes->{$base_class}->{$name};

    # Didn't found an entry:
    return $self->_unknown_attribute($name,$class) unless ref($entry);
  
    my $type = $entry->[ ATTR_TYPE_SLOT ] || ATTR_STRING;

    # need to inherit value?
    $out->{$name} = $self->attribute($name) if $type < ATTR_NO_INHERIT;
    }

  $out;
  }

sub get_attributes
  {
  # Return all effective attributes on this object (graph/node/group/edge) as
  # an anonymous hash ref. This respects inheritance and default values.
  # Does not return custom attributes, see get_custom_attributes().
  my $self = shift;

  $self->error("get_attributes() doesn't take arguments") if @_ > 0;

  my $att = {};
  my $class = $self->main_class();

  # f.i. "all", "node"
  for my $type ('all', $class)
    {
    for my $a (keys %{$attributes->{$type}})
      {
      my $val = $self->attribute($a);		# respect inheritance	
      $att->{$a} = $val if defined $val;
      }
    }

  $att;
  }

package Graph::Easy::Node;

BEGIN
  {
  *custom_attributes = \&get_custom_attributes;
  }

sub get_custom_attributes
  {
  # Return all custom attributes on this object (graph/node/group/edge) as
  # an anonymous hash ref.
  my $self = shift;

  $self->error("get_custom_attributes() doesn't take arguments") if @_ > 0;

  my $att = {};

  for my $key (keys %{$self->{att}})
    {
    $att->{$key} = $self->{att}->{$key};
    }

  $att;
  }

1;
__END__

=head1 NAME

Graph::Easy::Attributes - Define and check attributes for Graph::Easy

=head1 SYNOPSIS

	use Graph::Easy;

	my $graph = Graph::Easy->new();

	my $hexred = Graph::Easy->color_as_hex( 'red' );
	my ($name, $value) = $graph->valid_attribute( 'color', 'red', 'graph' );
	print "$name => $value\n" if !ref($value);

=head1 DESCRIPTION

C<Graph::Easy::Attributes> contains the definitions of valid attribute names
and values for L<Graph::Easy|Graph::Easy>. It is used by both the parser
and by Graph::Easy to check attributes for being valid and well-formed. 

There should be no need to use this module directly.

For a complete list of attributes and their possible values, please see
L<Graph::Easy::Manual>.

=head1 EXPORT

Exports nothing.

=head1 SEE ALSO

L<Graph::Easy>.

=head1 AUTHOR

Copyright (C) 2004 - 2008 by Tels L<http://bloodgate.com>

See the LICENSE file for information.

=cut
