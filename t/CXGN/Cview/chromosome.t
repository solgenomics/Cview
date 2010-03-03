
use strict;

use Test::More tests=>35;

use CXGN::Cview::Chromosome;
use CXGN::Cview::Marker;

my @markers = ( [ 'm1', 2 ], [ 'm2', 5 ], [ 'm3', 15 ], [ 'm4', 27 ], [ 'm5', 27 ], [ 'm6', 30 ], [ 'm7', 45 ] );

my $c = CXGN::Cview::Chromosome->new();

$c->set_length(100);
$c->set_height(50);
$c->set_caption("foo");
$c->set_url("http://www.google.com/");
$c->set_units("cM");
$c->set_labels_right();
$c->set_display_marker_offset(1);

is($c->get_length(), 100, "length test");

is($c->get_caption(), "foo", "caption test");
is($c->get_height(), 50, "height test");
is($c->get_url(), "http://www.google.com/", "url test");
is($c->get_units(), "cM", "map units test");
is($c->get_label_side(), "right", "label side test");

foreach my $m (@markers) { 
    my $marker = CXGN::Cview::Marker->new($c);
    $marker->set_marker_name($m->[0]);
    $marker->get_label()->set_name($m->[0]);
    $marker->set_offset($m->[1]);
    $c->add_marker($marker);
}

my @marker_objects = $c->get_markers();

is(@marker_objects, 7, "marker count test");

for (my $i=0; $i<$c->get_markers(); $i++) { 
    is($marker_objects[$i]->get_label()->get_name(), $markers[$i]->[0], "label name test ".$i);
    is($marker_objects[$i]->get_offset(), $markers[$i]->[1], "offset test $i");
    is($marker_objects[$i]->get_label()->get_Y(), undef, "label offset test $i");
}

$c->distribute_labels();

my @new = (-32, -19, -6, 6, 19, 32, 45);
for (my $i=0; $i<@marker_objects; $i++) { 
    is($marker_objects[$i]->get_label()->get_Y(), $new[$i], "distributed label position test $i");
    
}
