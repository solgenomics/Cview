

=head1 NAME

CXGN::Cview::Map_overviews::Physical - a class to draw physical map representations.           
           
=head1 SYNOPSYS

see L<CXGN::Cview::Map_overviews>.
         
=head1 DESCRIPTION


=head1 AUTHOR(S)

Lukas Mueller (lam87@cornell.edu)

=head1 VERSION
 

=head1 LICENSE


=head1 FUNCTIONS

This class implements/overrides the following functions:

=cut



=head1 CXGN::Cview::Map_overviews::physical_overview

A class to display a genetic map with the overgo results next to it.
Inherits from CXGN::Cview::Map_overviews.

=cut

use strict;

package CXGN::Cview::Map_overviews::Physical;

use base qw( CXGN::Cview::Map_overviews::Generic );

sub hilite_marker { 
    my $self = shift;
    my $marker_name = shift;
    push @{$self->{hilite_markers}}, $marker_name;
}

sub render_map {
    my $self = shift;

    if ($self->has_cache()) { return; }


    $self->{map_image}=CXGN::Cview::MapImage->new("", 13*$self->get_horizontal_spacing(), 150);
    my @c = ();
    
    my $cM_eq = 0.4; # 1 cM corresponds to 0.4 pixels.
    my $max_chr_len_cM = 0;
    my $max_chr_len_pixels = 0;
    
    # draw chromosomes
    #
    for (my $i=1; $i<=@{$self->get_map()->linkage_groups()}; $i++) {
	$c[$i]= CXGN::Cview::Chromosome -> new(1, 100, $self->get_horizontal_spacing()*$i, 40);
	CXGN::Cview::Cview_data_adapter::fetch_chromosome($self, $c[$i], $self->get_map(), $i); 
	my @markers = $c[$i]->get_markers();
	#$self->set_marker_count($i, scalar(@markers));
	my $chr_len = 0;
	foreach my $m (@markers) {
	    $m -> hide_label();
	    $m -> set_color(200, 100, 100);
	    if ($m->get_offset() > $chr_len) { $chr_len = $m->get_offset(); }
	}
	$c[$i]->set_caption($i);
	$c[$i]->set_width(12);
	#$c[$i]->set_url("/cview/view_chromosome.pl?map_id=$self->{map_id}&amp;chr_nr=$i");
	my $chr_len_pixels = $chr_len*$cM_eq; 
	$c[$i]->set_height($chr_len_pixels);
	if ($chr_len > $max_chr_len_cM) { 
	    $max_chr_len_cM = $chr_len; 
	    $max_chr_len_pixels = $chr_len_pixels;
	}
	$c[$i]->set_length($chr_len);
	$c[$i]->layout();
	$c[$i]->rasterize(5);
	$c[$i]->set_rasterize_link("/cview/view_chromosome.pl?map_version_id=".$self->get_map()->map_version_id()."&amp;chr_nr=$i&amp;show_ruler=1&amp;show_zoomed=1&amp;show_physical=1&amp;cM=");
	
	$self->{map_image}->add_chromosome($c[$i]);
    }
    my @p; # the physical maps
    # draw physical maps
    #
    for (my $i=1; $i<=@{$self->get_map()->linkage_groups()}; $i++) {
	$p[$i]= CXGN::Cview::Physical -> new(1, 100, $self->get_horizontal_spacing()*$i+22, 40);
	CXGN::Cview::Cview_data_adapter::fetch_chromosome($self, $p[$i], $self->get_map(), $i);
	CXGN::Cview::Cview_data_adapter::fetch_physical($self, $p[$i], $self->get_map(), $i); 
	$p[$i]->set_box_height(2);
	my @markers = $p[$i]->get_markers();
#	$self->{marker_count}[$i] = scalar(@markers);
	my $chr_len = 0;
	foreach my $m (@markers) {
	    $m -> hide_label();
	    if ($m->get_offset() > $chr_len) { $chr_len = $m->get_offset(); }
	}

	my $chr_len_pixels = $chr_len*$cM_eq; 
	$p[$i]->set_height($chr_len_pixels);
	if ($chr_len > $max_chr_len_cM) { 
	    $max_chr_len_cM = $chr_len; 
	    $max_chr_len_pixels = $chr_len_pixels;
	}
	#$c[$i]->rasterize(5);
	#$c[$i]->set_rasterize_link("/cview/view_chromosome.pl?map_id=$self->{map_id}&amp;chr_nr=$i&amp;show_zoomed=1&amp;cM=");
	
	$self->{map_image}->add_physical($p[$i]);
    }
#    print STDERR "mac chr len pixels: $max_chr_len_pixels, max chr len: $max_chr_len_cM\n";
    $self->{map_image}->add_ruler(CXGN::Cview::Ruler->new(20, 40, $max_chr_len_pixels, 0, $max_chr_len_cM)); 

    $self->set_image_map( $self->{map_image}->get_image_map("#mapmap") );
}

package CXGN::Cview::Map_overviews::physical_overview;

use base qw | CXGN::Cview::Map_overviews::Physical | ;

sub new { 
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    return $self;
}


return 1;
