
=head1 NAME

CXGN::Cview::MapFactory - a factory object for CXGN::Cview::Map objects

=head1 SYNOPSYS

my $map_factory  = CXGN::Cview::MapFactory->new($dbh);
$map = $map_factory->create({map_version_id=>"u1"});

=head1 DESCRIPTION

see L<CXGN::Cview::MapFactory>.

The MapFactory constructor takes a database handle (preferably constructed using CXGN::DB::Connection object). The map objects can then be constructed using the create function, which takes a hashref as a parameter, containing either map_id or map_version_id as a key (but not both). map_ids will be converted to map_version_ids immediately. Map_version_ids are then analyzed and depending on its format, CXGN::Cview::Map object of the proper type is returned.

The function get_all_maps returns all maps as list of appropriate CXGN::Cview::Map::* objects.


=head1 AUTHOR(S)

Lukas Mueller (lam87@cornell.edu)

=head1 VERSION

1.0, March 2007

=head1 LICENSE

Refer to the L<CXGN::LICENSE> file.

=head1 FUNCTIONS

This class implements the following functions:

=cut

use strict;

package CXGN::Cview::MapFactory::Ricebase;

use base qw| CXGN::DB::Object |;

use Scalar::Util qw/blessed/;

use CXGN::Cview::Map::SGN::Genetic;
#use CXGN::Cview::Map::SGN::User;
#use CXGN::Cview::Map::SGN::Fish;
use CXGN::Cview::Map::SGN::Sequence;
#use CXGN::Cview::Map::SGN::IL;
#use CXGN::Cview::Map::SGN::Physical;
use CXGN::Cview::Map::SGN::ProjectStats;
#use CXGN::Cview::Map::SGN::AGP;
#use CXGN::Cview::Map::SGN::ITAG;
use CXGN::Cview::Map::SGN::Contig;
use CXGN::Cview::Map::SGN::Scaffold;
use CXGN::Cview::Map::SGN::Image;
use CXGN::Cview::Map::SGN::QTL;

=head2 function new()

  Synopsis:	constructor
  Arguments:	a database handle
  Returns:	a CXGN::Cview::MapFactory::SGN object
  Side effects:	none
  Description:	none

=cut

sub new {
    my $class = shift;
    my $dbh = shift;
    my $context = shift;

    unless( blessed($context) && $context->isa('SGN::Context') ) {
        require SGN::Context;
	$context = SGN::Context->new();
    }
    my $self = $class->SUPER::new($dbh);

    $self->{context}=$context;


    return $self;
}

=head2 function create()

  Description:  creates a map based on the hashref given, which
                should either contain the key map_id or map_version_id
                and an appropriate identifier. The function returns undef
                if a map of the given id cannot be found/created.
  Example:

=cut

sub create {
    my $self = shift;
    my $hashref = shift;
    #print STDERR "Hashref = map_id => $hashref->{map_id}, map_version_id => $hashref->{map_version_id}\n";

    my $c = $self->{context};
    my $temp_dir = $c->path_to( $c->config->{tempfiles_subdir} );

    if (!exists($hashref->{map_id}) && !exists($hashref->{map_version_id})) {
	die "[CXGN::Cview::MapFactory] Need either a map_id or map_version_id.\n";
    }
    if ($hashref->{map_id} && $hashref->{map_version_id}) {
	die "[CXGN::Cview::MapFactory] Need either a map_id or map_version_id - not both.\n";
    }
    if ($hashref->{map_id}) {
	$hashref->{map_version_id}=CXGN::Cview::Map::Tools::find_current_version($self->get_dbh(), $hashref->{map_id});
    }

    # now, we only deal with map_versions...
    #
    my $id = $hashref->{map_version_id};

    #print STDERR "MapFactory: dealing with id = $id\n";

    # if the map_version_id is purely numeric,
    # check if the map is in the maps table and generate the
    # appropriate map

    if ($id=~/^\d+$/) {
	my $query = "SELECT map_version_id, map_type, map_id, short_name FROM sgn.map join sgn.map_version using(map_id) WHERE map_version_id=?";
	my $sth = $self->get_dbh()->prepare($query);
	$sth->execute($id);
	my ($id, $map_type) = $sth->fetchrow_array();
	$map_type ||= '';
	if ($map_type =~ /genetic/i) {
	    return CXGN::Cview::Map::SGN::Genetic->new($self->get_dbh(), $id);

	}
	
	elsif ($map_type =~ /seq/) {
	    print STDERR "Creating a seq map...($map_type, $id)\n";
	    my $map = CXGN::Cview::Map::SGN::Sequence->new($self->get_dbh(), $id);
	    #$map->set_marker_link("/gb2/gbrowse/nipponbare/?q=");
	    $map->set_link_by_name(0);
	    return $map;
	}
    }
    
    return;

}

=head2 function get_all_maps()

  Synopsis:
  Arguments:	none
  Returns:	a list of all maps currently defined, as
                CXGN::Cview::Map objects (and subclasses)
  Side effects:	Queries the database for certain maps
  Description:

=cut

sub get_all_maps {
    my $self = shift;

    my @system_maps = $self->get_system_maps();
    my @user_maps = $self->get_user_maps();
    my @maps = (@system_maps, @user_maps);
    return @maps;

}


=head2 get_system_maps

  Usage:        my @system_maps = $map_factory->get_system_maps();
  Desc:         retrieves a list of system maps (from the sgn
                database) as a list of CXGN::Cview::Map objects
  Ret:
  Args:
  Side Effects:
  Example:

=cut

sub get_system_maps {
    my $self = shift;

    my @maps = ();

    my $query = "SELECT map.map_id FROM sgn.map LEFT JOIN sgn.map_version USING(map_id) LEFT JOIN sgn.accession on(parent_1=accession.accession_id) LEFT JOIN sgn.organism USING(organism_id) LEFT JOIN common_name USING(common_name_id) WHERE current_version='t' ORDER by common_name.common_name";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute();

    while (my ($map_id) = $sth->fetchrow_array()) {
	my $map = $self->create({ map_id => $map_id });
	if ($map) { push @maps, $map; }
    }

    # push il, physical, contig, and agp map
    #
    # foreach my $id ("il6.5", "il6.9", "p9", "c9", "agp", "pachy") {
    # 	my $map = $self->create( {map_id=>$id} );
    # 	if ($map) { push @maps, $map; }
    # }

    return @maps;
}



=head2 get_user_maps

 Status:       DEPRECATED. Does nothing now, as user maps have been disabled.
 Usage:
 Desc:         retrieves the current user maps of the logged in user.
 Ret:          a list of CXGN::Cview::Map objects
 Args:         none
 Side Effects: none
 Example:

=cut

sub get_user_maps {
    my $self = shift;
    # push the maps that are specific to that user and not public, if somebody is logged in...
    #
    my @maps = ();
#     my $login = CXGN::Login->new($self->get_dbh());
#     my $user_id = $login->has_session();
#     if ($user_id) {
# 	my $q3 = "SELECT user_map_id FROM sgn_people.user_map WHERE obsolete='f' AND sp_person_id=?";
# 	my $h3 = $self->get_dbh()->prepare($q3);
# 	$h3->execute($user_id);
# 	while (my ($user_map_id) = $h3->fetchrow_array()) {
# 	    my $map = $self->create( {map_id=>"u".$user_map_id} );

# 	    if ($map) { push @maps, $map; }
# 	}
#     }
    return @maps;
}


sub get_db_ids {
    my $self = shift;
    my $id = shift;

    my $population_id = 6;
    my $reference_map_id=5;

    if ($id=~/il(\d+)\.?(\d*)?/) {
	$population_id=$1;
	$reference_map_id=$2;
    }
    if (!$reference_map_id) { $reference_map_id=5; }
    if (!$population_id) { $population_id=6; }
    #print STDERR "Population ID: $population_id, reference_map_id = $reference_map_id\n";

    return ($population_id, $reference_map_id);
}

return 1;
