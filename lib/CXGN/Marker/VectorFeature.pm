
use strict;

package CXGN::Cview::Marker::VectorFeature;

use base ("CXGN::Cview::Marker::RangeMarker");

use GD;

=head2 new

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    $self->set_color(0,0,0);
    $self->set_label_spacer(50);
    return $self;
}

=head2 render

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub render {
    my $self = shift;
    my $image = shift;

    #die "now rendering a marker!";


   #  my $feature_color = $image->colorAllocate(255, 100, 100);
#     my ($start_x, $start_y) = $self->get_chromosome()->mapunits2pixels($self->get_start());

#     #$image->line(10,10, 50, 50, $color);

#     my $angle = $self->get_chromosome()->angle($self->get_start());
#     my $width = $self->get_chromosome()->get_width();
#     #die "Angle is $angle. Width is ".$self->get_chromosome->get_width."\n";
    
#     #$image->line($start_x, $start_y, $start_x - sin($angle) * $width, $start_y - cos($angle) * $width, $color);

#     $angle = $self->get_chromosome()->angle($self->get_end());

#     my ($end_x, $end_y) = $self->get_chromosome()->mapunits2pixels($self->get_end());

#     my $d = $self->get_chromosome()->get_length() / 100;    
     
#     #die $self->get_north_range()." : ". $self->get_offset . " : ".$self->get_south_range();
    
#     if ( ( $self->get_offset()  - $self->get_north_range() > 2) || ($self->get_south_range()- $self->get_offset() > 2)) { 

# 	$self->draw_tick($image, $self->get_start());
# 	$self->draw_tick($image, $self->get_end());
# 	my $midpoint_angle = $self->get_chromosome()->angle($self->get_offset());
# 	my ($offset_x, $offset_y) = $self->get_chromosome()->mapunits2pixels($self->get_offset());
# 	$image->fill($offset_x - sin($midpoint_angle) * $width/2 , $offset_y - cos($midpoint_angle) * $width/2 , $feature_color);
#     }
#     else { 
# 	#$image->line($end_x, $end_y, $end_x - sin($angle) * $width, $end_y - cos($angle) * $width, $color);
 
    #}

    $self->render_region($image);
    $self->get_label()->render($image);

}

=head2 render_region

 Usage:        $m->render_region()
 Desc:         for range markers, renders the region of the 
               marker that highlights its position on the 
               chromosome.
 Ret:
 Args:
 Side Effects:
 Example:

=cut



sub render_region { 
    
    my $self = shift;
    my $image = shift;
    
    my $color = $image->colorAllocate($self->get_color());

    my ($start_x, $start_y) = $self->get_chromosome()->mapunits2pixels($self->get_start());

    #$image->line(10,10, 50, 50, $color);

    my $angle = $self->get_chromosome()->angle($self->get_start());
    my $width = $self->get_chromosome()->get_width();
    #die "Angle is $angle. Width is ".$self->get_chromosome->get_width."\n";
    
    #$image->line($start_x, $start_y, $start_x - sin($angle) * $width, $start_y - cos($angle) * $width, $color);

    $angle = $self->get_chromosome()->angle($self->get_end());

    my ($end_x, $end_y) = $self->get_chromosome()->mapunits2pixels($self->get_end());

    my $d = $self->get_chromosome()->get_length() / 100;    
     
    #die $self->get_north_range()." : ". $self->get_offset . " : ".$self->get_south_range();
    
    if ($self->has_range()) { 
	$self->draw_tick($image, $self->get_start());
	$self->draw_tick($image, $self->get_end());
	my $midpoint_angle = $self->get_chromosome()->angle($self->get_offset());
	my ($offset_x, $offset_y) = $self->get_chromosome()->mapunits2pixels($self->get_offset());
	$image->fill($offset_x - sin($midpoint_angle) * $width/2 , $offset_y - cos($midpoint_angle) * $width/2 , $color);
    }
    else { 
	$self->draw_tick($image, $self->get_offset());
    }
  
}

sub draw_tick { 
    my $self = shift;
    my $image = shift;
    my $offset = shift;

    my $d = $self->get_chromosome()->get_length() / 100;   
    my $color = $image->colorAllocate($self->get_color());
    $image->setAntiAliased($color);
    my $width = $self->get_chromosome()->get_width();
    my $angle = $self->get_chromosome()->angle($offset);
    my ($start_x, $start_y) = $self->get_chromosome()->mapunits2pixels($offset);
    my $tip_offset = $offset + $d;

    if (!($self->has_range())) {
	#die "Drawing a straight line...";
	$image->line($start_x, $start_y, $start_x - sin($angle) * $width, $start_y - cos($angle) * $width, gdAntiAliased);
	return;
	
    }
    
    if ($self->get_orientation() eq "R") { $tip_offset = $offset - $d; }
    else { 
	#die "Forward orientation";
    }
    my ($t_x, $t_y) = $self->get_chromosome()->mapunits2pixels($tip_offset);
    my $beta = $self->get_chromosome()->angle($tip_offset);
    my $tip_x = $t_x - sin($beta) * $self->get_chromosome()->get_width()/2;
    my $tip_y = $t_y - cos($beta) * $self->get_chromosome()->get_width()/2;
    $image->line($start_x, $start_y, $tip_x, $tip_y, gdAntiAliased);
    $image->line($tip_x, $tip_y, $start_x - sin($angle) * $width, $start_y - cos($angle) * $width, gdAntiAliased);
}



return 1;
