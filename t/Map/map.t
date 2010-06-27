use strict;
use warnings;

use Test::More tests => 7;

use CXGN::DB::Connection;

use_ok('CXGN::Cview::MapFactory');

my $dbh = CXGN::DB::Connection->new();

my %chromosome_counts = ( 
    9 => 12,
    7 => 5,
    5 => 12,
    );

for my $map_id (9, 7, 5) {
    my $map_factory = CXGN::Cview::MapFactory->new($dbh);
    my $map = $map_factory->create({map_id =>$map_id});
    is($map->get_chromosome_count(), $chromosome_counts{$map_id}, "chromosome_count test");
    is(scalar($map->get_chromosome_lengths()), $chromosome_counts{$map_id}, "chr len test");
}


