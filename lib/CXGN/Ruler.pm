
=head1 NAME

CXGN::Cview::Ruler - an class for drawing rulers

=head1 DESCRIPTION

Inherits from L<CXGN::Cview::ImageObject>. The basic class draws a simple linear ruler with the default units of cM. Each chromosome object knows what type of ruler it should use and the ruler for a given chromosome object can be obtained with get_ruler(). (set_ruler() is called in the chromosome objects constructor, where it constructs the right type of ruler to go with the chromosome).

=head1 KNOWN SUBCLASSES

L<CXGN::Cview::Ruler::PachyteneRuler> implements a ruler for fish chromosomes.

=head1 SEE ALSO

See also the documentation in L<CXGN::Cview>.

=head1 AUTHOR(S)

Lukas Mueller (lam87@cornell.edu)

=head1 FUNCTIONS


=cut

1;

use strict;
use CXGN::Cview::ImageObject;

package CXGN::Cview::Ruler;

use base qw( CXGN::Cview::ImageObject );

=head2 function new()

  Synopsis:	constructor.
  Arguments:	x-position, y-position, height, start value, 
                end_value.
  Returns:	a CXGN::Cview::Ruler object.
  Side effects:	sets the default units to "cM". 
                use set_unit() to change the units.
  Description:	

=cut

sub new {
    my $class = shift;
    my $args ={};
    my $self = $class -> SUPER::new(@_);
    my $x = shift;
    my $y = shift;
    $self ->{height} = shift;
    $self ->{start_value} = shift;
    $self ->{end_value} = shift;
    $self -> {font} = GD::Font->Small();
    $self -> set_color (50, 50, 50);
    $self -> {label_side} = "left";
    $self -> set_units("cM");
    return $self;
}

=head2 function set_color()

  Synopsis:	sets the color of the ruler
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

# Note: this function is defined in the parent class and 
# there is no need to override it here.
#
# sub set_color {
#     my $self = shift;
#     $self -> {color}[0] = shift;
#     $self -> {color}[1] = shift;
#     $self -> {color}[2] = shift;
# }

=head2 functions set_labels_right(), set_labels_left(), set_labels_none()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub set_labels_right {
    my $self = shift;
    $self->{label_side} = "right";
}

sub set_labels_left {
    my $self = shift;
    $self ->{label_side} = "left";
}

sub set_labels_none {
    my $self = shift;
    $self -> {label_side} = "";
}

=head2 functions get_units(), set_units()

  Synopsis:	sets the units displayed on the ruler.
                default is "cM".
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub set_units {
    my $self=shift;
    $self->{unit}=shift;
}

sub get_units { 
    my $self = shift;
    return $self->{unit};
}

=head2 function get_start_value()

 Synopsis:	accessor for the start_value property
 Arguments:	
 Returns:	
 Side effects:	
 Description:	

=cut

sub get_start_value { 
    my $self=shift;
    return $self->{start_value};
}

=head2 function set_start_value()

 Synopsis:	setter function for the start_value property
 Arguments:	the start value in map units
 Returns:	nothing
 Side effects:	defines the start value of the chromosome section
                in map units.
 Description:	

=cut

sub set_start_value { 
    my $self=shift;
    $self->{start_value}=shift;
}

=head2 function get_end_value(), set_end_value()

 Synopsis:	
 Arguments:	
 Returns:	
 Side effects:	
 Description:	

=cut

sub get_end_value { 
    my $self=shift;
    return $self->{end_value};
}

sub set_end_value { 
    my $self=shift;
    $self->{end_value}=shift;
}

=head2 function render()

  Synopsis:	renders the ruler on $image
  Arguments:	$image (GD::Image object).
  Returns:	nothing
  Side effects:	draws the ruler image on $image.
  Description:	

=cut


sub render {
    my $self = shift;
    my $image=shift;

    my $color = $image -> colorResolve($self->{color}[0], $self->{color}[1], $self->{color}[2]);

    $self->_calculate_scaling_factor();
    
    #draw line
    $image -> line($self->get_horizontal_offset(), $self->get_vertical_offset(), $self->get_horizontal_offset(), $self->get_vertical_offset()+$self->{height}, $color);
    my $length = 1;
    if ($self->{scaling_factor})  { 
	 $length = $self->get_height()/$self->{scaling_factor};
    }


    print STDERR "Length = $length\n";
    # draw tick marks
    #
    my $tick_spacing = 1;
    if ($length < 1000) { $tick_spacing=50; }
    if ($length < 500) { $tick_spacing = 25; }
    if ($length < 250) { $tick_spacing = 10; }
    if ($length < 100) { $tick_spacing = 5; }
    if ($length < 50) { $tick_spacing = 2; }
    if ($length < 10) { $tick_spacing = 0.5; }
    if ($length < 1) { $tick_spacing=0.1; }
    
    #my $tick_spacing = int($self->get_height()/40); # the spacing of the ticks in map units
    
    # the minor ticks need to be at least 10 pixels apart...
    #
    if ($tick_spacing*$self->{scaling_factor}<10) { 
	print STDERR "tick spacing too small... setting to 10.\n";
	$tick_spacing=10; 
    }
    my $label_spacing = 2 * $tick_spacing; # the spacing of the labels in map units


    # if the labels overlap, then we increment the label_spacing such that they don't.
    #
    if ($self->{scaling_factor})  { 
	#otherwise this is an infinite loop....
	while (($label_spacing * abs($self->{scaling_factor})) < ($self->{font}->height())) { 
	    $label_spacing +=10; 
	    print STDERR "Extending label_spacing... $label_spacing scaling: $self->{scaling_factor}\n";
        }
    }
    #if ($self->{end_value} < 100) { $label_spacing=10; $tick_spacing=5; }
    my $tick_number = int($self->{end_value}-$self->{start_value})/$tick_spacing;
    
    for (my $i=0; $i<$tick_number; $i++) {
	my $y = $self->get_vertical_offset() + (($i*$tick_spacing)*$self->{scaling_factor});
	$image -> line($self->get_horizontal_offset()-2, $y, $self->get_horizontal_offset()+2, $y, $color); 
	
	if  ($i*$tick_spacing % $label_spacing ==0) { 
	    if ($self->{label_side} eq "left") { 
		$image -> string($self->{font}, $self->get_horizontal_offset()-$self->{font}->width*length($i*$tick_spacing)-2, $y - $self->{font}->height/2, $i*$tick_spacing, $color);
	    }
	    if ($self->{label_side} eq "right") {
		$image -> string($self->{font}, $self->get_horizontal_offset()+4, $y - $self->{font}->height/2, $i*$tick_spacing, $color);
	    } 
	}
    }
    my $label = "[".$self->{unit}."]";
    $image -> string($self->{font}, $self->get_horizontal_offset()-$self->{font}->width()*length($label)/2, $self->get_vertical_offset()-$self->{font}->height()-3, $label, $color);

}

sub _calculate_scaling_factor {
    my $self = shift;
    my $dist = ($self->{end_value}-$self->{start_value});
    if ($dist ==0) { return 0; }
    $self -> {scaling_factor} = $self->{height}/($self -> {end_value} - $self->{start_value});
    return $self->{scaling_factor};
}
