
=head1 NAME

CXGN::Cview::Marker - a class for drawing markers

=head1 DESCRIPTION

Inherits from L<CXGN::Cview::ImageObject>. Defines a marker object on a Cview image. Markers can be rendered in different colors, and have labels associated with them, L<CXGN::Cview::Label>, that can be hilited, rendered in different colors, etc. See the L<CXGN::Cview::Label> class for more information. The two label objects that are associated with each marker are:

=over 5

=item o

a name label object. The label object can in theory be accessed using the accessors for this label are get_label() and set_label(), however it is best to use the standard accessors of the marker object and let it deal with the label object itself.

=item o

an offset label that gives the distance in cM (or in the current map units) and is drawn symmetrically on the other side of the chromosome to the name label. The accessors for this label are get_offset_label() and set_offset_label(). It is currently not drawn by default in the Cview programs. The accessor show_offset_label() will cause the offset label to be displayed.

=back

Labels also have a mark associated with them. That's a small round circle after the label that can be colored to provide some additional visual information about the marker. See the mark related functions below.

Markers can be hidden using the set_hidden(1) accessor. Only the small tick on the chromosome will be drawn, and the label will be omitted.

For a marker that can define a range on the chromosome instead of a specific location use the L<CXGN::Cview::Marker::RangeMarker> class. See that class for more information.

Other Marker properties are inherited from ImageObject, such as the enclosing_rect accessors, set_url and get_url, and others. See L<CXGN::Cview::ImageObject>.

=head1 SEE ALSO

See also the documentation in L<CXGN::Cview>.

=head1 AUTHOR(S)

Lukas Mueller (lam87@cornell.edu)

=head1 VERSION and CHANGE HISTORY

Original version July 2004

[2006-07-07] Replaced label functions with CXGN::Cview::Label class.

=head1 FUNCTIONS


=cut

return 1;

use strict;
use CXGN::Cview::ImageObject;
use CXGN::Cview::Label;

package CXGN::Cview::Marker;

use base qw/ CXGN::Cview::ImageObject /;

=head2 function new()

    my $m -> new ($chr, $marker_id, $marker_name, $marker_type, $confidence, $order_in_loc, $location_subscript, $cM_offset, $loc_type, $loc_order, $overgo, $bac_count);

Creates a new marker. The $chr is the chromosome object the marker belongs to. The marker_id has to be a unique id for the marker. The marker_name is any string, marker_type should be CAPS, COSII, RFLP, SNP etc, confidence is -1 for undefined, 0 = ? .. 4= LOD(3). order_in_loc is deprecated, location_subscript is the subscript of the marker on that chromosome, if any. cM_offset is the offset of the marker on the chr, in cM. overgo should be set to true if the marker has an overgo marker, has_bacs should be set to true if there are BACs associated to that overgo marker.

=cut

sub new {
    my $class = shift;
    my $self = $class -> SUPER::new(@_);
    my $chromosome = shift;

    $self->set_chromosome($chromosome);
    my ($marker_id, $marker_name, $marker_type, $confidence, $order_in_loc, $location_subscript, $offset, $loc_type, $loc_order, $has_overgo, $has_bacs) = @_;
#    print STDERR "\@_ = @_\n";
    
    # initialize the marker object with what was supplied by
    # the call and some reasonable default parameters
    #
    $self->set_id($marker_id);

    $self->set_marker_type($marker_type);
    $self->set_confidence($confidence);
    $self->set_order_in_loc($order_in_loc);
    $self->set_location_subscript($location_subscript);
    $self->set_offset($offset);
    $self->set_loc_type($loc_type);
    $self->set_loc_order($loc_order);
    $self->set_has_overgo($has_overgo);
    $self->set_has_bacs($has_bacs);
    $self->set_color(50, 50 , 50);
    $self->set_label(CXGN::Cview::Label->new());
    #$self->set_label_side("right");
    $self->set_show_tick(1);
    $self->set_north_range(0);
    $self->set_south_range(0);
    

    # initialize the label
    #
    $self->get_label()->set_hilite_color(255, 255, 0);
    $self->get_label()->set_line_color(150,150,150);    
    if (!$location_subscript) { $location_subscript=""; }
    if (!$marker_name) { $marker_name = ""; }
    $self->get_label()->set_name($marker_name.$location_subscript);
    $self->set_marker_name($marker_name);
    
    $self->unhilite();
    $self->unhide();
#    $self->set_north_range(0);
#    $self->set_south_range(0);
    $self->set_mark_color(255, 255, 255);
    $self->set_mark_size(8);
    $self->set_mark_link("");
    $self->hide_mark();
    # the default for this is set in the label object. $self->set_label_spacer(); # the distance between the label and the midline of the chromosome
    $self->set_font(GD::Font->Small());
    
    # the offset label is shown on the opposite side of 
    # the name label
    #
    my $offset_label = CXGN::Cview::Label->new();
    $offset_label->set_text_color(150, 150, 150);
    $offset_label->set_name( (sprintf "%5.2f", $offset)." ");
    $self->set_offset_label($offset_label);
    
    # print STDERR "Marker new: $self->{has_bacs}\n";
    #
    return $self;
}

=head2 function get_color()
    
Gets the color of the marker (more specifically, the line of the marker on the chromosome). Three numbers between 0 and 255 for red, green and blue channels are returned as a list. 
    
=cut
    
sub get_color {
    my $self = shift;
    if (!exists($self->{marker_color})) { @{$self->{marker_color}}=(); }
    return @{$self->{marker_color}};
}

=head2 function set_color()

Sets the color of the marker (more specifically, the line of the marker on the chromosome). Three numbers between 0 and 255 for red, green and blue channels are required. Default color is black.

=cut

sub set_color {
    my $self = shift;
    $self->{marker_color}[0]=shift;
    $self->{marker_color}[1]=shift;
    $self->{marker_color}[2]=shift;
}


=head2 function get_name()

 Gets the complete name of the marker including the suffix.

=cut

sub get_name {
    my $self = shift;
    # test if there is anything in loation_subscript and set to empty string
    # otherwise a 0 may be appended.
    if (!$self->get_location_subscript()) { $self->set_location_subscript(""); }
    return $self->get_marker_name().$self->get_location_subscript();
}

=head2 functions get_marker_name(), set_marker_name()

 gets the marker name, excluding the suffix.

=cut

sub get_marker_name {
    my $self = shift;
    # this function returns the marker name without the subscript. This is useful for constructing links to the marker detail page
    # which requires a type/name tuple 
    if (!exists($self->{marker_name}) || !defined($self->{marker_name})) { $self->{marker_name}=""; }
    return $self->{marker_name};
}

sub set_marker_name { 
    my $self = shift;
    my $name = shift;
    $self->{marker_name}=$name;
}

=head2 functions get_id(), set_id()

gets the unique id associated with the marker.

=cut 

sub get_id {
    my $self = shift;
    if (!exists($self->{marker_id}) || !defined($self->{marker_id})) { 
	$self->{marker_id}="";
    }
    return $self->{marker_id};
}

sub set_id { 
    my $self = shift;
    $self->{marker_id}=shift;
}

=head2 functions set_confidence() and get_confidence()

  Synopsis:	my $confidence = $m->get_confidence()
  Arguments:	setter function: -1 ... 3. 
                -1 means uncalculated confidence
                1 is ILOD<3
                2 is CFLOD=3
                3 is FLOD>3
  Returns:	getter returns values above
                defaults to -1 if confidence property has not been set.
  Side effects:	display in the chromosome viewer depends on confidence values.
  Description:	

=cut

sub set_confidence { 
    my $self = shift;
    $self->{confidence}=shift;
}

sub get_confidence { 
    my $self= shift;
    if (!exists($self->{confidence}) || !defined($self->{confidence}) || !$self->{confidence}) { 
	$self->{confidence}=-1; 
    }
    return $self->{confidence};
}



=head2 accessors set_marker_type() and get_marker_type()

  Synopsis:	accessors for the marker_type property.
  Arguments:	
  Returns:	
  Side effects:	rendering in the chromosome viewer depends on 
                marker type.
  Description:	marker types are: RFLP, SSR, CAPS and COS.

=cut

sub set_marker_type {
    my $self = shift;
    $self->{marker_type} = shift;
}

sub get_marker_type {
    my $self = shift;
    if (!exists($self->{marker_type}) || !defined($self->{marker_type})) { 
	$self->{marker_type}="";
    }
    return $self->{marker_type};
}

=head2 function get_mark_color()

the mark is a little circle displayed after the marker name.
it can be used to add additional visual information for a marker.
The mark is clickable. The link can be set using set_mark_link().
The default color is white with no link.

=cut

sub get_mark_color { 
    my $self = shift;
    return @{$self->{mark_color}};
}

=head2 function set_mark_color()

the mark is a little circle displayed after the marker name.
it can be used to add additional visual information for a marker.
The mark is clickable. The link can be set using set_mark_link().
The default color is white with no link.

=cut

sub set_mark_color {
    # the mark is a little circle displayed after the marker name.
    # it can be used to add additional visual information for a marker.
    # The mark is clickable. The link can be set using set_mark_link().
    # The default color is white with no link.
    my $self = shift;
    $self->{mark_color}[0] = shift;
    $self->{mark_color}[1] = shift;
    $self->{mark_color}[2] = shift;
}

=head2 function set_show_mark()

  Synopsis:	$m->set_show_mark()
  Arguments:	none
  Returns:	nothing
  Side effects:	causes the mark to be displayed when the marker
                is renderd.
  Description:	

=cut

sub set_show_mark {
    my $self = shift;
    $self->{show_mark} = 1;
}

=head2 function hide_mark()

  Synopsis:	$m->hide_mark()
  Arguments:	
  Returns:	
  Side effects:	hides the mark
  Description:	

=cut

sub hide_mark {
    my $self = shift;
    $self->{show_mark}=0;
}

=head2 function get_show_mark()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub get_show_mark {
    my $self = shift;
    return $self->{show_mark};
}

=head2 functions set_mark_link(), get_mark_link()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub set_mark_link {
    my $self = shift;
    $self->{mark_link} = shift;
}

sub get_mark_link {
    my $self = shift;
    if (!exists($self->{mark_link})) { $self->{mark_link}=""; }
    return $self ->{mark_link};
}

=head2 functions has_overgo(), set_has_overgo()

  Synopsis:	$m->has_overgo()
  Arguments:	
  Returns:	
  Side effects:	used to derive the mark\'s color
  Description:	

=cut

sub has_overgo {
    my $self = shift;
    return $self->{has_overgo};
}

sub set_has_overgo {
    my $self = shift;
    $self->{has_overgo}=1;
}

=head2 functions has_bacs(), set_has_bacs()

  Synopsis:	$m->set_has_bacs(1)
  Arguments:	
  Returns:	nothing
  Side effects:	causes the mark to be displayed in red.
  Description:	

=cut

sub set_has_bacs {
    my $self = shift;
    $self->{has_bacs} = shift; # the number of bacs associated with this marker
}

sub has_bacs {
    my $self = shift;
    return $self->{has_bacs};
}

=head2 functions get_mark_rect(), set_mark_rect()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub get_mark_rect {
    my $self = shift;
    if (! exists($self->{mark_rect})) { @{$self->{mark_rect}} = (0,0,0,0); }
    return ($self ->{mark_rect}[0], $self->{mark_rect}[1], $self->{mark_rect}[2], $self->{mark_rect}[3]);
}

sub set_mark_rect {
    my $self = shift;
    ($self ->{mark_rect}[0], $self->{mark_rect}[1], $self->{mark_rect}[2], $self->{mark_rect}[3]) = @_;
}

=head2 functions set_mark_size(), get_mark_size()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub set_mark_size {
    my $self = shift;
    $self->{mark_size} = shift;
}

sub get_mark_size {
    my $self = shift;
    if (!exists($self->{mark_size})) { $self->{mark_size}=0; }
    return $self->{mark_size};
}

=head2 functions is_frame_marker(), set_frame_marker()

  Synopsis:	
  Arguments:	none
  Returns:	returns true if the object represents 
                a frame marker.
  Side effects:	the chromosome viewer may decide to render
                these markers differently
  Description:	set_frame_marker just sets the property to 1.
                It cannot be unset.

=cut

sub is_frame_marker {
    my $self = shift;
    if (!exists($self->{loc_type})) { $self->{loc_type}=""; }
    return ($self->{loc_type} eq "frame");
}

sub set_frame_marker {
    my $self = shift;
    $self->{loc_type} = "frame";
}


=head2 functions set_chromosome(), get_chromosome()

  Synopsis:	accessors for the chromosome property, representing
                the chromosome this marker is associated with.
  Arguments:	setter: a CXGN::Cview::Chromosome object.
  Returns:	getter: a CXGN::Cview::Chromosome object.
  Side effects:	the marker will be drawn on this chromosome. The 
                marker also needs to be added to the marker list of 
                the chromosome. Calling add_marker on the chromosome
                object takes care of all that.
  Description:	

=cut

sub get_chromosome {
    my $self=shift;
    return $self->{chromosome};
}

sub set_chromosome { 
    my $self =shift; 
    $self->{chromosome}=shift;
}

=head2 function hide()

Hides the marker completely from the chromosome.

=cut 

sub hide {
    my $self = shift;
    #$self -> {hidden} = 1;
    $self->get_label()->set_hidden(1);
}

=head2 function unhide()

Unhides the marker.

=cut

sub unhide {
    my $self = shift;
    #$self -> {hidden} = 0;
    $self->get_label()->set_hidden(0);
}

=head2 function is_hidden()

Returns true if marker is hidden.

=cut

sub is_hidden {
    my $self = shift;
    #return $self -> {hidden};
    return $self->get_label()->is_hidden();
}

=head2 function hide_label()

Hides the label of the marker only. The marker 'tick' is still being drawn.

=cut

sub hide_label {
    my $self= shift;
    #$self->{label_hidden} = 1;
    $self->get_label()->set_hidden(1);
}

=head2 function show_label()

Unhides the label if it was previously hidden. Otherwise has no effect.

=cut 

sub show_label {
    my $self=shift;
    #$self ->{label_hidden} = 0;
    $self->get_label()->set_hidden(0);
}

=head2 function is_label_visible()

Returns true if the label is not hidden.

=cut

sub is_label_visible {
    my $self = shift;
    return !$self->is_hidden();
}

=head2 function get_image_map()

Returns the image map for this label as a string. Usually the chromosome object calls this function.

=cut

sub get_image_map {
    my $self = shift;
    #print STDERR "get_image_mapo marker\n";
#    my $coords = join ",", ($self -> get_label_rect());
    my $s = "";
    if ($self->get_url()) {
	$s = $self->get_label()->get_image_map();
#	$s = "<area shape=\"rect\" coords=\"".$coords."\" href=\"".$self->get_url()."\" alt=\"\" />\n";
    }
    if ($self->get_show_mark()) { 
	$s .= "<area shape=\"rect\" coords=\"".(join(",", $self->get_mark_rect()))."\" href=\"".$self->get_mark_link()."\" alt=\"\" title=\"".($self->get_tooltip())."\"  />\n";
									    
    }
    return $s;
	
}

=head2 function render()

    $marker -> render($image);

Renders the marker on a GD image object. The chromosome object usually calls this function to render the entire chromosome.

=cut 

sub render { 
    my $self = shift;
    my $image = shift;

    # calculate y position in pixels
    #
    my $y = $self->get_chromosome()->get_vertical_offset() + $self->get_chromosome()->mapunits2pixels($self->get_offset());

    #warn "[Marker.pm] ".$self->get_offset()."cM is $y pixels...\n";
    # determine the side which this label should be drawn on. If it was not set manually,
    # retrieve the side from the chromosome as a default.
    #
    if (!$self->get_label_side()) { 
	$self->set_label_side($self->get_chromosome()->get_label_side());
    }

    # render marker only if it is visible (markers outside of sections or hidden markers are not visible)
    if ($self -> is_visible()) {
	
	# draw the tick on the chromosome
	#
	my $color = $image -> colorResolve($self->get_color());
	my $chromosome_width = $self->get_chromosome()->get_width();
	my $halfwidth = int($chromosome_width/2);
	$self->draw_tick($image);
       
	# deal with label stuff
	#
	# the $label object deals with displaying the marker's name
	# the $offset_label object deals with displaying the marker's offset
	# on the opposite side
	#
	my $label = $self->get_label();
	my $offset_label = $self->get_offset_label();
	
	if ($self->get_hilited()) {	    
	    $label->set_hilited(1);
	}
    
	# draw the labels left of the chromosome if label_side eq left 
	#
	if ($self->get_label_side() eq "left") { 
	    
	    # define the Label's reference point
	    #
	    $label->set_reference_point($self->get_chromosome()->get_horizontal_offset()-$halfwidth,$y);
	    $label->set_horizontal_offset($self->get_chromosome()->get_horizontal_offset()- $label->get_label_spacer());

	    # draw the offset on the right if label_side eq left, if display_marker
	    # offset is true in the chromosome object
	    #
	    if ($self->get_chromosome()->{display_marker_offset}) { 
		
		# define the label's reference point
		#
		$offset_label->set_reference_point($self->get_chromosome()->get_horizontal_offset()+$halfwidth, $y);
		$offset_label->set_horizontal_offset($self->get_chromosome()->get_horizontal_offset()+ $label->get_label_spacer()
						     );
		$offset_label->set_vertical_offset($label->get_vertical_offset());
		$offset_label->set_align_side("left");

		$offset_label->set_hidden($label->is_hidden());
		$offset_label->render($image);
	    }
	}

	# draw the labels on the right side if label_side is right
	#
	elsif ($self->get_label_side() eq "right") {
	    
	    # define the Label's reference point (the point where the label points to) 
	    # and the horizontal offset (the actual position of the text label)
	    #
	    $label->set_reference_point($self->get_chromosome()->get_horizontal_offset()+$halfwidth,$y);
	    $label->set_horizontal_offset($self->get_chromosome()->get_horizontal_offset()+$label->get_label_spacer());

	    # if show offset is turned on, draw a label on the opposite side of the chromosome
            # showing the cM position
	    #
	    if ($self->get_chromosome()->{display_marker_offset}) {

		$offset_label->set_reference_point(
						   $self->get_chromosome()->get_horizontal_offset()-$halfwidth, $y
						  
						   );
		$offset_label->set_horizontal_offset($self->get_chromosome()->get_horizontal_offset()-
						     $label->get_label_spacer()
						     );
		$offset_label->set_vertical_offset($label->get_vertical_offset());
		$offset_label->set_align_side("right");
		$offset_label->set_hidden($label->is_hidden());
		$offset_label->render($image);
		
	    }   
	}
	$label->render($image);

 	# draw the offset on the left if label_side eq right, if display_marker
	# offset is true in the chromosome object
	#
	$self->draw_mark($image);
    }
    
}

=head2 function draw_tick

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub draw_tick {
    my $self  =shift;
    my $image = shift;

    my $color = $image -> colorResolve($self->get_color());
    my $halfwidth = int($self->get_chromosome->get_width/2);
    my $y = $self->get_chromosome()->get_vertical_offset() + $self->get_chromosome()->mapunits2pixels($self->get_offset());

    if ($self->get_show_tick()) { 	
	$image -> line($self->get_chromosome()->get_horizontal_offset() - $halfwidth +1, $y, $self->get_chromosome()->get_horizontal_offset()+$halfwidth-1, $y, $color);
    }
}

=head2 functions get_label(), set_label()

  Synopsis:	Accessors for the label property, which 
                is a CXGN::Cview::Label object. This attribute
                is set automatically in the constructor and the 
                label name set to the marker name.
  Arguments:	the setter takes a CXGN::Cview::Label object as a 
                parameter.
  Returns:	the getter returns the marker\'s label object.
  Side effects:	the label object attributes are used for rendering 
                the label.
  Description:	

=cut

sub get_label { 
    my $self=shift;
    return $self->{label};
}

sub set_label { 
    my $self=shift;
    $self->{label}=shift;
}

=head2 function is_visible()

returns true if the marker is visible, meaning it is not hidden and it lies not outside the chromosome section, if defined.

=cut

sub is_visible {
    my $self = shift;
    #
    # if it is hidden, we know its not visible...
    #
    if ($self->{hidden}) { return 0; }
    #
    # if the chromosome is a section, we return true if the offset is in that inverval, not otherwise
    if ($self->get_chromosome()->is_section()) {
	if ($self->get_offset() >= $self->get_chromosome()->get_start_cM() && $self->get_offset() <= $self ->get_chromosome()->{end_cM}) {
	    return 1;
	}
	else {return 0; }
    }
    #
    # it's not hidden, and it's not a section, so it has to be visible...
    #
    return 1;
}

sub get_type{
    my $self = shift;
    return $self -> {type};
}

=head2 function draw_mark()

  Synopsis:	draws the mark as specified with the other mark functions.
  Arguments:	
  Returns:	
  Side effects:	
  Description:	the mark is a little circle next to the marker name that
                can be used to convey additional information about the marker.
                The color can be set using set_mark_color() and the link can be
                set using set_mark_url(). The mark should be its own object...

=cut

sub draw_mark {
    my $self = shift;
    my $image = shift;

    my $halfwidth = $self -> get_chromosome()->get_width() / 2;
    my $label = $self->get_label();    
    my $x = 0;
    my $y = $label->get_vertical_offset(); 
    my $circle_color = $image -> colorResolve($self->{mark_color}[0], $self->{mark_color}[1], $self->{mark_color}[2]);
    
    if ($self->get_show_mark()) {
	if ($self->get_label_side() eq "left") { 
	    
	    # draw the mark for the left labels
	    #
	    my $circle_color = $image -> colorResolve($self->get_mark_color());
	    
	    $x = $self->get_chromosome()->get_horizontal_offset()-$label->get_label_spacer()-$label->get_width()-$self->get_mark_size();
	    
	    $self->set_mark_rect($x, $y, $x+$self->get_mark_size(), $y+$self->get_mark_size());
	}
	elsif ($self->get_label_side() eq "right") {
	    $x = $self->get_chromosome()->get_horizontal_offset()+$label->get_label_spacer()+$self->get_label_width()+$self->get_mark_size();    
	    
	    $self->set_mark_rect($x, $y, $x+$self->get_mark_size(), $y+$self->get_mark_size());
	}
	for (my $i=1; $i<=$self->get_mark_size(); $i++) {
	    $image -> arc($x,$y, $i, $i, 0, 360, $circle_color);
	}
    }
}

=head2 accessors get_offset(), set_offset()

Returns the offset of the marker in map units (by default cM).

=cut
    
sub get_offset {
    my $self = shift;
    return $self->{offset};
}

sub set_offset { 
    my $self = shift;
    $self->{offset}=shift;
}

=head2 functions get_north_range(), set_north_range

  Synopsis:	$m->set_north_range(5)
  Args/returns:	a range in cM that describes the uncertainty
                of the marker\'s location 
  Side effects:	the label is drawn reflecting the uncertainty.
  Description:	

=cut

sub get_north_range { 
    my $self=shift;
    return $self->{north_range};
}

sub set_north_range { 
    my $self=shift;
    $self->{north_range}=shift;
}

=head2 functions get_south_range(), set_south_range()

  Synopsis:	$m->set_south_range(4)
  Description:	see set_north_range()

=cut

sub get_south_range { 
    my $self=shift;
    return $self->{south_range};
}

sub set_south_range { 
    my $self=shift;
    $self->{south_range}=shift;
}


=head2 set_range_coords

 Usage:        $m->set_range_coords($start, $end)
 Desc:         for markers that require a range, sets
               the feature start to $start and end to $end,
               calling set_offset(), set_north_range(), and 
               set_south_range() with the appropriate values.
 Ret:          nothing
 Args:         start [int], end [int]
 Side Effects: 
 Example:

=cut

sub set_range_coords {
    my $self = shift;
    my $start = shift;
    my $end = shift;
    $self->set_offset(($start + $end )/2);
    $self->set_north_range(($end - $start)/2);
    $self->set_south_range(($end-$start)/2);
    
}

=head2 get_start

 Usage:        my $s = $m->get_start();
 Desc:         accessor for the start coord of the marker.
               no corresponding setter. Use set_range_coords().
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_start {
    my $self = shift;
    return $self->get_offset()-$self->get_north_range();
}

=head2 get_end

 Usage:        my $e = $m->get_end();
 Desc:         accessor for the end coord of the marker.
 Ret:          no corresponding setter. Use set_range_coords().
 Args:
 Side Effects:
 Example:

=cut

sub get_end {
    my $self = shift;
    return $self->get_offset()+$self->get_south_range();
}

=head2 accessors get_orientation, set_orientation

 Usage:        $m->set_orientation("F");
 Desc:
 Property      the orientation of the feature, either "F" or "R".
 Side Effects:
 Example:

=cut

sub get_orientation {
  my $self = shift;

  # make F the default
  #
  if (!exists($self->{orientation})) { 
      $self->{orientation} = "F";
  }
  return $self->{orientation}; 
}

sub set_orientation {
  my $self = shift;
  my $orientation = shift;
  if ($orientation !~ /F|R/i) { 
      die "Orientation has to be either F or R!";
  }
  $self->{orientation} = uc($orientation);
}


=head2 functions get_label_side(), set_label_side()

  Synopsis:	
  Args/Returns:	either "right" or "left"
  Side effects:	labels are drawn on the right of the 
                chromosome object if this equals "right", on 
                the left if equal to "left". 
  Description:	

=cut

sub get_label_side { 
    my $self=shift;
    if (!exists($self->{label_side})) { 
	return $self->get_chromosome()->get_label_side();
    }
    return $self->{label_side};
}

sub set_label_side { 
    my $self=shift;
    my $side = shift;
    $self->{label_side}=$side;
}

=head2 function get_offset_label()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub get_offset_label { 
    my $self=shift;
    return $self->{offset_label};
}

=head2 function set_offset_label()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub set_offset_label { 
    my $self=shift;
    $self->{offset_label}=shift;
}

=head2 function show_offset_label()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub show_offset_label {
    my $self = shift; 
    my $show = shift;
    if ($show != undef) { 
	my $self->{show_offset_label}=$show;
    }
    else { 
	return $self->{show_offset_label};
    }
}

=head2 function get_show_tick

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub get_show_tick { 
my $self=shift;
return $self->{show_tick};
}

=head2 function set_show_tick

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub set_show_tick { 
my $self=shift;
$self->{show_tick}=shift;
}

=head2 functions set_url(), get_url()

 sets the url that this marker links to.

=cut

sub set_url {
    my $self = shift;
    $self->get_label()->set_url(shift);
}

sub get_url {
    my $self = shift;
    return $self->get_label()->get_url();
}

=head2 accessors set_tooltip, get_tooltip

  Property:	
  Setter Args:	
  Getter Args:	
  Getter Ret:	
  Side Effects:	
  Description:	

=cut

sub get_tooltip { 
    my $self=shift;
    return $self->{tooltip};
}

sub set_tooltip { 
    my $self=shift;
    $self->{tooltip}=shift;
}



=head2 function hilite()

 Hilites the marker in the hilite color (default is yellow).

=cut

sub hilite {
    my $self = shift;
    $self->get_label()->set_hilited(1);
}

sub unhilite {
    my $self = shift;
    $self->get_label()->set_hilited(0);
}

sub get_hilited { 
    my $self = shift;
    return $self->get_label()->get_hilited();
}



=head2 functions get_label_height()

  Synopsis:	gets the height of the label.
                note: the height can\'t be set because
                it depends on the font size.
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut


sub get_label_height {
    my $self = shift;
    return $self ->get_label()->get_font()->height();
}

=head2 function get_label_width()

  Synopsis:	gets the width of the label.
                note - the width can\'t be set because
                it depends on the text in the label 
                and the current font size.
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut


sub get_label_width {
    my $self = shift;
    return $self->get_label()->get_width();
}

=head2 functions set_label_pos(), get_label_pos()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut


sub set_label_pos {
    #
    # sets the position of the label in pixels.
    #
    my $self = shift;
    my $vertical_position = shift;
#    $self -> {label_position} = $vertical_position;
    $self->get_label()->set_vertical_offset($vertical_position);
}

sub get_label_pos {
    my $self = shift;
    #return $self->{label_position};
    return $self->get_label()->get_vertical_offset();
}

=head2 functions set_label_spacer(), get_label_spacer()

  Synopsis:	Accessors for the label_spacer property, which 
                represents the number of pixels from the edge of the
                label to the mid-line of the chromosome.
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut


sub set_label_spacer { 
    my $self = shift;
    my $label_spacer = shift;
    $self->get_label()->set_label_spacer($label_spacer);
}

sub get_label_spacer {
    my $self = shift;
    
    return $self->get_label()->get_label_spacer();
}

=head2 function get_label_line_color()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub get_label_line_color { 
    my $self=shift;
    return $self->get_label()->get_line_color();
}

=head2 function set_label_line_color()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub set_label_line_color { 
    my $self=shift;
    $self->get_label()->set_line_color(@_);
}

=head2 function get_hilite_color()

 Gets the hilite color. Returns the RGB components of the color 
 as a list of three elements.

=cut

sub get_hilite_color {
    my $self = shift;
#    if (!exists($self->{hilite_color})) { @{$self->{hilite_color}}=(); }
#    return @{$self->{hilite_color}};
    return $self->get_label()->get_hilite_color();
}

=head2 function set_hilite_color()

Sets the hilite color. Default is yellow. Three numbers between 0 and 255 for red, green and blue channels are required.

=cut

sub set_hilite_color {
    my $self = shift;
    $self->get_label()->set_hilite_color(@_);
}

=head2 function get_offset_text_color()

 Gets the current offset text color (the color of the line 
 that connects the marker tick with the marker name).

=cut

sub get_offset_text_color { 
    my $self = shift;
    #if (!exists($self->{offset_text_color})) { @{$self->{offset_text_color}}=(); }
    return $self->get_offset_label()->get_text_color();
    #return @{$self->{offset_text_color}};
}

=head2 function set_offset_text_color()

  Sets the color of the offset scale text, if enabled.

=cut

sub set_offset_text_color {
    my $self = shift;
    $self->get_offset_label()->set_text_color(@_);
}
    
=head2 function get_text_color()

 gets the color of the label text.

=cut


sub get_text_color {
    my $self = shift;
    return $self->get_label()->get_text_color();
}

=head2 function set_text_color()

 sets the color of the label text.

=cut

sub set_text_color {
    my $self = shift;
    $self->get_label()->set_text_color(@_);

}

=head2 accessors get_order_in_loc(), set_order_in_loc()

  Synopsis:	I think this is deprecated...
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub get_order_in_loc { 
    my $self=shift;
    return $self->{order_in_loc};
}

sub set_order_in_loc { 
    my $self=shift;
    $self->{order_in_loc}=shift;
}


=head2 functions get_location_subscript(), set_location_subscript()

  Synopsis:	sets the location subscript of this marker position
  Arguments:	setter: a subscript, usually "a".."c" or similar
  Returns:	getter: the current subscript
  Side effects:	the subscript will be rendered on the map, 
                added to the marker name. The CXGN::Cview::Marker function 
                get_name() will also include the subscript, whereas 
                get_marker_name() will not.
  Description:	

=cut

sub get_location_subscript { 
    my $self=shift;
    return $self->{location_subscript};
}

sub set_location_subscript { 
    my $self=shift;
    $self->{location_subscript}=shift;
}

=head2 accessors get_loc_type(), set_loc_type()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub get_loc_type { 
    my $self=shift;
    return $self->{loc_type};
}

sub set_loc_type { 
    my $self=shift;
    $self->{loc_type}=shift;
}

=head2 accessors get_loc_order(), set_loc_order()

  Synopsis:	I think this is deprecated.
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub get_loc_order { 
    my $self=shift;
    return $self->{loc_order};
}

sub set_loc_order { 
    my $self=shift;
    $self->{loc_order}=shift;
}

=head2 has_range

 Usage:        my $flag = $m->has_range()
 Desc:         returns true if the marker has a range defined
               (usually using set_north_range() and set_south_range())
               false otherwise.
 Side Effects: none
 Example:

=cut

sub has_range {
    my $self = shift;
    if ( ($self->get_end() - $self->get_start()) >  12) { return 1;}
    return 0;
}

