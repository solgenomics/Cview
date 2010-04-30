
use strict;

package CXGN::Cview::Chromosome::Scaffold;

use base "CXGN::Cview::Chromosome";

our $INTER_SCAFFOLD_DISTANCE = 100_000;

sub new { 
    my $class = shift;
    my $file = shift;
    my $chr_nr = shift;
    my $marker_link = shift;

    my $self = $class-> SUPER::new($chr_nr);

    $self->{marker_link} = $marker_link;
    
    open (my $F, "<$file") || die "Can't find file $file.";

    my $current_offset = 0;

    while (<$F>) { 
	chomp;
	
	my ($scaffold, $length, $c, $cM) = split /\t/;
	
	if ($c != $chr_nr) { next(); }
	
	my $m = CXGN::Cview::Marker::RangeMarker->new($self);
	
	$current_offset += $INTER_SCAFFOLD_DISTANCE;
	
	$m->get_label()->set_name($scaffold);
	$m->set_marker_name($scaffold);
	$m->get_label()->set_url(&{$self->{marker_link}}($scaffold));
	$m->set_offset($current_offset + ($length/2));
	$m->set_north_range($length/2);
	$m->set_south_range($length/2);
	$self->add_marker($m);
	$current_offset += $length;
    }
    close($F);

    $self->sort_markers();
    $self->set_length($current_offset);
    #$chr->set_url($self->{url});
    $self->distribute_labels();
    $self->distribute_label_stacking();
    $self->set_units("bp");
    $self->get_ruler()->set_units("bp");

    return $self;
}

return 1;
