
=head1 NAME

CXGN::Cview::ImageI - an interface for top-level Cview images.

=head1 DESCRIPTION

=head1 AUTHOR(S)

Lukas Mueller (lam87@cornell.edu)

=head1 FUNCTIONS


=cut

use strict;

package CXGN::Cview::ImageI;

use GD;

=head2 function new

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    
    # set some defaults...
    #
    $self->set_width(600);
    $self->set_height(400);

    return $self;
}

=head2 function render

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub render {
}

=head2 accessors get_width(), set_width()

  Synopsis:	$width = $ii->get_width()
  Property:     the width, in pixels, of the canvas
  Side effects:	
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

=head2 accessors get_height(), set_height()

  Synopsis:	my $height = $ii->get_height()
  Property:     the height in pixels of the canvas
  Side effects:	
  Description:	

=cut

sub get_height { 
    my $self=shift;
    return $self->{height};
}

sub set_height { 
    my $self=shift;
    $self->{height}=shift;
}

=head2 accessors get_image(), set_image()

  Synopsis:	my $i = $ii->get_image()
  Property:     the GD::Image used for drawing on this canvas
  Side effects:	
  Description:	

=cut

sub get_image { 
    my $self=shift;
    return $self->{image};
}

sub set_image { 
    my $self=shift;
    $self->{image}=shift;
}

=head2 function add_image_object

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub add_image_object { 
    my $self = shift;
    my $object = shift;
    if (!exists($self->{image_objects})) { $self->{image_objects}= []; }
    push @{$self->{image_objects}}, $object;
}

=head2 function get_image_objects

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub get_image_objects { 
    my $self = shift;
    return @{$self->{image_objects}};
}

=head2 accessors get_name, set_name

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_name {
  my $self = shift;
  return $self->{name}; 
}

sub set_name {
  my $self = shift;
  $self->{name} = shift;
}

return 1;
