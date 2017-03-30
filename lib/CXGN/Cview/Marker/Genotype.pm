
use strict;

package CXGN::Cview::Marker::Genotype;

use base qw | CXGN::Cview::Marker |;

sub set_score { 
    my $self = shift;
    $self->{score} = shift;
}

sub get_score { 
    my $self = shift;
    return $self->{score};
}

1;
