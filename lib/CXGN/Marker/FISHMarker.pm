
=head1 NAME

CXGN::Cview::Marker::FISHMarker - a class for drawing fished BACs.

=head1 DESCRIPTION

Inherits from L<CXGN::Cview::Marker>. Deals with displaying FISH markers on the pachytene chromosomes. Work pretty much like other marker objects, the main difference being how the offset is being represented: The unit is percent, not cM, and the distances are measured from the centromere. On the short arm (top arm), the percent values are given as negative values, on the long (bottom) arm, the values are positive.

=head1 SEE ALSO

See also the documentation in L<CXGN::Cview>.

=head1 AUTHOR(S)

Lukas Mueller (lam87@cornell.edu)

=head1 FUNCTIONS


=cut

1;

use strict;
use CXGN::Cview::Marker;

package CXGN::Cview::Marker::FISHMarker;

use base qw( CXGN::Cview::Marker );

sub new { 
    my $class = shift;
    my $self = $class -> SUPER::new(@_);
    return $self;
}

=head2 function set_offset()

Sets the offset in percent. Legal range -100 .. +100. Negative offset is drawn on the short arm,
positive offset is drawn on the long arm.

=cut

sub set_offset { 
    my $self = shift;
    my $offset = shift;
    if (abs($offset)>100) { 
	print STDERR "CXGN::Cview::Marker::FISH_marker::set_offset: warning, abs(offset) [$offset] > 100\n";
    }
    $self->SUPER::set_offset($offset);
}
#
# always return a constant color, such as light green, for the FISH marker colors.
# and for the label... So we override some marker functions here.
#
sub get_color { 
    my $self = shift;
    return (255,50,50);
}

sub get_label_line_color { 
    my $self = shift;
    return (50, 50, 150);
}

sub get_text_color { 
    my $self = shift;
    return (50, 50, 150); 
}
