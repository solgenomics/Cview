

=head1 NAME

CXGN::Cview::ChrLink - an class for drawing chromosome relationships.

=head1 DESCRIPTION

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

package CXGN::Cview::ChrLink;

use base qw/CXGN::Cview::ImageObject/;

use GD;

sub new { 
    my $class = shift;
    my $args = {};
    my $self = bless $args, $class;

    $self->{chr1}=shift;
    $self->{cM1} = shift;
    $self->{chr2}=shift;
    $self->{cM2} = shift;
    $self->{marker_name}=shift;
 
    # define default color
    $self -> set_color(100, 100, 100);
    return $self;
}

sub set_color {
    my $self = shift;
    $self->{color}[0]=shift;
    $self->{color}[1]=shift;
    $self->{color}[2]=shift;
}

sub render {
    my $self = shift;
    my $image = shift;

    # draw only of both markers are visible...
    if ($self->{chr1}->is_visible($self->{cM1}) && $self->{chr2}->is_visible($self->{cM2})) {
	my $sign = (($self->{chr2}->get_horizontal_offset()) <=> ($self->{chr1}->get_horizontal_offset()));
	my $x1 = $self->{chr1}->get_horizontal_offset() + $sign*($self->{chr1}->get_width()/2);
	my $y1 = $self->{chr1}->mapunits2pixels($self->{cM1});
	my $x2 = $self->{chr2}->get_horizontal_offset() - $sign*($self->{chr2}-> get_width()/2);
	my $y2 = $self->{chr2}->mapunits2pixels($self->{cM2});

	#print STDERR "link color: $self->{color}[0], $self->{color}[1], $self->{color}[2]\n";
	my $color = $image -> colorResolve($self->{color}[0], $self->{color}[1], $self->{color}[2]);
	$image->setAntiAliased($color);
	$image -> line($x1, $self->{chr1}->get_vertical_offset()+$y1, $x2, $self->{chr2}->get_vertical_offset()+$y2, gdAntiAliased);
    }
    else { 
	#print STDERR "Not rendering link because not visible. chr1 cM: $self->{cM1} chr2 cM: $self->{cM2}\n"; 
    }
    
}

=head2 get_marker_name(), set_marker_name()

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_marker_name {
  my $self=shift;
  return $self->{marker_name};

}

sub set_marker_name {
    my $self=shift;
    $self->{marker_name}=shift;
}

