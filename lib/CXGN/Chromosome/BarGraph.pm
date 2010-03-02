
=head1 NAME

CXGN::Cview::Chromosome::BarGraph - a class for displaying numeric quanity information alongside a genetic map

=head1 DESCRIPTION

Inherits from the abstract class L<CXGN::Cview::Chromosome::Graph> and implements a bar graph along a chromosome. If a graph is added to the chromosome with the add_bargraph() method, and set to be visible by the show_bargraph() method, it is rendered automatically along the chromosome when calling render() on the chromosome. 

=head1 SEE ALSO

See also the documentation in L<CXGN::Cview>.

=head1 AUTHOR(S)

Lukas Mueller (lam87@cornell.edu)

=head1 FUNCTIONS


=cut

use strict;


    
package CXGN::Cview::Chromosome::BarGraph;

use CXGN::Cview::Chromosome;
use base qw(CXGN::Cview::Chromosome::Graph);

=head2 function new()

  Synopsis:	constructor
  Arguments:	none
  Returns:	a pointer to the CXGN::Cview::Chromosme::BarGraph object
  Side effects:	
  Description:	

=cut

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    $self->{box_height}=4;
#    %{$self->{offset}} = ();
#    $self -> set_color(100,100,0);
#    $self -> {font} = GD::Font->Tiny();
#    $self-> set_caption("count");
    $self-> set_tracks("overgo", "computational", "manual");
#    $self->set_maximum(100);
    return $self;
}


=head2 function set_box_height()

  Synopsis:	$physical->set_box_height(4);
  Arguments:	the width of the bar graph bars in pixels.
  Returns:	nothing
  Side effects:	the bar graph will be rendered with the width
                specified with this function.
  Description:	

=cut

sub set_box_height { 
    my $self = shift;
    $self->{box_height}=shift;
}


=head2 function render()

  Synopsis:	$bg->render($image)
  Arguments:	a GD::Image object
  Returns:	
  Side effects:	renders the graph on the image
  Description:	

=cut

sub render {
    my $self= shift;
    my $image = shift;

    $self->_calculate_chromosome_length();
    $self->_calculate_scaling_factor();

    #print STDERR "rendering physical...\n";

    my $color = $image -> colorResolve($self->{color}[0], $self->{color}[1], $self->{color}[2]);
    
    # draw coordinate system lines
    #
    my $halfwidth = $self->get_width()/2;
    $self->{largest} = $self->_get_largest_group();
    
    $image -> line($self->get_horizontal_offset()-$halfwidth, $self->get_vertical_offset(), $self->get_horizontal_offset()-$halfwidth, $self->get_vertical_offset()+$self->{height}, $color);

    $image -> stringUp($self->{font}, $self->get_horizontal_offset()-$halfwidth-$self->{font}->height()/2, $self->get_vertical_offset()-4, "Chr ".$self->get_caption(), $color);
    
    # draw the 10 line. Logarithmic scale
    #
    my $x = $self->get_horizontal_offset()-$halfwidth+log(10)/log($self->{largest})*$self->get_width();
    $image -> dashedLine ($x, $self->get_vertical_offset(), $x, $self->get_vertical_offset()+$self->{height}, $color);
    $image -> stringUp ($self->{font}, $x - $self->{font}->height()/2, $self->get_vertical_offset()-4,"10", $color);

    # draw the 100 line. Logarithmic scale
    #
    if ($self->{largest}>100) { 

	$x = $self->get_horizontal_offset()-$halfwidth+log(100)/log($self->{largest})*$self->get_width();
	$image -> dashedLine ($x, $self->get_vertical_offset(), $x, $self->get_vertical_offset()+$self->{height}, $color);
	$image -> stringUp ($self->{font}, $x - $self->{font}->height()/2, $self->get_vertical_offset()-4,"100", $color);
    }
    # draw the boxes
    # 
    print STDERR "Largest = $self->{largest} WIDTH= ".$self->get_width()."\n";
    #print STDERR "Physical connections: ".@{$self->{offset}}."\n";
    foreach my $type ($self->get_types()) { 
	if (exists($self->{offset}{$type})) { 
	    for (my $i=0; $i<(@{$self->{offset}{$type}}); $i++) {
		#print STDERR "offset = $i, $self->{offset}[$i]\n";
		if ($self->{offset}{$type}[$i]) {
		    my $y = $self->get_vertical_offset()+$self->mapunits2pixels($i);
		    #print STDERR "Drawing box...y = $y scaling: $self->{scaling_factor}\n";
		    my $box_width = log($self->{offset}{$type}[$i])/log($self->{largest})*$self->get_width();
		    if ($box_width<1) { $box_width=2; }
		    if ($type eq "computational") { 
			my $computational_color = $image->colorResolve(230, 100, 100);
			$image -> rectangle(
					      $self->get_horizontal_offset()+1 - $halfwidth, 
					      $y-$self->{box_height}/2, 
					      ($self->get_horizontal_offset()-$halfwidth)+$box_width,  
					      $y + $self->{box_height}/2, 
					      $computational_color);
		    }
		    else { 
			$image -> filledRectangle(
						  $self->get_horizontal_offset() - $halfwidth, 
						  $y-$self->{box_height}/2, 
						  ($self->get_horizontal_offset()-$halfwidth)+$box_width,  
						  $y + $self->{box_height}/2, 
						  $color);
		    }
		}
	    }
	}
    }
}



 
return 1;
