

=head1 NAME

CXGN::Cview::Map_overviews::Individual - a class to display genetic map overviews associated with individual that contain chromosome fragments from other accessions (such as ILs) or carry genes mapped between 2 flanking markers.
           
=head1 SYNOPSYS

         
=head1 DESCRIPTION


=head1 AUTHOR(S)

Lukas Mueller (lam87@cornell.edu)

=head1 VERSION
 

=head1 LICENSE


=head1 FUNCTIONS

This class implements the following functions:

=cut

use strict;
#use CXGN::Map::IndividualMap;

package CXGN::Cview::Map_overviews::Individual;

use CXGN::Cview::Map_overviews;

use base qw | CXGN::Cview::Map_overviews |;

=head2 function new

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub new {
    my $class = shift;
    
    my $self = $class->SUPER::new(@_);
    my $individual_id = shift;
    $self->set_individual_id($individual_id);
    $self->render_map();
    if (!$self->get_cache()->is_valid() && !$self->get_chromosome_count()) { 
	return undef;
    }
    return $self;
}

=head2 accessors set_individual_id, get_individual_id

  Property:	
  Setter Args:	
  Getter Args:	
  Getter Ret:	
  Side Effects:	
  Description:	

=cut

sub get_individual_id { 
    my $self=shift;
    return $self->{individual_id};
}

sub set_individual_id { 
    my $self=shift;
    $self->{individual_id}=shift;
}


=head2 function render_map

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	
  To Do: move this to the data adapter

=cut

sub render_map {
    my $self = shift;
    my $individual_id = $self->get_individual_id();

    #$self->get_cache()->set_force(1); # during development
    $self->get_cache()->set_key("individual overview $individual_id");
    $self->get_cache()->set_expiration_time(); # should never expire...
    $self->get_cache()->set_map_name("overview");

    if ($self->get_cache()->is_valid()) { return; }

    my $IMAGE_WIDTH = 700;

    # get chromosome number of the individual in question.
    my $chr_q = "SELECT count(distinct(linkage_group.lg_name)) FROM phenome.genotype
                 JOIN phenome.genotype_experiment using (genotype_experiment_id) 
                 JOIN sgn.map_version ON (genotype_experiment.reference_map_id=sgn.map_version.map_id)
                 JOIN sgn.linkage_group using (map_version_id)
                 WHERE map_version.current_version='t' AND individual_id=?";
    my $chr_h = $self->prepare($chr_q);
    $chr_h->execute($individual_id);
    my ($chr_count) = $chr_h->fetchrow_array();

    print STDERR "Individual has $chr_count chromosomes.\n";
    $self->set_chromosome_count($chr_count);
    if (!$chr_count) { return; }
    
    $self->set_horizontal_spacing( int($IMAGE_WIDTH/($chr_count+1)) );

    my %lengths = ();
    
    my $query = "SELECT lg_name, max(position), map_version.map_id FROM sgn.linkage_group
                   JOIN sgn.marker_location using (lg_id)
                   JOIN sgn.map_version on (map_version.map_version_id=linkage_group.map_version_id)
                   JOIN phenome.genotype_experiment on (map_version.map_id=genotype_experiment.reference_map_id)
                   JOIN phenome.genotype using (genotype_experiment_id)
                   WHERE genotype.individual_id=?
                         AND map_version.current_version='t'
                   GROUP BY lg_name, map_version.map_id";

    print STDERR "QUERY: $query\n";

    my $sth = $self->prepare($query);
    $sth ->execute($self->get_individual_id());
    my $map_id = 0; 
    while (my ($lg_name, $length, $reference_map_id) = $sth->fetchrow_array()) {
	print STDERR "LENGTHS: $lg_name is $length long.\n";
	$lengths{$lg_name}=$length;
	$map_id=$reference_map_id;
    }



    my @c = ();
#    my %clen = $self->get_map()->get_linkage_group_lengths();
    $self->{map_image}=CXGN::Cview::MapImage->new("", 700, 200);
    foreach my $chr (0..($chr_count-1)) { 
	print STDERR "Generating chromosome $chr...\n";
	$c[$chr] = CXGN::Cview::Chromosome->new();
	$c[$chr]->set_vertical_offset(40);
	$c[$chr]->set_width(12);
	$c[$chr]->set_height(100);
	$c[$chr]->set_caption($chr+1);
	$c[$chr]->set_length($lengths{$chr+1});
	$c[$chr]->set_horizontal_offset(($chr+1) * $self->get_horizontal_spacing());
	$c[$chr]->set_hilite_color(100, 100, 200);
	
	$self->{map_image}->add_chromosome($c[$chr]);
    }

    # now get the fragments to be highlighted
    #
    my $query2 = "SELECT linkage_group.lg_name, position, type, zygocity_code FROM phenome.genotype
                 JOIN phenome.genotype_region USING(genotype_id) 
                 JOIN phenome.genotype_experiment USING (genotype_experiment_id)
                 JOIN sgn.map_version ON (genotype_experiment.reference_map_id=sgn.map_version.map_id)
                 JOIN sgn.marker_location using(map_version_id)
                 JOIN sgn.marker_experiment using(location_id)
                 JOIN sgn.linkage_group ON (genotype_region.lg_id=linkage_group.lg_id)
                 WHERE map_version.current_version='t' 
                   AND genotype_region.marker_id_ns=sgn.marker_experiment.marker_id
                 AND individual_id =? and genotype_experiment.preferred='t' ORDER BY position";

 #   print STDERR "QUERY2: $query2\n";

    
    my $query3 = "SELECT linkage_group.lg_name, position  FROM phenome.genotype
                 JOIN phenome.genotype_region USING(genotype_id) 
                 JOIN phenome.genotype_experiment USING (genotype_experiment_id)
                 JOIN sgn.map_version ON (genotype_experiment.reference_map_id=sgn.map_version.map_id)
                 JOIN sgn.marker_location using(map_version_id)
                 JOIN sgn.marker_experiment using(location_id)
                 JOIN sgn.linkage_group ON (genotype_region.lg_id=linkage_group.lg_id)
                 WHERE map_version.current_version='t' 
                   -- AND phenome.genotype_region.lg_id=sgn.linkage_group.lg_id
                   AND marker_id_sn=sgn.marker_experiment.marker_id
                 AND individual_id =? and genotype_experiment.preferred='t' ORDER BY position";

#    print STDERR "QUERY3: $query3\n";

    my $sth2 = $self-> prepare($query2);
    $sth2->execute($individual_id);

    my $sth3 = $self-> prepare($query3);
    $sth3->execute($individual_id);
    
    while (my ($chr1, $top_marker, $type, $zygocity_code) = $sth2->fetchrow_array()) { 
	my ($chr2, $bottom_marker) = $sth3->fetchrow_array();
    
	if ($type eq "map") { 
	    my $m = CXGN::Cview::Marker->new($c[$chr1-1]);
	    $m->get_label()->set_hidden(1);
	    
	    my @color = (200, 200, 200);
	    if ($zygocity_code eq "a") { @color = (255, 0, 0); }
	    if ($zygocity_code eq "b") { @color = (0, 0, 255); }
	    if ($zygocity_code eq "c") { @color = (200, 100, 0); }
	    if ($zygocity_code eq "d") { @color = (0, 100, 200); }
	    if ($zygocity_code eq "h") { @color = (50, 50, 50); }
	    $m->set_color(@color);
	    $m->set_offset($top_marker);
	    $c[$chr1-1]->add_marker($m);
	    $c[$chr1-1]->set_url("/cview/view_chromosome.pl?chr_nr=$chr1&amp;map_id=$map_id&amp;show_ruler=1");
	}
	
	elsif ("$chr1" eq "$chr2") { 
	    
	    my $m = CXGN::Cview::Marker::RangeMarker->new($c[$chr1-1]);
	    #$m->get_label()->set_stacking_level(1);
#	    $m->set_label_side("right");
	    $m->get_label()->set_name("IL");
	    
	    my $offset = ($top_marker+$bottom_marker)/2;
	    $m->set_offset($offset);
	    $m->set_north_range($offset-$top_marker);
	    $m->set_south_range($bottom_marker-$offset);
	    
	    $c[$chr1-1]->add_marker($m);
	    $m->set_hilite_chr_region(1);
	    #$m->get_label()->set_url("/cview/view_chromosome.pl?map_id=5&cM_start=$top_marker&cM_end=$bottom_marker&show_zoomed=1");
	    $c[$chr1-1]->set_url("/cview/view_chromosome.pl?chr_nr=$chr1&amp;map_id=$map_id&amp;cM_start=".($top_marker-1)."&amp;cM_end=".($bottom_marker+1)."&amp;show_zoomed=1&amp;show_ruler=1");
	    
	    #print STDERR "Fragment: $offset, $top_marker, $bottom_marker\n";
	}
	else { print STDERR "[Individual_overviews] $chr1 should be the same as $chr2...\n"; }
	
    }
    $self->get_cache()->set_image_data( $self->{map_image}->render_png_string() );
    $self->get_cache()->set_image_map_data( $self->{map_image}->get_image_map("overview") );
    
}

=head2 function get_cache_key

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub get_cache_key {
    my $self = shift;
    return "Individual".$self->get_individual_id();
}


=head2 accessors set_chromosome_count, get_chromosome_count

  Property:	
  Setter Args:	
  Getter Args:	
  Getter Ret:	
  Side Effects:	
  Description:	

=cut

sub get_chromosome_count { 
    my $self=shift;
    return $self->{chromosome_count};
}

sub set_chromosome_count { 
    my $self=shift;
    $self->{chromosome_count}=shift;
}


package CXGN::Cview::Map_overviews::Individual_overview;

use base qw | CXGN::Cview::Map_overviews::Individual |; 

sub new { 
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    return $self;
}

return 1;
