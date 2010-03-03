
use strict;

use Test::More qw | no_plan |;

BEGIN {
    use_ok("CXGN::Cview::Chromosome");
    use_ok("CXGN::Cview::Marker");
}

my $c = CXGN::Cview::Chromosome->new();
my $m = CXGN::Cview::Marker->new($c);

$m->set_offset(30);
is($m->get_offset(), 30, "offset test");

$m->set_north_range(15);
is($m->get_north_range(), 15, "north range accessor test");

$m->set_south_range(22);
is($m->get_south_range(), 22, "sourth range test");

is($m->get_start(), 15, "start coord test");
is($m->get_end(), 52, "end coord test");

$m->set_range_coords(60, 100);
is($m->get_north_range(), 20, "set_range_coords north_range test");
is($m->get_south_range(), 20, "set_range_coords south_range test");
is($m->get_offset(), 80, "set_range_coords offset test");

$m->hide_label();
is($m->is_label_visible(), 0 || '', "label not visible test");

$m->show_label();
is($m->is_label_visible(), 1, "label visible test");

$m->set_marker_name("ABC27");
$m->set_location_subscript("B");
is($m->get_name(), "ABC27B", "marker complete name test");

$m->hide();
is($m->is_hidden(), 1, "marker hidden test");
$m->unhide();
is($m->is_hidden(), 0, "marker shown test");

