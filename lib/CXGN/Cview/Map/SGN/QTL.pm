
use strict;
use warnings;

package CXGN::Cview::Map::SGN::QTL;

use base "CXGN::Cview::Map::SGN::Genetic";

use CXGN::Cview::Marker::QTL;
use CXGN::Cview::Marker::RangeMarker;

sub new { 
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    return $self;

}

sub get_chromosome { 
    my $self = shift;
    my $chr_nr = shift;
    my $chr = $self->SUPER::get_chromosome($chr_nr);

    my $side = "right";

    my $qtl = CXGN::Cview::Marker::QTL->new($chr);
    $qtl->set_range_coords(20,30);
    $qtl->set_marker_name("blabla");
    $qtl->get_label()->set_name("blabla");

    $qtl->set_label_side($side);
#    $qtl->get_label()->set_align_side("default");
    $qtl->set_url("http://google.com");
    $qtl->set_tooltip("congratulations!");
    $qtl->set_fill_color(0, 0, 255);
#    $qtl->set_show_tick(1);
    
    $chr->add_marker($qtl);

    my $rl = CXGN::Cview::Marker::RangeMarker->new($chr);
    $rl->set_marker_name("RangeMarker");
    $rl->set_color(244,0, 0);
    $rl->hilite();
    $rl->get_label()->set_name('foo');
    $rl->get_label()->set_hilited(1);
    $rl->set_range_coords(40, 50);
    $rl->set_label_side($side);
    $rl->get_label()->set_align_side("auto");
    $rl->show_label();
    $rl->set_url('http://google.com');
    $rl->unhide();

    $chr->add_marker($rl);

    $chr->sort_markers();

    return $chr;

}

1;

