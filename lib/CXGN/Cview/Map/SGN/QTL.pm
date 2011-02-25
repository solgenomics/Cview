
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

    my $q = "SELECT marker_alias.marker_id, marker_alias.alias, marker_location.position_north, marker_location.position_south, locus_marker.locus_id FROM sgn.marker_alias join  sgn.marker_experiment using(marker_id) join sgn.marker_location using(location_id) join sgn.linkage_group using(lg_id) left join phenome.locus_marker using(marker_id)  where lg_name=? and marker_location.map_version_id=? and protocol=?";

    my $h = $self->get_dbh()->prepare($q);
    $h->execute($chr_nr, $self->get_id(), "QTL");

    while (my ($marker_id, $name, $north, $south, $locus_id) = $h->fetchrow_array()) { 
	
	#print STDERR "Adding marker $marker_id, $name, $north, $south\n";
	my $qtl = CXGN::Cview::Marker::QTL->new($chr, $marker_id);
	$qtl->set_range_coords($north,$south);
	$qtl->set_marker_name($name);
	$qtl->get_label()->set_name($name);
	$qtl->get_label()->set_vertical_stacking_spacing(2);
	$qtl->get_label()->set_stacking_height(10);

	$qtl->set_label_side($side);

	if ($locus_id) { 
	    $qtl->set_url("/phenome/locus_display.pl?locus_id=$locus_id");
	}
	$qtl->set_tooltip($name ." (".(sprintf "%5.2f", $north)."-".(sprintf "%5.2f", $south)." cM)");

	if ($name =~ /blight/i) { 
	    $qtl->set_fill_color(0, 0, 255);
	}
	elsif ($name =~ /maturity/i) { 
	    $qtl->set_fill_color(0, 255, 0);
	}
	else { 
	    $qtl->set_fill_color(0, 255, 255);
	}
	$chr->add_marker($qtl);
    }

    $chr->distribute_label_stacking();
    $chr->sort_markers();

    return $chr;

}


sub get_overview_chromosome { 
    my $self = shift;
    my $chr_nr = shift;
    
    my $chr = $self->SUPER::get_overview_chromosome($chr_nr);

    foreach my $m ($chr->get_markers()) { 
	$m->get_label()->set_stacking_height(5);
	print STDERR "STACKING LEVEL: ".$m->get_label()->get_stacking_level()."\n";

    }

    $chr->distribute_label_stacking();
    

    return $chr;
}
    
1;

