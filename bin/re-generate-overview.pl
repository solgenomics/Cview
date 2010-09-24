
=head1 NAME

re-generate-overview.pl - regenerates the small progress overview image on the homepage

=head1 DESCRIPTION

This is a quick hack to generate the overview diagram for mirror sites. Needs to be run on the actual production system.

=head1 AUTHOR

Lukas Mueller <lam87@cornell.edu>

=cut

use strict;
use warnings;
use Carp;
use CXGN::Cview::Map_overviews;
use CXGN::Cview::Map_overviews::ProjectStats;
use CXGN::Cview::Config;

my $vhost = CXGN::Cview::Config->new();

print STDERR "Generating new overview object...\n";
my $map_overview = CXGN::Cview::Map_overviews::ProjectStats->new("force"); # force re-calculation of the image/stats

print STDERR "Setting the parameters for the small overview...\n";
# also generate a smaller version of the image that can be 
# used on the homepage.
#
$map_overview->set_image_width(400);
$map_overview->set_image_height(100);
$map_overview->set_chr_height(50);
$map_overview->set_horizontal_spacing(30);

print STDERR "Creating the file...\n";
my $url = "/documents/tempfiles/frontpage/project_stats_overview.png";
my $path = File::Spec->catfile($vhost->get_conf("basepath"), $url);

print STDERR "File name is: $path\n";
$map_overview->set_temp_file($url, $path);
$map_overview->render_map();
$map_overview->get_file_png();

print STDERR "Done.";



  


