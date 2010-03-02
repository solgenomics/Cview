
=head1 NAME

CXGN::Cview::Chromosome::LineGraph - a class for displaying numeric quanity information alongside a genetic map

=head1 DESCRIPTION

Inherits from L<CXGN::Cview::Chromosome::Graph>. 

=head1 SEE ALSO

See also the documentation in L<CXGN::Cview>.

=head1 AUTHORS

Lukas Mueller (lam87@cornell.edu) and Isaak Tecle (iyt2@cornell.edu)

=head1 FUNCTIONS


=cut

use strict;

use CXGN::Cview::Chromosome;
    
package CXGN::Cview::Chromosome::LineGraph;

use base qw(CXGN::Cview::Chromosome::Graph);

=head2 function new()

  Synopsis:	constructor
  Arguments:	none
  Returns:	a pointer to the CXGN::Cview::Chromosme::LineGraph object
  Side effects:	
  Description:	

=cut

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    $self->set_types("LOD");
    $self->set_color(100,100,100);
    return $self;
}

=head2 function render()

  Synopsis:	$lg -> render($image)
  Arguments:	a GD::Image object
  Returns:	
  Side effects:	
  Description:	renders the graph on the image

=cut

sub render {
    my $self= shift;
    my $image = shift;

    $self->_calculate_chromosome_length();
    $self->_calculate_scaling_factor();

    #print STDERR "rendering physical...\n";

    my $color = $image -> colorResolve($self->get_color());
    
    # draw coordinate system lines
    #
    my $halfwidth = $self->get_width()/2;

    if (defined($self->get_maximum())) { 
	$self->{largest} = $self->get_maximum();
    }
    else { 
	$self->{largest} = $self->_get_largest_group();
    }
    
    $image -> line($self->get_horizontal_offset()-$halfwidth, $self->get_vertical_offset(), $self->get_horizontal_offset()-$halfwidth, $self->get_vertical_offset()+$self->{height}, $color);

    $image -> stringUp($self->{font}, $self->get_horizontal_offset()-$halfwidth-$self->{font}->height()/2, $self->get_vertical_offset()-4, $self->get_caption(), $color);
    
    # draw the 10 line. 
    #
    my $x = $self->get_horizontal_offset()-$halfwidth+10/($self->{largest})*$self->get_width();
    $image -> dashedLine ($x, $self->get_vertical_offset(), $x, $self->get_vertical_offset()+$self->{height}, $color);
    $image -> stringUp ($self->{font}, $x - $self->{font}->height()/2, $self->get_vertical_offset()-4,"10", $color);

    # draw the 2 line.
    #
    #if ($self->{largest}>100) { 
    my $red_color = $image->colorResolve(255, 0, 0);
    $x = $self->get_horizontal_offset()-$halfwidth+2/($self->{largest}*$self->get_width());
    $image -> dashedLine ($x, $self->get_vertical_offset(), $x, $self->get_vertical_offset()+$self->{height}, $red_color);
    $image -> stringUp ($self->{font}, $x - $self->{font}->height()/2, $self->get_vertical_offset()-4,"2", $color);
    #}
    # draw the boxes
    # 
    print STDERR "Largest = $self->{largest} WIDTH= ".$self->get_width()."\n";
    #print STDERR "Physical connections: ".@{$self->{offset}}."\n";
    foreach my $type ($self->get_types()) { 
	if (exists($self->{offset}{$type})) { 
	    my $last_position = $self->get_vertical_offset();
	    my $last_value = $self->get_horizontal_offset() - $halfwidth;
	    for (my $i=0; $i<(@{$self->{offset}{$type}}); $i++) {
		#print STDERR "offset = $i, $self->{offset}[$i]\n";
		if (exists($self->{offset}{$type}[$i])) {
		    my $y = $self->get_vertical_offset()+$self->mapunits2pixels($i);
		    #print STDERR "Drawing box...y = $y scaling: $self->{scaling_factor}\n";
		    my $x = ($self->get_horizontal_offset()-$halfwidth) + ($self->{offset}{$type}[$i]/($self->{largest})*$self->get_width());
		    #if ($box_width<1) { $box_width=2; }
		    
		    $image -> line(
					      $last_value, 
					      $last_position, 
					      $x,  
					      $y, 
					      $color);

		    print STDERR "x $last_value, y $last_position, x $x, y $y\n";
		    
		    $last_position = $y;
		    $last_value = $x;
		}
		

	    }
	}
    }
}


# sub draw_chromosome { 
#     my $self = shift;
#     my $image = shift;
#     $self->render($image);
# }

# sub get_box_rect {
#     my $self = shift;
#     my $offset = shift;
#     my $type = shift;
#     my $y = $self->get_vertical_offset()+$offset;
#     if ($self->{offset}{$type}[$offset] > 0 && $self->{largest}>0) {
# 	print STDERR "LARGEST: $self->{largest}\n";
# 	print STDERR "WIDTH ". $self->get_width()."\n";
# 	my $box_width = log($self->{offset}{$type}[$offset])/log($self->{largest})*$self->get_width();
# 	if ($box_width<1) { $box_width=2; }
# 	return ($self->get_horizontal_offset() - $self->get_width()/2, $y-$self->{box_height}/2, ($self->get_horizontal_offset()-$self->get_width()/2)+$box_width,  $y + $self->{box_height}/2);    
#     }
# }

# sub get_image_map {
#     my $self = shift;
#     my $string = "";
#     my ($x, $y, $a, $b) = $self->get_enclosing_rect();
#     my $url = $self->get_url();
#     $string .= qq{ <area shape="rect" coords="$x, $y, $a, $b" href="$url" alt="" /> };
# #     #print STDERR "get_image_map physical\n";
# #     if ($self->get_url()) {
# # 	foreach my $type ($self->get_types()) { 
# # 	    for (my $i; $i<(@{$self->{offset}{$type}}); $i++) {
# # 		my ($x, $y, $v, $w) = $self -> get_box_rect($i, $type);
# # 		$string .="<area shape=\"rect\" coords=\"$x, $y, ".($self->get_horizontal_offset()+$self->get_width()/2).", $w \" href=\"".$self->get_url()."\" alt=\"\" />";
# # 	    }
# # 	}
# #     }
#     return $string;
# }


 
return 1;
