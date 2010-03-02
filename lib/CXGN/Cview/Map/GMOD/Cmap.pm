
use strict;

package CXGN::Cview::Map::GMOD::Cmap;

use base "CXGN::Cview::Map";

sub new { 
    my $class = shift;
    my $dbh = shift;
    my $id = shift;

    my $self = $class->SUPER::new($dbh, $id);
    $self->set_id($id);

    my $map_q = "SELECT map_set_name, map_set_short_name, map_units, species_common_name FROM cmap_map_set JOIN cmap_species USING (species_id)  WHERE map_set_id=?";
    my $map_h = $self->get_dbh()->prepare($map_q);
    $map_h->execute($self->get_db_id());
    
    my ($map_set_name, $map_set_short_name, $map_units, $species) = 
	$map_h->fetchrow_array();

    $self->set_short_name($map_set_short_name);
    $self->set_long_name($map_set_name);
    $self->set_units($map_units);
    $self->set_organism($species);
    $self->set_common_name($species);
    my $count_q = "SELECT map_name, map_stop FROM cmap_map WHERE map_set_id=? ORDER BY (map_acc + 0)";
    my $count_h = $self->get_dbh()->prepare($count_q);
    $count_h->execute($self->get_db_id());
    my @chr_names = ();
    my @chr_len = ();
    while (my ($name, $length) = $count_h->fetchrow_array()) { 
	push @chr_names, $name;
	push @chr_len, $length;
    }

    print STDERR "Chromosome Names = ".(join " ", @chr_names)."\n";

    print STDERR "map id: ".($self->get_id())." db id = ".($self->get_db_id())."\n";
    $self->set_chromosome_names(@chr_names);

    print STDERR "chr lens = ".(join " ", @chr_len)."\n";
    $self->set_chromosome_lengths(@chr_len);
    $self->set_chromosome_count(scalar(@chr_len));


    return $self;
}

sub get_chromosome { 
    my $self = shift;
    my $chr_nr = shift;
    
    my $query = "SELECT feature_id,feature_name, feature_start, feature_stop, feature_type_acc FROM cmap_map_set JOIN cmap_map using(map_set_id) JOIN cmap_feature USING (map_id) WHERE map_set_id=? AND map_name=? ORDER BY feature_start";

    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_db_id(), $chr_nr);

    my $chr = CXGN::Cview::Chromosome->new();

    while (my ($feature_id, $name, $start, $stop, $type) = $sth->fetchrow_array()) { 
	
	my $marker = CXGN::Cview::Marker->new($chr);
	$marker->set_offset($start);
	$marker->set_id($feature_id);
	$marker->set_marker_name($name);
	$marker->get_label()->set_name($name);
	$marker->get_offset_label()->set_name($start);
	$chr->add_marker($marker);

    }
    
    $chr->_calculate_chromosome_length();

    return $chr;

}

sub get_overview_chromosome { 
    my $self = shift;
    my $chr_nr = shift;
    
    my $chr = $self->get_chromosome($chr_nr);
    foreach my $m ($chr->get_markers) { 
	$m->hide_label();
    }

    $chr->set_width(12);
    return $chr;
}

sub get_chromosome_section { 
    my $self = shift;
    my $chr_nr = shift;
    my $start = shift;
    my $end = shift;
    
    my $chr =  $self-> get_chromosome($chr_nr);
    
    $chr->set_section($start, $end);
    
    $chr->_calculate_chromosome_length();
    return $chr;
}



sub get_marker_count { 
    my $self = shift;
    my $chr_name = shift;
    my $query = "SELECT count(*) from cmap_map JOIN cmap_feature USING(map_id) WHERE map_set_id=? and map_name=?";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_db_id(), $chr_name);
    my ($count) = $sth->fetchrow_array();
    return $count;
}

sub get_chromosome_connections { 
    my $self = shift;
    my $chr_nr = shift;
    
    my $query = "SELECT comp_map.map_set_id, comp_map_set.map_set_short_name, comp_map.map_name, count(comp_feature.feature_id) FROM cmap_map JOIN cmap_feature USING (map_id) join cmap_feature_correspondence ON (cmap_feature.feature_id=cmap_feature_correspondence.feature_id1) JOIN cmap_feature AS comp_feature ON (cmap_feature_correspondence.feature_id2=comp_feature.feature_id) JOIN cmap_map AS comp_map ON (comp_feature.map_id=comp_map.map_id) JOIN cmap_map_set as comp_map_set ON (comp_map.map_set_id=comp_map_set.map_set_id) WHERE cmap_map.map_name=? AND cmap_map.map_set_id=? GROUP BY comp_map.map_set_id, comp_map.map_name, comp_map_set.map_set_short_name";

    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($chr_nr, $self->get_db_id());
    
    my @list = ();
    while (my ($id, $short_name, $chr_name, $count) = $sth->fetchrow_array()) { 
	push @list, { map_version_id=>"cmap".$id, short_name=>$short_name, lg_name=>$chr_name, marker_count=> $count};

    }

    
    return @list;
}

sub can_zoom { 
    return 1;
}


sub get_db_id { 
    my $self = shift;
    my $id = $self->get_id();
    $id=~s/.*(\d+).*/$1/;
    return $id;
}

return 1;
