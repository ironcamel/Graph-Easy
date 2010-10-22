#!/usr/bin/perl

use strict;
use warnings;

use IO::All;

my ($version) = 
    (map { m{\$VERSION *= *'([^']+)'} ? ($1) : () } 
    io->file("./lib/Graph/Easy.pm")->getlines()
    )
    ;

if (!defined ($version))
{
    die "Version is undefined!";
}

my @cmd = (
    "svn", "copy", "-m",
    "Tagging Grapy-Easy as $version",
    "https://svn.berlios.de/svnroot/repos/web-cpan/Graph-Easy/trunk",
    "https://svn.berlios.de/svnroot/repos/web-cpan/Graph-Easy/tags/releases/$version",
);

print join(" ", @cmd), "\n";
exec(@cmd);
