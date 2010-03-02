 


=head1 NAME

CXGN::Cview::MapFactory - a factory object for CXGN::Cview::Map objects
           
=head1 SYNOPSYS

 my $map_factory  = CXGN::Cview::MapFactory->new($dbh);
 $map = $map_factory->create({map_version_id=>"u1"});
         
=head1 DESCRIPTION

The MapFactory object is part of a compatibility layer that defines the data sources of the comparative mapviewer. If there are different types of maps that can be distinguished by their ids, the MapFactory should be implemented to return the right map object for the given id. Of course, the corresponding map object also needs to be implemented, using the interface defined in CXGN::Cview::Map .

The MapFactory constructor takes a database handle (preferably constructed using CXGN::DB::Connection object). The map objects can then be constructed using the create function, which takes a hashref as a parameter, containing either map_id or map_version_id as a key (but not both). map_ids will be converted to map_version_ids immediately. Map_version_ids are then analyzed and depending on its format, CXGN::Cview::Map object of the proper type is returned. 

The function get_all_maps returns all maps as list of appropriate CXGN::Cview::Map::* objects.

For the current SGN implementation, the following identifier formats are defined and yield following corresponding map objects

 \d+       refers to a map id in the database and yields either a
           CXGN::Cview::Map::SGN::Genetic (type genetic)
           CXGN::Cview::Map::SGN::FISH (type fish)
           CXGN::Cview::Map::SGN::Sequence (type sequence)
 u\d+      refers to a user defined map and returns:
           CXGN::Cview::Map::SGN::User object
 filepath  refers to a map defined in a file and returns a
           CXGN::Cview::Map::SGN::File object
 il\d+      refers to a population id in the phenome.population table
           (which must be of type IL) and returns a
           CXGN::Cview::Map::SGN::IL object
 p\d+      CXGN::Cview::Map::SGN::Physical
 c\d+      CXGN::Cview::Map::SGN::Contig
 o         CXGN::Cview::Map::SGN::ProjectStats map object
 
The actual map objects returned are defined in the CXGN::Cview::Maps namespace. Because this is really a compatibility layer, an additional namespace of the resource is appended, such that a genetic map at SGN could be defined as CXGN::Cview::Maps::SGN::Genetic . If no corresponding map is found, undef is returned.

=head1 AUTHOR(S)

Lukas Mueller (lam87@cornell.edu)

=head1 VERSION
 
1.0, March 2007

=head1 LICENSE

Refer to the L<CXGN::LICENSE> file.

=head1 FUNCTIONS

This class implements the following functions:

(See the superclass, CXGN::Cview::Maps, for a definition of the class interface)

=cut

package CXGN::Cview::MapFactory;
use strict;
use warnings;
use Carp;

use base qw| CXGN::DB::Object |;

=head2 function new()

  Synopsis:	constructor
  Arguments:	database handle, configuration variable hashref
                the configuration hashref supports the following
                hash keys:
                o cview_db_backend

                with the following values:
                o cxgn_and_cmap
                o cmap
                o cxgn [DEFAULT]
    
  Returns:	a CXGN::Cview::MapFactory object
  Side effects:	none
  Description:	none

=cut

sub new {
    my $class  = shift;
    my ($dbh, $conf_hash_ref) = @_;

    # if no config was passed, warn about it and try to load SGN::Config
   #  $config ||= do{
#         carp "WARNING: no config specified, trying to load SGN::Config";
#         require SGN::Config;
#         SGN::Config->load
#       };

    my $db_backend = $conf_hash_ref->{cview_db_backend}; 

    # figure out what map factory class we need.  if cview_db_backend
    # conf var is set, use that, otherwise try to use the project_name
    # conf var, and if that's not set then fall back to SGN

     my $mf_name = $db_backend ?     $db_backend eq 'cxgn_and_cmap' ? 'CviewAndCmap'
                                      : $db_backend eq 'cmap'          ? 'Cmap'
                                      : $db_backend eq 'cxgn'          ? 'SGN'
                                      : croak "invalid cview backend $db_backend"
				      : 'SGN';

    
    # try to load the mapfactory class
    my $mf_class = __PACKAGE__."::$mf_name";
    eval "require $mf_class";
    $@ and die "error loading $mf_class:\n$@";

    # now instantiate it, passing along the same dbh and config we got
    return $mf_class->new( @_ );
}





return 1;
