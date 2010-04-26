
package CXGN::Cview::Map::SGN::Scaffold;

use base qw | CXGN::Cview::Map |;

use CXGN::Cview::Chromosome;

sub new { 
    my $class = shift;
    my $dbh = shift;
    my $args = shift;
    my $self = $class->SUPER::new($dbh);

    $self->{file} = $args->{file};
    $self->{marker_link} = $args->{marker_link};
    $self->set_temp_dir($args->{temp_dir});

    $self->set_chromosome_names(1,2,3,4,5,6,7,8,9,10,11,12);
    $self->set_chromosome_count(12);
    $self->set_short_name($args->{short_name});
    $self->set_long_name($args->{long_name});
    return $self;
}


sub get_chromosome_lengths { 
    
}


sub get_chromosome { 
    my $self = shift;
    my $chr_nr = shift;

    my $INTER_SCAFFOLD_DISTANCE = 10_000;

    
    open (my $F, "<".$self->{file}) || die "Can't open file $file.";

    my $chr = CXGN::Cview::Chromosome->new();
    $chr->set_height(500);
    $chr->set_width(20);
    $chr->set_units('bp');
    $chr->set_height(100);
    my $length = 0;

    my $current_offset=0;

    while (<$F>) { 
	chomp;
	
	my ($scaffold, $length, $c, $cM) = split /\t/;

	if ($c != $chr_nr) { next(); }

	my $m = CXGN::Cview::Marker::RangeMarker->new($chr);

	$current_offset += $INTER_SCAFFOLD_DISTANCE;
	
	$m->get_label()->set_name($scaffold);
	$m->set_marker_name($scaffold);
	$m->get_label()->set_url(&{$self->{marker_link}}($scaffold));
	$m->set_offset($current_offset + ($length/2));
	$m->set_north_range($length/2);
	$m->set_south_range($length/2);
	$chr->add_marker($m);
	$current_offset += $length;
    }
    close($F);
    $chr->set_length($current_offset); 
    $chr->sort_markers();
    #$chr->set_url($self->{url});
    $chr->distribute_labels();
    $chr->distribute_label_stacking();
    return $chr;
}

sub get_overview_chromosome { 
    my $self = shift;
    my $chr_nr = shift;
    my $chr = $self->get_chromosome($chr_nr);
    my @m = $chr->get_markers();
    foreach my $m (@m) { 
	$m->hide_label();
    }
    return $chr;
}

sub cache_chromosome_lengths { 
    my $self = shift;
    my $temp_dir = $self->get_temp_dir();
    my $path = File::Spec->catfile($temp_dir, "scaffold_chromosome_length_cache.txt");
    if (! -e $path) { 
	
	open my $F, ">".$path || die "Can't open file $path for writing";

	
    }

}

return 1;
