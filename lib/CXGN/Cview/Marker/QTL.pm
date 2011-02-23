
use strict;
use warnings;

package CXGN::Cview::Marker::QTL;

use base "CXGN::Cview::Marker::Physical";

sub new { 
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    $self->set_marker_width(4);
    return $self;
}

sub render { 
    my $self = shift;
    $self->SUPER::render(@_);
}

1;
