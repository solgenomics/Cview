


=head1 NAME

CXGN::Cview::PachyteneRuler - a class for a pachytene chromosome ruler.

=head1 DESCRIPTION

Inherits from L<CXGN::Cview::Ruler>.  This class adds two accessors: set_short_arm_pixels() and set_long_arm_pixels(). These will represent the number of pixels that are in the short arm and long arm. The default unit is "%". Zero will be drawn in the middle of the arms, and the percent extending out in the arms will be labeled outwards toward the telomeres, which are both 100%. 

=head1 SEE ALSO

See also the documentation in L<CXGN::Cview>.

=head1 AUTHOR(S)

Lukas Mueller (lam87@cornell.edu)

=head1 FUNCTIONS


=cut


1;

use strict;
use CXGN::Cview::Ruler;

package CXGN::Cview::Ruler::PachyteneRuler;

use base qw( CXGN::Cview::Ruler );

sub new { 
    my $class = shift;
    my $self = $class -> SUPER::new(@_);
    
}

sub set_short_arm_ruler_pixels { 
    my $self = shift;
    $self->{short_arm_ruler_pixels} = shift;
}

sub set_long_arm_ruler_pixels { 
    my $self = shift;
    $self->{long_arm_ruler_pixels}=shift;
}

sub render { 
    
    my $self = shift;
    my $image=shift;
    
    my $blackcolor = $image -> colorResolve($self->{color}[0], $self->{color}[1], $self->{color}[2]);
    my $redcolor =   $image -> colorResolve(255, 50, 50);
    my $color = $blackcolor;
   #draw line
    $image -> line($self->get_horizontal_offset(), $self->get_vertical_offset(), $self->get_horizontal_offset(), $self->get_vertical_offset()+$self->get_height(), $color);
    
    #draw tick marks
    foreach my $i (0, 50, 100) {
	#print STDERR "SHORT ARM: $self->{short_arm_ruler_pixels}. LONG ARM: $self->{long_arm_ruler_pixels}\n";
	my $y_short = $self->get_vertical_offset()+$self->{short_arm_ruler_pixels} - ($i*$self->{short_arm_ruler_pixels}/100);
	my $y_long  = $self->get_vertical_offset()+$self->{short_arm_ruler_pixels}  + ($i*$self->{long_arm_ruler_pixels}/100);
	foreach my $y ($y_short, $y_long) { 
	    
	    if ($i ==0) { $color = $redcolor; } else { $color=$blackcolor; }
	    $image -> line($self->get_horizontal_offset()-2, $y, $self->get_horizontal_offset()+2, $y, $color); 
	    $self->draw_label($image, $i, $self->get_horizontal_offset(), $y, $color);
	}
	
    }
    my $label = "[".$self->get_units()."]";
    $image -> string($self->{font}, $self->get_horizontal_offset()-$self->{font}->width()*length($label)/2, $self->get_vertical_offset()-$self->{font}->height()-3, $label, $color);
    
    
}

sub draw_label {
    my $self = shift;
    my $image = shift;
    my $name = shift;
    my $x_pos = shift;
    my $y_pos = shift;
    my $color = shift;
    
    if ($self->{label_side} eq "left") { 
	$image -> string($self->{font}, $x_pos-$self->{font}->width*length($name)-2, $y_pos - $self->{font}->height/2, $name, $color);
    }
    if ($self->{label_side} eq "right") {
	$image -> string($self->{font}, $x_pos+4, $y_pos - $self->{font}->height/2, $name, $color);
    } 
}
