
=head1 NAME

CXGN::Cview::Marker::Physical - a class to draw markers representing physical associations to maps, such as BACs or contigs.

=head1 DESCRIPTION

CXGN::Cview::Marker::Physical inherits from L<CXGN::Cview::Marker>.

my $m = CXGN::Cview::Marker::Physical->new();
$m->set_offset(30);

=head1 AUTHOR

Lukas Mueller (lam87@cornell.edu)

=head1 FUNCTIONS

This class implements the following functions:

=cut

use strict;
use CXGN::Cview::Marker;
use CXGN::Cview::Label::Physical;

package CXGN::Cview::Marker::Physical;

use base qw / CXGN::Cview::Marker::RangeMarker /;

=head2 function new()

  Constructor. 
  Arguments:   A CXGN::Cview::Chromosome object (or subclassed object) 
               to which this marker belongs.

=cut

sub new {
    my $class = shift;
    my $chromosome = shift;
    my $self = $class -> SUPER::new($chromosome);
    
    my $bac_label = CXGN::Cview::Label::Physical->new();
    $self->show_label();
    $self->set_label($bac_label);
    $self->set_label_side("right");
    $self->set_hilite_chr_region(0);
    $self->set_region_hilite_color(100, 100, 150);
    $self->set_north_range(1);
    $self->set_south_range(1);
    return $self;
}

sub render { 
    my $self = shift;
    my $image = shift;

    # calculate the pos in pixels of the northern range limit
    #
    my $north_pixels = $self->get_chromosome()->mapunits2pixels($self->get_offset()) + $self->get_chromosome()->get_vertical_offset() - $self->get_chromosome()->mapunits2pixels($self->get_north_range());
    
    # determine the pixels of the southern limit
    #
    my $south_pixels = $self->get_chromosome()->mapunits2pixels($self->get_offset()) + $self->get_chromosome()->get_vertical_offset() + $self->get_chromosome()->mapunits2pixels($self->get_south_range());
#    print STDERR "cM = ".$self->get_north_range().", pixels= $north_pixels\n";
#    print STDERR "cM = ".$self->get_south_range().", pixels= $south_pixels\n";

    $self->get_label()->set_north_position($north_pixels);
    $self->get_label()->set_south_position($south_pixels);

    #if ($self->get_url()) { $self->get_label()->set_url($self->get_url()); }

    my $stacking = $self->get_label()->get_stacking_height() * $self->get_label()->get_stacking_level();


    if ($self->is_visible()) { 
	if ($self->get_label_side() eq "right") { 
	    my $x = $self->get_chromosome()->get_horizontal_offset()
		+int($self->get_chromosome()->get_width()/2)
		+$stacking;
	    
	    my $label_horizontal_position = $x + 50;
	    if ($stacking > 200) { 
		$label_horizontal_position=$x-100; 
		$self->get_label()->align_right();
	    }
	    $self->get_label()->set_horizontal_offset($label_horizontal_position);
	    $self->get_label()->set_reference_point($x, int($north_pixels+$south_pixels)/2);
	    
	}
	elsif ($self->get_label_side() eq "left") { 
	    my $x = $self->get_chromosome()->get_horizontal_offset()-int($self->get_chromosome()->get_width()/2) - $self->get_label()->get_stacking_height()*($self->get_label()->get_stacking_level());
	    
	    $self->get_label()->set_horizontal_offset($x-50);
	    $self->get_label()->set_reference_point($x, int($north_pixels+$south_pixels)/2);
	    
	}
	else { 
	    die "[RangeMarker.pm] label_side can either be right or left. Sorry.";
	}
	if ($self->is_label_visible()) { 
	    $self->get_label()->render($image);
	}
	
	if ($self->get_hilite_chr_region()) { 
	    $self->hilite_chr_region($image);
	}
	$self->draw_tick($image);
    }
    
}


=head2 accessors set_region_hilite_color(), get_region_hilite_color()

  Property:	
  Setter Args:	
  Getter Args:	
  Getter Ret:	
  Side Effects:	
  Description:	

=cut

sub get_region_hilite_color { 
    my $self=shift;
    return @{$self->{region_hilite_color}};
}

sub set_region_hilite_color { 
    my $self=shift;
    @{$self->{region_hilite_color}}= (shift, shift, shift);
}

=head2 accessors set_hilite_chr_region(), get_hilite_chr_region()

  Property:	
  Setter Args:	
  Getter Args:	
  Getter Ret:	
  Side Effects:	
  Description:	

=cut

sub get_hilite_chr_region { 
    my $self=shift;
    return $self->{hilite_chr_region};
}

sub set_hilite_chr_region { 
    my $self=shift;
    $self->{hilite_chr_region}=shift;
}

sub draw_tick { 
    my $self = shift;
    my $image = shift;
    my $color = $image -> colorResolve($self->get_color());

    my ($x, $north_y, $y, $south_y) = $self->get_enclosing_rect();

    if ($self->get_show_tick()) { 	
	$image -> rectangle($x, $north_y, $y, $south_y, $color);
    }
}

sub get_image_map { 
    my $self = shift;
    my $coords = join ",", ($self->get_enclosing_rect());

    
    my $s= '<area shape="rect" coords="'.$coords.'" href="'.$self->get_url().'" alt="'.$self->get_marker_name().'" title="'.$self->get_tooltip().'" />';
    #print STDERR "Imagemap = $s\n";
    return $s;

}

sub get_enclosing_rect { 
    my $self = shift;
    my $halfwidth = int($self->get_chromosome->get_width/2);
    my $north_y = $self->get_chromosome()->get_vertical_offset() + $self->get_chromosome()->mapunits2pixels($self->get_offset()-$self->get_north_range());

    my $south_y = $self->get_chromosome()->get_vertical_offset() + $self->get_chromosome()->mapunits2pixels($self->get_offset()+$self->get_south_range());

    my $x = $self->get_chromosome()->get_horizontal_offset()+$halfwidth+$self->get_label()->get_stacking_height()*$self->get_label()->get_stacking_level();
    return ($x-1, $north_y, $x+1, $south_y);
}

return 1;

