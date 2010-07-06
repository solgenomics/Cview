
=head1 NAME

CXGN::Cview::Map_overviews::Generic - a class to display generic genetic map overviews.
           
=head1 SYNOPSYS

see L<CXGN::Cview::Map_overviews>.
         
=head1 DESCRIPTION


=head1 AUTHOR(S)

Lukas Mueller (lam87@cornell.edu)

Isaak Tecle (iyt2@cornell.edu)

=head1 VERSION
 

=head1 LICENSE


=head1 FUNCTIONS

This class implements the following functions:

=cut

use strict;

package CXGN::Cview::MapOverviews::QTLOverview;

use CXGN::Cview::Map::Tools;
use CXGN::Marker::Tools qw | clean_marker_name |;
use CXGN::Cview::Chromosome::LineGraph;
use base "CXGN::Cview::MapOverviews::Generic";


=head2 function new()

 Synopsis:	my $overview = CXGN::Cview::MapOverviews::QTLOverview->
                 new(CXGN::Cview::Map::SGN::Genetic->new(9),$qtl_file);
 Arguments:	(1) The a CXGN::Cview::Map object for the map to be 
                    displayed.
                (2) the QTL file from R/QTL
                    this file has the format:
                    marker_name \t chromosome \t position \t lod score
 Returns:	an overview object (constructor)
 Side effects:	sets up the overview object.
 Description:	

=cut

sub new {
    my $class = shift;
    my $map = shift;
    my $qtl_file =shift;
    my $args = shift;

    my $self = $class -> SUPER::new($map, $args);

    #print STDERR "We are in the constructure now\n";
    if (!$map) { exit(); }
    $self->set_qtl_file($qtl_file);
    $self->set_map($map);
    return $self;
}

=head2 render()

 Usage:        $map->render()
 Desc:         renders the map on the GD::Image
 Side Effects:
 Example:

=cut

sub render { 
    my $self = shift;
    my $map_width=$self->get_image_width();
    my $image_height = $self->get_image_height();
    my $top_margin = 40;
    $self->{map_image}= CXGN::Cview::MapImage->new("", $map_width, $image_height);

    $self->SUPER::render($map_width, $image_height);

    my $c = $self->get_chromosomes();

    my @graphs = ();

    my $maximum = -99999;

    #print STDERR "Current QTL file is ".$self->get_qtl_file()."\n";
    open (my $F, "<", $self->get_qtl_file()) || die "Can't open qtl file ".$self->get_qtl_file()." $!";
    my $first_line = <$F>;
    while (<$F>) { 
	chomp;
	my ($marker, $chr, $pos, $lod) = split /\s+/;

	#print STDERR "$marker, $chr, $pos, $lod\n";

	if ($lod>$maximum) { $maximum = $lod; }
	if (!exists($graphs[$chr])) { 
	    $graphs[$chr]=CXGN::Cview::Chromosome::LineGraph->new();
	    $graphs[$chr]->set_width($self->get_horizontal_spacing() - $c->[$chr-1]->get_width() -8);
	    $graphs[$chr]->set_horizontal_offset($c->[$chr-1]->get_horizontal_offset() + $c->[$chr-1]->get_width()/2 + $graphs[$chr]->get_width()/2 + 4) ;
						
	    $graphs[$chr]->set_vertical_offset($c->[$chr-1]->get_vertical_offset() );
	    
	    $graphs[$chr]->set_length($c->[$chr-1]->get_length());
	    $graphs[$chr]->set_height($c->[$chr-1]->get_height());

	}
	$graphs[$chr]->add_association("LOD", $pos, $lod);
    }
    
    #print STDERR "The map has ".scalar(@$c)." chromosomes!\n";
    for (my $i=0; $i<@$c; $i++) { 
	#print STDERR "Adding graph to chromosome in slot $i...\n";
	$c->[$i]->set_name($i);
	$c->[$i]->set_bargraph($graphs[$i+1]);
	$c->[$i]->show_bargraph();

	$graphs[$i+1]->set_maximum($maximum);
	$graphs[$i+1]->set_caption("");
    }
	
}

sub render_map {
    my $self = shift;
    
    die "We are in render_map in QTL_overview...\n";
    # set up the cache
    $self->get_cache()->set_key($self->get_map()->get_id()."-".($self->get_image_height())."-".(join "-", ($self->get_hilite_markers())).__PACKAGE__ );
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

=head2 function get_map

 Synopsis:	
 Arguments:	
 Returns:       gets the map object to refer to.
 Side effects:	
 Description:	

=cut

sub get_map { 
    my $self=shift;
    return $self->{map};
}

=head2 function set_map

 Synopsis:	
 Arguments:	the map object to refer to 
 Returns:	nothing
 Side effects:	the data about map object will be displayed
 Description:	

=cut

sub set_map { 
    my $self=shift;
    $self->{map}=shift;
}

=head2 accessors get_qtl_file, set_qtl_file

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_qtl_file {
  my $self = shift;
  return $self->{qtl_file}; 
}

sub set_qtl_file {
  my $self = shift;
  $self->{qtl_file} = shift;
}

1;
