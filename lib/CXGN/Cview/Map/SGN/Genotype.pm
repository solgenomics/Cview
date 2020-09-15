
=head1 NAME

CXGN::Cview::Map::SGN::Genotype - a map object that represents the genetic composition of an individual accession

=head1 DESCRIPTION

Inhertis from CXGN::Cview::Map

=head1 AUTHORS

Lukas Mueller

=cut

use strict;
use warnings;

package CXGN::Cview::Map::SGN::Genotype;

use base 'CXGN::Cview::Map';

sub new { 
    my $class = shift;
    my $dbh = shift;
    my $stock_id=shift;


    my $self = $class->SUPER::new($dbh);
    $self->set_id($stock_id);
    $self->get_chromosome_count();

    return $self;
}


sub get_chromosome_names { 
    my $self = shift;

    if (!exists($self->{chromosome_names})) { 
	@{$self->{chromosome_names}} = ();
    }
    if (!@{$self->{chromosome_names}}) { 

	my $chr_q = "SELECT distinct(linkage_group.lg_name), linkage_group.lg_order FROM phenome.phenome_genotype
                 JOIN phenome.genotype_experiment using (genotype_experiment_id) 
                 JOIN sgn.map_version ON (genotype_experiment.reference_map_id=sgn.map_version.map_id)
                 JOIN sgn.linkage_group using (map_version_id)
                 WHERE map_version.current_version='t' AND stock_id=?  ORDER BY linkage_group.lg_order";
	my $chr_h = $self->get_dbh()->prepare($chr_q);
	$chr_h->execute($self->get_id());
	my @names = ();
	while (my($chr) = $chr_h->fetchrow_array()) { 
	    push @names, $chr;
	}
	@{$self->{chromosome_names}} = @names;
    }
    #print STDERR "Chromosome names: ".(join(", ", @{$self->{chromosome_names}}))."\n";
    return @{$self->{chromosome_names}};
}

sub get_chromosome_count { 
    my $self = shift;
    
    return scalar($self->get_chromosome_names());
    
}

sub get_chromosome_lengths { 
    my $self = shift;

    my $query = "SELECT lg_name, max(position), map_version.map_id, lg_order FROM sgn.linkage_group
                   JOIN sgn.marker_location using (lg_id)
                   JOIN sgn.map_version on (map_version.map_version_id=linkage_group.map_version_id)
                   JOIN phenome.genotype_experiment on (map_version.map_id=genotype_experiment.reference_map_id)
                   JOIN phenome.phenome_genotype using (genotype_experiment_id)
                   WHERE phenome_genotype.stock_id=?
                         AND map_version.current_version='t'

                   GROUP BY lg_name, map_version.map_id, lg_order
                   ORDER BY lg_order";


    my $sth = $self->get_dbh()->prepare($query);
    $sth ->execute($self->get_id());
    my $map_id = 0; 
    @{$self->{chromosome_lengths}} = ();

    while (my ($lg_name, $length, $reference_map_id) = $sth->fetchrow_array()) {

	push @{$self->{chromosome_lengths}},$length;
	$self->{map_id}=$reference_map_id;
    }

    return @{$self->{chromosome_lengths}};

}

sub get_chromosome { 
    my $self = shift;
    my $chr_nr = shift;
    my $c = CXGN::Cview::Chromosome->new();
    $c->set_caption($chr_nr);
    
    # now get the fragments to be highlighted
    #
    my $query2 = "SELECT linkage_group.lg_name, position, type, zygocity_code FROM phenome.phenome_genotype
                 JOIN phenome.genotype_region USING(phenome_genotype_id) 
                 JOIN phenome.genotype_experiment USING (genotype_experiment_id)
                 JOIN sgn.map_version ON (genotype_experiment.reference_map_id=sgn.map_version.map_id)
                 JOIN sgn.marker_location using(map_version_id)
                 JOIN sgn.marker_experiment using(location_id)
                 JOIN sgn.linkage_group ON (genotype_region.lg_id=linkage_group.lg_id)
                 WHERE map_version.current_version='t' 
                   AND genotype_region.marker_id_ns=sgn.marker_experiment.marker_id
                 AND stock_id =? and genotype_experiment.preferred='t' and linkage_group.lg_name =? ORDER BY position limit 1";

    my $query3 = "SELECT linkage_group.lg_name, position  FROM phenome.phenome_genotype
                 JOIN phenome.genotype_region USING(phenome_genotype_id) 
                 JOIN phenome.genotype_experiment USING (genotype_experiment_id)
                 JOIN sgn.map_version ON (genotype_experiment.reference_map_id=sgn.map_version.map_id)
                 JOIN sgn.marker_location using(map_version_id)
                 JOIN sgn.marker_experiment using(location_id)
                 JOIN sgn.linkage_group ON (genotype_region.lg_id=linkage_group.lg_id)
                 WHERE map_version.current_version='t' 
                   -- AND phenome.genotype_region.lg_id=sgn.linkage_group.lg_id
                   AND marker_id_sn=sgn.marker_experiment.marker_id
                 AND stock_id =? and genotype_experiment.preferred='t' and linkage_group.lg_name=? ORDER BY position limit 1";


    my $sth2 = $self->get_dbh()->prepare($query2);
    $sth2->execute($self->get_id, $chr_nr);

    my $sth3 = $self->get_dbh()->prepare($query3);
    $sth3->execute($self->get_id, $chr_nr);
    
    while (my ($chr1, $top_marker, $type, $zygocity_code) = $sth2->fetchrow_array()) { 
        my ($chr2, $bottom_marker) = $sth3->fetchrow_array();
    
	if ($type eq "map") { 
	    my $m = CXGN::Cview::Marker->new($c);
	    $m->get_label()->set_hidden(1);
	    $m->set_marker_name($top_marker."-".$zygocity_code);
	    my @color = (200, 200, 200);
	    if ($zygocity_code eq "a") { @color = (255, 0, 0); }
	    if ($zygocity_code eq "b") { @color = (0, 0, 255); }
	    if ($zygocity_code eq "c") { @color = (200, 100, 0); }
	    if ($zygocity_code eq "d") { @color = (0, 100, 200); }
	    if ($zygocity_code eq "h") { @color = (50, 50, 50); }
	    $m->set_color(@color);
	    $m->set_offset($top_marker);
	    $c->add_marker($m);
	    $c->set_url("/cview/view_chromosome.pl?chr_nr=$chr1&amp;map_id=".($self->get_id())."&amp;show_ruler=1");
	}
	
	elsif ("$chr1" eq "$chr2") { 
	    
	    my $m = CXGN::Cview::Marker::RangeMarker->new($c);
	    #$m->get_label()->set_stacking_level(1);
#	    $m->set_label_side("right");
	    $m->get_label()->set_name("IL");
	    
	    my $offset = ($top_marker+$bottom_marker)/2;
	    $m->set_offset($offset);
	    $m->set_north_range($offset-$top_marker);
	    $m->set_south_range($bottom_marker-$offset);
	    
	    $c->add_marker($m);
	    $m->set_hilite_chr_region(1);
	    #$m->get_label()->set_url("/cview/view_chromosome.pl?map_id=5&cM_start=$top_marker&cM_end=$bottom_marker&show_zoomed=1");
	    $c->set_url("/cview/view_chromosome.pl?chr_nr=$chr1&amp;map_id=$self->{map_id}&amp;cM_start=".($top_marker-1)."&amp;cM_end=".($bottom_marker+1)."&amp;show_zoomed=1&amp;show_ruler=1");
	    
	}
	else { warn "[Genotype map] $chr1 should be the same as $chr2...\n"; }
	
    }

    return $c;


}


sub get_overview_chromosome { 
    my $self =shift;
    my $chr_nr = shift;
    
    my $chr = $self->get_chromosome($chr_nr);

    $chr->set_width(12);
    return $chr;
}

1;
 
