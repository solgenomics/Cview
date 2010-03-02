
use strict;

use CXGN::Cview::Label;

package CXGN::Cview::Label::Physical;

use GD;

use base qw / CXGN::Cview::Label /;


=head2 function new()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    # set some interesting defaults
    #
    $self->set_align_side("left");
    $self->set_label_spacer(20);
    $self->set_vertical_stacking_spacing(2);
    $self->set_stacking_height(5);


    return $self;
}


=head2 function render_line()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

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

	#my $horizontal = ($self->get_reference_point())[0]-$self->get_stacking_level()*$self->get_stacking_height();

 	$image->line($connection_x, $connection_y,  
  		     ($self->get_reference_point())[0], ($self->get_reference_point())[1], 
  		     gdAntiAliased
  		     );
    }
    if ($self->get_align_side() eq "left") { 

	$connection_x = $x;
	$connection_y = $y + CXGN::Cview::ImageObject::round(($b - $y)/2);

	#my $horizontal = ($self->get_reference_point())[0]+$self->get_stacking_level()*$self->get_stacking_height();

	$image->line($connection_x, 
		     $connection_y,  
		     ($self->get_reference_point())[0], 
		     ($self->get_reference_point())[1], 
		     gdAntiAliased 
		     );

    }

}

return 1;
