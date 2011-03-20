
use Modern::Perl;

package CXGN::Cview::Chromosome::Image;

use base 'CXGN::Cview::Chromosome';

use GD;

sub new { 
    my $class = shift;
    my $id = shift;
    my $file = shift;

    my $self = $class->SUPER::new(@_);

    
    $self->{chr_image}  = GD::Image->newFromPng($file);

    if (!defined($self->{chr_image})) { die "Unable to load image file $file."; }

    return $self;
}

sub draw_chromosome { 
    my $self = shift;
    
    $self->render(@_);
}
sub render { 
    my $self = shift;
    my $image = shift;

    #print STDERR "Rendering chromosome...\n";
    my $ratio = $self->{chr_image}->width()/$self->{chr_image}->height();
    my $halfwidth = int(($self->get_height()* $ratio)/2);
    $image->copyResized($self->{chr_image}, 
			$self->get_X()-$halfwidth, 
			$self->get_Y(), 
			0, 
			0, 
			$self->get_height() * $ratio,
			$self->get_height(),
			$self->{chr_image}->width(), 
			$self->{chr_image}->height()
	);

    $self->draw_caption($image);
    #print STDERR "Done.\n";

}

1;
