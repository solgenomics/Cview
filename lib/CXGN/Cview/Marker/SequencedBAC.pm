
=head1 NAME

CXGN::Cview::SequencedBAC - a class for drawing sequenced BACs

=head1 DESCRIPTION

Inherits from L<CXGN::Cview::Marker>. 

=head1 SEE ALSO

See also the documentation in L<CXGN::Cview>.

=head1 AUTHOR(S)

Lukas Mueller (lam87@cornell.edu)

=head1 FUNCTIONS


=cut

return 1;

use strict;
use CXGN::Cview::Marker;

package CXGN::Cview::Marker::SequencedBAC;

use base qw( CXGN::Cview::Marker );

sub new { 
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    
    return $self;
}




