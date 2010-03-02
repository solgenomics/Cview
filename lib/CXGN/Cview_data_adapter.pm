
# NOTE: THIS MODULE IS DEPRECATED AND WILL BE REMOVED SOON. 
# --LUKAS, APR 2007.
#
use strict;
return 1;

use CXGN::Cview::Marker;
use CXGN::Cview::Marker::SequencedBAC;
use CXGN::Cview::Marker::FISHMarker;
use CXGN::VHost;
use CXGN::Genomic::Clone;
use CXGN::Map::Tools;

package CXGN::Cview::Cview_data_adapter;

=head2 function get_chromosome()

 Synopsis:	gets a chromosome object of the appropriate type given a map_version_id
 Arguments:	database handle, CXGN::Map object,  and a chr_nr. 
 Returns:	a chromosome object of the appropriate type.
 Side effects:	
 Description:	

=cut

sub get_chromosome {
    my $dbh = shift;
    my $map = shift; # CXGN::Map object
    my $chr_nr = shift;
    my $type   = shift;
    my $c;
    unless (defined($type)) {$type='';} 
    if ($type =~ /fish/i) { 
	$c=CXGN::Cview::Chromosome::PachyteneIdiogram -> new ($chr_nr, 100, 100, 40);
	CXGN::Cview::Cview_data_adapter::fetch_pachytene_idiogram($c, $chr_nr);
	CXGN::Cview::Cview_data_adapter::fetch_fish_chromosome($dbh, $c, $map, $chr_nr, 0, $type);
	$c->set_width(6);
	$c->set_units("%");
	
    }
    else {
	$c= CXGN::Cview::Chromosome -> new($chr_nr, 60, 100, 40);
	CXGN::Cview::Cview_data_adapter::fetch_chromosome($dbh, $c, $map, $chr_nr, 0, $type); 
	
    }
    return $c;     
}

sub fetch_chromosome {
    my $dbh = shift;
    my $chromosome = shift; # the chromosome object
    my $map = shift;     # CXGN::Map object
    my $chr_nr = shift;     # the chromosome name
    my $marker_confidence_cutoff = shift; # the confidence cutoff. 3=frame 2=coseg 1=interval LOD=2 0=interval
    my $type = shift;

    #  if ($type=~/fish/i) {   
#  	return fetch_fish_chromosome($dbh, $chromosome, $map_id, $chr_nr); 
#      }
    

    if (!$marker_confidence_cutoff) { $marker_confidence_cutoff=-1; }

    my %seq_bac = ();

    my $sgn = $dbh->qualify_schema('sgn');
    my $physical = $dbh->qualify_schema('physical');

    if ($map->map_id() == CXGN::Map::Tools::current_tomato_map_id()) { 

	my $Sequenced_BAC_query =
        "
            SELECT 
                distinct $physical.bac_marker_matches.bac_id, 
                $physical.bac_marker_matches.cornell_clone_name, 
                $physical.bac_marker_matches.marker_id,
                $physical.bac_marker_matches.position
            FROM 
                $physical.bac_marker_matches 
                LEFT JOIN $sgn.linkage_group USING (lg_id) 
                LEFT JOIN sgn_people.bac_status USING (bac_id) 
            WHERE 
                $sgn.linkage_group.lg_name=? 
                AND sgn_people.bac_status.status='complete'
        ";
	my $sth2 = $dbh->prepare($Sequenced_BAC_query);
	$sth2->execute($chr_nr);
	while (my ($bac_id, $name, $marker_id, $offset)=$sth2->fetchrow_array()) { 
# print STDERR "Sequenced BAC for: $bac_id, $name, $marker_id, $offset...\n";
	    $name = CXGN::Genomic::Clone->retrieve($bac_id)->clone_name();

	    my $m = CXGN::Cview::Marker::SequencedBAC->new($chromosome, $bac_id, $name, "", "", "", "", $offset);
	    $m->get_label()->set_text_color(200,200,80);
	    $m->get_label()->set_line_color(200,200,80);
	    $seq_bac{$marker_id}=$m;
	}
    }

    # get the "normal" markers
    #
    my $query = 
    "
        SELECT 
            marker_experiment.marker_id, 
            alias, 
            mc_name, 
            confidence_id, 
            0, 
            subscript, 
            position, 
            0
        FROM   
            $sgn.map_version
            inner join $sgn.linkage_group using (map_version_id)
            inner join $sgn.marker_location using (lg_id)
            inner join $sgn.marker_experiment using (location_id)
            inner join $sgn.marker_alias using (marker_id)
            inner join $sgn.marker_confidence using (confidence_id)
            left join $sgn.marker_collectible using (marker_id)
            left join $sgn.marker_collection using (mc_id)
        WHERE  
            map_version.map_version_id=? 
            and lg_name=? 
            and preferred='t'
         ORDER BY  
            position,  
            confidence_id desc
    "; 


#         GROUP BY
#             markers.marker_id, 
#             marker_name,
#             marker_types.type_name,
#             confidence,
#             marker_locations.order_in_loc,
#             location_subscript,
#             \"offset\",
#             loc_type

    my $sth =  $dbh -> prepare($query);
    $sth -> execute($map->map_version_id(), $chr_nr);
    
    while (my ($marker_id, $marker_name, $marker_type, $confidence, $order_in_loc, $location_subscript, $offset, $loc_type) = $sth->fetchrow_array()) {
	#print STDERR "Marker Read: $marker_id\t$marker_name\t$marker_type\t$offset\n";
	my $m = CXGN::Cview::Marker -> new($chromosome, $marker_id, $marker_name, $marker_type, $confidence, $order_in_loc, $location_subscript, $offset, undef , $loc_type, 0);
	#print STDERR "dataadapter baccount = $bac_count!\n";
	if ($loc_type == 100) { $m -> set_frame_marker(); }
	$m -> set_url("/search/markers/markerinfo.pl?marker_id=".$m->get_id());
	$chromosome->add_marker($m);
	
	if (exists($seq_bac{$marker_id})) { 
	    #print STDERR "Adding Sequenced BAC [".($seq_bac{$marker_id}->get_name())."] to map...[$marker_id]\n";
	    $chromosome->add_marker($seq_bac{$marker_id});
	}
    }   

    $chromosome -> _calculate_chromosome_length();
}

sub fetch_fish_chromosome { 
    my $dbh = shift;
    my $chromosome = shift;
    my $map = shift; # CXGN::Map object
    my $chr_nr = shift;
    # The following query is a composition of 3 subqueries (look for the 'AS'
    # keywords), joined using the clone_id.  Here's what the subqueries do:
    #
    # * clone_id_and_percent: gets the average percent distance from the
    #   centromere as a signed float between -1.0 and +1.0, for each
    #   BAC on a given chromosome.  This is done by first computing the
    #   average absolute distance from the centromere (signed, in um),
    #   and then dividing by the length of the arm that the average
    #   would be located on.
    #
    # * min_marker_for_clone: finds one marker associated with the BAC
    #   (if any).
    #
    # * clone_info: finds the library shortname and clone name components.
    my $query = "
   SELECT shortname, clone_id, platenum, wellrow, wellcol, percent, marker_id
     FROM (SELECT clone_id, (CASE WHEN absdist < 0
                                       THEN absdist / short_arm_length
                                       ELSE absdist / long_arm_length END) AS percent
             FROM (SELECT clone_id, chromo_num,
                          AVG(percent_from_centromere * arm_length *
                              CASE WHEN r.chromo_arm = 'P' THEN -1 ELSE 1 END)
                              AS absdist
                     FROM fish_result r
                     JOIN fish_karyotype_constants k USING (chromo_num, chromo_arm)
                    WHERE chromo_num = ?
                    GROUP BY clone_id, chromo_num) AS clone_id_and_absdist
             JOIN (SELECT k1.chromo_num, k1.arm_length AS short_arm_length,
                          k2.arm_length AS long_arm_length
                     FROM fish_karyotype_constants k1
                     JOIN fish_karyotype_constants k2 USING (chromo_num)
                    WHERE k1.chromo_arm = 'P' AND k2.chromo_arm = 'Q')
                   AS karyotype_rearranged USING (chromo_num))
       AS clone_id_and_percent
LEFT JOIN (SELECT clone_id, MIN (m.marker_id) AS marker_id
             FROM sgn.fish_result AS c
             LEFT JOIN physical.overgo_associations a ON (c.clone_id = a.bac_id)
             LEFT JOIN physical.probe_markers m USING (overgo_probe_id)
             LEFT JOIN marker_experiment e ON (m.marker_id = e.marker_id)
             LEFT JOIN marker_location l ON (l.location_id = e.location_id)
             LEFT JOIN linkage_group g ON (g.lg_id = l.lg_id)
             LEFT JOIN map_version v ON (g.map_version_id = v.map_version_id)
            WHERE (v.current_version = 't' OR v.current_version IS NULL)
              AND (v.map_id = ? OR v.map_id IS NULL)
            GROUP BY c.clone_id)
       AS min_marker_for_clone USING (clone_id)
LEFT JOIN (SELECT shortname, clone_id, platenum, wellrow, wellcol
             FROM genomic.clone
             JOIN genomic.library USING (library_id))
       AS clone_info USING (clone_id)
ORDER BY percent
";

    my $sth = $dbh -> prepare($query);
    $sth->execute($chr_nr, CXGN::Map::Tools::current_tomato_map_id);
    while (my ($library_name, $clone_id, $platenum, $wellcol, $wellrow, $percent, $marker_id) = $sth->fetchrow_array()) {
	#print STDERR "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!Adding marker BAC:$library_name, $wellrow, $wellcol, $chromo_arm etc.\n";
	my $offset = 0;
	my $factor = 0;
	$offset = $percent * 100;

	my $clone_name = CXGN::Genomic::Clone->retrieve($clone_id)->clone_name();

	my $m = CXGN::Cview::Marker::FISHMarker -> new($chromosome, $marker_id, $clone_name, "", 3, $offset+100, "", $offset );
	$m -> set_url("/maps/physical/clone_info.pl?id=".$clone_id);
	$chromosome->add_marker($m);
    }
}
    


# sub get_overgo_bac_data {
#     my $dbh = shift;
#     my $m = shift;
    
#     my $query = 
#     "
#         SELECT 
#             if (physical.probe_markers.overgo_probe_id IS NULL, 0, 1), 
#             count(distinct(physical.overgo_associations.bac_id)) 
#         FROM 
#             marker
#             left join physical.probe_markers using (marker_id) 
#             left join physical.overgo_associations using (overgo_probe_id) 
#         where 
#             marker.marker_id=? 
#         group by 
#             marker.marker_id
#     ";

#     my $sth = $dbh -> prepare($query);
#     $sth -> execute($m->get_id());

#     if (my ($probes, $bacs) = $sth -> fetchrow_array()) {
# 	if ($probes) { $m->set_has_overgo(); }
# 	if ($bacs) { $m->set_has_bacs($bacs); }
#     }

# }


sub fetch_chromosome_overgo {
    my $dbh = shift;
    my $chromosome = shift; # the chromosome object
    my $map = shift;        # CXGN::Map object
    my $chr_nr = shift;     # the chromosome number
    my $start = shift;      # the start of the section in cM
    my $end = shift;        # the end of the section in cM

    # main query to get the marker data, including the BACs that are associated with this
    # marker -- needs to be refactored to work with the materialized views for speed improvements.
    #
    my $query = 
    "
        SELECT 
            marker_experiment.marker_id, 
            alias, 
            mc_name, 
            confidence_id,
            0, 
            subscript, 
            position, 
            0,
 	    min(physical.probe_markers.overgo_probe_id),
 	    count(distinct(physical.overgo_associations.bac_id)),
 	    max(physical.oa_plausibility.plausible)
        FROM 
            map_version
            inner join linkage_group using (map_version_id)
            inner join marker_location using (lg_id)
            inner join marker_experiment using (location_id)
            inner join marker_alias using (marker_id)
            inner join marker_confidence using (confidence_id)
            left join marker_collectible using (marker_id)
            left join marker_collection using (mc_id)
            LEFT JOIN physical.probe_markers ON (marker_experiment.marker_id=physical.probe_markers.marker_id)
            LEFT JOIN physical.overgo_associations USING (overgo_probe_id)
            LEFT JOIN physical.oa_plausibility USING (overgo_assoc_id)
        WHERE 
            map_version.map_version_id=? 
            and lg_name=? 
            and preferred='t'
            -- and current_version='t' 
            AND position >= ?
            AND position <= ?
        GROUP BY 
            marker_experiment.marker_id, 
            alias, 
            mc_name, 
            confidence_id, 
            subscript, 
            position
        ORDER BY 
            position, 
            confidence_id desc, 
            max(physical.oa_plausibility.plausible),
            max(physical.probe_markers.overgo_probe_id)
    ";


    my $sth =  $dbh -> prepare($query);
#    print STDERR "START/END: $start/$end\n";
    $sth -> execute($map->map_version_id, $chr_nr, $start, $end);

    # for each marker, look if there is a associated fully sequenced BAC, and add that 
    # as a marker of type Sequenced_BAC to the map at the right location
    #
    my $bac_status_q = 
    "
        SELECT 
            cornell_clone_name, 
            bac_id 
        FROM 
            physical.bac_marker_matches 
            JOIN sgn_people.bac_status using (bac_id) 
        WHERE 
            physical.bac_marker_matches.marker_id=? 
            AND sgn_people.bac_status.status='complete'
    ";

    my $bac_status_h = $dbh->prepare($bac_status_q);
    my $seq_bac;

    while (my ($marker_id, $marker_name, $marker_type, $confidence, $order_in_loc, $location_subscript, $offset, $loc_type, $overgo, $bac_count, $plausible, $status, $bac_name, $bac_id) = $sth->fetchrow_array()) {
	#print STDERR "Marker Read: $marker_id\t$marker_name\t$marker_type\toffset: $offset\tovergo: $overgo\tbac_count: $bac_count\tplausible: $plausible\n";
	my $seq_bac=undef;
	my $seq_bac_name="";
	my $seq_bac_id="";
	if (!$plausible || $plausible == 0)  { $bac_count = 0; }
	my $m = CXGN::Cview::Marker -> new($chromosome, $marker_id, $marker_name, $marker_type, $confidence, $order_in_loc, $location_subscript, $offset, , $loc_type, 0, $overgo, $bac_count);
	#print STDERR "dataadapter baccount = $bac_count!\n";
	if ($loc_type == 100) { $m -> set_frame_marker(); }
	
	# only add the sequenced BAC information to the F2-2000.
	#
	if ($map->map_id == CXGN::Map::Tools::current_tomato_map_id()) { 

	    $bac_status_h->execute($marker_id);
	    ($seq_bac_name, $seq_bac_id) = $bac_status_h->fetchrow_array();
           
	    # change the name to look more standard
	    #
	    if ($seq_bac_name) { 
		 if ($seq_bac_name =~ m/(\d+)([A-Z])(\d+)/i) { 
 		    $seq_bac_name = sprintf ("%3s%04d%1s%02d", "HBa",$1,$2,$3); 
 		}
		$seq_bac = CXGN::Cview::Marker::SequencedBAC->new($chromosome, $seq_bac_id, $seq_bac_name, "", "", "", "", $offset);
	    }
	}
	
	# add the marker $m to the chromosome
	#
	$chromosome->add_marker($m);
	
	# add the sequenced BAC to the chromosome 
	# -url link needs to be changed
	# -add a confidence level of 3 so that it is always displayed.
	#
	if ($seq_bac) { 
	    $seq_bac->set_confidence(3);
	    $seq_bac->set_url("/maps/physical/clone_info.pl?id=$seq_bac_id");
	    $chromosome->add_marker($seq_bac);
	}
    }
    $chromosome -> _calculate_chromosome_length();
}


=head2 fetch_chromosome_connections

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub fetch_chromosome_connections {
    my $dbh = shift;
    my $map = shift;  # CXGN::Map object
    my $chr_nr = shift;

    my $query = 
	"
        SELECT 
            c_map_version.map_version_id,
            c_map.short_name, 
            c_linkage_group.lg_name, 
            count(distinct(marker.marker_id)) as marker_count 
        from 
            marker
            join marker_experiment using(marker_id)
            join marker_location using (location_id)
            join linkage_group on (marker_location.lg_id=linkage_group.lg_id)
            join map_version on (linkage_group.map_version_id=map_version.map_version_id)

            join marker_experiment as c_marker_experiment on
                 (marker.marker_id=c_marker_experiment.marker_id)
            join marker_location as c_marker_location on 
                 (c_marker_experiment.location_id=c_marker_location.location_id)
            join linkage_group as c_linkage_group on (c_marker_location.lg_id=c_linkage_group.lg_id)
            join map_version as c_map_version on 
                 (c_linkage_group.map_version_id=c_map_version.map_version_id)
            join map as c_map on (c_map.map_id=c_map_version.map_id)
        where 
            map_version.map_version_id=? 
            and linkage_group.lg_name=? 
            and c_map_version.map_version_id !=map_version.map_version_id 
            and c_map_version.current_version='t'
        group by 
            c_map_version.map_version_id,
            c_linkage_group.lg_name,
            c_map.short_name
        order by 
            marker_count desc
    ";
    
    my $sth = $dbh -> prepare($query);
    $sth -> execute($map->map_version_id(), $chr_nr);
    my @chr_list = ();

    #print STDERR "***************** Done with query..\n";
    while (my $hashref = $sth->fetchrow_hashref()) {
	#print STDERR "READING----> $hashref->{map_version_id} $hashref->{chr_nr} $hashref->{marker_count}\n";
	push @chr_list, $hashref;

    }
    return @chr_list;
}

=head2 fetch_available_maps

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub fetch_available_maps { 
    my $dbh = shift;

    my $query = "SELECT map_version.map_version_id, short_name 
                   FROM map_version JOIN map using (map_id) 
                  WHERE current_version='t' order by short_name";    
    my $sth = $dbh -> prepare($query);
    $sth -> execute();

    my @maps = ();
    while (my $map_ref = $sth -> fetchrow_hashref()) {
	push @maps, $map_ref;
    }
    return @maps;
}

sub fetch_physical {
    my $dbh = shift;
    my $physical = shift;
    my $map = shift; # CXGN::Map object
    my $chr_nr = shift;

    my $query = 
    "
        SELECT 
            distinct(physical.bacs.bac_id), 
            marker_experiment.marker_id, 
            position 
        FROM 
            map_version
            inner join linkage_group using (map_version_id)
            inner join marker_location using (lg_id)
            inner join marker_experiment using (location_id)
            inner join physical.probe_markers using (marker_id)
            inner join physical.overgo_associations using (overgo_probe_id)
            inner join physical.bacs using (bac_id) 
            inner join physical.oa_plausibility using (overgo_assoc_id) 
        where 
            map_version.map_version_id=? 
            and lg_name=? 
            and current_version='t' 
            and physical.oa_plausibility.plausible=1
    ";

#    print STDERR "Query: $query\n";
    my $sth = $dbh->prepare($query);
    $sth -> execute($map->map_version_id, $chr_nr);
    while (my ($bac_id, $marker_id, $offset) = $sth->fetchrow_array()) {
	#print STDERR "Physical: Marker Read: $bac_id\t$marker_id\t$offset\n";
	$physical -> add_bac_association($offset, $bac_id, "overgo");
	
    }   
    my $sgn = $dbh -> qualify_schema("sgn");
    my $computational_query = "
         SELECT distinct(physical.computational_associations.clone_id), 
                physical.computational_associations.marker_id,
                marker_location.position
           FROM physical.computational_associations
           JOIN $sgn.marker_experiment using(marker_id)
           JOIN $sgn.marker_location using (location_id) 
           JOIN $sgn.linkage_group using (lg_id)
           JOIN $sgn.map_version on (map_version.map_version_id=linkage_group.map_version_id) 
          WHERE map_version.map_version_id=?
                AND linkage_group.lg_name=?
          ORDER BY marker_location.position
          ";
    
    my $cq_sth = $dbh->prepare($computational_query);
    $cq_sth->execute($map->map_version_id(), $chr_nr);
    
    while (my ($clone_id, $marker_id, $offset)=$cq_sth->fetchrow_array()) { 
	$physical -> add_bac_association($offset, $clone_id, "computational");
    }
    


}

sub fetch_IL {
    my $IL = shift;
    my $IL_name = shift;
    my $chr_nr = shift;

    my %marker_pos = ();
    my @m2 = $IL -> get_markers();
    foreach my $m (@m2) {
	$marker_pos{$m->get_name()} = $m-> get_offset();
	#print STDERR $m->get_name()." ".$m->get_offset()." \n";
    }
    
    my $vhost_conf=CXGN::VHost->new();
    my $data_folder=$vhost_conf->get_conf('basepath').$vhost_conf->get_conf('documents_subdir');
    open (F, "$data_folder/cview/IL_defs/$IL_name".".txt") || die "Can't open IL file IL_defs/$IL_name\n";

    while (<F>) {
	chomp;
	my ($chromosome, $name, $start_marker, $end_marker) = split/\t/;
	if (/^\#/) { next; }
	if ($chr_nr == $chromosome) {
	    $start_marker =~ s/^\s+(.*)/$1/;
	    $start_marker =~ s/(.*)\s+/$1/;
	    $end_marker =~ s/^\s+(.*)/$1/;
	    $end_marker =~ s/(.*)\s+/$1/;
	    if (exists($marker_pos{$start_marker}) && exists($marker_pos{$end_marker})) {
		if ($name=~ /^\d+\-\w+/) {
		    $IL -> add_section($name, $start_marker, $marker_pos{$start_marker}, $end_marker, $marker_pos{$end_marker});
		}
		elsif ($name =~/IL/i) {
		    $IL -> add_fragment($name, $start_marker, $marker_pos{$start_marker},$end_marker,$marker_pos{$end_marker});
		}
	    }
	    else { print STDERR "$start_marker or $end_marker where not found.\n";}
	}
    }
    close(F);
}
	
# POD Documentation

=head2 fetch_pachytene_idiogram(pachytene_object, chromosome_number)

for a pachytene object, fetches the definition data from a file. The tab delimited file has the following columns:

chromosome number
feature type ( can be short_arm, telomere, centromere,  )
feature start (a signed integer, negative numbers are on the short (top) arm, in arbitrary units, positive values on the long arm.
feature end

Comment lines starting with # are ignored.

=cut


sub fetch_pachytene_idiogram { 
    my $pachytene_object = shift;
    my $chromosome_number = shift;
    
    #print STDERR "Fetching $chromosome_number pachytene\n";
    my $vhost_conf=CXGN::VHost->new();
    my $data_folder=$vhost_conf->get_conf('basepath').$vhost_conf->get_conf('documents_subdir');
    open (F, "<$data_folder/cview/pachytene/pachytene_tomato_dapi.txt") || die "Can't open pachytene def file";
    
    while (<F>) { 
	chomp;
	
	my ($chr, $type, $start, $end) = split/\t/;
	
	# skip comment lines.
	if (/^\#/) { next(); }
	
	if ($chr == $chromosome_number) { 
	    #print STDERR "Adding feature $type ($start, $end)\n";
	    $pachytene_object -> add_feature($type, $start, $end);
	}
    }
}


