
=head1 NAME

CXGN::Cview::Utils - library for cview-related helper code

=head1 DESCRIPTION

=head1 AUTHOR(S)

Lukas Mueller (lam87@cornell.edu)

=cut

use strict;

package CXGN::Cview::Utils;

use CXGN::Cview::ChrLinkList;

require Exporter;
our (@ISA) = qw(Exporter);
our (@EXPORT_OK) = qw | get_maps_select set_marker_color get_chromosome_links |;  # symbols to export on request

=head2 get_chromosome_links

 Usage:        my @chromosome_links = CXGN::Cview::Utils::get_chromosome_links($chr1_object, $chr2_object)
 Desc:         get_chromosome_links gets all the links between two 
               chromosomes (CXGN::Cview::Chromosome and subclasses).
 Ret:          returns a list of CXGN::Cview::ChrLink objects
 Args:         two CXGN::Cview::Chromosome objects (or subclasses)
 Side Effects: none
 Example:

=cut

sub get_chromosome_links {
    my $chr1 = shift;
    my $chr2 = shift;

    my %find_by_id=();
    my %find_by_name=();
    
    my $link_list = CXGN::Cview::ChrLinkList->new();

    print STDERR "Finding links between chr ".$chr1->get_caption()." and ".$chr2->get_caption()."\n";

    foreach my $m1 ($chr1->get_markers()) { 
	my $name1 = uc($m1->get_marker_name());
	$find_by_name{$name1}=$m1->get_offset();
	$find_by_id{$m1->get_id()}=$m1->get_offset();
    }
    foreach my $m2 ($chr2->get_markers()) {
	# we want to connect if either the marker names are identical (but not undef),
	# or the ids are identical (but not undef).
	my $name2 = uc($m2->get_marker_name());
	my $id2 = $m2->get_id();
	my $offset1 = 0;
	if (exists($find_by_name{$name2}) && defined($find_by_name{$name2})) { 
	    $offset1=$find_by_name{$name2}; 
	}
	
	if (exists($find_by_id{$id2}) && defined($find_by_id{$id2})) { 
	    $offset1=$find_by_id{$id2}; 
	}
	if ($offset1) { 
	    my $clink = CXGN::Cview::ChrLink -> new($chr1, $offset1, $chr2, $m2->get_offset(), $name2) ;
	    $clink -> set_color(100,100,100);
	    $link_list->add_link($name2, $clink);    
	}
	
    }
    return $link_list;
}



=head2 function get_maps_select()

  Synopsis:     
  Parameters:   none
  Returns:      a string with html code for the maps select pull down menu
  Side effects: none
  Status:       implemented
  Example:
  Notes:
  Version:

=cut

sub get_maps_select {
    my $dbh = shift;
    my $selected_map_version = shift;
    my $field_name = shift;
    my $add_empty_selection =1;
    if (!$field_name) { $field_name = "map_version_id"; }

    #    my $query = "select map.map_id, short_name from map join "
    #	. "map_version using (map_id) where current_version = 't' order by short_name";
    #     my $sth = $self -> prepare($query);
    #     $sth -> execute();

    my $select = qq { <select name="$field_name" > };
    my $selected="";
    my $map_factory = CXGN::Cview::MapFactory->new($dbh);
    my @maps = $map_factory->get_all_maps();

    if ($add_empty_selection) { 
	$select .= qq { <option value=""></option> };
    }

    foreach my $m (@maps) { 
	my ($map_version_id, $short_name) = ($m->get_id(), $m->get_short_name());
	if ($map_version_id =~ /^$selected_map_version$/) { $selected="selected=\"selected\""; }
	else {$selected=""; }
	$select .= "<option value=\"$map_version_id\" $selected>$short_name</option>";
    }
    $select .= "</select>";
    return $select;
}

=head2 function set_marker_color()

  Synopsis: 
  Parameters:   marker object [CXGN::Cview::Marker], color model [string]
  Returns:      nothing
  Side effects: sets the marker color according to the supplied marker color model
                the color model is a string from the list: 
                "marker_types", "confidence" 
  Status:       implemented
  Example:
  Note:         this function was moved to Utils from Chromosome_viewer, such that
                it is available for other scripts, such as view_maps.pl

=cut

sub set_marker_color {
    my $m = shift;
    my $color_model = shift;
    if ($color_model eq "marker_types") {
	if ($m->get_marker_type() =~ /RFLP/i) {
	    $m->set_color(255, 0, 0);
	    $m->set_label_line_color(255, 0,0);
	    $m->set_text_color(255,0,0);
	}
	elsif ($m->get_marker_type() =~ /SSR/i) {
	    $m->set_color(0, 255, 0);
	    $m->set_label_line_color(0, 255,0);
	    $m->set_text_color(0,255,0);
	}
	elsif ($m->get_marker_type() =~ /CAPS/i) {
	    $m->set_color(0, 0, 255);
	    $m->set_label_line_color(0, 0,255);
	    $m->set_text_color(0,0,255);
	}
	elsif ($m->get_marker_type() =~ /COS/i) {
	    $m->set_color(255,0 , 255);
	    $m->set_label_line_color(255,0, 255);
	    $m->set_text_color(255,0,255);
	}
	else {
	    $m->set_color(0, 0, 0);
	    $m->set_label_line_color(0, 0,0);
	    $m->set_text_color(0,0,0);
	}

    }
    else {
	my $c = $m -> get_confidence();
	if ($c==0) { 
	    $m->set_color(0,0,0); 
	    $m->set_label_line_color(0,0,0);
	    $m->set_text_color(0,0,0);
	}
	if ($c==1) { 
	    $m->set_color(0,0,255); 
	    $m->set_label_line_color(0,0,255);
	    $m->set_text_color(0,0,255);
	    
	}
	if ($c==2) { 
	    $m->set_color(0,255, 0); 
	    $m->set_label_line_color(0,255,0);
	    $m->set_text_color(0,255,0);
	}
	if ($c==3) { 
	    $m->set_color(255, 0, 0); 
	    $m->set_label_line_color(255, 0,0);
	    $m->set_text_color(255, 0,0);
	}
	if ($c==4) { 
	    $m->set_color(128, 128, 128);
	    $m->set_label_line_color(128, 128, 128);
	    $m->set_text_color(128, 128, 128);
	}
    }
}



return 1;
