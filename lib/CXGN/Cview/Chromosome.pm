

=head1 NAME

CXGN::Cview::Chromosome - a class for drawing chromosomes.

=head1 DESCRIPTION

Inherits from L<CXGN::Cview::ImageI>. The chromosome can be defined by adding markers as CXGN::Cview::Marker objects, using the add_marker() function. An object defining a ruler (CXGN::Cview::Ruler) can be obtained by calling the get_ruler() function. The length of the chromosome is either defined implicitly by the marker with the highest cM position, or explicitly using the set_length() function. The placement of the chromosome is defined by CXGN::Cview::ImageI defined functions such as set_horizontal_offset(), which defines the mid-line of the chromosome, and set_vertical_offset(), which defines the top edge.

Chromosomes can be rendered either in full or in section. The sections can start at cM positions other than 0 and are rendered slightly differently. Use set_section() to define the section.

The render() function will render the chromosome on the GD::Image supplied. It calls the subroutines to draw the chromosomes, lays out the marker labels and then calls the render function on each marker object.

Certain aspects of the appearance of the chromosome can be changed. For example, the color of the chromosome can be changed using set_color(). Labels can be rendered on the left or on the right of the chromosome, using set_labels_right() or set_labels_left(). 

Markers with the highest LOD score or rendered last, such that they will appear on the chromosome at the expense of lower scoring markers.

Chromosome areas can be rendered clickable using the function rasterize().

=head1 SEE ALSO

See also the documentation in L<CXGN::Cview> and L<CXGN::Cview::ImageI>.

=head1 AUTHOR(S)

Lukas Mueller (lam87@cornell.edu)

=head1 FUNCTIONS

CXGN::Cview::Chromosome has the following methods:

=cut

use strict;
use CXGN::Cview::ImageObject;
use CXGN::Cview::Marker;
use CXGN::Cview::Marker::SequencedBAC;
use CXGN::Cview::Ruler;
use CXGN::Cview::Ruler::PachyteneRuler;
use CXGN::Cview::Chromosome::BarGraph;


package CXGN::Cview::Chromosome;

use base qw(CXGN::Cview::ImageObject);

use GD;

=head2 function new()

my $c = CXGN::Cview::Chromosome -> new( chr number, height in pixels, horizontal offset, vertical offset, [start cM], [end cM])

Creates a new chromosome object. The horizontal offset denotes the offset of the chromosome mid-line. The vertical offset defines the upper end of the chromosome. Note that some renditions of the chromosome will add round edges on the top and on the bottom, so that the rounded top position will be smaller than the vertical offset.

Optionally, start_cM and end_cM can be supplied, which will set the start and end in cM for a chromosome section. The chromosome will be rendered as a section, i.e, the ends will be flat instead of rounded.

=cut

sub new {
    my $class = shift;

    my $chr_nr = shift;
    my $height = shift;
    my $x = shift;
    my $y = shift;
    my $start = shift;
    my $end = shift;

    my $self = $class -> SUPER::new($x, $y, $height);

    $self -> set_start_cM($start); # if a chromosome section, where the section starts, in cM
    $self -> set_end_cM($end); # if a chromosome section, where the section ends, in cM

    $self -> {markers} = ();    

    $self->set_labels_right();
    $self -> set_width(20); # default width
    $self -> {curved_height} = $self->get_width();

    $self->{chr_nr}=$chr_nr;
    $self->set_name($chr_nr);

    $self -> {font} = GD::Font->Small();
    # set default colors
    $self -> set_horizontal_offset($x);
    $self -> set_vertical_offset($y);
    $self -> set_color(200, 150, 150);
    $self -> set_hilite_color(255, 255, 0);
    $self -> set_outline_color(0,0,0);
    $self -> set_hide_marker_offset();
    $self -> set_ruler( CXGN::Cview::Ruler->new($self->get_horizontal_offset(), $self->get_vertical_offset(), $self->get_height(), 0, $self->get_length()) );
#    don't do this - will cause deep recursion... $self -> set_bargraph( CXGN::Cview::Chromosome::BarGraph->new($self->get_horizontal_offset(), $self->get_vertical_offset(), $self->get_height(), 0, $self->get_length()));
    $self -> hide_bargraph(); # by default, do not show the bar graph.
    return $self;
}

=head2 function set_height()

    $chr->set_height($height)

Sets the height of the chromosome in pixels. Recalculates all the scaling information.
Implemented in superclass.

=cut


=head2 function get_height()

    $height = $chr ->get_height()

Gets the height of the chromosome in pixels. Implemented in the superclass.

=cut


=head2 function set_length()

sets the length in map units [cM].

This can also be automatically determined if not set manually, to the offset of the marker with the highest map unit value.

=cut 

    
sub set_length {
    my $self=shift;
    $self->{chromosome_length_cM}=shift;
}

=head2 function get_length()

gets the length of the chromosome in map units.

=cut 

sub get_length {
    my $self=shift;
    
    return $self->{chromosome_length_cM};
}


=head2 function get_units()

 Synopsis:	
 Arguments:	
 Returns:	
 Side effects:	
 Description:	

=cut

sub get_units { 
    my $self=shift;
    return $self->get_ruler()->get_units();
}

=head2 function set_units()

 Synopsis:	
 Arguments:	
 Returns:	
 Side effects:	
 Description:	

=cut

sub set_units { 
    my $self=shift;
    my $units = shift;
    $self->get_ruler()->set_units($units);
}

=head2 function get_ruler()

 Synopsis:	
 Arguments:	
 Returns:	
 Side effects:	
 Description:	

=cut

sub get_ruler { 
    my $self=shift;
    return $self->{ruler};
}

=head2 function set_ruler()

 Synopsis:	
 Arguments:	
 Returns:	
 Side effects:	
 Description:	

=cut

sub set_ruler { 
    my $self=shift;
    $self->{ruler}=shift;
}

=head2 accessors set_bargraph(), get_bargraph()

  Property:	an associated bar graph with this chromosome
                The bargraph is a CXGN::Cview::Chromosome::BarGraph
                object. The default is no bar graph, ie, an empty
                bar graph is initialized in the constructor.
 
  Side Effects:	
  Description:	

=cut

sub get_bargraph { 
    my $self=shift;
    return $self->{bargraph};
}

sub set_bargraph { 
    my $self=shift;
    $self->{bargraph}=shift;
}


=head2 functions show_bargraph(), hide_bargraph()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub show_bargraph {
    my $self = shift;
    $self->{show_bargraph}=1;
}

sub hide_bargraph { 
    my $self = shift;
    $self->{show_bargraph}=0;
}

=head2 function set_section()

    $chr->set_section($start_in_map_units, $end_in_map_units);

Defines the chromosome as a section. The section starts at the start coordinate in map units, and ends at the end coordinate in map units. Chromosomes that are sections are rendered differently than full chromosomes. The section will be rendered so that it fills the entire height of the chromosome as defined with new or set_height, and the top edge will be drawn at the horizontal and vertical offset defined in the new call or with set_horizonatal_offset and set_vertical_offset.

=cut 

    

sub set_section {
    my $self = shift;
    $self -> set_start_cM(shift);
    $self -> set_end_cM(shift);
    $self -> {is_section} =1;
}

=head2 function get_section()

    $flag = $chr->is_section()

Returns true if the chromosome $chr is a section. 

=cut

sub is_section {
    my $self = shift;
    return $self -> {is_section};
}

=head2 function set_hilite()

$chr->set_hilite(start_coord, end_coord)

Highlights the region of the chromosome between start_coord and end_coord with the hilite_color (which can be set with set_hilite_color, see below).

=cut

sub set_hilite { 
    my $self = shift;
    $self->{hilite_start}=shift;
    $self->{hilite_end}=shift;
}

=head2 function set_hilite_color()

$chr->set_hilite($red_channel, $green_channel, $blue_channel)

Sets the hilite color for chromosome highlighting. Three values between 0 and 255 are required for defining red, green and blue channels. The default color is yellow (255, 255,0)

=cut

sub set_hilite_color {
    my $self = shift;
    $self->{hilite_color}[0]=shift;
    $self->{hilite_color}[1]=shift;
    $self->{hilite_color}[2]=shift;
}

sub get_hilite_color { 
    my $self = shift;
    return @{$self->{hilite_color}};
}



=head2 function set_color()

Sets the chromosome outline color. Three values between 0 and 255 are required for defining red, green and blue channels. The default color is 0,0,0, which is black. This function is defined in the parent class.

=cut

sub set_outline_color {
    my $self = shift;
    $self->{outline_color}[0]=shift;
    $self->{outline_color}[1]=shift;
    $self->{outline_color}[2]=shift;
}


=head2 function set_caption()

Sets the caption of the chromosome. The caption will be drawn centered on the top of the chromosome. Usually, the chromosome number should be displayed.

=cut


sub set_caption {
    my $self = shift;
    $self->{caption}=shift;
}

sub get_caption {
    my $self = shift;
    return $self->{caption};
}

=head2 function set_labels_left()

Causes the labels to be displayed on the left side of the chromosome.

=cut 

sub set_labels_left {
    my $self = shift;
    $self->{label_side} = "left";
}

=head2 function set_labels_right()

Causes the labels to be displayed on the right side of the chromosome.

=cut 

sub set_labels_right {
    my $self = shift;
    $self->{label_side} = "right";
}

=head2 function set_labels_none()

Causes the labels not to be displayed for the whole chromosome.

=cut

sub set_labels_none {
    my $self = shift;
    $self -> {label_side} = "";
}

=head2 function get_label_side()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub get_label_side {
    my $self = shift;
    return $self->{label_side};
}


=head2 function set_display_marker_offset()

Causes the marker offsets to be displayed on the opposite side of the labels.

=cut

sub set_display_marker_offset {
    #
    # is set, the marker offset in cM will be displayed on the opposite side of the label
    #
    my $self = shift;
    $self -> {display_marker_offset} = 1;
}

sub set_hide_marker_offset {
    my $self = shift;
    $self -> {display_marker_offset} = 0;
}

=head2 function render()

    $chr-> render($image);

This function is called to render the chromosome and recursively calls all the rendering functions of the objects it contains. The image parameter is an GD image object. Usually, you should not have to call this function, but the MapImage object calls this function for you if you render a map.

=cut

sub render { 
    my $self = shift;
    my $image = shift;
    
    $self -> layout();
    $self -> draw_chromosome($image);
    $self -> render_markers($image);
}

=head2 function render_markers()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	This function renders the markers of the chromosome object. 
                The important thing is to render the markers such that the highest
                load score marker is rendererd last. 

=cut

sub render_markers { 
    my $self = shift;
    my $image = shift;

    my @markers = $self->get_markers();

    foreach my $lod (-1,0,1,2,3) {

	foreach my $m (@markers) { 

	    if (!$m->isa("CXGN::Cview::Marker::SequencedBAC")) { 
		if ($m->get_confidence()==$lod) { 
		    $m -> render($image); 
		    #print STDERR "lod: $lod. Rendered ".$m->get_name()." confidence=".$m->get_confidence()."\n";
		}
		else {
		    #print STDERR "lod: $lod.Not rendered: ".$m->get_name()." Marker confidence: ".$m->get_confidence()."\n";
		}
	    }
	    
	}    }

    # render highlighted markers again to prevent clobbering
    foreach my $m (@markers) { 
	if ($m->is_visible() && $m->get_hilited()) { 
	    $m->render($image);
	}
    }


    foreach my $m (@markers) { 
	if ($m->isa("CXGN::Cview::Marker::SequencedBAC")) {
	    $m->get_label()->set_text_color(200,200,80);
	    $m->get_label()->set_line_color(200,200,80);
	    $m->set_color(255,255,0);
	    $m->render($image);
	}
    }
    
}   


# =head2 function render_labels

#   Synopsis:	
#   Arguments:	
#   Returns:	
#   Side effects:	
#   Description:	

# =cut

# sub render_labels {
#     my $self = shift;
#     my $image = shift;
#     foreach my $m ($self->get_markers()) { 
# 	if ($m->is_visible() && $m->get_label()->get_hilited()) { 
# 	    $m->get_label()->render($image);
# 	}
#     }

# }


sub get_enclosing_rect {
    my $self = shift;
    return (int($self->get_horizontal_offset()-$self->get_width()/2), $self->get_vertical_offset(), $self->get_horizontal_offset()+int($self->get_width()/2), $self->get_vertical_offset()+$self->{height});
}

=head2 function rasterize()

Causes the chromosome to be rasterized in the MapImage tags. A scaffold of rectangular areas is overlaid on the chromosome that can be used to link to something to this part of the chromosome. The link is supplied through set_rasterize_link. The parameter gives the size of the raster in cM. With the parameter set to zero, no rastering occurs. 

=cut 

sub rasterize {
    # this function sets the rasterize variable, get_image_map then rasterizes the chromosome if necessary.
    my $self = shift;
    if (@_) {
	$self->{rasterize}=shift;
   }
    return $self->{rasterize};
}

sub set_rasterize_link {
    my $self = shift;
    $self->{rasterize_link} = shift;
}

# the rasterize link has to be of the format http://url.domain.etc/etc/program?parameter=values&parameter=values&cM=
# rasterizatio will add the number of cM where clicked at the end of the link.
sub get_rasterize_link {
    my $self = shift;
    if (!exists($self->{rasterize_link}) || !defined($self->{rasterize_link})) { 
	$self->{rasterize_link}="";
    }
    return $self->{rasterize_link};
}

=head2 function get_image_map()

Gets the image map for the chromosome and all contained objects within chromosome. This is normally called by the MapImage object.

=cut 

sub get_image_map {
    my $self = shift;
    my $coords = join ",", ($self -> get_enclosing_rect());
    my $string = "";;
    #print STDERR "get_image_map chromosome\n";
    if ($self->get_url()) {  $string =  "<area shape=\"rect\" coords=\"".$coords."\" href=\"".$self->get_url()."\" alt=\"\" />";}
    foreach my $m (($self->get_markers())) {
	if ($m->is_visible()) { 
	    $string .= $m -> get_image_map();
	}
    }
    if ($self->rasterize() && $self->get_length()>0) {
	my $raster = $self->get_length()/20;#$self->{rasterize}; # cM
	my $steps = ($self->get_length()/$raster);

	my $halfwidth = ($self->get_width()/2);
	my $x = $self->get_horizontal_offset();
	my $y = $self->get_vertical_offset();
	my $box_pixel_height = $self->get_height()/$steps;
	#print STDERR "STEPS: $steps. boxheight: $box_pixel_height\n";
	for (my $i=0; $i<=($steps+1); $i++) {
	    my $cM = $i*$raster;
	    my $pixels = $self->mapunits2pixels($cM)+$y;
	    
	    $string .="<area shape=\"rect\" coords=\"".int($x-$halfwidth).",".int($pixels).",".int($x+$halfwidth).",".int($pixels+$box_pixel_height)."\" href=\"".$self->get_rasterize_link().$cM."\" alt=\"\" />\n";
	}
    }
	return $string;
    
}

sub _sort_by_position { 
    return ($a->get_offset() <=> $b->get_offset);
}

=head2 function sort_markers()

  Synopsis:	$c->sort_markers()
  Arguments:	none
  Returns:	nothing
  Side effects:	sorts the markers according to their position
                in the internal datastructure. This is required
                for proper rendering of the marker labels; if 
                the markers are added in sequence, calling this
                is superfluous.
  Description:	

=cut



sub sort_markers {
    my $self=shift;
    my @sorted_markers = sort _sort_by_position ($self->get_markers());
    $self->set_markers(@sorted_markers);
}

sub _calculate_scaling_factor {
    my $self = shift;    

    $self -> _calculate_chromosome_length();     
    if ($self->get_length()==0) { return 0; }
    
    $self->{scaling_factor}=($self->get_height()/$self->get_length());
    
    #print STDERR "calculating scaling factor. height in pixels: $self->{height} chromosome_length=$self->{chromosome_length_cM} scaling factor: $self->{scaling_factor}\n";

    return $self->{scaling_factor};
}

sub get_scaling_factor {
    my $self = shift;
    if (!exists($self->{scaling_factor})) { 
	$self->{scaling_factor}=0; 
        #print STDERR "[CXGN::Cview::Chromosome] WARNING! Scaling factor is 0.\n"; 
    }
    return $self->{scaling_factor};
}

=head2 function add_marker()
    
    $chr->add_marker($m);

Adds the marker object $m to the chromosome.
    
=cut
    
sub add_marker {
    my $self = shift;
    my $m = shift;
    push @{$self->{markers}}, $m;
}

=head2 function get_markers()

    my @m = $chr -> get_markers();

Gets all the markers in the chromosome as an array.

=cut

sub get_markers {
    my $self = shift;
    if (!defined($self->{markers})) { return (); }
    return @{$self->{markers}};
}

sub set_markers { 
    my $self =shift;
    @{$self->{markers}} = @_;
}

=head2 accessors set_start_cM(), get_start_cM()

  Property:	
  Setter Args:	
  Getter Args:	
  Getter Ret:	
  Side Effects:	
  Description:	

=cut

sub get_start_cM { 
    my $self=shift;
    if (!exists($self->{start_cM}) || !defined($self->{start_cM})) { $self->{start_cM}=0; }
    return $self->{start_cM};
}

sub set_start_cM { 
    my $self=shift;
    $self->{start_cM}=shift;
}

=head2 accessors set_end_cM(), get_end_cM()

  Property:	
  Setter Args:	
  Getter Args:	
  Getter Ret:	
  Side Effects:	
  Description:	

=cut

sub get_end_cM { 
    my $self=shift;
    if (!exists($self->{end_cM}))  { $self->{end_cM}=0; }
    return $self->{end_cM};
}

sub set_end_cM { 
    my $self=shift;
    $self->{end_cM}=shift;
}



sub get_markers_in_interval {
    my $self = shift;
    my $start = shift;  # start in cM
    my $end = shift;    # end position in cM
    if (!$start && !$end) { $start = 0; $end = $self -> get_length()+1 ; }
    my @markers;
    foreach my $m (@{$self->{markers}}) {
	if ($m -> get_offset() >= $start && $m->get_offset() <= $end) {
	    push @markers, $m;
	}
    }
    return @markers;    # returns all the markers in between start and end
}

sub get_frame_markers {
    my $self = shift;
    my @framemarkers = ();
    foreach my $m (@{$self->{markers}}) { 
	if ($m->is_frame_marker()) { 
	    push @framemarkers, $m;
	}
    }
    return @framemarkers;
}

sub get_markers_ref {
    my $self = shift;
    return \@{$self->{markers}};
}

sub layout { 
    my $self = shift;
    $self->_calculate_chromosome_length();
    $self->_calculate_scaling_factor();
    $self -> distribute_labels();
    $self -> distribute_label_stacking();

}

sub _calculate_chromosome_length {
    my $self = shift;
    my $length = 0;
    
    # get chromosome length in cM.
    # 
    # if it is a section, we return the length of the section, as defined by start_cM and end_cM
    #
    if ($self->is_section()) { 
	if ($self->get_end_cM()>$self->{chromosome_length_cM}) { 
	    $self->get_end_cM($self->{chromosome_length_cM});
	}
	$self->{chromosome_length_cM}=$self->get_end_cM()-$self->get_start_cM();
	return $self->{chromosome_length_cM};
    }
    
    # it may be that chromosome_length has been manually set with set_length.
    #
    if ($self->get_length()) {
	return $self->get_length();
    }

    # otherwise, we get the marker with the highest cM position.
    # the length may have been set already by set_length...
    else { 
	foreach my $m (@{$self->{markers}}) {
	    my $offset = $m -> get_offset();
	    if ($offset > $length) { $length = $offset; }
	}
	$self->{chromosome_length_cM} = $length;
	
	return $self->{chromosome_length_cM};	
    }
    
    # otherwise return some default length
    #
    return 10;
    
}

sub get_chromosome_length {
    # same as get_length. Deprecated.
    my $self = shift;
    return $self->{chromosome_length_cM};
}

=head2 function mapunits2pixels()

    my $pixels = $chr->mapunits2pixels($cM_pos);

Gets the number of pixels the cM value corresponds to. Note that you have to add the vertical chromosome offset (get_vertical_offset) to this number the get the actual image coordinates.

=cut


sub mapunits2pixels {
    my $self = shift;
    my $cM = shift;
    
    if (! $cM) { $cM=0; }
    my $pixels = ($cM - $self->get_start_cM()) * $self->get_scaling_factor();
    #print STDERR "Scaling factor: $self->{scaling_factor} cM: $cM = $pixels pixels\n";
    return $pixels;
}

=head2 function get_pixels_cM()

    my $cM = $chr->get_pixels_cM($pixels);

Gets the number of cM that the number of $pixels correspond to. Note that you have to substract the vertical chromosome offset (get_vertical_offset) from the pixels this number the get the correct number of cM.

=cut

sub get_pixels_cM {
    my $self = shift;
    my $pixels = shift;
    my $cM = ($pixels / $self->{scaling_factor}) + $self->get_start_cM();
}



sub is_visible {
    my $self = shift;
    my $cM = shift;

    if ($self->is_section()) {
	if ($cM >= $self->get_start_cM() && $cM <= $self ->get_end_cM()) {
	    return 1;
	}
	else {return 0; }
    }
    return 1;
}


=head2 function distribute_labels()

  Synopsis:	$c->distribute_labels()
  Arguments:	none
  Returns:	distributes the labels nicely along the chromosome 
  Side effects:	changes the positions of the labels
  Description:	first it calculates label positions by setting the first label
                to be equal to the top of the chromosome, then adjusts  
                all following label positions not to overlap with the 
                previous label, pushing them down if necessary. 
                Second, it calculates the label positions by setting the last 
                label to be equal to the end of the chromosome, and iterates 
                through all labels not to overlap with the previous label, if 
                necessary, pushing it up. To calculate the final label 
                position, it takes the average of the downwards and the 
                upwards iterations through the labels. Note that the labels need
                to be ordered for this to work.
                this function was renamed slightly (_ omitted) and refactored
                such that left labels and right labels are distributed 
                separately.

=cut

sub distribute_labels {
    my $self = shift;
    $self->_distribute_labels("left");
    $self->_distribute_labels("right");

}


sub _distribute_labels { 
     my $self = shift;
     my $side = shift;

     my @m = $self->get_markers();
     my $lastlabelpos = 0;

     # calculate the downwards offsets
     #
     my %downwards=();
     
     if (!@m) { return; }

     foreach my $m (@m) {
	 #if ($m->get_label_side() !~ /right|left/i) { die "Label side is not set correctly for marker ".$m->get_name()."\n"; }
	 if ($m->is_visible() && $m->is_label_visible() && ($m->get_label_side() eq "$side")) { # || !$m->get_label_side())) {
	     my $cM= $m->get_offset();
	     my $labelpos = $self->mapunits2pixels($cM)+$self->get_vertical_offset();
	     my $labelheight = $m -> get_label_height();
	     #print STDERR "label height: $labelheight\n";

	     if (($labelpos-$labelheight)<$lastlabelpos) { 
		 $labelpos = $lastlabelpos+$labelheight;
		 if (exists($downwards{$m->get_name()})) { print STDERR "CATASTROPHE: Duplicate marker name ".($m->get_name())."\n"; }
		 $downwards{$m->get_name()} = $labelpos;
	     }
	     else {
		 $downwards{$m->get_name()}=$labelpos;
	     } 
	     $lastlabelpos = $labelpos;
	 }
     }
     
     # calculate the upwards offsets
     #
     my %upwards = ();
     my $toplabelpos = $self->get_vertical_offset()+$self->get_height()+12+$m[-1]->get_label_height();
     foreach my $m (reverse(@m))  {
	 if($m->is_visible() && $m->is_label_visible() && $m->get_label_side() eq "$side") {
	     my $cM=$m->get_offset();
	     my $labelpos = $self->mapunits2pixels($cM)+$self->get_vertical_offset();
	     #print STDERR "VERTICAL OFFSET = ".$self->get_vertical_offset()."\n";
	     my $labelheight= $m->get_label_height();
#	     print STDERR $m->get_name()." offset = $cM ID=".$m->get_id()."\n";
	     if (($labelpos+$labelheight)>$toplabelpos) {
		 $labelpos = $toplabelpos-$labelheight;
		 if (!$m->get_name()) { print STDERR "CATASTROPHE: Didn't get name on marker ".$m->get_id()."\n"; }
		 if (exists($upwards{$m->get_name})) { print STDERR "CATASTHROPHE: duplicate marker name ".$m->get_name()."\n"; }
		 $upwards{$m->get_name()} = $labelpos;
	     }
	     else {
		 $upwards{$m->get_name()}=$labelpos;
	     }
	     $toplabelpos = $labelpos;
	 }
     }
     
     # load into marker objects
     #
     foreach my $m (@m) {
	 if ($m->get_label_side() eq "$side") { 
	     my $marker_name = $m -> get_name();
	     # test to prevent warnings...
	     if (! $downwards{$marker_name}) { $downwards{$marker_name}=0; }
	     if (! $upwards{$marker_name}) { $upwards{$marker_name} = 0; }
	     
	     my $pixels = int(($downwards{$marker_name}+$upwards{$marker_name})/2);
	     #print STDERR "Vertical pixels for marker ".$m->get_marker_name()." : $pixels.\n";
	     $m->get_label()->set_vertical_offset($pixels);
	 }
     }
 }

=head2 function distribute_label_stacking()

  Synopsis:	
  Arguments:	none
  Returns:	nothing
  Side effects:	distributes the labels of the markers of type
                RangeMarker such that they do not collide 
                vertically, and does this for each side
                independently.
  Description:	

=cut

sub distribute_label_stacking { 
    my $self = shift;
    $self->_distribute_label_stacking("left");
    $self->_distribute_label_stacking("right");
}

sub _distribute_label_stacking {
    my $self = shift;
    my $side = shift;
    my @tracks = ();
    my $maximum_stacking_level = 0;
    my $skipped = 0;
    my $TRACK_LIMIT = 20000; # exit the loop if we exceed this number of tracks.

    # the @tracks array keeps track of which positions are already occupied by giving the 
    # lower boundary to which the track has been filled.
    # it is important that the markers are sorted by position in some way 
    # for this to look good (currently, for physical map, BACs are sorted by status, association_type
    # and offset, which forces sequenced BACs to be rendered next to the chromosome
    # and other BACs further away). All other maps should just be sorted by position.
    #
    foreach my $m ($self->get_markers()) { 
	if ($m->is_visible() && $m->get_label_side() eq $side) { 

	    # define the position of the marker
	    my $upper_edge = $m->get_offset()-$m->get_north_range(); # the position of the top of the marker
	    if ($upper_edge < 0 || !defined($upper_edge)) { $upper_edge = 0; }
	    my $lower_edge = $m->get_offset()+$m->get_south_range(); # the position of the bottom of the marker
	    if ($lower_edge < 0 || !defined($lower_edge)) { $lower_edge = 0; }

	    
	    my $current_track = 1;
	    

	    while (defined($tracks[$current_track]) && ($tracks[$current_track]>($upper_edge - $m->get_label()->get_vertical_stacking_spacing()))) { 
	
		if (!exists($tracks[$current_track]) || !defined($tracks[$current_track])) { $tracks[$current_track]=0; }
	

		# under certain conditions an infinite loop may be created. To prevent it, we set
                # an arbitrary limit on the number of tracks supported.
		if ($current_track>$TRACK_LIMIT) { 
		    $skipped++;
#		    if ($m->get_marker_name() =~ /Lpen/) { 
#			print STDERR "Skipping pennellii bac ".($m->get_marker_name())." at position ".($m->get_offset())."\n";
#		    }
		    last();
		}
		if ($current_track > $maximum_stacking_level) { 
		    $maximum_stacking_level = $current_track;
		}
		$current_track++;
		
	    }
	   # print STDERR "TRACK $current_track has lower bound $tracks[$current_track]. \n";
	    $tracks[$current_track] = $lower_edge;
	    
	    $m->get_label()->set_stacking_level($current_track);
	    
	    #print STDERR "TRACKS: ".($m->get_marker_name())." [$current_track] = $tracks[$current_track], $upper_edge\n";
	} 
    }   

    # here we adjust the label_spacer property of the label to be higher than the highest track. 
    # seems like a good idea but it may produce weird effects on some maps. Maybe this should 
    # be factored out into another subroutine so that it could be called only if desired.
    #
    foreach my $m ($self->get_markers()) { 
	if ( ($m->get_label_side() eq "$side") && ($m->get_label()->get_stacking_height()>0)) { 
	    my $label_spacer = $m->get_label()->get_label_spacer();
	    my $dynamic_spacer = ($maximum_stacking_level+1) * $m->get_label()->get_stacking_height()+10;
	    if ($dynamic_spacer > $label_spacer ) { 
		$m->get_label()->set_label_spacer( $dynamic_spacer );
	    }
	}
    }
    if ($skipped) { 
	print STDERR "Skipped $skipped because of space constraints (max $TRACK_LIMIT tracks).\n";
    }
}

=head2 function draw_chromosome()

    $chr->draw_chromosome($image, $type);

Draws the chromosome on $image. Image is a GD image. The default chromosome rendering is as a 'sausage' type chromosome. A line model is available by supplying the type parameter "line". This is usually called by the MapImage object.

=cut

sub draw_chromosome {
    my $self = shift;
    my $image = shift;

    # draw chromosome outline

    if (! $self->{style}) { $self->{style}=""; }
    if ($self->{style} eq "line") { 
	$self->draw_chromosome_line($image);
    }
    elsif ($self->{style} eq "sausage") {
	$self->draw_chromosome_sausage($image);
    }
    else { $self->draw_chromosome_sausage($image); }
}

sub draw_chromosome_line {
    my $self=shift;
    my $image=shift;

    my $color = $image -> colorResolve($self->{color}[0], $self->{color}[1], $self->{color}[2]);
    #print STDERR "$self->{x}, $self->get_vertical_offset(), $self->{x}, $self->get_vertical_offset()+$self->{height}, $color\n";
    $image -> line($self->get_horizontal_offset(), $self->get_vertical_offset(), $self->get_horizontal_offset(), $self->get_vertical_offset()+$self->{height}, $color);
}

sub draw_chromosome_sausage {
    my $self = shift;
    my $image = shift;
    
    # allocate colors
    #
    my $outline_color = $image -> colorResolve($self->{outline_color}[0], $self->{outline_color}[1], $self->{outline_color}[2]);
    my $hilite_color = $image -> colorResolve($self->{hilite_color}[0], $self->{hilite_color}[1], $self->{hilite_color}[2]);
    my $color = $image -> colorResolve($self->{color}[0], $self->{color}[1], $self->{color}[2]);

    my $halfwidth = $self ->{width}/2;

    $image -> line($self->get_horizontal_offset() - $halfwidth, $self->get_vertical_offset() , $self->get_horizontal_offset()-$halfwidth, $self->get_vertical_offset()+$self->{height}, $outline_color);
    $image -> line($self->get_horizontal_offset() + $halfwidth, $self->get_vertical_offset() , $self->get_horizontal_offset()+$halfwidth, $self->get_vertical_offset()+$self->{height}, $outline_color);
    if ($self->is_section()) {
	my $text_color = $image -> colorResolve(50, 50, 50);
	$image -> line ($self->get_horizontal_offset()-$halfwidth, $self->get_vertical_offset(), $self->get_horizontal_offset()+$halfwidth, $self->get_vertical_offset(), $outline_color);
	$image -> line ($self->get_horizontal_offset()-$halfwidth, $self->get_vertical_offset()+$self->{height}, $self->get_horizontal_offset()+$halfwidth, $self->get_vertical_offset()+$self->{height}, $outline_color);
	$image -> fill($self->get_horizontal_offset(), $self->get_vertical_offset()+1, $color);
	my $top_label = int($self->get_start_cM()).$self->get_units();
	my $bottom_label = int($self ->{end_cM}).$self->get_units();
	$image -> string($self->{font}, $self->get_horizontal_offset()-$self->{font}->width()* length($top_label)/2, $self->get_vertical_offset()-$self->{font}->height()-3, $top_label, $text_color);
$image -> string($self->{font}, $self->get_horizontal_offset() - $self->{font}->width() * length($bottom_label)/2, $self->get_vertical_offset()+$self->get_height()+3, $bottom_label,$text_color);
    }
    else {
	$image -> setAntiAliased($outline_color);
	$image -> arc ($self->get_horizontal_offset(), $self->get_vertical_offset(), $self->{width}, $self->{curved_height}, 180, 0, GD::gdAntiAliased);
	$image -> arc ($self->get_horizontal_offset(), $self->get_vertical_offset()+$self->{height}, $self->{width}, $self->{curved_height}, 0, 180, GD::gdAntiAliased);
	$image -> fill ($self->get_horizontal_offset(), $self->get_vertical_offset(), $color);
    }
    
    

    if ($self->{hilite_start} || $self->{hilite_end}) { 

	# if we are dealing with a section, don't hilite more than the section...
	#
	if ($self->is_section()) { 
	    if ($self->{hilite_start} < $self->get_start_cM()) { 
		$self->{hilite_start} = $self->get_start_cM();
	    }
	    if ($self->{hilite_end} > $self->get_end_cM()) { 
		$self->{hilite_end} = $self->get_end_cM;
	    }
	}
	    
	my $start = $self->get_vertical_offset()+$self->mapunits2pixels($self->{hilite_start});
	my $end   = $self->get_vertical_offset()+$self->mapunits2pixels($self->{hilite_end});
	$image -> rectangle($self->get_horizontal_offset()-$halfwidth, 
                            $start, 
                            $self->get_horizontal_offset()+$halfwidth,
                            $end,
			    $outline_color);
	$image -> fill ($self->get_horizontal_offset(), $start+1,  $hilite_color);

    }
    
    $self->draw_caption($image);
}

sub draw_caption { 
    my $self = shift;
    my $image = shift;
    
    my $outline_color = $image -> colorResolve(
					       $self->{outline_color}[0], 
					       $self->{outline_color}[1], 
					       $self->{outline_color}[2]
					       );
    my $bigfont = GD::Font->Large();
    $image -> string(
		     $bigfont, 
		     $self->get_horizontal_offset()- $bigfont->width() * length($self->get_caption())/2, 
		     $self->get_vertical_offset()-$bigfont->height()-$self->{curved_height}/2, 
		     $self->get_caption(), $outline_color );

}

1;
