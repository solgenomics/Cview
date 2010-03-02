


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

=cut

use strict;

package CXGN::Cview::MapFactory::SGN;

use base qw| CXGN::DB::Object |;

use SGN::Context;
use CXGN::Cview::Map::SGN::Genetic;
#use CXGN::Cview::Map::SGN::User;
use CXGN::Cview::Map::SGN::Fish;
use CXGN::Cview::Map::SGN::Sequence;
use CXGN::Cview::Map::SGN::IL;
use CXGN::Cview::Map::SGN::Physical;
use CXGN::Cview::Map::SGN::ProjectStats;
use CXGN::Cview::Map::SGN::AGP;
use CXGN::Cview::Map::SGN::ITAG;
use CXGN::Cview::Map::SGN::Contig;

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
    
    my $self = $class->SUPER::new($dbh);

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
    
    my $c = SGN::Context->new();
    #print STDERR "Hashref = map_id => $hashref->{map_id}, map_version_id => $hashref->{map_version_id}\n";
    
    my $temp_dir =  File::Spec->catfile($c->get_conf('basepath'), $c->get_conf('tempfiles_subdir'), 'cview'); 

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
	elsif ($map_type =~ /fish/) { 
	    #print STDERR "Creating a fish map...\n";
	    return CXGN::Cview::Map::SGN::Fish->new($self->get_dbh(), $id);
	}
	elsif ($map_type =~ /seq/) { 
	    #print STDERR "Creating a seq map...\n";
	    return CXGN::Cview::Map::SGN::Sequence->new($self->get_dbh(), $id);
	}
    }
    elsif ($id =~ /^u/i) { 
	return CXGN::Cview::Map::SGN::User->new($self->get_dbh(), $id);
    }
    elsif ($id =~ /^il/i) { 
	my $abstract = 
	"The tomato Introgression lines (ILs) are a set of nearly isogenic lines (NILs) developed by Dani Zamir through a succession of backcrosses, where each line carries a single genetically defined chromosome segment from a divergent genome. The ILs, representing whole-genome coverage of S. pennellii in overlapping segments in the genetic background of S. lycopersicum cv. M82, were first phenotyped in 1993, and presently this library consists of 76 genotypes. ";
	
	my ($population_id, $map_id) = $self->get_db_ids($id);
	if ($map_id == 9) { 
	    $abstract .= " This IL map is based on markers of the F2-2000 map. ILs have also been mapped <a href=\"map.pl?map_id=il6.5&amp;show_ruler=1&amp;show_offsets=1\" >with the ExPEN1992 map as a reference</a>.";
	}
	elsif ($map_id ==5) { 
	    $abstract .= " The IL lines on this map have been characterized based on the markers on the 1992 tomato map. ILs have also been mapped <a href=\"map.pl?map_id=il6.9&amp;show_ruler=1&amp;show_offsets=1\" >with the ExPEN2000 map as a reference</a>. ";
	}
	
	my $ref_map = "ExPEN2000";
	if ($id==5) { $ref_map = "ExPEN1992";}
	my $long_name =qq | <i>Solanum lycopersicum</i> Zamir Introgression Lines (IL) based on $ref_map |;

	return CXGN::Cview::Map::SGN::IL->new($self->get_dbh(), $id, 
					      { short_name => "Tomato IL map",
						long_name => $long_name,
						abstract => $abstract 
					      });
    }
    elsif ($id =~ /^\//) { 
	#return CXGN::Cview::Map::SGN::File->new($dbh, $id);
    }
    elsif ($id =~ /^p\d+/) { 
	return CXGN::Cview::Map::SGN::Physical->new($self->get_dbh(), $id);
    }
    elsif ($id =~ /^o$/i) { 
	
	return CXGN::Cview::Map::SGN::ProjectStats->new($self->get_dbh(), { 
	    short_name=>"Tomato Sequencing Progress",
	    long_name=>"Tomato Sequencing Statistics by Chromosome", 
	    abstract => $self->get_abstract(),
	    
	});
    }
    
    elsif ($id =~ /^agp$/i) { 
	return CXGN::Cview::Map::SGN::AGP->new($self->get_dbh(), $id, {
					       short_name => "Tomato AGP map",
					       long_name => "Tomato (Solanum lycopersicum) Accessioned Golden Path map",
					       abstract => "<p>The AGP map shows the sequencing progress of the international tomato genome sequencing project by listing all finished clones by estimated physical map position . Each sequencing center generates one or more AGP (Accessioned Golden Path) files and uploads them to SGN. These files contain all the sequenced BACs, their position on the chromosome, the overlaps with other BACs and other information. For a complete specification, please refer to the <a href=\"http://www.sanger.ac.uk/Projects/C_elegans/DOCS/agp_files.shtml\">Sanger AGP specification</a>. The AGP files can also be downloaded from the SGN FTP site, at <a href=\"ftp://ftp.sgn.cornell.edu/tomato_genome/agp/\">ftp://ftp.sgn.cornell.edu/tomato_genome/agp/</a>.</p> <p>Note that this map is in testing (beta), and not all features may be functional.</p>" ,
					       temp_dir => $temp_dir } );
    }
    elsif ($id =~ /^itag$/i) { 
	return CXGN::Cview::Map::SGN::ITAG->new($self->get_dbh(), $id, { 
						short_name => "Tomato ITAG map",
						long_name=>"Tomato (Solanum lycopersicum) ITAG map",
						abstract=>"<p>The ITAG map shows the contig assembly and the corresponding BACs as used by the most recent annotation from the International Tomato Annotation Group (ITAG, see <a href=\"http://www.ab.wur.nl/TomatoWiki\">ITAG Wiki</a>). Clicking on the contigs will show the ITAG annotation in the genome browser.",
						temp_dir => $temp_dir }
	    );
    }
#    elsif ($id =~ /^u\d+$/i) {
#	return CXGN::Cview::Map::SGN::User->new($self->get_dbh(), $id);
#    }
    elsif ($id =~ /^c\d+$/i) { 
	return CXGN::Cview::Map::SGN::Contig->new($self->get_dbh(), $id, { 
	    berkeley_db_path=>'/data/prod/public/tomato_genome/physical_mapping/fpc/SGN_2009/gbrowse/curr/',
	    short_name => "Tomato FPC map SGN2009",
	    long_name => "Solanum lycopersicum Contig Map SGN2009",
	    temp_dir => $temp_dir,
	    marker_link => "/gbrowse/gbrowse/fpc_tomato_sgn_2009/?name=",
	    
	    abstract => qq|
	    
<p>This map shows the contig positions of the SGN2009 physical map constructed at the Arizona Genome Institute in late 2009. The marker positions shown are from the latest <a href="/cview/map.pl?map_id=9">EXPEN2000 map</a>.</p>
    
    <p>This physical map contains clones from the HindIII, EcoRI, MboI and sheared BAC library.</p>
    
    <p>This overview shows the counts of contigs along the chromosome. Click on any chromosome to view the individual contigs. More information on each contig can be obtained by by clicking on a specific contig.
    
    <p>Specific contig IDs, including contigs that are not mapped, can be searched on the <a href="/gbrowse/gbrowse/fpc_tomato_sgn_2009/">FPC viewer page</a>.</p>
    <br />
    
    
|
						  
						  }
	    );
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
    foreach my $id ("il6.5", "il6.9", "p9", "c9", "agp", "itag") { 
	my $map = $self->create( {map_id=>$id} );
	if ($map) { push @maps, $map; }
    }

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
    print STDERR "Population ID: $population_id, reference_map_id = $reference_map_id\n";

    return ($population_id, $reference_map_id);
}

return 1;
