

=head1 NAME

CXGN::Cview::Chromosome::Physical

=head1 DESCRIPTION

Inherits from L<CXGN::Cview::Chromosome>. 

=head1 SEE ALSO

See also the documentation in L<CXGN::Cview>.

=head1 AUTHOR(S)

Lukas Mueller (lam87@cornell.edu)

=head1 FUNCTIONS


=cut

1;

use strict;
use CXGN::Cview::Chromosome;

package CXGN::Cview::Chromosome::Physical;

use base qw( CXGN::Cview::Chromosome );

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    if (!defined($self)) { return undef; }
    # set some standard attributes of physical chromosomes
    #
    $self->set_width(10);
    #$self->set_color(200,200,200);
    return $self;
}

