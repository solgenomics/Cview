


=head1 NAME

CXGN::Cview::Map - an abstract class to deal with maps for the SGN comparative viewer.           
           
=head1 DESCRIPTION

The SGN mapviewer traditionally used a Perl module called CXGN::Cview::Cview_data_adapter to interface to different data sources. However, this approach was not scalable and was replaced with the CXGN::Cview::Map abstract interface approach. 

Every Map represented in the SGN comparative viewer version 2.0 needs a corresponding Map object. It needs to inherit from CXGN::Cview::Map, and implement its functions. Each map should be identifyable by an identifier, which is used by CXGN::Cview::MapFactory to create the appropriate map object. If a new map type is added, corresponding code has to be added to the MapFactory to create the map object. 

The inherited classes should be placed in the CXGN::Cview::Map::<DATABASE>:: namespace, where <DATABASE> signifies the website these interfaces are specific to. For SGN, <DATABASE> equals "SGN".

See L<CXGN::Cview::MapFactory> for the current list of supported identifiers and which types of maps they will generate.

=head1 AUTHOR(S)

Lukas A. Mueller <lam87@cornell.edu>

=head1 VERSION
 
part of the compatibility layer of version 2.0 of the SGN mapviewer

=head1 FUNCTIONS

This class implements the following functions:

=cut

use strict;

package CXGN::Cview::Map;

use CXGN::DB::Object;
use CXGN::Cview::Chromosome;
use CXGN::Cview::Chromosome::IL;
use CXGN::Cview::Chromosome::PachyteneIdiogram;
use CXGN::Cview::Legend;

use base qw | CXGN::DB::Object |;

=head2 function new()

  Synopsis:	constructor
  Arguments:	should take a database handle and a parameter identifying a map.
  Returns:	
  Side effects:	
  Description:	

=cut

sub new {
    my $class = shift;
    my $dbh = shift;
    my $self = $class->SUPER::new($dbh);
    
    # set some defaults
    #
    $self->set_preferred_chromosome_width(20);
    $self->set_type("generic");
    $self->set_units("cM");
    $self->set_short_name("unknown map");
    $self->set_long_name("");
    $self->set_chromosome_names("");
    $self->set_chromosome_lengths(1);
    $self->set_chromosome_count(1);
    $self->set_organism("Solanum lycopersicum");
    $self->set_common_name("Tomato");
    $self->set_marker_link("/maps/physical/clone_info.pl?id="); 
    $self->set_legend(CXGN::Cview::Legend->new()); # an empty legend.
    
    return $self;
}

=head2 accessors set_id(), get_id()

  Property:	the primary id of the map object
  Side Effects:	
  Description:	

=cut

sub get_id { 
    my $self=shift;
    return $self->{id};
}

sub set_id { 
    my $self=shift;
    $self->{id}=shift;
}



=head2 function get_chromosome()

  Synopsis:	my $chr = $map -> get_chromosome( $chr_nr);
  Arguments:	a legal linkage group name (usually a number, but could also
                be alphanumeric for certain linkage groups).
  Returns:	a CXGN::Cview::Chromosome object, or a derived class thereof.
  Side effects:	in most implementations, this function will likely access  
                the databases and generate the chromosome object anew for 
                each call, such that there is considerable overhead calling
                this function on complex chromosomes.
  Description:	

=cut

sub get_chromosome {
    my $self = shift;
    my $chr_nr = shift;
    # this function should return a CXGN::Cview::Chromosome object 
    # or subclass thereof
    my $empty_chr =  CXGN::Cview::Chromosome->new($chr_nr, 100, 40, 40);
    #$emtpy_chr -> set_height(1);
    #$emtpy_chr -> set_length(1);
    #$emtpy_chr -> set_color(255, 255, 255);
    return $empty_chr;
    
}

=head2 function get_linkage_group()

  Synopsis:	this is a synonym for get_chromosome()
  Arguments:	see get_chromosome()
  Returns:	see get_chromosome()
  Side effects:	etc.
  Description:	

=cut

sub get_linkage_group {
    my $self = shift;
    return $self->get_chromosome(@_);
}


=head2 function get_chromosome_section()

  Synopsis:	my $chr_section = $map->
                    get_chromosome_section($chr_nr, $start, $end, $comparison);
  Arguments:	the chromosome name, the start offset in map units, 
                and the end offset in map units. The $comparison bit 
                tells the function that there is a comparison present 
                in the viewer, which can be used to subtly change the 
                appearance of the zoomed in section.
  Returns:	a chr_section. 
  Side effects:	
  Note:         the default implementation just calls get_chromosome, ignoring the 
                start and end parameters. This is probably a useful behaviour if the
                Map does not support sections.

=cut

sub get_chromosome_section {
    my $self = shift;   
    return $self->get_chromosome();
}


=head2 function get_chromosomes()

  Synopsis:	my @lg = $map->get_chromosomes()
  Arguments:	none
  Returns:	a list of the linkage groups in the order
                defined by lg_order (in the case of genetic maps anyway)
  Side effects:	accesses the database, if the map is db-based.
  Description:	calls get_chromosome_names and then get_chromosome on 
                each name

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub get_chromosomes {
    my $self = shift;
    my @linkage_groups = ();
    foreach my $lg ($self->get_chromosome_names()) { 
	push @linkage_groups, $self->get_chromosome($lg);
    }
    return @linkage_groups;
	

}


=head2 function get_linkage_groups()

  Synopsis:	a synonym for get_chromosomes()
  Arguments:	none
  Returns:	
  Side effects:	calls get_chromosomes()
  Description:	see get_chromosomes().
                

=cut

sub get_linkage_groups {
    my $self = shift;
    return $self->get_chromosomes(@_);
}

=head2 function get_overview_chromosome()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub get_overview_chromosome {
    my $self =shift;
    my $chr_nr = shift;
    my $chr = $self->get_chromosome($chr_nr);
    return $chr;
}

=head2 function get_chromosome_connections()

  Synopsis:	my @chr_links = $map->get_chromosome_connections($chr_name);
  Arguments:	a chromosome name
  Returns:	a list of hashrefs, containing 4 keys
                map_version_id, lg_name, marker_count, short_name
                and the corresponding values
  Side effects:	most implementations will query the database
  Description:	the default implementation does nothing and returns
                an empty list.

=cut

sub get_chromosome_connections {
    my $self = shift;
    my @connections  = ();
    return @connections;
}


=head2 accessors set_chromosome_count(), get_chromosome_count()

  Synopsis:  	my $chr_count = $map->get_chromosome_count();
  Property:     the number of chromosomes in the Map (integer).
  Side Effects:	
  Notes:        The constructor should set this property
                in subclasses.

=cut

sub get_chromosome_count { 
    my $self=shift;
    return $self->{chromosome_count};

}

sub set_chromosome_count { 
    my $self=shift;
    $self->{chromosome_count}=shift;
}


=head2 accessors set_chromosome_names(), get_chromosome_names()

  Property:	an ordered list of chromosome names
  Side Effects:	names will be used on the display to identify the 
                chromosomes.
  Description:	This property should be set in the constructor of the
                Map object.

=cut

sub get_chromosome_names { 
    my $self=shift;
    return @{$self->{chromosome_names}};
}

sub set_chromosome_names { 
    my $self=shift;
    @{$self->{chromosome_names}}= @_;
}


=head2 accessors set_chromosome_lengths(), get_chromosome_lengths()

  Synopsis:	an ordered list of chromosomes lengths in the Map units.
  Arguments:	none.
  Returns:	
  Side effects:	
  Description:	

=cut

sub get_chromosome_lengths { 
    my $self = shift;
    return @{$self->{chromosome_lengths}};
}


sub set_chromosome_lengths { 
    my $self = shift;
    @{$self->{chromosome_lengths}} = @_;
}


=head2 get_chr_length_by_name

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_chr_len_by_name {
    my $self = shift;
    my $chr_name = shift;
    my @names = $self->get_chromosome_names();
    for (my $i=0; $i<@names; $i++) { 
	if ($names[$i] eq $chr_name) { 
	    return ($self->get_chromosome_lengths())[$i];
	}
    }
    return undef;
}



=head2 function has_linkage_group()

  Synopsis:	if ($map->has_linkage_group("7F")) { ... }
  Arguments:	a chromosome or linkage group name
  Returns:	returns a true value if a linkage group 
                of that name exists, a false value if it does 
                not exist. This default implementation should 
                work for all subclasses that set the chromosome_names
                in the constructor.
  Side effects:	
  Description:	

=cut

sub has_linkage_group {
    my $self = shift;
    my $linkage_group = shift;
    foreach my $lg ($self->get_chromosome_names()) { 
	if ($lg eq $linkage_group) { 
	    return 1;
	}
    }
    return 0;
}

=head2 function get_marker_count()

  Synopsis:	$map->get_marker_count($chr_nr)
  Arguments:    a chromosome number
  Returns:      the number of markers on that chr in the map
  Side effects:	depending on implementation, may access db
  Description:	this function needs to be implemented in sub-
                classes for the map statistics in the SGN
                mapviewer to work.

=cut

sub get_marker_count {
    my $self = shift;
    
}

=head2 function get_marker_type_stats()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub get_marker_type_stats {
}



=head2 accessors set_short_name(), get_short_name()

  Property:	
  Setter Args:	
  Getter Args:	
  Getter Ret:	
  Side Effects:	
  Description:	

=cut

sub get_short_name { 
    my $self=shift;
    return $self->{short_name};
}

sub set_short_name { 
    my $self=shift;
    $self->{short_name}=shift;
}

=head2 accessors set_long_name(), get_long_name()

  Property:	
  Setter Args:	
  Getter Args:	
  Getter Ret:	
  Side Effects:	
  Description:	

=cut

sub get_long_name { 
    my $self=shift;
    return $self->{long_name};
}

sub set_long_name { 
    my $self=shift;
    $self->{long_name}=shift;
}

=head2 accessors set_abstract(), get_abstract()

  Property:	
  Setter Args:	
  Getter Args:	
  Getter Ret:	
  Side Effects:	
  Description:	

=cut

sub get_abstract { 
    my $self=shift;
    return $self->{abstract};
}

sub set_abstract { 
    my $self=shift;
    $self->{abstract}=shift;
}


=head2 accessors set_centromere(), get_centromere()

  Synopsis:	my ($north, $south, $center) = $map->get_centromere($lg_name)
  Arguments:	a valid linkage group name
  Returns:	this function should return a three member list, the first 
                element corresponds to the north boundary of the centromere in cM
                the second corresponds to the south boundary of 
                the centromere in cM, the third is the arithmetic mean
                of the two first values. 
  Side effects:	none
  Description:	this property should be set in the constructor. The setter takes
                the north and the south position as parameters.
                $map->set_centromere($lg_name, $north, $south)

=cut

sub get_centromere { 
    my $self=shift;
    my $chr_name = shift;
    return ($self->{centromere}->{$chr_name}->{north}, $self->{centromere}->{$chr_name}->{south}, ($self->{centromere}->{$chr_name}->{north}+$self->{centromere}->{$chr_name}->{south})/2);
}

sub set_centromere { 
    my $self = shift;
    my $chr_name = shift;
    ($self->{centromere}->{$chr_name}->{north}, $self->{centromere}->{$chr_name}->{south}) = @_;
}



=head2 accessors set_deprecated_by(), get_deprecated_by()

  Property:	some maps will support deprecation information,
                such as the maps in the SGN database. This 
                property returns the id of the map that supercedes
                the current map.
  Side Effects:	
  Description:	

=cut

sub get_deprecated_by { 
    my $self=shift;
    return $self->{deprecated_by};
}

sub set_deprecated_by { 
    my $self=shift;
    $self->{deprecated_by}=shift;
}



=head2 accessors set_type(), get_type()

  Property:	the map type, which is defined for 
                the database-based maps. Types include
                FISH and Genetic
  Side Effects:	
  Description:	

=cut

sub get_type { 
    my $self=shift;
    return $self->{type};
}

sub set_type { 
    my $self=shift;
    $self->{type}=shift;
}


=head2 accessors set_units(), get_units()

  Property:	the unit measure of the map, such 
                as cM or MB
  Side Effects:	
  Description:	

=cut

sub get_units { 
    my $self=shift;
    return $self->{units};
}

sub set_units { 
    my $self=shift;
    $self->{units}=shift;
}



=head2 accessors set_preferred_chromosome_width(),  get_preferred_chromosome_width()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub set_preferred_chromosome_width { 
    my $self = shift;
    $self->{preferred_chromosome_width}= shift;
}

sub get_preferred_chromosome_width {
    my $self = shift;
    return $self->{preferred_chromosome_width};
}

=head2 function can_zoom()

  Synopsis:	if ($map->can_zoom()) { ...
  Arguments:	none
  Returns:	1 if the map supports zooming in, 0 if it 
                doesn\'t
  Side effects:	none
  Description:	default is zooming not supported.

=cut

sub can_zoom {
    return 0;
}

=head2 function show_stats()

  Synopsis:	whether to show the stats on the overview page for 
                this map. Override if default of 1 is not appropriate.
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub show_stats {
    return 1;
}


=head2 function get_map_stats()

  Synopsis:	my $marker_type_html = $map->get_map_stats()
  Returns:	a HTML snippet with marker type information on this map.
  Side effects:	this will be displayed on the map overview page.

=cut

sub get_map_stats {
}


=head2 function collapsed_marker_count()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	the comparative viewer displays the reference chromosome
                with only a small number of markers shown. This function
                should give a number for the number of markers shown.
                The default is 12.

=cut

sub collapsed_marker_count { 
    my $self = shift;
    return 12;
}

=head2 function initial_zoom_height()

  Synopsis:	the initial zoom level, in map units.
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub initial_zoom_height {
    my $self = shift;
    if ($self->get_units() eq "MB") { 
	return 4;
    }
    return 20;
}


=head2 accessors set_marker_link(), get_marker_link()

  Synopsis:	returns the appropriate link for marker $m
  Arguments:	a marker name
  Returns:	
  Side effects:	will be used to link that marker from the map
  Description:	

=cut

sub get_marker_link { 
    my $self=shift;
    my $id = shift;
    if ($id) { 
	return $self->{marker_link}.$id;
    }
    return "";
}

sub set_marker_link { 
    my $self=shift;
    $self->{marker_link}=shift;
}

=head2 function has_IL()

  Synopsis:	if the map has an associated IL map.
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub has_IL {
}

=head2 function has_physical()

  Synopsis:	if the map has an associated physical map.
  Arguments:	
  Returns:	
  Side effects:	
  Description:	soon to be deprecated but still used...

=cut

sub has_physical {
}

=head2 accessors set_organism(), get_organism()

  Property:	the organism name

  Getter Args:	
  Getter Ret:	
  Side Effects:	
  Description:	
    to do:    	this should be expanded the two parents...

=cut

sub get_organism { 
    my $self=shift;
    return $self->{organism};
}

sub set_organism { 
    my $self=shift;
    $self->{organism}=shift;
}

=head2 accessors set_common_name(), get_common_name()

  Property:	the common name
  Setter Args:	
  Getter Args:	
  Getter Ret:	
  Side Effects:	
  Description:	

=cut

sub get_common_name { 
    my $self=shift;
    return $self->{common_name};
}

sub set_common_name { 
    my $self=shift;
    $self->{common_name}=shift;
}

=head2 function append_messages()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	appends a message string that can be displayed by the 
                chromosome viewer to tell the user about unexpected 
                conditions or errors. The messages can be retrieved 
                using get_messages().

=cut

sub append_messages {
    my $self = shift;
    $self->{messages} .= shift;
}


=head2 function get_messages()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	gets the message string that has been constructed using
                the append_messages() function.

=cut

sub get_messages {
    my $self = shift;
    return $self->{messages};
}

=head2 map_id2map_version_id

 Usage:        $map_version_id = $map->map_id2map_version_id($map_id)
 Desc:         converts the $map_id to its corresponding $map_version_id
               if the map supports versioning of maps. The default 
               implementation returns the same id that is fed to it
               (no versioning). 
 Note:         Needs to be over-ridden in a subclass for maps that
               support versioning. The most recent, current version
               should be returned.
 Side Effects:
 Example:

=cut

sub map_id2map_version_id {
    my $self = shift;
    my $map_id = shift;
    return $map_id;
}

=head2 map_version_id2map_id

 Usage:        $map_id = $map->map_version_id2map_id($map_version_id)
 Desc:         converts the $map_version_id to its corresponding $map_id
               if the map supports versioning of maps. The default 
               implementation returns the same id that is fed to it
               (no versioning).
 Note:         Needs to be over-ridden in a subclass for maps that
               support versioning.
 Side Effects:
 Example:

=cut

sub map_version_id2map_id {
    my $self = shift;
    my $map_version_id = shift;
    return $map_version_id;
}

=head2 accessors get_legend, set_legend

 Usage:        $m->set_legend($legend_object)
 Desc:         the legend object defines the legend that
               will be displayed in the viewer.
 Property:     a CXGN::Cview::Legend object
 Side Effects: 
 Example:

=cut

sub get_legend {
  my $self = shift;
  return $self->{legend}; 
}

sub set_legend {
  my $self = shift;
  $self->{legend} = shift;
}

=head2 accessors get_temp_dir, set_temp_dir

 Usage:        $m->get_temp_dir()
 Desc:         Accessors for the temp dir [string]
 Property      
 Side Effects: temporary files generated by this object will
               be stored in the specified dir
 Example:

=cut

sub get_temp_dir {
  my $self = shift;
  return $self->{temp_dir}; 
}

sub set_temp_dir {
  my $self = shift;
  $self->{temp_dir} = shift;
}




return 1;
