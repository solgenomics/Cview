
=head1 NAME

CXGN::Cview::MapOverviews::Generic - a class to display generic genetic map overviews.
           
=head1 SYNOPSYS

see L<CXGN::Cview::MapOverviews> for a definition of the interface.
         
=head1 DESCRIPTION

This class implements an overview of a genetic map that is stored in the database.

=head1 AUTHOR(S)

Lukas Mueller (lam87@cornell.edu)

=head1 VERSION
 
1.0

=head1 FUNCTIONS

This class implements the following functions:

=cut

use strict;

package CXGN::Cview::MapOverviews::Generic;

use CXGN::Cview::Map::Tools;
use CXGN::Marker::Tools qw | clean_marker_name |;

use base qw | CXGN::Cview::MapOverviews CXGN::DB::Object |;

=head2 function new()

 Synopsis:	my $overview = CXGN::Cview::MapOverviews::generic_map_overview->new(CXGN::Cview::Map::SGN::Genetic->new(9));
 Arguments:	The a CXGN::Cview::Map object for the map to be displayed.
 Returns:	an overview object (constructor)
 Side effects:	sets up the overview object.
 Description:	

=cut

sub new {
    my $class = shift;
    my $map = shift;
    my $args = shift;

    my $self = $class -> SUPER::new($map, $args);

#    if (!$map) { exit(); }

    $self->set_dbh($args->{dbh});
    $self->set_map($map);
    return $self;
}

    
sub render { 
    my $self = shift;
    my $map_width=$self->get_image_width();
    my $image_height = $self->get_image_height();
    my $top_margin = 40;
    $self->{map_image}= CXGN::Cview::MapImage->new("", $map_width, $image_height);

    my @c = ();
#    my $unit_eq = 0.4; # 1 cM corresponds to 0.4 pixels.

    # determine the longest chromosome for proper scaling...
    #
    my @c_len = $self->get_map()->get_chromosome_lengths();
    #print STDERR "chromosome lengths: ".(join " ", @c_len)."\n";
    my $longest_length = 0; # zero based
    my $longest_chr = undef;
    if (!$self->get_map()->get_chromosome_count()) { 
	die "This map does not seem to have any chromosomes..."; 
    }
    for (my $i=0; $i<$self->get_map()->get_chromosome_count(); $i++)  { 
	if ($c_len[$i] >= $longest_length) { 
	    $longest_chr = $i; 
	    $longest_length = $c_len[$i];
	} 
    }


    my $unit_eq = ($image_height-2*$top_margin) /$longest_length;
    #print STDERR "unit_eq = $unit_eq\n";

    my @clean_markers = ();
    foreach my $hm ($self->get_hilite_markers()) { 
	my($clean, $suffix) = clean_marker_name($hm);
	push @clean_markers, $clean;
    }

    my @map_item_names = map { (split /\s+/, $_)[2] } $self->get_map()->get_map_items();

    my $hilite_markers = join (" ", @clean_markers, @map_item_names);
    my $hilite_markers_link = $hilite_markers;
    $hilite_markers_link =~ s/ /\+/g;
#    my $max_chr_len_units = 0;
#    my $max_chr_len_pixels = 0;
    my $chr_count = $self->get_map()->get_chromosome_count();
    my @chr_names = $self->get_map()->get_chromosome_names();

    #print STDERR "chromosome names: ".(join " ", @chr_names)."\n";
    $self->set_horizontal_spacing(int(($map_width-40)/($chr_count)));
    
    #print STDERR "chromosome count is $chr_count\n";
    my %marker_found = ();
    
    for (my $i=$chr_count-1; $i>=0; $i--) {
	
	#print STDERR "Instantiating chr $chr_names[$i]... in index $i\n";

	$c[$i] = $self->get_map()->get_overview_chromosome($chr_names[$i]);

	$c[$i]->set_horizontal_offset($self->get_horizontal_spacing()*($i)+35);
	$c[$i]->set_vertical_offset($top_margin);

	$c[$i]->set_caption($chr_names[$i]);
	
	my @markers = $c[$i]->get_markers();

	my $chr_len = 0;

	foreach my $m (@markers) {
	
	    #$m -> set_color(200, 100, 100);
	    if ($m->get_offset() > $chr_len) { $chr_len = $m->get_offset(); }
	    #print STDERR "Read: ".$m->get_name." offset: ".$m->get_offset()."\n";
	    my $marker_name_suffix = $m->get_marker_name();
	    my $marker_name = $m->get_name();
            my $marker_id = $m->get_id();
	    if (($hilite_markers =~ /\b($marker_name)\b|\b($marker_name_suffix)\b/i)) {
		my $match = $1 || $2; 
		#print STDERR "MATCH:$match\n";
		$marker_found{$match}=1;
		$m->set_label_spacer(15);
		#$m->set_url("/search/markers/markerinfo.pl?marker_id=$marker_id");
		$m->show_label();
		$m->hilite();
	    }
	}
	
	#print STDERR "$i, $c_len[$i], $unit_eq\n";
	#print STDERR "(".join(", ", @c_len).")\n";
	$c[$i]->set_height($c_len[$i]*$unit_eq); 
	$c[$i]->set_length($c_len[$i]);
	$c[$i]->layout();
	if ($self->get_map()->can_zoom()) { 
	    my $lg_name = $chr_names[$i];
	    $c[$i]->rasterize(5);
	    $c[$i]->set_rasterize_link("/cview/view_chromosome.pl?map_version_id=".$self->get_map()->get_id()."&amp;chr_nr=$lg_name&amp;show_offsets=1&amp;show_zoomed=1&amp;show_ruler=1&amp;hilite=$hilite_markers_link&amp;clicked=1&amp;cM=");

	}
	else { 
	    $c[$i]->set_url("/cview/view_chromosome.pl?map_version_id=".($self->get_map()->get_id())."&amp;chr_nr=$chr_names[$i]");
	}    
	if ($c[$i]->get_scaling_factor() == 0) { 
	    print STDERR join (", ", map { $_->get_offset } $c[$i]->get_markers())."\n";
	    print STDERR "LENGTH = ".$c[$i]->get_length()."\n";
	    print STDERR "HEIGHT = ".$c[$i]->get_height()."\n";
	    die "Scaling factor is 0 for chromosome $i. How did this happen?";
	}
	$self->{map_image}->add_chromosome($c[$i]);
    }
#    if (!$self->is_fish_map()) { 
#	my $ruler = CXGN::Cview::Ruler->new(20, $top_margin, $longest_length * $unit_eq, 0, $longest_length, $self->get_map()->get_units());
#	$ruler ->set_units( $self->get_map()->get_units() );
#	$self->{map_image}->add_ruler($ruler); 

#}
    # get the ruler and add it to the image
    #
    #print STDERR "Setting up the ruler... longest chr is $longest_chr\n";
    my $ruler = $c[$longest_chr]->get_ruler();
    $ruler->set_vertical_offset($top_margin);
    $ruler->set_horizontal_offset(20);
    $ruler->set_units($self->get_map()->get_units());
    $ruler->set_start_value(0);
    $ruler->set_end_value( $c[$longest_chr]->get_length() );
    $ruler->set_height( $c[$longest_chr]->get_height() );


    $self->{map_image}->add_ruler($ruler);
    
    #print STDERR "done.\n";

    # hilite markers that were requested...
    #
    foreach my $hm (@clean_markers) {
	chomp($hm);
	if (!exists($marker_found{$hm})) { 
	    #print STDERR "Adding $hm to the list...\n";
	    $self->add_marker_not_found($hm); 
	}
    }

    # add a legend if the map is F2-2000.
    #
    if (CXGN::Cview::Map::Tools::find_map_id_with_version($self->get_dbh(), $self->get_map()->get_id()) == CXGN::Cview::Map::Tools::current_tomato_map_id()) { 
	
	#   $image->string($font,$x,$y,$string,$color)
	my $legend = CXGN::Cview::Label->new();
	$legend->set_name('Note: Positions of fully sequenced BACs are shown in yellow');
	$legend->set_vertical_offset($image_height-12);
	$legend->set_horizontal_offset(30);
	$legend->set_reference_point(30, $image_height-15);
	
	$self->{map_image}->add_image_object($legend);
    }
    $self->set_chromosomes(\@c);
}



sub render_map {
    my $self = shift;

    # set up the cache
    $self->get_cache()->set_key($self->get_map()->get_id()."-".($self->get_image_height())."-".join (".", $self->get_map()->get_map_items())."-".(join "-", ($self->get_hilite_markers())).__PACKAGE__ );
    $self->get_cache()->set_map_name("mapmap");
    
    if ($self->get_cache()->is_valid())  { 
	return;
    }
    
    #print STDERR "Regenerating the map ".$self->get_map()->get_id()."\n";
    $self->render();
  
    $self->get_cache()->set_image_data( $self->{map_image}->render_png_string());
    $self->get_cache()->set_image_map_data( $self->{map_image}->get_image_map("mapmap") );

    
}

sub is_fish_map { 
    my $self = shift;
    if ($self->get_map()->get_type() =~/fish/i) { return 1;    }
    else {
	return 0; 
    }
}



1;
