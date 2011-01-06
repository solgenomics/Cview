=head1 NAME

CXGN::Cview::MapOverviews::ProjectStats - a class to display the tomato genome sequence project status.

=head1 SYNOPSYS

see L<CXGN::Cview::MapOverviews>.

=head1 DESCRIPTION

This class implements the project status overview graph found on the SGN homepage and the /about/tomato_sequencing.pl page, where each chromosome is represented by a glyph that is filled to the fraction of the estimated number of BACs needed to complete the chromosome sequence.

=head1 AUTHOR(S)

Lukas Mueller (lam87@cornell.edu)

=head1 FUNCTIONS

This class implements the following functions:

=cut

package CXGN::Cview::MapOverviews::ProjectStats;
use strict;
use warnings;

use base "CXGN::Cview::MapOverviews";

use Carp;

use File::Basename;
use File::Path 'mkpath';

use List::Util;

use CXGN::Cview::Map::SGN::ProjectStats;

=head2 constructor new()

  Synopsis:
  Arguments:
  Returns:
  Side effects:
  Description:

=cut

sub new {
    my $class = shift;
    my $args = shift;

    my $map = CXGN::Cview::Map::SGN::ProjectStats->new({ dbh => $args->{dbh} });

    my $self = $class->SUPER::new($map, $args);
    $self->{dbh}= $args->{dbh};
    $self->set_horizontal_spacing(50);
    $self->set_image_width(586);
    $self->set_image_height(160);
    $self->set_chr_height(80);
    $self->{basepath}=$args->{basepath};
    $self->{tempfiles_subdir} = $args->{tempfiles_subdir};
    $self->{progress_data} = $args->{progress_data}
        or croak "must provide progress_data arg to $class constructor";
#    print STDERR "Generating new map object...\n";
    $self->set_map($map);
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

#    print STDERR "WIDTH=".$self->get_image_width()." HEIGHT ".$self->get_image_height()."\n";
    $self->{map_image}=CXGN::Cview::MapImage->new("", $self->get_image_width(), $self->get_image_height());

    my $progress_data = $self->{progress_data};

    my @c = ();
    my @chr_nums = 1..12;
    my @c_len = ( 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200 );
    my @bacs_to_complete   = ( undef, map $progress_data->{$_}{total_bacs},    @chr_nums );
    my @c_percent_finished = ( undef, map $progress_data->{$_}{pct_done},    @chr_nums );
    my @bacs_in_progress   = ( undef, map $progress_data->{$_}{in_progress}, @chr_nums );
    my @bacs_submitted     = ( undef, map $progress_data->{$_}{available},   @chr_nums );
    my @bacs_phase         = ( undef, map $progress_data->{$_}{htgs_3},      @chr_nums );

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

	#print STDERR "Chromosome $i $percent_htgs3, $percent_available, $percent_finished, $percent_in_progress\n";

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
    my $path = File::Spec->catfile($self->{basepath}, $url);
    mkpath( dirname( $path ) );

    $self->render_map();
    $self->get_file_png($path);

}

1;
