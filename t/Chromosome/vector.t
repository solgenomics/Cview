
use strict;

use Test::More qw | no_plan |;

BEGIN { 
    use_ok("CXGN::Cview::Chromosome::Vector");
    use_ok("CXGN::Cview::Marker::VectorFeature");

}

my $v = CXGN::Cview::Chromosome::Vector->new();


$v->set_length(3000);
$v->set_height(200);

my $m1 = CXGN::Cview::Marker::VectorFeature->new($v);
$m1->set_range_coords(500, 1000);

my $start = $m1->get_start();

is ($start, 500, "feature start coord test");

my $end = $m1->get_end();

is ($end, 1000, "feature end coord test");

my $offset = $m1->get_offset();

is($offset, (500+1000)/2, "offset test");
is($m1->get_north_range(), 250, "north range test");
is($m1->get_south_range(), 250, "south range test");


my $angle = $v->angle($start);

is((sprintf "%5.4f", $angle), 2.0944, "angle test");

my ($x, $y) = $v->mapunits2pixels($start);

is( (sprintf "%4.1f", $x), 86.6, "mapunits2pixels x test");

is( (sprintf "%4.1f", $y), "-50.0", "mapunits2pixels y test");

$v->add_marker($m1);

my $m2 = CXGN::Cview::Marker::VectorFeature->new($v);

$m2->set_range_coords(1500, 2500);

$v->add_marker($m2);

is($v->get_markers(), 2, "marker test");




