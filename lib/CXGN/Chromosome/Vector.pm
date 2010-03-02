
=head1 NAME 

CXGN::Cview::Chromosome::Vector - a class to draw circular vectors, plasmids, or genomes

=head1 DESCRIPTION

This class inherits from L<CXGN::Cview::Chromosome>, but represents a circular DNA molecule. The only marker type that is supported is L<CXGN::Cview::Marker::VectorFeature>. 

The height property of the chromosome object is used to set the height in pixels of the circular structure (represents the diameter) whereas the width property represents the thickness of the molecule. The outer edge of the vector image is represented by height/2, and the thickness is going inwards from there.

The mapunits2pixels function has been overridden to yield two coordinates, representing the position on the outer edge of the visual representation of the vector. 

A function, angle(), has been added to calculate the angle for a given map position. 

The default map units are bp (set in the constructor).

=head1 AUTHOR

Lukas Mueller <lam87@cornell.edu>

=cut
 
use strict;

package CXGN::Cview::Chromosome::Vector;

use CXGN::Cview::Marker::VectorFeature;

use base qw | CXGN::Cview::Chromosome |;

our $pi = 3.1415962;

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
    $self->set_units("bp");
    return $self;
}



=head2 mapunits2pixels

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub mapunits2pixels {
    my $self = shift;
    my $mapunits = shift;
    
    my $angle =  $self->angle($mapunits);

    my $x = sin($angle) * $self->get_radius() + $self->get_X();
    my $y = cos($angle) * $self->get_radius() + $self->get_Y();

    return ($x, $y);
    
}

=head2 angle

 Usage:        $v->angle($offset);
 Desc:         returns the angle on the circle for the given
               offset
 Ret:          an angle in radians
 Args:         the offset in map units

=cut


sub angle { 
    my $self = shift;
    my $mapunits = shift;
    return (2 * $pi - ($mapunits / $self->get_length()) * ( 2 * $pi) - $pi);
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

    $self->layout();

    $self->draw_chromosome($image);
    $self->draw_markers($image);
    $self->draw_caption($image);
}

=head2 layout

 Usage:        $v->layout()
 Desc:         lays out the vector and labels
 Ret:          nothing
 Args:         none
 Side Effects: coordinates calculated in layout are 
               used to render the vector with render()
 Example:

=cut

sub layout {
    my $self = shift;

    my @right_markers = ();
    my @left_markers = ();
    
    # set each marker to the corresponding x height 
    # of its corresponding vector position
    #
    my $marker_name = 1;
    my $r = $self->get_radius() * 1.4;

    foreach my $m ($self->get_markers()) {
 
	my ($x, $y) = $m->get_chromosome()->mapunits2pixels($m->get_offset());
	my $angle = $m->get_chromosome()->angle($m->get_offset());
	$m->get_label()->set_Y($y);

	$m->get_label()->set_reference_point($x, $y);
	$m->set_marker_name($marker_name);	

	# is the marker on the right side of the vector?
	#
	if ($x >=  $self->get_X()) { 
	    $m->set_label_side("right");
	    $m->get_label()->set_X( $self->get_X() +  $r * sin($angle) );
	    push @right_markers, $m;
	}
	else { 	    
	    # the label is on the left...
	    #
	    $m->get_label()->align_right(); # the line of the label should attach on the right side of the label
	    $m->get_label()->set_X( $self->get_X() + $r * sin($angle));
	    $m->set_label_side("left");
	    push @left_markers, $m;
	}
	$marker_name++;
    }
    
    @left_markers = sort _sort_by_y_coord @left_markers;
    @right_markers = sort _sort_by_y_coord @right_markers;

    @{$self->{left_markers}} = @left_markers;
    @{$self->{right_markers}} = @right_markers;
    
    $self->_distribute_labels(@left_markers);
    $self->_distribute_labels(@right_markers);
    
	    
}

sub _sort_by_y_coord { 
    my ($a_x, $a_y) = $a->get_chromosome()->mapunits2pixels($a->get_offset());
    my ($b_x, $b_y) = $b->get_chromosome()->mapunits2pixels($b->get_offset());
    $a_y <=> $b_y;
    
}

sub _distribute_labels { 
     my $self = shift;
     my @m = @_;
    
     if (!@m) { return; }

     # calculate the downwards offsets
     #
     my $previous_labelpos = 0;
     my %downwards=();
     foreach my $m (@m) {
	 #die "marker name = ". $m->get_name() ."\n";
	 #if ($m->is_visible() && $m->is_label_visible()) { 
	     my $offset= $m->get_offset();
	     my ($x, $y) = $self->mapunits2pixels($offset);
	     my $angle = $self->angle($offset);
	     my $labelpos = cos($angle) * ($m->get_label_spacer() + $self->get_radius()) + $self->get_Y();
	     my $labelheight = $m -> get_label_height();
	     #print STDERR "label height: $labelheight\n";
	     
	     if (($labelpos-$labelheight)<$previous_labelpos) { 
		 $labelpos = $previous_labelpos+$labelheight;
		 if (exists($downwards{$m->get_name()})) { print STDERR "CATASTROPHE: Duplicate marker name ".($m->get_name())."\n"; }
		 $downwards{$m->get_name()} = $labelpos;
	     }
	     else {
		 $downwards{$m->get_name()}=$labelpos;
	     } 
	     $previous_labelpos = $labelpos;
	 #}
     }
     
     # calculate the upwards offsets
     #
     my %upwards = ();
     my @reverse_markers = reverse(@m);
     my $top_angle = $self->angle($reverse_markers[0]->get_offset());
     my $toplabelpos = 99999; #sin($top_angle) * ($self->get_height()/2 + $reverse_markers[0]->get_label_spacer());
     foreach my $m (@reverse_markers)  {
	 #if ($m->is_visible() && $m->is_label_visible()) { 
	     my $offset=$m->get_offset();
	     my ($x, $y) = $self->mapunits2pixels($offset);
	     my $angle = $self->angle($offset);
	     my $labelpos = cos($angle) * ( $m->get_label_spacer() + $self->get_radius()) + $self->get_Y();
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
	 #}
     }
     
     # load into marker objects
     #
     foreach my $m (@m) {
	 my $marker_name = $m -> get_name();
	 # test to prevent warnings...
	 if (! $downwards{$marker_name}) { $downwards{$marker_name}=0; }
	 if (! $upwards{$marker_name}) { $upwards{$marker_name} = 0; }
	 
	 my $pixels = int(($downwards{$marker_name}+$upwards{$marker_name})/2);
	 
	 $m->get_label()->set_Y($pixels);
	 my $r = 200;
	 
	 #print STDERR "Vertical pixels for marker ".$m->get_marker_name()." : $pixels.\n";
	 
	 
     }
 }



=head2 draw_chromosome

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub draw_chromosome {
    my $self = shift;
    my $image = shift;
    
    # render vector backbone
    #
    my $draw_color = $image->colorAllocate(0,0,0);
    $image->arc($self->get_X(), $self->get_Y(), $self->get_height(), $self->get_height(), 0, 360, $draw_color);

    $image->arc($self->get_X(), $self->get_Y(), $self->get_height()- 2 * $self->get_width(), $self->get_height()- 2 * $self->get_width(), 0, 360, $draw_color);

        my $fill_color = $image->colorAllocate($self->get_color());
    $image->fill($self->get_X()+$self->get_height()/2 - 2, $self->get_Y(), $fill_color);

    $self->draw_caption($image);

}

sub draw_markers { 
    my $self = shift;
    my $image = shift;

    # first render markers with ranges, otherwise this will mess up their highlighting.
    # then draw the other marker ticks.
    # then draw the labels.
    #
    foreach my $m (@{$self->{right_markers}}, @{$self->{left_markers}}) { 
	if ($m->has_range()) { $m->render_region($image); }
    }
    foreach my $m (@{$self->{right_markers}}, @{$self->{left_markers}}) { 
	$m->get_label()->render($image);
    }
    foreach my $m (@{$self->{right_markers}}, @{$self->{left_markers}}) { 
	if (!$m->has_range())  { $m->draw_tick($image); }
    }
	


}

=head2 draw_caption

 Usage:        $v->draw_caption($image)
 Desc:         draws the caption on $image, centered in 
               the vector.
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub draw_caption {
    my $self = shift;
    my $image = shift;

    my $font = GD::Font->Giant;
    my $color = $image->colorAllocate(0, 0, 0);

    my $x =  $self->get_X() - $font->width() * length($self->get_caption()) / 2;
    my $y =  $self->get_Y() - $font->height();

    $image->string($font, $x, $y, $self->get_caption(),  $color);

    $font = GD::Font->Small;

    my $string = "(".$self->get_length()." bp)";
    my $x = $self->get_X() - $font->width() * length($string)/2 ;
    my $y = $self->get_Y() + $font->height()/2;
    
    $image->string($font, $x, $y, $string, $color);
    
}


=head2 get_radius

 Usage:        my $r = $v->get_radius();
 Desc:         returns the radius of the circle deliniating the 
               vector. There is no setter, use set_height() instead,
               which corresponds to the diameter.
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_radius {
    my $self = shift;
    return $self->get_height()/2;
}


return 1;
