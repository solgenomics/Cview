

=head1 NAME

CXGN::Cview::Map_overviews::ProjectStats - a class to display the tomato genome sequence project status.
           
=head1 SYNOPSYS

see L<CXGN::Cview::Map_overviews>.
         
=head1 DESCRIPTION

This class implements the project status overview graph found on the SGN homepage and the /about/tomato_sequencing.pl page, where each chromosome is represented by a glyph that is filled to the fraction of the estimated number of BACs needed to complete the chromosome sequence.

=head1 AUTHOR(S)

Lukas Mueller (lam87@cornell.edu)

=head1 FUNCTIONS

This class implements the following functions:

=cut

use strict;

package CXGN::Cview::Map_overviews::ProjectStats;

use CXGN::Cview::Map_overviews;
use CXGN::Cview::Map::SGN::ProjectStats;
use CXGN::People::BACStatusLog;
use List::Util;


use base qw( CXGN::Cview::Map_overviews );

=head2 constructor new()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub new {
    my $class = shift;
    my $force = shift;

    my $self = $class->SUPER::new($force);

    $self->set_horizontal_spacing(50);
    $self->set_image_width(586);
    $self->set_image_height(160);
    $self->set_chr_height(80);

#    print STDERR "Generating new map object...\n";
    $self->set_map(CXGN::Cview::Map::SGN::ProjectStats->new($self));
    return $self;
}

=head2 function generate_image()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub generate_image {
    my $self = shift;
    $self->render_map();
}

=head2 function send_image()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub send_image {
    my $self = shift;
    print "Content-Type: image/png\n\n";
    return $self->{map_image}->render_png();
}

=head2 function render_map()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub render_map {
    my $self = shift;

    $self->get_cache()->set_key("project stats overview graph");
    $self->get_cache()->set_force(1);
    $self->get_cache()->set_expiration_time(40000);  # set expiration time of cache to half a day.
    $self->get_cache()->set_map_name("overview_map");

    if ($self->get_cache()->is_valid()) {  return; }

    my $bac_status_log=CXGN::People::BACStatusLog->new($self);

#    print STDERR "WIDTH=".$self->get_image_width()." HEIGHT ".$self->get_image_height()."\n";
    $self->{map_image}=CXGN::Cview::MapImage->new("", $self->get_image_width(), $self->get_image_height());
    my @c = ();
    my @c_len = $bac_status_log->get_chromosome_graph_lengths();
    my @bacs_to_complete = $bac_status_log->get_number_bacs_to_complete();
    my @c_percent_finished = $bac_status_log->get_chromosomes_percent_finished();

    my @bacs_in_progress = $bac_status_log->get_number_bacs_in_progress();
    my @bacs_submitted = $bac_status_log->get_number_bacs_uploaded();

    my @bacs_phase = $bac_status_log->get_number_bacs_in_phase(3);
    

    for my $i (1..12) {
	$c[$i]= CXGN::Cview::Chromosome::Glyph -> new(1, 100, $self->get_horizontal_spacing()*($i-1)+17, 25);
	my $m = CXGN::Cview::Marker->new($c[$i],0,0,0,0,0,0,$c_len[$i]);
	$m -> hide();
	$c[$i]->add_marker($m);
	$c[$i]->set_caption($i);
	$c[$i]->set_height($self->get_chr_height());
	$c[$i]->set_url("/cview/view_chromosome.pl?map_version_id=agp&show_offsets=1&show_ruler=1&chr_nr=$i");

	my $percent_in_progress = $bacs_in_progress[$i]/$bacs_to_complete[$i]*100;

	my $percent_finished = $c_percent_finished[$i];
	
	my $percent_htgs3 = $bacs_phase[$i]/$bacs_to_complete[$i]*100;
	
	my $percent_available = $bacs_submitted[$i]/$bacs_to_complete[$i]*100;

	#$percent_submitted = $percent_submitted - $percent_htgs3;

	my $percent_in_progress_base_level = List::Util::max($percent_finished, $percent_htgs3, $percent_available);

	$percent_in_progress += $percent_in_progress_base_level;

	print STDERR "Chromosome $i $percent_htgs3, $percent_available, $percent_finished, $percent_in_progress\n";


	$c[$i]->set_fill_level(0, $percent_htgs3);
	$c[$i]->set_fill_level(1, $percent_available);
	$c[$i]->set_fill_level(2, $percent_finished);
	$c[$i]->set_fill_level(3, $percent_in_progress);
	$c[$i]->set_bac_count(0);
	$self->{map_image}->add_chromosome($c[$i]);
    }
    my $white = $self->{map_image}->get_image()->colorResolve(255,255,255);
    $self->{map_image}->get_image()->transparent($white);
    
    

    $self->get_cache()->set_image_data( $self->{map_image}->render_png_string());
    $self->get_cache()->set_image_map_data ($self->{map_image}->get_image_map("overview_map") );

}

=head2 function create_mini_overview()

  Synopsis:	
  Arguments:	none
  Returns:	nothing
  Side effects:	creates the mini overview png image that goes on the 
                homepage
  Description:	

=cut

sub create_mini_overview { 
    my $self = shift;
    $self->set_image_width(400);
    $self->set_image_height(100);
    $self->set_chr_height(50);
    $self->set_horizontal_spacing(30);
    
    my $url = "/documents/tempfiles/frontpage/project_stats_overview.png";
    my $path = File::Spec->catfile($self->get_vhost()->get_conf("basepath"), $url);
    
    $self->render_map();
    $self->get_file_png($path);
    
}


=head2 DEPRECATED CLASS CXGN::Cview::Map_overviews::project_stats

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	This class is deprecated. It now inherits from 
                CXGN::Cview::Map_overviews::ProjectStats 
                Use CXGN::Cview::Map_overview::ProjectStats 
                directly.

=cut




package CXGN::Cview::Map_overviews::project_stats;

use base qw | CXGN::Cview::Map_overviews::ProjectStats |;

sub new { 
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    return $self;
}

return 1; 
