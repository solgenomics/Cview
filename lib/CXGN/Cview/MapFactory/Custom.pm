

=head1 NAME

CXGN::Cview::MapFactory::Custom - a class to provide custom behaviour for the comparative viewer

=head1 DESCRIPTION 

For the interface to be implemented, see L<CXGN::Cview::MapFactory>, and for an example, see L<CXGN::Cview::MapFactory::SGN>.

=head1 AUTHOR

Lukas Mueller <lam87@cornell.edu>

=cut

use strict;

package CXGN::Cview::MapFactory::Custom;

use base qw| CXGN::DB::Object |;

use CXGN::Cview::Map::SGN::Genetic;
use CXGN::Cview::Map::SGN::User;
use CXGN::Cview::Map::SGN::Fish;
use CXGN::Cview::Map::SGN::Sequence;
use CXGN::Cview::Map::SGN::IL;
use CXGN::Cview::Map::SGN::Physical;
use CXGN::Cview::Map::SGN::ProjectStats;
use CXGN::Cview::Map::SGN::AGP;
use CXGN::Cview::Map::SGN::Contig;
use CXGN::Cview::Map::GMOD::Cmap;
  
=head2 function new()

  Synopsis:	constructor
  Arguments:	none
  Returns:	a CXGN::Cview::MapFactory object
  Side effects:	none
  Description:	none

=cut 

sub new {
    my $class = shift;
    my $dbh = shift;
    
    my $self = $class->SUPER::new($dbh);

    my $mysql = DBI->connect("DBI:mysql:database=CMAP;host=localhost", "web_usr", "tomato");
    $self->set_dbh($mysql);

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
    my $args = shift;
    
    my $id = 0;
    if (exists($args->{map_version_id})) { 
	$id=$args->{map_version_id};
	
    }
    elsif (exists($args->{map_id})) { 
	$id=$args->{map_id};
    }
    else { 
	die "Need a map_id or map_version_id key in hashref\n";
    }
    
    print STDERR "Create: Using id = $id\n";

    my $map = CXGN::Cview::Map::GMOD::Cmap->new($self->get_dbh(), $id);

    return $map;



}

=head2 function get_all_maps()

  Synopsis:	my @maps = $map_factory->get_all_maps();
  Arguments:	none
  Returns:	a list of all maps currently defined, as 
                CXGN::Cview::Map objects (and subclasses)
  Side effects:	Queries the database for certain maps
  Description:	

=cut

sub get_all_maps {
    my $self = shift;
    my $query = "SELECT map_set_id FROM cmap_map_set";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute();
    my @maps = ();
    while (my ($map_id) = $sth->fetchrow_array()) { 
	push @maps, $self->create({ map_id=>$map_id} );
    }
    return @maps;
}

sub get_system_maps { 
    my $self = shift;
    return $self->get_all_maps();
}

sub get_user_maps { 
}

return 1;
