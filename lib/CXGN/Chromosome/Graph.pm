
=head1 NAME

CXGN::Cview::Chromosome::Graph - an abstract class for displaying numeric quanity information alongside a genetic map

=head1 DESCRIPTION

Inherits from L<CXGN::Cview::Chromosome>. Current implementations include L<CXGN::Cview::Chromosome::BarGraph>, to display a bar graph along the chromosome, and L<CXGN::Cview::Chromosome::LineGraph>, to display a line graph along the chromosome, such as lod scores from a QTL experiment.

=head1 SEE ALSO

See also the documentation in L<CXGN::Cview>.

=head1 AUTHOR(S)

Lukas Mueller (lam87@cornell.edu)

=head1 FUNCTIONS


=cut

use strict;


    
package CXGN::Cview::Chromosome::Graph;

use CXGN::Cview::Chromosome;
use base qw(CXGN::Cview::Chromosome);

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
    %{$self->{offset}} = ();
    $self -> set_color(100,100,0);
    $self -> {font} = GD::Font->Tiny();
    $self-> set_caption("");
    return $self;
}


=head2 accessors get_types(), set_types()

  Status:       DEPRECATED. Use get_tracks() and set_tracks().
  Synopsis:	$physical->set_types("overgo", "computational", "manual");
  Args/Ret:	a list of legal types. This is normally set in the constructor.
  Side effects:	adding a type using the add_association that is not in the 
                list set by set_types will cause an error.
                The color for each type can be set by calling 
                set_color_type("type", "<COLOR>")
  Description:	the bargraph can display a number of "tracks", each of which
                needs an associated type and color. 

=cut

sub set_types { 
    my $self = shift;
    $self->set_tracks(@_);
}

sub get_types { 
    my $self = shift;
    return $self->get_tracks();
}

=head2 accessors get_tracks(), set_tracks()

 Usage:        $physical->set_tracks("overgo", "computational", "manual");
 Args/Ret:     a list of legal types. A default may be set in the constructor.
 Side effects: adding a type using the add_association that is not in the 
               list set by set_types will cause an error.
               The color for each type can be set by calling 
               set_color_type("type", "<COLOR>")
 Description:  the bargraph can display a number of tracks, each of which
               needs an associated type and color. This method replaces the
               somewhat mis-named get_types() and set_types() methods.

=cut

sub get_tracks {
  my $self = shift;
  return @{$self->{tracks}}; 
}

sub set_tracks {
  my $self = shift;
  @{$self->{tracks}} = @_;
}



=head2 accessors set_log_base(), get_log_base()

  STATUS:       NOT IMPLEMENTED
  Property:	the base of the logarithm to use for drawing
                the y axis (which is horizontal, actually).
                zero indicates that a linear scale should be
                used
                
  Args/Ret:     the base of the log. 0=linear.
  Side Effects:	the bar graph is drawn with the log of this base.

=cut

sub get_log_scale { 
    my $self=shift;
    return $self->{log_scale};
}

sub set_log_scale { 
    my $self=shift;
    $self->{log_scale}=shift;
}



=head2 function add_association()

  Synopsis:	$physical -> add_association($type, $offset, $value);
  Arguments:	offset - the offset in the appropriate unit
                type - the type of association. For exampe, for the 
                physical map, three types can be defined:
                overgo, computational, and manual. The legal types should
                be set in the constructor. Specifying other types 
                than the ones defined will raise an error.
  Returns:	nothing
  Side effects:	the offset position of the given type will be incremented 
                by one. This will be reflected in the rendering of the 
                physical object.
  Description:	

=cut

sub add_association {
    my $self = shift;
    my $type = shift;
    my $offset = shift;
    my $value = shift;
    
    #print STDERR "Adding BAC assoc: offset=$offset, bac_id=$bac_id\n";
    if (!grep (/$type/, ($self->get_tracks()))) { 
	die "[CXGN::Cview::physical::add_bac_association] $type not a legal type \n";
    }
    $self->{offset}{$type}[$offset] += $value;
}

sub _get_largest_group {
    my $self = shift;
    my $largest = 0;
    if (exists($self->{offset})) { 
	foreach my $type ($self->get_types()) {
	    if (exists($self->{offset}{$type})) { 
		for (my $i=0; $i<(@{$self->{offset}{$type}}); $i++) {
		    #print STDERR "offset = $i\n";
		    if (exists($self->{offset}{$type}[$i])) { 
			if ($self->{offset}{$type}[$i]>$largest) { 
			    $largest = $self->{offset}{$type}[$i]; 
			}
		    }
		}   
	    }
	}
    }
    return $largest;
}
    
=head2 accessors set_maximum(), get_maximum()

 Usage:         $graph->set_maximum(200);
 Desc:          the maximum value in graph units for the graph
                if it is not set, it should scale to the largest
                value in the series.
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_maximum {
  my $self=shift;
  $self->{maximum}=shift;
}

sub get_maximum { 
    my $self = shift;
    return $self->{maximum};
}



=head2 function render()

  Synopsis:	render should draw the graph on a GD image object
  Arguments:	an GD image object
  Returns:	
  Side effects:	this is an abstract class, therefore this does 
                nothing. Extend this class and implement the render
                function there.
  Description:	

=cut

sub render {
    my $self= shift;
    my $image = shift;

#     $self->_calculate_chromosome_length();
#     $self->_calculate_scaling_factor();

#     #print STDERR "rendering physical...\n";

#     my $color = $image -> colorResolve($self->{color}[0], $self->{color}[1], $self->{color}[2]);
    
#     # draw coordinate system lines
#     #
#     my $halfwidth = $self->get_width()/2;
#     $self->{largest} = $self->_get_largest_group();
    
#     $image -> line($self->get_horizontal_offset()-$halfwidth, $self->get_vertical_offset(), $self->get_horizontal_offset()-$halfwidth, $self->get_vertical_offset()+$self->{height}, $color);

#     $image -> stringUp($self->{font}, $self->get_horizontal_offset()-$halfwidth-$self->{font}->height()/2, $self->get_vertical_offset()-4, "Chr ".$self->get_caption(), $color);
    
#     # draw the 10 line. Logarithmic scale
#     #
#     my $x = $self->get_horizontal_offset()-$halfwidth+log(10)/log($self->{largest})*$self->get_width();
#     $image -> dashedLine ($x, $self->get_vertical_offset(), $x, $self->get_vertical_offset()+$self->{height}, $color);
#     $image -> stringUp ($self->{font}, $x - $self->{font}->height()/2, $self->get_vertical_offset()-4,"10", $color);

#     # draw the 100 line. Logarithmic scale
#     #
#     if ($self->{largest}>100) { 

# 	$x = $self->get_horizontal_offset()-$halfwidth+log(100)/log($self->{largest})*$self->get_width();
# 	$image -> dashedLine ($x, $self->get_vertical_offset(), $x, $self->get_vertical_offset()+$self->{height}, $color);
# 	$image -> stringUp ($self->{font}, $x - $self->{font}->height()/2, $self->get_vertical_offset()-4,"100", $color);
#     }
#     # draw the boxes
#     # 
#     print STDERR "Largest = $self->{largest} WIDTH= ".$self->get_width()."\n";
#     #print STDERR "Physical connections: ".@{$self->{offset}}."\n";
#     foreach my $type ($self->get_types()) { 
# 	if (exists($self->{offset}{$type})) { 
# 	    for (my $i=0; $i<(@{$self->{offset}{$type}}); $i++) {
# 		#print STDERR "offset = $i, $self->{offset}[$i]\n";
# 		if ($self->{offset}{$type}[$i]) {
# 		    my $y = $self->get_vertical_offset()+$self->mapunits2pixels($i);
# 		    #print STDERR "Drawing box...y = $y scaling: $self->{scaling_factor}\n";
# 		    my $box_width = log($self->{offset}{$type}[$i])/log($self->{largest})*$self->get_width();
# 		    if ($box_width<1) { $box_width=2; }
# 		    if ($type eq "computational") { 
# 			my $computational_color = $image->colorResolve(230, 100, 100);
# 			$image -> rectangle(
# 					      $self->get_horizontal_offset()+1 - $halfwidth, 
# 					      $y-$self->{box_height}/2, 
# 					      ($self->get_horizontal_offset()-$halfwidth)+$box_width,  
# 					      $y + $self->{box_height}/2, 
# 					      $computational_color);
# 		    }
# 		    else { 
# 			$image -> filledRectangle(
# 						  $self->get_horizontal_offset() - $halfwidth, 
# 						  $y-$self->{box_height}/2, 
# 						  ($self->get_horizontal_offset()-$halfwidth)+$box_width,  
# 						  $y + $self->{box_height}/2, 
# 						  $color);
# 		    }
# 		}
# 	    }
# 	}
#     }

}


sub draw_chromosome { 
    my $self = shift;
    my $image = shift;
    $self->render($image);
}

sub get_box_rect {
    my $self = shift;
    my $offset = shift;
    my $type = shift;
    my $y = $self->get_vertical_offset()+$offset;
    if ($self->{offset}{$type}[$offset] > 0 && $self->{largest}>0) {
	print STDERR "LARGEST: $self->{largest}\n";
	print STDERR "WIDTH ". $self->get_width()."\n";
	my $box_width = log($self->{offset}{$type}[$offset])/log($self->{largest})*$self->get_width();
	if ($box_width<1) { $box_width=2; }
	return ($self->get_horizontal_offset() - $self->get_width()/2, $y-$self->{box_height}/2, ($self->get_horizontal_offset()-$self->get_width()/2)+$box_width,  $y + $self->{box_height}/2);    
    }
}

sub get_image_map {
    my $self = shift;
    my $string = "";
    my ($x, $y, $a, $b) = $self->get_enclosing_rect();
    my $url = $self->get_url();
    $string .= qq{ <area shape="rect" coords="$x, $y, $a, $b" href="$url" alt="" /> };
#     #print STDERR "get_image_map physical\n";
#     if ($self->get_url()) {
# 	foreach my $type ($self->get_types()) { 
# 	    for (my $i; $i<(@{$self->{offset}{$type}}); $i++) {
# 		my ($x, $y, $v, $w) = $self -> get_box_rect($i, $type);
# 		$string .="<area shape=\"rect\" coords=\"$x, $y, ".($self->get_horizontal_offset()+$self->get_width()/2).", $w \" href=\"".$self->get_url()."\" alt=\"\" />";
# 	    }
# 	}
#     }
    return $string;
}


 
return 1;
