
=head1 NAME

CXGN::Cview::MapOverviews - classes to display different kinds of map overviews.

=head1 SYNOPSYS

 my $overview = CXGN::MapOverview::Generic->new( 
           CXGN::Cview::Map::SGN::Genetic->new($dbh, 9), $args_ref
                                                );
 $overview->hilite_markers(@marker_names);
 $overview->render_map();
 $overview->get_image_html();
 

=head1 DESCRIPTION

CXGN::Cview::MapOverviews contains a number of classes designed to display map overview images (chromosomes aligned horizontally) for a given map. The base class is an abstract class called CXGN::Cview::MapOverviews and it depends on CXGN::Cview classes for drawing the chromosomes. The subclasses derived from this class are 

=over 5

=item *

CXGN::Cview::MapOverviews::Generic, which displays a generic overview for maps of type "genetic", "fish" or "physical" - or any other map that has an appropriate CXGN::Cview::Map object implemented.

=item *

CXGN::Cview::MapOverviews::ProjectStats displays a map showing the progress of the sequencing project. It also uses CXGN::People, to get the BAC statistics associated to the different chromosomes. 

=back

=head2 Caching implementation

The caching is implemented using CXGN::Tools::WebImageCache, which implements caching on the file system level. Each subclass of MapOverviews can implement its own get_cache_key() function, which should should be set to a distinct key for each map. MapOverviews::Generic concatenates the map_version_id, the hilited markers, and the package name. For more information, see L<CXGN::Tools::WebImageCache>.

=head2 Resetting the cache

The cache can be reset by deleting the contents of the caching directory. The default value is set using CXGN::VHost properties basepath, tempfiles_subdir and the string "cview", which resolves to "/data/local/website/sgn/documents/tempfiles/cview/" on the current production systems (as of Dec 2006). The class also takes a $reset_cache parameter in the constructor, which will be passed to the CXGN::Tools::WebImageCache constructor. A true value will cause the cache to be considered as expired.

=head1 AUTHORS

 Lukas Mueller (lam87@cornell.edu)
 John Binns (zombieite@gmail.com)

=cut

use strict;
use warnings;

package CXGN::Cview::MapOverviews;

use File::Spec;
use CXGN::People;
use CXGN::Tools::WebImageCache;
use CXGN::Cview;
use CXGN::Cview::Chromosome;
use CXGN::Cview::Chromosome::PachyteneIdiogram;
use CXGN::Cview::Chromosome::Glyph;
use CXGN::Cview::MapImage;
use CXGN::Cview::Marker;
use CXGN::Cview::Marker::RangeMarker;
use CXGN::Cview::Ruler;
use CXGN::Cview::Chromosome::Physical;
use CXGN::Cview::Label;
use CXGN::Cview::Map::Tools;
use CXGN::Cview::MapOverviews::Generic;
use CXGN::Cview::MapOverviews::Physical;
use CXGN::Cview::MapOverviews::ProjectStats;
use CXGN::Cview::MapOverviews::Individual;

=head1 CXGN::Cview::MapOverviews

This class implements an abstract interface for drawing map overview images.

=cut


# an abstract class from which other overviews inherit.

=head2 function new()

 Synopsis:	Constructor for MapOverview object
  Example:      my $map_overview = CXGN::Cview::MapOverviews::Generic
                                   ->new( $map_object, $args_ref );
 Arguments:	usually a subclass of CXGN::Cview::Map
                subclasses. 
                the $args_ref can have the following keys (* means required)
                force              forces recalculation of the image    
                basepath*          the basepath to use for tempfile storage
                tempfiles_subdir*  the subdir, after the basepath, where
                                   the tempfiles are stored
                dbh*               a database handle

 Returns:	a CXGN::Cview::MapOverview object
 Side effects:	none
 Description:	

=cut

sub new {
    my $class = shift;
    my $map = shift;
    my $args = shift;

    my $self = bless {}, $class;

    $self->_set_force($args->{force});

    # define some default values
    #
    ####@{$self->{c_len}} = (0, 163, 140, 170, 130, 120, 100, 110, 90, 115, 90, 100,  120);

    $self->set_horizontal_spacing(50);
#    $self->set_vhost(CXGN::VHost->new());
    
    # set up the cache
    #
    my $cache =  CXGN::Tools::WebImageCache->new();
    $cache->set_force($args->{force});
    $cache->set_basedir($args->{basepath});
    $cache->set_temp_dir($args->{tempfiles_subdir});
    $self->set_cache($cache);
    $self->set_image_width(700);
    $self->set_image_height(200);
    $self->set_map($map);
    return $self;
}

=head2 accessors set_map(), get_map()

 Synopsis:	$overview->get_map();
 Arguments:	
 Returns:       gets the map object.
 Side effects:	the corresponding map will be represented
                on the overview.
 Description:	

=cut

sub get_map { 
    my $self=shift;
    return $self->{map};
}

sub set_map { 
    my $self=shift;
    $self->{map}=shift;
}

# =head2 accessors set_vhost(), get_vhost()

#   Property:	a CXGN::VHost object
#   Description:	This is set to a new CXGN::VHost object
#                 in the constructor. The getter is used
#                 to obtain configuration information, such
#                 as tempfile pathnames and the like.

# =cut

# sub get_vhost { 
#     my $self=shift;
#     return $self->{vhost};
# }

# sub set_vhost { 
#     my $self=shift;
#     $self->{vhost}=shift;
# }

=head2 function set_horizontal_spacing()

 Synopsis:      $overview->set_horizontal_spacing(60)
 Arguments:     the horizontal spacing in pixels
 Returns:	nothing
 Side effects:	Defines the spacing between the chromosome glyphs 
                in the overview image. If this is not set, the 
                default is 50.
 Description:	

=cut

sub set_horizontal_spacing {
    my $self=shift;
    $self->{horizontal_spacing} = shift;
}

=head2 function get_horizontal_spacing()

 Synopsis:	$my_spacing = $overview->get_horizontal_spacing()
 Arguments:	None (accessor)
 Returns:	the number of pixels between the chromosome glyphs.
 Side effects:	None
 Description:	

=cut

sub get_horizontal_spacing {
    my $self=shift;
    return $self->{horizontal_spacing};
}

=head2 function render_map()

 Synopsis:	$overview->render_map()
 Arguments:	
 Returns:	nothing
 Side effects:	renders the map and sets two properties (see below). 
 Description:	this function needs to be implemented in subclasses
                to draw the desired map. The calculated map should be
                stored directly using the cache functions 
                (see CXGN::Tools::WebImageCache) (essentially, using the
                functions set_image_data() and set_image_map_data() ).
               
                The subclassed function should call SUPER::render_map(),
                such that the key can be properly set.
             

=cut

sub render_map {
    my $self = shift;
    
  
    
}

=head2 function get_file_png()

 Synopsis:	$overview->get_file_png($path)
 Arguments:	a fully qualified path of the file 
 Returns:	
                
 Side effects:	
 Description:	saves the image into the specified file
 Status:        

=cut

sub get_file_png {
    my $self=shift;
    my $path = shift;
    
    $self->{map_image}->render_png_file($path);
}    

=head2 function get_image_map()

 Synopsis:	my $html_image_map = $overview->get_image_map();
 Arguments:	none
 Returns:	an html image map, defining the links on the image
 Side effects:	none
 Description:	none
 Status:        DEPRECATED! USE get_image_html INSTEAD!

=cut

sub get_image_map {
    my $self=shift;
    my $map_name = shift;

    my $map_file = ($self->get_temp_file())[1].".map";

    if (!$self->has_cache()) { 
	open (my $FILE, ">", $map_file) ||
	    die "Can't open map file $map_file: $!";
	print $FILE $self->{image_map};
	close($FILE);
    }
    else { 
	open (my $FILE, "<", $map_file) ||
	    die "Can't open map file! $map_file";
	my @FILE = (<$FILE>);
	close($FILE);
	$self->{image_map} = join "\n", @FILE;
    }
    return $self->{image_map};
    
}

=head2 function set_image_map()

  Synopsis:	$overview->set_image_map();
  Arguments:	a string representing the html image map for 
                the overview image (essentially, the appropriate
                <map> tag that goes with the overview image).
  Returns:	
  Side effects:	this will be used directly to print the <map> tag
  Description:	

=cut

sub set_image_map {
    my $self = shift;
    $self->{image_map}=shift;
}

=head2 function get_image_html()

  Synopsis:	
  Arguments:	none
  Returns:	a string representing the image for an html page,
                including image tag and image map
  Side effects:	
  Description:	

=cut

sub get_image_html {
    my $self = shift;
    return $self->get_cache()->get_image_html();

#    return '<img src="'.($self->get_file_png())[0].'" usemap="#overview" border="0" />'."<br />\n". $self->get_image_map("overview");
}

=head2 accessors get_marker_count(), set_marker_count()

 Synopsis:     my $count = $map->get_marker_count($chr)
 Arguments:    a chromosome name
 Returns:      the number of markers on that chromosome	
 Side effects: 
 Description:  needs to be implemented in a subclass.

=cut


sub get_marker_count { 
}

sub set_marker_count { 
}

=head2 accessors set_map_image(), get_map_image()

  Property:     the image object (GD::Image)
  Side Effects:	
  Description:	this image object is used for drawing the image

=cut

sub get_map_image { 
    my $self=shift;
    return $self->{map_image};
}

sub set_map_image { 
    my $self=shift;
    $self->{map_image}=shift;
}

=head2 function hilite_marker()

 Synopsis:	$overview->hilite_marker("TG280");
 Arguments:	a marker name (string)
 Returns:	nothing
 Side effects:	causes the marker to be highlighted on the overview
 Description:	

=cut

sub hilite_marker { 
    my $self = shift;
    my $marker_name = shift;
    if (!exists($self->{hilite_markers})) { @{$self->{hilite_markers}}=(); }
    push @{$self->{hilite_markers}}, $marker_name;
}

sub get_hilite_markers { 
    my $self = shift;
    if (!exists($self->{hilite_markers})) { @{$self->{hilite_markers}}=(); }
    return @{$self->{hilite_markers}};
}

sub add_marker_not_found { 
    my $self = shift;
    my $marker = shift;
    #
    # prevent these not initialized errors...
    #
    if (!exists($self->{markers_not_found})) { %{$self->{markers_not_found}}=(); } 
    ${$self->{markers_not_found}}{$marker}=1;
}

# return the markers that were not found for hiliting on the overview diagram
# Note: render_map has to be called before calling this function.
#
sub get_markers_not_found { 
    my $self = shift;
    if (!$self->{markers_not_found}) { %{$self->{markers_not_found}}=(); }
    return ( map ($_, (keys(%{$self->{markers_not_found}}))));
}

=head2 add_map_items

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub add_map_items {
    my $self = shift;
    my @map_items = @_;
    
    $self->get_map()->set_map_items(@map_items);
    
}

=head2 accessors set_chr_height(), get_chr_height()

  Property:	the height of the chromosome in pixels.
                This is currently only used for the Project
                Stats overview, in which chromosome don\'t 
                have a 'natural' height.
  Side Effects:	
  Description:	

=cut

sub get_chr_height { 
    my $self=shift;
    return $self->{chr_height};
}

sub set_chr_height { 
    my $self=shift;
    $self->{chr_height}=shift;
}

=head2 accessors set_image_height(), get_image_height()

  Property:	The height of the image in pixels.
  Setter Args:  
  Side Effects:	
  Description:	

=cut

sub get_image_height { 
    my $self=shift;
    return $self->{image_height};
}

sub set_image_height { 
    my $self=shift;
    $self->{image_height}=shift;
}

=head2 accessors set_image_width(), get_image_width()

  Property:	the width of the entire image in pixels.
  Setter Args:	
  Getter Args:	
  Getter Ret:	
  Side Effects:	
  Description:	

=cut

sub get_image_width { 
    my $self=shift;
    return $self->{image_width};
}

sub set_image_width { 
    my $self=shift;
    $self->{image_width}=shift;
}



# accessors _set_force, _get_force
#
# if set to true, forces the re-calculation of the image and stats.
#
sub _get_force { 
    my $self=shift;
    return $self->{force};
}

sub _set_force { 
    my $self=shift;
    $self->{force}=shift;
}




# =head2 function has_cache()

#   Synopsis:	$overview->has_cache()
#   Arguments:	none
#   Returns:	true if there is a cached web image for the 
#                 given cache key (as returned by get_cache_key()).
#   Side effects:	none
#   Description:	

# =cut

# sub has_cache {
#     my $self = shift;
#     if ($self->_get_force()) { return 0; }
#     if (-e ($self->get_temp_file())[1] && -e (($self->get_temp_file())[1].".map")) { 
# 	return 1;
#     }
#     else { 
# 	return 0;
#     }
# }

=head2 accessors set_cache(), get_cache()

  Property:	a CXGN::Tools::WebImageCache object
  Args/Ret:     the same
  Side Effects:	
  Description:	see CXGN::Tools::WebImageCache

=cut

sub get_cache { 
    my $self=shift;
    return $self->{cache};
}

sub set_cache { 
    my $self=shift;
    $self->{cache}=shift;
}

=head2 get_chromosomes(), set_chromosomes()

 Usage:        my @c = $map->get_chromosomes();
 Desc:         returns (sets) a list of Cview chromosome objects for 
               this map, in the same order as get_chromosome_names().
 Side Effects:
 Example:

=cut

sub get_chromosomes {
  my $self=shift;
  return $self->{chromosomes};

}

sub set_chromosomes {
  my $self=shift;
  $self->{chromosomes}=shift;
}


=head2 accessors set_chromosome_count, get_chromosome_count

  Property:	
  Setter Args:	
  Getter Args:	
  Getter Ret:	
  Side Effects:	
  Description:	

=cut

sub get_chromosome_count { 
    my $self=shift;
    return $self->{chromosome_count};
}

sub set_chromosome_count { 
    my $self=shift;
    $self->{chromosome_count}=shift;
}


=head2 function get_cache_key()

 Usage:        $map->get_cache_key()
 Desc:         needs to be implemented in subclass and return 
               a cache key for the current map
 Side Effects:
 Example:

=cut

sub get_cache_key {
    die "get_cache_key is abstract. Please implement in subclass.";
}

1;
