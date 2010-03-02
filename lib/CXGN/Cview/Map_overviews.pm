
=head1 NAME

Map_overviews.pm - classes to display different kinds of map overviews.

=head1 SYNOPSYS

 my $overview = CXGN::Map_overview::Generic->new( 
           CXGN::Cview::Map::SGN::Genetic->new($dbh, 9)
                                                );
 $overview->hilite_markers(@marker_names);
 $overview->render_map();
 $overview->get_image_html();
 

=head1 DESCRIPTION

Map_overviews.pm contains a number of classes designed to display map overview images (chromosomes aligned horizontally) for a given map. The base class is an abstract class called CXGN::Cview::Map_overviews, which inherits from CXGN::DB::Connection for database access and it depends on CXGN::Cview for drawing the chromosomes. The subclasses derived from this class are 

=over 5

=item *

CXGN::Cview::Map_overviews::Generic, which displays a generic overview for maps of type "genetic", "fish" or "physical" - or any other map that has an appropriate CXGN::Cview::Map object implemented.

=item *

CXGN::Cview::Map_overviews::ProjectStats displays a map showing the progress of the sequencing project. In addition to CXGN::DB::Connection, it also uses CXGN::People, to get the BAC statistics associated to the different chromosomes. 

=back

=head2 Caching implementation

The caching is implemented using CXGN::Tools::WebImageCache, which implements caching on the file system level. Each subclass of Map_overviews can implement its own get_cache_key() function, which should should be set to a distinct key for each map. Map_overviews::Generic concatenates the map_version_id, the hilited markers, and the package name. For more information, see L<CXGN::Tools::WebImageCache>.

=head2 Resetting the cache

The cache can be reset by deleting the contents of the caching directory. The default value is set using CXGN::VHost properties basepath, tempfiles_subdir and the string "cview", which resolves to "/data/local/website/sgn/documents/tempfiles/cview/" on the current production systems (as of Dec 2006). The class also takes a $reset_cache parameter in the constructor, which will be passed to the CXGN::Tools::WebImageCache constructor. A true value will cause the cache to be considered as expired.

=head1 AUTHORS

 Lukas Mueller (lam87@cornell.edu)
 John Binns (zombieite@gmail.com)

=cut

use strict;

use CXGN::Page;
use CXGN::People;
use File::Spec;
use CXGN::Tools::WebImageCache;
use CXGN::Cview;
use CXGN::Cview::Chromosome;
use CXGN::Cview::Chromosome::PachyteneIdiogram;
use CXGN::Cview::Chromosome::Glyph;
use CXGN::Cview::Cview_data_adapter;
use CXGN::Cview::MapImage;
use CXGN::Cview::Marker;
use CXGN::Cview::Marker::RangeMarker;
use CXGN::Cview::Ruler;
use CXGN::Cview::Chromosome::Physical;
use CXGN::Cview::Label;
use CXGN::Cview::Map::Tools;
use CXGN::VHost;

use CXGN::Cview::Map_overviews::Generic;
use CXGN::Cview::Map_overviews::Physical;
use CXGN::Cview::Map_overviews::ProjectStats;
use CXGN::Cview::Map_overviews::Individual;

package CXGN::Cview::Map_overviews;

=head1 CXGN::Cview::Map_overviews

This class implements an abstract interface for drawing map overview images.

=cut

use CXGN::DB::Connection;

use base qw( CXGN::DB::Connection );

# an abstract class from which other overviews inherit.

=head2 function new()

 Synopsis:	Constructor for Map_overview object
  Example:      my $map_overview = CXGN::Cview::Map_overviews::Generic
                                   ->new( $map_object );
 Arguments:	usually a subclass of CXGN::Cview::Map
                subclasses. Accepts a force parameter that 
                if set to true, we force the recalculation
                of the map and stats.
 Returns:	a CXGN::Cview::Map_overview object
 Side effects:	none
 Description:	

=cut

sub new {
    my $class = shift;
    my $force = shift;

    my $self = $class -> SUPER::new("sgn");

    $self->_set_force($force);

    # define some default values
    #
    @{$self->{c_len}} = (0, 163, 140, 170, 130, 120, 100, 110, 90, 115, 90, 100, 120);

    $self->set_horizontal_spacing(50);
    $self->set_vhost(CXGN::VHost->new());
    
    # set up the cache
    #
    my $cache =  CXGN::Tools::WebImageCache->new();
    $cache->set_force($force);
    $cache->set_basedir($self->get_vhost()->get_conf("basepath"));
    $cache->set_temp_dir("/documents/tempfiles/cview");
    $self->set_cache($cache);
    $self->set_image_width(700);
    $self->set_image_height(200);

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

=head2 accessors set_vhost(), get_vhost()

  Property:	a CXGN::VHost object
  Description:	This is set to a new CXGN::VHost object
                in the constructor. The getter is used
                to obtain configuration information, such
                as tempfile pathnames and the like.

=cut

sub get_vhost { 
    my $self=shift;
    return $self->{vhost};
}

sub set_vhost { 
    my $self=shift;
    $self->{vhost}=shift;
}

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
	open (my $FILE, ">$map_file") || 
	    die "Can't open map file $map_file";
	print $FILE $self->{image_map};
	close($FILE);
    }
    else { 
	open (my $FILE, "<$map_file") || 
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

 Synopsis:	
 Arguments:	
 Returns:	
 Side effects:	
 Description:	

=cut


# sub get_marker_count { 
#     my $self = shift;
#     my $chromosome = shift;
#     my $query = "";
#     if ($self->get_map()->get_type() eq "fish") { 
# 	$query = "SELECT count(distinct(clone_id)) from sgn.fish_result WHERE chromo_num=?";
# 	my $sth = $self->prepare($query);
# 	$sth->execute($chromosome);
# 	my ($count) = $sth->fetchrow_array();
# 	return $count;
#     }
#     else { 
# 	$query = "SELECT count(distinct(location_id)) FROM sgn.map_version JOIN marker_location using (map_version_id) 
#                             JOIN linkage_group using (lg_id)
#                       WHERE linkage_group.lg_name=? and map_version.map_version_id=?";
# 	my $sth = $self->prepare($query);
# 	$sth->execute($chromosome, $self->get_map()->get_id());
# 	my ($count) = $sth->fetchrow_array();
# 	return $count;
#     }
   
    
    
# }

# sub set_marker_count { 
#     my $self = shift;
#     my $chromosome =  shift;
#     $self->{marker_count}->[$chromosome] = shift;
# }

=head2 accessors set_map_image(), get_map_image()

  Property:	
  Setter Args:	
  Getter Args:	
  Getter Ret:	
  Side Effects:	
  Description:	

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


# =head2 accessors get_cache_key()

#   Property:	
#   Setter Args:	
#   Getter Args:	
#   Getter Ret:	
#   Side Effects:	
#   Description:	This function needs to be overridden in
#                 a subclass to give a reproducible key for 
#                 a given map. Default value here is:
#                 the map_version_id + 

# =cut

# sub get_cache_key { 
#     my $self=shift;
#     my $type = ref($self);
#     return ($self->get_map()->get_id()."-".(join ":", $self->get_hilite_markers())."-".$type."-".$self->get_image_width()."-".$self->get_image_height());
# }

# =head2 function set_temp_file

#   Synopsis:	
#   Arguments:	
#   Returns:	
#   Side effects:	
#   Description:	

# =cut

# sub set_temp_file {
#     my $self = shift;
#     $self->{temp_url} = shift;
#     $self->{temp_file} = shift;
# }


# =head2 function get_temp_file()

#   Example:      my $file_path = $overview->get_temp_file();
#   Getter Args:	none
#   Getter Ret:	a list of 2 strings:
#                 (1) the url to the image
#                 (2) the fully qualified path to the image file.
#   Side Effects:	these are the locations where the image can
#                 be accessed.
#   Description:	

# =cut

# sub get_temp_file { 
#     my $self=shift;

#     if (exists($self->{temp_url})) { return ($self->{temp_url}, $self->{temp_file}); }

#     my $fileurl  = File::Spec->catfile( $self->get_temp_dir(), $self->get_filename());
#     my $filepath = File::Spec->catfile( $self->get_base_dir(), $self->get_temp_dir(), $self->get_filename()); 
#     return ($fileurl, $filepath);
# }

# =head2 function get_temp_dir()

#   Synopsis:	my $temp_dir = $overview->get_temp_dir();
#   Arguments:	none
#   Returns:	the tempdir, as defined in the CXGN::VHost 
#                 tempfiles_subdir property.
#   Side effects:	this is the temp_dir used to store the image 
#                 (in conjunction with get_base_dir()).
#   Description:	there is no setter for this property.

# =cut

# sub get_temp_dir {
#     my $self = shift;
#     my $temp_dir  = File::Spec->catfile($self->get_vhost()->get_conf('tempfiles_subdir'), "cview");
#     return $temp_dir;
# }

# =head2 function get_base_dir()

#   Synopsis:	my $basedir = $overview->get_base_dir();
#   Arguments:	none
#   Returns:	the $basedir (from the CXGN::VHost basepath property)
#   Side effects:	none
#   Note:         There is no setter for this property.

# =cut

# sub get_base_dir {
#     my $self = shift;
#     my $basedir = $self->get_vhost()->get_conf('basepath');
#     return $basedir;
# }


# =head2 function get_filename()

#   Synopsis:	$overview->get_filename()
#   Arguments:	none
#   Returns:	the filename of the image file for this overview
#   Side effects:	this file is used to construct the overview page
#   Implementation: the filename is calculated in this function from 
#                 the value returned by get_cache_key(), which is 
#                 fed into the MD5sum function.

# =cut

# sub get_filename { 
#     my $self=shift;
#     if (exists($self->{filename})) { return $self->{filename}; }
#     return Digest::MD5->new()->add($self->get_cache_key())->hexdigest().".png";
# }

# sub set_filename { 
#     my $self=shift;
#     $self->{filename}=shift;
# }


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

=head2 get_chromosomes

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_chromosomes {
  my $self=shift;
  return $self->{chromosomes};

}

=head2 set_chromosomes

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_chromosomes {
  my $self=shift;
  $self->{chromosomes}=shift;
}




return 1;
