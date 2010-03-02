
=head1 NAME

CXGN::Cview::Map::Tools

=head1 AUTHOR

John Binns <zombieite@gmail.com>

=head1 DESCRIPTION

Non-object-oriented quick functions for getting random bits of data about maps.

=head2 is_current_version

    #example: make a new map object but only if we have the current version
    if(CXGN::Map::Tools::is_current_version($dbh,$map_version_id))
    {
        my $map=CXGN::Map->new({map_version_id=>$map_version_id});
    }

=head2 find_current_version

    #example: find the current map_version_id for a map_id
    my $map_version_id=CXGN::Map::Tools::find_current_version($dbh, $map_id);

=head2 current_tomato_map_id

    returns 9. whatever.

=cut

use strict;

package CXGN::Cview::Map::Tools;

sub is_current_version
{    
    my ($dbh,$map_version_id)=@_;
    my $q=$dbh->prepare('select current_version from sgn.map_version where map_version_id=?');
    $q->execute($map_version_id);
    my ($current)=$q->fetchrow_array();
    return $current;   
}

sub find_current_version
{
    my ($dbh,$map_id)=@_;

    # if it is not a database-based map, the map_id and map_version_id
    # are identical and contain the char prefix
    #
    if (!is_db_map($map_id)) { 
	return $map_id;
    }
    
    # otherwise we look in the database to find out.
    #
    my $q=$dbh->prepare("select map_version_id from sgn.map_version where current_version='t' and map_id=?");
    $q->execute($map_id);
    my ($current)=$q->fetchrow_array();
    return $current; 
}

sub current_tomato_map_id {
	# returns the current Tomato EXPEN-2000 map, which I keep changing.
	return 9;
}

sub find_map_id_with_version { 
    my $dbh = shift;
    my $map_version_id = shift;

    # the map_id's for the maps that are not in the database are 
    # identical to their map_version_ids
    #
    if (!is_db_map($map_version_id)) { 
	return $map_version_id;
    }

    # all other map_versions need to be retrieved from the database
    #
    my $q =$dbh->prepare("select map_id from sgn.map_version where map_version_id=?");
    $q->execute($map_version_id);
    my ($map_id) = $q->fetchrow_array();
#    warn "[CXGN::Cview::Map::Tools] find_map_id_with_version: $map_version_id corresponds to $map_id.\n";
    return $map_id;
}

sub is_db_map { 
    my $id = shift;
    if ($id =~ /^\d+$/) { 
	return 1;
    }
    return 0;
}

=head2 function get_physical_marker_color

  Synopsis:	
  Arguments:	the physical marker association type, currently
                one of "overgo", "computational", "manual".
  Returns:	the associated color, as a list of three ints.
  Side effects:	will be used by the comparative viewer to render
                the marker.
  Description:	

=cut

sub get_physical_marker_color {
    my $type = shift;
    my $status = shift;
    if (!defined($status)) { $status = ""; }
    
    if ($status eq "complete") { return (20, 250, 20); }
    if ($status eq "in_progress") { return (20, 20, 250); }
    if (!$type) { return (0, 0, 0); }
    
    if ($type eq "overgo") { 
	return (100, 100, 100);
    }
    if ($type eq "computational") { 
	return (200, 100, 100, ); 
    }
    if ($type eq "manual") { 
	return (200, 200, 100);
    }
    if ($type eq "Lpen_manual") { 
	return (50, 200, 200);
    }
    return (0, 0, 0);
}



1;
