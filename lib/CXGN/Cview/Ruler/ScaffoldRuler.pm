
use strict;

package CXGN::Cview::Ruler::ScaffoldRuler;

use base "CXGN::Cview::Ruler";

sub new { 
    my $class = shift;
    my ($x, $y, $height, $start, $end) = @_;

    my $self = $class->SUPER::new($x, $y, $height, $start, $end);

    $self->set_start_value($start);
    $self->set_end_value($end);
    $self->set_units('Mb');

    return $self;
}

sub set_start_value { 
    my $self = shift;
    my $value = shift;
    $self->{start_value} = (int($value / 1_000_000)); # show in megabases
}

sub set_end_value { 
    my $self = shift;
    my $value = shift;
    $self->{end_value} = (int($value / 1_000_000));
}

return 1;
