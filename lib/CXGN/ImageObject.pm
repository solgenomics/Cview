

=head1 NAME

CXGN::Cview::ImageObject - parent class for all image objects in Cview.

=head1 DESCRIPTION

This class defines and implements a number of functions. Some functions, such as render(), need to be overridden in derived classes.

=head1 SEE ALSO

L<CXGN::Cview>

=head1 AUTHOR(S)

Lukas Mueller <lam87@cornell.edu>

=head1 FUNCTIONS

This class defines the following methods:

=cut

    1;

use strict;

package CXGN::Cview::ImageObject;

=head2 function new()

  Synopsis:	constructor
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub new {
    my $class = shift;
    my $args = {};
    my $self = bless $args, $class;
    my $x = shift;
    my $y = shift;
    my $height = shift;
    my $width = shift;
    $self->set_horizontal_offset($x);
    $self->set_vertical_offset($y);
    $self->set_height($height);
    $self->set_width($width);
    $self->set_color(0,0,0);
    return $self;
}

=head2 accessors get_name(), set_name()

  Synopsis:	$io -> set_name("foo")
  Property:	the name of the image element
  Side effects:	
  Description:	

=cut

sub set_name {
    my $self =shift;
    $self->{name} = shift;
}

sub get_name {
    my $self = shift;
    return ($self->{name});
}

=head2 accessors get_enclosing_rect(), set_enclosing_rect()

  Synopsis:     $io->set_enclosing_rect(10, 10, 100, 100)	
  Property:	a list of coords, top left x,y and bottom right x,y
  Side effects:	
  Description:	

=cut

sub set_enclosing_rect {
    my $self = shift;
    @{$self->{enclosing_rect}} = @_;
}

sub get_enclosing_rect {
    my $self = shift;
    if (!exists($self->{enclosing_rect})) { 
	@{$self->{enclosing_rect}}=(0, 0, 0, 0); 
    }
    return @{$self->{enclosing_rect}};
}

=head2 accessors set_color(), get_color()

  Synopsis:	$io->set_color(255,255,0)
  Property:     the color of the element
  Side effects:	the element will be rendered in this color
  Description:	

=cut

sub set_color {
    my $self = shift;
    ($self->{color}[0], $self->{color}[1], $self->{color}[2]) = @_;
}
    
sub get_color { 
    my $self = shift;
    return @{$self->{color}};
}

=head2 function render()

  Synopsis:	[abstract method]
  Arguments:	an GD::Image object
  Returns:	nothing
  Side effects:	this should be implemented to draw the image object
                on the GD::Image.
  Description:	

=cut

sub render {
    my $self = shift;
    # does nothing
}

=head2 function get_image_map()

  Synopsis:	$io->get_mage_map()
  Arguments:	none
  Returns:	a string representing the html image map for the object
  Side effects:	
  Description:	a default implementation is given that should work for most
                objects, or it may be overridden in sub-classes.

=cut

sub get_image_map {
    my $self = shift;
     my $coords = join ",", ($self -> get_enclosing_rect());
     my $string;
     if ($self->get_url()) {  $string =  "<area name=".$self->get_name()." shape=\"rect\" coords=\"".$coords."\" href=\"".$self->get_url()."\" alt=\"".$self->get_name()."\" />";}
    return $string;

}

=head2 accessors get_url(), set_url()

  Synopsis:	$io->set_url("http://sgn.cornell.edu/search/unigene.pl?unigene_id=449494")
  Property:     the link this object should go to when clicked
  Side effects:	this link will be imbeded in the html image map
  Description:	

=cut

sub set_url {
    my $self = shift;
    $self->{url}=shift;
}

sub get_url {
    my $self = shift;
    if (!exists($self->{url}) || !defined($self->{url})) { $self->{url}=""; }
    return $self->{url};
}

=head2 accessors set_horizontal_offset(), get_horizontal_offset()

 Synopsis:	my $offset = $chr -> get_horizontal_offset()
                $chr->set_horizontal_offset(57)
 Arguments:     setter: the offset in pixels [integer]
 Returns:	getter: returns the horizontal offset in pixels 
                        of the image element. The 
 Side effects:	
 Description:	The horizontal offset can be defined in different ways 
                depending on the image. Most often, it denotes the mid-line 
                of the object (such as a chromosome) or the left boundary.

=cut

sub get_horizontal_offset { 
    my $self=shift;
    if (!exists($self->{horizontal_offset}) || ! defined($self->{horizontal_offset})) { $self->set_horizontal_offset(0); }
    return $self->{horizontal_offset};
}

sub set_horizontal_offset { 
    my $self=shift;
    $self->{horizontal_offset}=shift;
}

=head2 accessors get_X(), set_X()

  Synopsis:	same as accessors for horizontal_offset(), but shorter!
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub get_X { 
    my $self=shift;
    return $self->{horizontal_offset};
}

sub set_X { 
    my $self=shift;
    $self->{horizontal_offset}=shift;
}

=head2 accessors get_vertical_offset(), set_vertical_offset()

 Synopsis:	$chr -> get_vertical_offset()
 Arguments:	setter: the vertical offset in pixels.
 Returns:	Returns the vertical offset of the image element in pixels. 
 Side effects:	
 Description:	Returns the vertical offset of the image element, which 
                defines the upper limit of the image element. Certain 
                chromosome renditions will add a round edge on the top that 
                will extend the chromomsome beyond that value.

=cut

sub get_vertical_offset { 
    my $self=shift;
    if (!exists($self->{vertical_offset}) || !defined($self->{vertical_offset})) { 
	$self->{vertical_offset}=0;
    }
    return $self->{vertical_offset};
}

sub set_vertical_offset { 
    my $self=shift;
    $self->{vertical_offset}=shift;
}

=head2 accessors get_Y(), set_Y()

  Synopsis:	same as vertical_offset accessors
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub get_Y { 
    my $self=shift;
    return $self->{vertical_offset};
}

sub set_Y { 
    my $self=shift;
    $self->{vertical_offset}=shift;
}



=head2 accessors get_height(), set_height()

 Synopsis:	$io->set_height(300)
 Property:	the height of the object in pixels
 Side effects:	note that changing this property does not change
                the enclosing rect automatically. This has to be
                done manually.
 Description:	

=cut

sub get_height { 
    my $self=shift;
    if (!exists($self->{height})) { $self->set_height(0); }
    return $self->{height};
}

sub set_height { 
    my $self=shift;
    $self->{height}=shift;
}

=head2 accessors get_width(), set_width()

  Synopsis:	$io->set_width(100)
  Property:	the width of this object in pixels
  Side effects:	note that changing this will not change the 
                enclosing rect - this needs to be changed 
                separately manually
  Description:	

=cut

sub get_width { 
    my $self=shift;
    return $self->{width};
}


sub set_width { 
    my $self=shift;
    $self->{width}=shift;
}




=head2 accessors get_font(), set_font()

  Synopsis:	$io->set_font(GD::Font->Tiny)
  Property:     the GD font to be used when drawing this object
  Side effects:	
  Description:	

=cut

sub get_font { 
    my $self=shift;
    return $self->{font};
}

sub set_font { 
    my $self=shift;
    $self->{font}=shift;
}

=head2 function round()

  Synopsis:	my $rounded = round(4.3);
  Arguments:	a real number to be rounded
  Returns:	an int
  Side effects:	none
  Description:	Perl does not have a round function built in (it\'s in Math::round),
                but we need it for rounding calculation of pixels. 
  Note:         works also for negative numbers, astoninglishly

=cut

sub round { 
    my $value = shift;
    my $int = int($value);
    my $rest = abs($value)-abs($int);
    if ($rest > 0.5) { 
	if ($value > 0) { 
	    $int++;
	}
	else { 
	    $int--;
	}
    }
    #print STDERR "Rounded $value to $int\n";
    return $int;
}
