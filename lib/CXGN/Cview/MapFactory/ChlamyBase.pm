
use strict;

package CXGN::Cview::MapFactory::ChlamyBase;

use base qw | CXGN::DB::Object | ;

use CXGN::Cview::Map::SGN::Genetic;

sub new { 
    my $class = shift;
    my $dbh = shift;
    my $self = $class->SUPER::new($dbh);

    return $self;
}


sub create { 
    my $self = shift;
    my $hashref = shift;
    
    #print STDERR "Hashref = map_id => $hashref->{map_id}, map_version_id => $hashref->{map_version_id}\n";
    
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
	if ($map_type =~ /genetic/i) { 
	    return CXGN::Cview::Map::SGN::Genetic->new($self->get_dbh(), $id);
	}
    }	
    print STDERR "Map NOT FOUND!!!!!!!!!!!!!!!!!!\n\n";
    return undef;

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
    foreach my $id ("il6.5", "il6.9", "p9", "c9", "agp") { 
	my $map = $self->create( {map_id=>$id} );
	if ($map) { push @maps, $map; }
    }

    return @maps;
}



=head2 get_user_maps

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
    my $login = CXGN::Login->new($self->get_dbh());
    my $user_id = $login->has_session();
    if ($user_id) { 
	my $q3 = "SELECT user_map_id FROM sgn_people.user_map WHERE obsolete='f' AND sp_person_id=?";
	my $h3 = $self->get_dbh()->prepare($q3);
	$h3->execute($user_id);
	while (my ($user_map_id) = $h3->fetchrow_array()) { 
	    my $map = $self->create( {map_id=>"u".$user_map_id} );
	    
	    if ($map) { push @maps, $map; }
	}
    }
    return @maps;
}



return 1;

