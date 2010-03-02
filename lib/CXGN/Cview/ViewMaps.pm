
package CXGN::Cview::ViewMaps;

use CXGN::Page::FormattingHelpers qw | page_title_html |;
use CXGN::Cview::MapFactory;
use CXGN::Cview::Chromosome_viewer;
use CXGN::Cview::ChrLink;
use CXGN::Cview::Utils qw | set_marker_color |;
use CXGN::Cview::MapImage;
use CXGN::Tools::WebImageCache;
use CXGN::Map;
use CXGN::VHost;

use base qw | CXGN::DB::Object |;



=head2 function new()

  Synopsis:	
  Arguments:	a database handle [ DBI object or CXGN::DB::Connection object]
                the base dir [ file path ]
                the temp_dir [ relative path ]
  Returns:	a handle to a view_maps object
  Side effects:	
  Description:	constructor

=cut

sub new {
    my $class = shift;
    my $dbh = shift;
    my $basepath = shift;
    my $temp_dir = shift;

    my $self = bless {}, $class;
    $self->set_dbh($dbh);
    # set some defaults...
    #
    $self->{unzoomedheight} = 20; # how many cM are seen at zoom level 1    

    # create an set the cache file in the constructor,
    # such that we can define the temp dirs before
    # we generate the image using generate_image()
    #
    my $cache = CXGN::Tools::WebImageCache->new();
    $self->set_cache($cache);
    $cache->set_basedir($basepath);
    $cache->set_temp_dir($temp_dir);

    return $self;
}

sub adjust_parameters {
    my $self = shift;
    
    # adjust input arguments
    #
    
    
}

=head2 accessors set_maps(), get_maps()

  Property:	
  Setter Args:	
  Getter Args:	
  Getter Ret:	
  Side Effects:	
  Description:	

=cut

sub get_maps { 
    my $self=shift;
    return @{$self->{maps}};
}

sub set_maps { 
    my $self=shift;
    @{$self->{maps}}=@_;
}

=head2 accessors set_cache(), get_cache()

  Property:	the CXGN::Tools::WebImageCache object
  Args/Ret:     the same
  Side Effects:	this is the object used to generate the 
                cache image.
  Description:	

=cut

sub get_cache { 
    my $self=shift;
    return $self->{cache};
}

sub set_cache { 
    my $self=shift;
    $self->{cache}=shift;
}




=head2 function generate_page()

  Arguments:	none
  Returns:	nothing
  Side effects:	generates the CXGN::Cview::MapImage and stores it
                to the cache if necessary, or reads just reads
                the image cache if it is still valid.

=cut

sub generate_image {
    my $self = shift;

    # define a key for the cache. lets just use the name of the
    # script and the map_version_ids of the maps being displayed
    #
    $self->get_cache()->set_key("view_maps".(join "-", map { $_->get_id() } ($self->get_maps())));
    
    $self->get_cache()->set_expiration_time(86400);


    if (! $self->get_cache()->is_valid()) { 
	my $map_width = $self->{map_width} = 720;    
	my $x_distance = $map_width/4; # the number of pixels the different elements are spaced
	my $row_count = 0;
	my $row_height = 120;    # the height of a row (vertical space for each chromosome image)
	my $y_distance = $row_height * (1/3);
	my $chr_height = $row_height * (2/3);
	my $map_height;
	
	# determine the maximum chromosome count among all maps
	# so that we can accommodate it
	#
	my $max_chr = 0;
	foreach my $m ($self->get_maps()) { 
	    my $chr_count = 0;
	    if ($m) { 
		$chr_count = $m->get_chromosome_count();
	    }
	    if ($chr_count > $max_chr) { $max_chr=$chr_count; }
	}
	
	$map_height = $row_height * $max_chr+2*$y_distance;
    	# show the ruler if requested
	#
#	if ($self->{show_ruler}) { 
#	    my $r = ruler->new($x_distance-20, $row_height * $row_count + $y_distance, $chr_height, 0, $self->{c}{$track}[$i]->get_chromosome_length());
#	    $self->{map}->add_ruler($r);
#	}
	$row_count++;
	
	$self->{map} = CXGN::Cview::MapImage -> new("", $map_width, $map_height);
	
	# get all the chromosomes and add them to the map
	#
	my $track = 0;
	foreach my $map ($self->get_maps()) { 
	    my @chr_names = $map->get_chromosome_names();
	    for (my $i=0; $i<$map->get_chromosome_count(); $i++) {	
		
		$self->{c}{$track}[$i] = ($self->get_maps())[$track]->get_chromosome($i+1);
		$self->{c}{$track}[$i] -> set_vertical_offset($row_height*$i+$y_distance);
		$self->{c}{$track}[$i] -> set_horizontal_offset($x_distance + $x_distance * ($track));
		$self->{c}{$track}[$i] -> set_height($chr_height);
		$self->{c}{$track}[$i] -> set_caption( $chr_names[$i] );
		$self->{c}{$track}[$i] -> set_width(16);
		$self->{c}{$track}[$i] -> set_url("/cview/view_chromosome.pl?map_version_id=".($self->get_maps())[$track]->get_id()."&amp;chr_nr=$i");
		
		$self->{c}{$track}[$i] -> set_labels_none();       
		$self->{map}->add_chromosome($self->{c}{$track}[$i]);
	    }
	    $track++;
	    
	}
	
	# get the connections between the chromosomes
	#
	my %find = ();
	
	for (my $track=0; $track<($self->get_maps()); $track++) { 
	    for (my $i =0; $i< ($self->get_maps())[$track]->get_chromosome_count(); $i++) { 
		foreach my $m ($self->{c}{$track}[$i]->get_markers()) { 
		    $m->hide_label();
		    # make entry into the find hash and store corrsponding chromosomes and offset 
		    # (for drawing connections)
		    # if the map is the reference map ($compare_to_map is false).
		    #
		    $find{$m->get_id()}->{$track}->{chr}=$i;
		    $find{$m->get_id()}->{$track}->{offset}=$m->get_offset();
		    
		    # set the marker colors
		    #
		    set_marker_color($m, "marker_types");
		}
		
	    }
	}
	foreach my $f (keys(%find)) { 
	    foreach my $t (keys %{$find{$f}}) { 
		my $chr = $find{$f}->{$t}->{chr};
		my $offset = $find{$f}->{$t}->{offset};
		
		if (exists($find{$f}->{$t-1}) || defined($find{$f}->{$t-1})) {
		    my $comp_chr = $find{$f}->{$t-1}->{chr};
		    my $comp_offset = $find{$f}->{$t-1}->{offset};
		    #print STDERR "Found on track $t: Chr=$chr offset=$offset, links to track ".($t-1)." Chr=$comp_chr offset $comp_offset\n";
		    if ($comp_chr) { 
			my $link1 = CXGN::Cview::ChrLink->new($self->{c}{$t}[$chr], $offset, $self->{c}{$t-1}[$comp_chr], $comp_offset);
			$self->{map}->add_chr_link($link1);
		    }
		}
		if (exists($find{$f}->{$t+1})) { 
		    my $comp_chr = $find{$f}->{$t+1}->{chr};
		    my $comp_offset = $find{$f}->{$t+1}->{offset};
		    my $link2 = CXGN::Cview::ChrLink->new($self->{c}{$t}[$chr], $offset, $self->{c}{$t+1}[$comp_chr], $comp_offset);
		    $self->{map}->add_chr_link($link2);		
		    
		}
	    }
	    
	}
	
	$self->get_cache()->set_map_name("viewmap");
	$self->get_cache()->set_image_data($self->{map}->render_png_string());
	$self->get_cache()->set_image_map_data($self->{map}->get_image_map("viewmap"));
	
# 	# show the ruler if requested
# 	#
# 	if ($self->{show_ruler}) { 
# 	    my $r = ruler->new($x_distance-20, $row_height * $row_count + $y_distance, $chr_height, 0, $self->{c}{$track}[$i]->get_chromosome_length());
# 	    $self->{map}->add_ruler($r);
# 	}
    }
    

	# my $filename = "cview".(rand())."_".$$.".png";
    
#     $self->{image_path} = $vhost_conf->get_conf('basepath').$vhost_conf->get_conf('tempfiles_subdir')."/cview/$filename";
#     $self->{image_url} = $vhost_conf->get_conf('tempfiles_subdir')."/cview/$filename";
    
#     $self->{map} -> render_png_file($self->{image_path});
    
#     $self->{imagemap} = $self->{map}->get_image_map("imagemap");

    
}

    
sub get_select_toolbar { 
    my $self = shift;
    
#    $left_map = $self->get_left_map() || 0;
#    $center_map = $self->get_center_map() || 0;
#    $right_map = $self->get_right_map || 0;
    my @names = ("left_map_version_id", "center_map_version_id", "right_map_version_id");
    my @selects = ();
    for (my $i=0; $i< 3; $i++) { 
	if ( defined(($self->get_maps())[$i])) { 
	    push @selects,  CXGN::Cview::Utils::get_maps_select($self->get_dbh(), ($self->get_maps())[$i]->get_id(), $names[$i], 1);
	}
	else { 
	    push @selects, CXGN::Cview::Utils::get_maps_select($self->get_dbh(), undef, $names[$i], 1);
	}
    }
#    my $center_select = CXGN::Cview::Utils::get_maps_select($self, !$center_map || $center_map->get_id(), "center_map_version_id", 1);
#    my $right_select = CXGN::Cview::Utils::get_maps_select($self, !$right_map || $right_map->get_id(), "right_map_version_id", 1);


    return qq { 
	<form action="#">
	    <center>
	    <table summary=""><tr><td>$selects[0]</td><td>$selects[1]</td><td>$selects[2]</td></tr></table>
	    <input type="submit" value="set" />
	    </center>
	</form>
	};
}

# =head2 function display()

#   Synopsis:	
#   Arguments:	
#   Returns:	
#   Side effects:	
#   Description:	composes the page and displays it.

# =cut

# sub display {
#     my $self = shift;
    

#     $self->{page}->header("SGN comparative mapviewer");
#     my $width = int($self->{map_width}/3);
    
#     my $select = $self->get_select_toolbar();
    
#     print "$select";

#     if (!$self->get_maps()) { 
# 	print "<br /><br /><center>Note: No maps are selected. Please select maps from the pull down menus above.</center>\n";
#     }

#     print $self->get_cache()->get_image_html();

# #    print "<img src=\"$self->{image_url}\" usemap=\"#chr_comp_map\" border=\"0\" alt=\"\" />\n";

# #    print $self->{map}->get_image_map("chr_comp_map");

#     $self->{page}->footer();

    
    
# }

=head2 function error_message_page()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub error_message_page {
    my $self = shift;

    my $title = page_title_html("Error: No center map defined");

    print <<HTML;
    
    $title
	<p>
	A center map needs to be defined for this page to work. Please supply
        a center_map_version_id as a parameter. If this was the result of a link,
	please inform SGN about the error.
	</p>
	<p>
	Contact SGN at <a href="mailto:sgn-feedback\@sgn.cornell.edu">sgn-feedback\@sgn.cornell.edu</a>

HTML

    exit();
}


sub clean_up {
    my $self = shift;
}


return 1;
