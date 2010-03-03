

use strict;
use Test::More;

use CXGN::DB::Connection;
use CXGN::Cview::MapFactory;

my $dbh = CXGN::DB::Connection->new();

foreach my $map_id (9, 7, 5) { 
    my $map_factory = CXGN::Cview::MapFactory->new($dbh);
    my $map = $map_factory->create({map_id =>$map_id});
    print $map->get_short_name();
    print $map->get_long_name();
    is($map->get_chromosome_count(), 12, "chromosome_count test");
    is(scalar($map->get_chromosome_lengths()), 12, "chr len test");
}


