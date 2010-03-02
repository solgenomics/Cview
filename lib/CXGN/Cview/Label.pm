

=head1 NAME

CXGN::Cview::Label - a class for managing labels with links and hilite etc.

=head1 DESCRIPTION

This class deals with text labels for the Cview classes. It is similar to the CXGN::Phylo::Label class and should be merged sometimes in the future. The Label class currently supports:

=over 5

=item o

Hiliting 

=item o

Left/right alignment

=item o

URL linking

=back

Future/partial support:

=over 5

=item o

vertical orientation for labels

=back

The idea of the label class is that it points to a reference point, which is set using set_reference_point(). Then you specify the distance on the side of the label, and the label will be drawn with a line to the reference point. The actual placement of the label occurs through the set_horizontal_offset and set_vertical_offset routines of the ImageObject interface from which Label inherits. You can also use align_right() to force the text label to align on the right side of the connector line, and set_align_left to force the text to align on the left. The default is if the horizontal coordinate of the reference point is smaller than the horizontal offset of the text label, the text label is aligned right, and left otherwise.

Inherits from L<CXGN::Cview::ImageObject>. 

=head1 SEE ALSO

See also the documentation in L<CXGN::Cview>.

=head1 AUTHOR(S)

Lukas Mueller (lam87@cornell.edu)

=head1 FUNCTIONS


=cut


1;

use strict;

use CXGN::Cview::ImageObject;

package CXGN::Cview::Label;

use base qw( CXGN::Cview::ImageObject );

use GD;

sub new { 
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    my $args = shift;
    $self->set_font(GD::Font->Small());
    $self->align_default();
    $self->set_hilite_color(255,255,0);
    $self->set_line_color(100,100,100);
    $self->set_text_color(30,30,30);
    $self->set_label_text($args->{name});
    $self->set_url($args->{url});
    $self->set_vertical_stacking_spacing(0);
    $self->set_stacking_height(0);
    $self->set_stacking_level(0);
    $self->set_label_spacer(30);
    
    return $self;
}

=head2 function get_label_text()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	same as get_name()

=cut

sub get_label_text { 
    my $self=shift;
    return $self->get_name();
}

=head2 function set_label_text()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	same as set_name()
  Description:	

=cut

sub set_label_text { 
    my $self=shift;
    my $label = shift;
    $self->set_name($label);
}

=head2 functions get_line_color(), function set_line_color()

 Synopsis:	
 Arguments:	gets/sets the color of the line connecting the label 
                with the marker. Default is black. Three numbers 
                between 0 and 255 for red, green and blue channels 
                are required.
 Returns:	
 Side effects:	
 Description:	gets/sets the line color connecting the label
                to the reference point

=cut

sub get_line_color { 
    my $self=shift;
    if (!exists($self->{line_color}) || (@{$self->{line_color}}==0)) { @{$self->{line_color}}=(255, 0, 0); }
    return @{$self->{line_color}};
}

sub set_line_color {
    my $self = shift;

    $self->{line_color}->[0]=shift;
    $self->{line_color}->[1]=shift;
    $self->{line_color}->[2]=shift;
}   

=head2 functions get_hilited(), set_hilited()

  Synopsis:	my $flag = $l->get_hilited()
  Args/Returns: a boolean value - true if the label is hilited
                false if it should be drawn without hiliting.
  Side effects:	label is drawn with the hilite color
  Description:	

=cut

sub get_hilited { 
    my $self=shift;
    return $self->{hilited};
}

sub set_hilited { 
    my $self=shift;
    $self->{hilited}=shift;
}

=head2 function get_hilite_color(), set_hilite_color()

  Synopsis:	$l->set_hilite_color(255,100,100)
  Args/Returns:	list of three values representing the hilite
                color
  Side effects:	the hilited markers will be drawn in this 
                color
  Description:	

=cut

sub get_hilite_color { 
    my $self=shift;
    if (!exists($self->{hilite_color})) { @{$self->{hilite_color}}=(255,255,255); }
    return @{$self->{hilite_color}};
}

sub set_hilite_color { 
    my $self=shift;
    @{$self->{hilite_color}}=@_;
}



=head2 function is_hidden()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub is_hidden { 
    my $self=shift;
    return $self->{hidden};
}

=head2 function set_hidden()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub set_hidden { 
    my $self=shift;
    $self->{hidden}=shift;
}

=head2 function get_reference_point()

  Synopsis:	
  Arguments:	
  Returns:	the point of reference that the label is attached to.
  Side effects:	
  Description:	

=cut

sub get_reference_point { 
    my $self=shift;
    if (!exists($self->{reference_point})) { @{$self->{reference_point}}=(0,0); }
    return @{$self->{reference_point}};
}

=head2 function set_reference_point()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub set_reference_point { 
    my $self=shift;
    @{$self->{reference_point}}=@_;
}

=head2 function align_right()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub align_right {
    my $self=shift;
    $self->{align_side}="right";
}

=head2 function align_left()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub align_left { 
    my $self=shift;
    $self->{align_side}="left";
}

=head2 function align_center()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub align_center { 
    my $self = shift;
    $self->{align_side}="center";
}

=head2 function align_default()

  Synopsis:	
  Arguments:	none
  Returns:	nothing
  Side effects:	chooses some reasonable default for label alignment
  Description:	

=cut

sub align_default {
    my $self =shift;
    $self->{align_side}="default";
}


=head2 function get_align_side()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub get_align_side { 
    my $self=shift;
    return $self->{align_side};
}

=head2 function set_align_side()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub set_align_side { 
    my $self=shift;
    $self->{align_side}=shift;
}

=head2 function get_text_color(), set_text_color()

  Synopsis:	
  Args/Returns: a list of three integers representing
                the three color components	
  Side effects:	the font will be drawn in this color
  Description:	

=cut

sub get_text_color { 
    my $self=shift;
    return @{$self->{text_color}};
}

sub set_text_color { 
    my $self=shift;
    @{$self->{text_color}}= @_;
}

=head2 function render()

  Synopsis:	
  Arguments:	a GD::Image object
  Returns:	nothing
  Side effects:	renders the marker on the image object
  Description:	

=cut

sub render { 
    my $self = shift;
    my $image = shift;

    $self->calc_coords();
    my ($x, $y, $a, $b) = $self->get_enclosing_rect();



    my $bg_color = $image->colorResolve($self->get_hilite_color());
    my $text_color = $image->colorResolve($self->get_text_color());

    # debug
#    $image->rectangle($x, $y, $a, $b, $text_color);

   
    #print STDERR "Rendering label: ".$self->get_name()." Location: $x, $y. \n";
    if (!$self->is_hidden()) { 
	if ($self->get_hilited()) { 
	    $image->filledRectangle($self->get_enclosing_rect(), $bg_color); 
	}
	
	$image->string($self->get_font(), $x, $y, $self->get_name(),$text_color);
	$self->render_line($image); 
    }
}

# render_line is factored out so that it is easy to create 
# subclasses that draw the lines differently (see for 
# example CXGN::Cview::Label::RangeLabel).
#
sub render_line { 
    my $self = shift;
    my $image = shift;
    my $line_color = $image->colorResolve($self->get_line_color());
    $image -> setAntiAliased($line_color);
    my $width = 0;

    # calculate the point that the line should connect to 
    # on the label
    #
    my ($x, $y, $a, $b) = $self->get_enclosing_rect();
    my ($connection_x, $connection_y) = (0, 0);

    if ($self->get_align_side() eq "right") { 
	$connection_x = $a;
	$connection_y = $y + CXGN::Cview::ImageObject::round(($b - $y ) /2);

    }
    elsif ($self->get_align_side() eq "left") { 
	$connection_x = $x;
	$connection_y = $y + CXGN::Cview::ImageObject::round(($b - $y)/2);
    }
    
    # adjust for label height
    #
    $image->line($connection_x, $connection_y,  ($self->get_reference_point())[0], ($self->get_reference_point())[1], gdAntiAliased );
    #$image->rectangle($self->get_enclosing_rect(), $line_color);
}

sub calc_coords { 
    my $self = shift;
    $self->calculate_width();
    $self->calculate_height();

    if ($self->get_align_side() eq "default") { 
	if ($self->get_horizontal_offset()<($self->get_reference_point())[0]) { 
	    $self->align_right();
	}
	else { 
	    $self->align_left();
	}
    }
    
    my ($x, $y) = ($self->get_horizontal_offset(), $self->get_vertical_offset());
    my ($a, $b);

    $x = $self->get_horizontal_offset(); #- $self->get_label_spacer();
    $y = $self->get_vertical_offset(); # -int($self->get_height()/2);

    if ($self->get_align_side() eq "right" && $self->get_orientation() eq "horizontal") { 

	my $old_x = $x;
	$x = $x - $self->get_width() ;
	$a = $old_x;
	$b = $y + $self->get_height();
#	$self->set_horizontal_offset($x);
#	$self->set_vertical_offset($y);
	
	#print STDERR "before: calculated label coords: $x, $y, $a, $b\n";
    }
    if ($self->get_align_side() eq "left" && $self->get_orientation() eq "horizontal") { 
	#$x += $self->get_label_spacer();
	$a = $x + $self->get_width();
	$b = $y + $self->get_height();

	#print STDERR "after:calculated label coords: $x, $y, $a, $b\n";
    }
    if ($self->get_align_side() eq "center" && $self->get_orientation() eq "horizontal") { 
	$x = $x - int($self->get_width()/2);
	$y = $y - int($self->get_height()/2);
	$a = $x + int($self->get_width()/2);
	$b = $y + $self->get_height();
    }
    # (vertical not yet supported.)

    $self->set_enclosing_rect($x, $y -int($self->get_height()/2), $a, $b-int($self->get_height()/2));
}

=head2 function set_orientation_vertical(), get_orientation_vertical()

  Synopsis:	not yet supported.
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub set_orientation_vertical { 
    my $self = shift;
    print STDERR "vertical orientation not yet supported.\n";
}

sub set_orientation_horizontal { 
    my $self = shift;
    $self->{orientation}="horizontal";
}

=head2 function get_orientation()

  Synopsis:	not yet supported.
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut
    
sub get_orientation { 
    my $self = shift;
    # only horizontal supported at this time.
    return "horizontal";
}

sub calculate_width { 
    my $self =shift;
    my $width = $self->get_font()->width()* length($self->get_name());
    $self->set_width($width);
    return $width;
}

sub get_width { 
    my $self = shift;
    my $width = $self->calculate_width();
    if (!defined($width)) { return 0; }
    return $width;
}

sub get_height { 
    my $self = shift;
    my $height = $self->calculate_height();
    if (!defined($height)) { return 0; }
    return $height;
}

sub calculate_height { 
    my $self = shift;
    my $height = $self->get_font()->height();
    $self->set_height($height);
    return $height;
}

=head2 function get_label_spacer(), set_label_spacer()

  Synopsis:	DEPRECATED. Use set_stacking_height instead.
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub get_label_spacer { 
    my $self=shift;
    return $self->{label_spacer};
}

sub set_label_spacer { 
    my $self=shift;
    $self->{label_spacer}=shift;
}


=head2 accessors get_stacking_level(), set_stacking_level()

  Synopsis:	
  Args, Ret:	the level that some label features are moved 
                horizontally, by get_stacking_level()*get_stacking_height()
                pixels. The chromosome renderer will adjust this value
                such that certain label types, ie CXGN::Cview::Label::RangeLabel,
                won\'t clobber each other visually in the horizontal 
                dimension.
  Side effects: affects the rendering of the Label object.	
  Description:	

=cut

sub get_stacking_level { 
    my $self=shift;
    return $self->{stacking_level};
}

sub set_stacking_level { 
    my $self=shift;
    $self->{stacking_level}=shift;
}



=head2 accessors get_stacking_height(), set_stacking_height()

  Synopsis:	
  Args/Ret: 	the stacking height, which is the number of pixels
                that label features will be pushed over in the horizontal
                dimension to prevent labels from overlapping. 
                This is currently implemented only in RangeLabel.
  Side effects:	
  Description:	

=cut

sub get_stacking_height { 
    my $self=shift;
    return $self->{stacking_height} || 3;
}

sub set_stacking_height { 
    my $self=shift;
    $self->{stacking_height}=shift;
}

=head2 accessors set_vertical_stacking_spacing, get_vertical_stacking_spacing

  Property:	the space that is allowed to remain when two labels
                are physically next to each other
  Setter Args:	
  Getter Args:	
  Getter Ret:	
  Side Effects:	
  Description:	

=cut

sub get_vertical_stacking_spacing { 
my $self=shift;
return $self->{vertical_stacking_spacing};
}

sub set_vertical_stacking_spacing { 
my $self=shift;
$self->{vertical_stacking_spacing}=shift;
}





=head2 functions get_north_position(), set_north_position

  Synopsis:	$m->set_north_position(57)
  Args/returns:	position in pixels that describes the northern limit
                of the marker\'s range
  Side effects:	
  Description:	

=cut

sub get_north_position { 
    my $self=shift;
    return $self->{north_position};
}

sub set_north_position { 
    my $self=shift;
    my $pos = shift;
    $self->{north_position}=$pos;
}

=head2 functions get_south_position(), set_south_position()

  Synopsis:	$m->set_south_position(78)
  Description:	see set_north_position()

=cut

sub get_south_position { 
    my $self=shift;
    return $self->{south_position};
}

sub set_south_position { 
    my $self=shift;
    my $pos = shift;
    $self->{south_position}=$pos;

}



=head2 function get_image_map()

  Synopsis:	
  Arguments:	
  Returns:	an html image map for this label, if set_url() was
                used to set a http link.
  Side effects:	
  Description:	

=cut

sub get_image_map {
    my $self = shift;
    my $s = "";

    if ($self->get_url()) { 
	$s .= "<area shape=\"rect\" coords=\"".(join ",", $self->get_enclosing_rect())."\" href=\"".$self->get_url()."\" alt=\"\" />\n";
    }
    return $s;
}



sub copy { 
    my $self = shift;


}
    

1;



