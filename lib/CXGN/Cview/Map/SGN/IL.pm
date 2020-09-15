package CXGN::Cview::Map::SGN::IL;

=head1 NAME

CXGN::Cview::Map::SGN::IL - a map class that represents IL maps.

=head1 DESCRIPTION

This map represents a collection of IL lines as a map of intervals, showing all the inbred sections of each IL as an aggregated map.

The map constructor takes a parameter, map_id, that has the form "IL" + a number + "." + another number (such as "IL6.9").The first number designates the id of the population in the SGN database (in the phenome.population table), and the second number designates the map_id for the map that was used as a reference for the intervals. 

The data for this class are gathered from the SGN database, mainly from the marker and map tables, and the phenome schema. The relationships are complex.nN

This class implements the L<CXGN::Cview::Map> interface.

=head1 AUTHOR(S)

Lukas Mueller <lam87@cornell.edu>

=head1 VERSION

This is part of the Chromosome viewer version 2.0 data adapter interface. For more information, see L<CXGN::Cview::Map>.

=head1 FUNCTIONS

This class implements the following functions:

=cut

use strict;
use warnings;
use base qw | CXGN::Cview::Map |;

use GD;
use CXGN::Cview::Marker::RangeMarker;

=head2 function new()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub new {
    my $class = shift;
    my $dbh   = shift;
    my $id    = shift;
    my $args  = shift;

    # hardcode some stuff (BAAAAAD!)
    if ( $id !~ /il6/ ) { return undef; }

    my $self = $class->SUPER::new($dbh);

    $self->set_id($id);
    my ( $population_id, $reference_map_id ) = $self->get_db_ids();

    if ( exists( $args->{short_name} ) ) {
        $self->set_short_name( $args->{short_name} );
    }
    if ( exists( $args->{long_name} ) ) {
        $self->set_long_name( $args->{long_name} );
    }
    if ( exists( $args->{abstract} ) ) {
        $self->set_abstract( $args->{abstract} );
    }

    if ( !defined($self) ) { return undef; }

    $self->set_reference_map_id($reference_map_id);

    # the id in this case is a population id that has associated
    # data
    #
    my $lg_name_q =
"SELECT distinct(lg_name), lg_order FROM phenome.population join phenome.individual using(population_id) join phenome.phenome_genotype using (individual_id) JOIN phenome.genotype_experiment using(genotype_experiment_id) JOIN sgn.map_version on (genotype_experiment.reference_map_id=map_version.map_id) JOIN sgn.linkage_group using (map_version_id) WHERE population_id=? and genotype_experiment.reference_map_id=? and map_version.current_version='t' ORDER BY lg_order, lg_name";
    my $lg_name_h = $self->get_dbh()->prepare($lg_name_q);
    if ( $id =~ /il(\d+)/ ) {
        $id = $1;
    }
    $lg_name_h->execute( $population_id, $reference_map_id );
    my @names = ();
    while ( my ( $lg_name, $lg_order ) = $lg_name_h->fetchrow_array() ) {
        push @names, $lg_name;
    }
    $self->set_chromosome_names(@names);
    $self->set_chromosome_count( scalar(@names) );

    if ( $self->get_chromosome_count() == 0 ) { return undef; }

    return $self;
}

=head2 function get_chromosome()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub get_chromosome {
    my $self   = shift;
    my $chr_nr = shift;

    my $IL = CXGN::Cview::Chromosome::IL->new();

    my $query =
"SELECT distinct(name), ns_alias, ns_marker_id, ns_position, sn_alias, sn_marker_id, sn_position, map_id, map_version_id, lg_name FROM sgn.il_info WHERE lg_name=? AND map_id=? AND population_id=?";

    my $sth = $self->get_dbh()->prepare($query);
    my $id  = $self->get_id();

    #    $id=~s/^il(\d+)/$1/;
    my ( $pop_id, $map_id ) = $self->get_db_ids();

    #print STDERR "POP: $pop_id, CHR: $chr_nr, MAP $map_id\n";
    $sth->execute( $chr_nr, $map_id, $pop_id );

    while (
        my (
            $individual_name, $alias_ns,  $marker_id_ns,
            $position_ns,     $alias_sn,  $marker_id_sn,
            $position_sn,     $map_id_ns, $map_version_id_ns
        )
        = $sth->fetchrow_array()
      )
    {

        my $m1 = CXGN::Cview::Marker->new( $IL, $marker_id_ns, $alias_ns );
        $m1->set_offset($position_ns);
        $m1->hide_label();
        $m1->set_url(
            "/search/markers/markerinfo.pl?marker_id=" . $m1->get_id() );
        my $m2 = CXGN::Cview::Marker->new( $IL, $marker_id_sn, $alias_sn );
        $m2->set_offset($position_sn);
        $m2->hide_label();
        $m2->set_url(
            "/search/markers/markerinfo.pl?marker_id=" . $m2->get_id() );

        $IL->add_marker($m1);
        $IL->add_marker($m2);

        my $marker =
          CXGN::Cview::Marker::RangeMarker->new( $IL, $individual_name,
            $individual_name );
        $marker->get_label()->set_name($individual_name);
        $marker->set_marker_name($individual_name);
        my $offset = ( ( $position_ns + $position_sn ) / 2 );
        $marker->set_offset($offset);
        $marker->get_label()->set_stacking_height(6);
        $marker->get_label()->set_label_spacer(24);
        my $north_range = $offset - $position_ns;
        my $south_range = $position_sn - $offset;
        $marker->set_north_range($north_range);
        $marker->set_south_range($south_range);

        $marker->set_url(
"/cview/view_chromosome.pl?map_version_id=$map_version_id_ns&amp;chr_nr=$chr_nr&amp;show_IL=1&amp;show_zoomed=1&amp;cM_start=$position_ns&amp;cM_end=$position_sn"
        );

#print STDERR "Generated a new RangeMarker object...offset=".$marker->get_offset().". Northrange=Southrange=".$marker->get_north_range."\n";
        $IL->add_marker($marker);
    }

    $IL->sort_markers();
    $IL->set_width( $self->get_preferred_chromosome_width() / 2 );
    $IL->get_ruler()->set_start_value(0);
    $IL->layout();
    $IL->get_ruler()->set_end_value( $IL->get_length() )
      ;    # ($IL->get_markers())[-1]->get_offset())

    # save for later
    #
    ${ $self->{chromosomes} }{$chr_nr} = $IL;

    return $IL;

}

=head2 function get_overview_chromosome()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub get_overview_chromosome {
    my $self   = shift;
    my $chr_nr = shift;
    my $chr    = $self->get_chromosome($chr_nr);
    $chr->set_width( $self->get_preferred_chromosome_width() / 2 );
    foreach my $m ( $chr->get_markers() ) {
        if ( $m->isa("CXGN::Cview::Marker::RangeMarker") ) {
            $m->show_label();
            $m->get_label()->set_font( GD::Font->Tiny );
            $m->get_label()->set_label_spacer(16);
            $m->get_label()->set_stacking_height(3);
        }
        else {
            $m->hide_label();
        }
    }
    return $chr;
}

=head2 function get_chromosome_lengths()

This function takes the chromosome lengths from the corresponding reference map in the sgn map database.

=cut

sub get_chromosome_lengths {
    my $self = shift;

    my $map_version_id =
      CXGN::Cview::Map::Tools::find_current_version( $self->get_dbh(),
        $self->get_reference_map_id() );
    my $query =
"SELECT lg_name, max(position) FROM sgn.linkage_group JOIN sgn.marker_location USING(lg_id) WHERE linkage_group.map_version_id=? GROUP BY lg_name, lg_order ORDER BY lg_order";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($map_version_id);
    my @chromosome_lengths = ();
    while ( my ( $lg_name, $length ) = $sth->fetchrow_array() ) {
        push @chromosome_lengths, $length;
    }
    return @chromosome_lengths;
}

=head2 function has_IL()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub has_IL {
}

=head2 function has_physical()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub has_physical {
}

=head2 function get_chromosome_connections()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub get_chromosome_connections {
    my $self   = shift;
    my $chr_nr = shift;
    my $map_1992 =
      CXGN::Cview::Map::SGN::Genetic->new( $self->get_dbh(),
        CXGN::Cview::Map::Tools::find_current_version( $self->get_dbh(), 5 ) );
    return {
        map_version_id => $map_1992->get_id(),
        lg_name        => $chr_nr,
        marker_count   => "?",
        short_name     => $map_1992->get_short_name(),
    };
}

=head2 accessors set_reference_map_id(), get_reference_map_id()

  Property:	
  Setter Args:	
  Getter Args:	
  Getter Ret:	
  Side Effects:	
  Description:	

=cut

sub get_reference_map_id {
    my $self = shift;
    return $self->{reference_map_id};
}

sub set_reference_map_id {
    my $self = shift;
    $self->{reference_map_id} = shift;
}

=head2 function get_units()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub get_units {
    return "cM";
}

=head2 function get_preferred_chromosome_width()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub get_preferred_chromosome_width {
    return 12;
}

=head2 function collapsed_marker_count()

The value given by this function is large, such that markers are never collapsed in the reference chromosome view.

=cut

sub collapsed_marker_count {
    return 2000;
}

=head2 function get_map_stats()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub get_map_stats {
    return "None.";
}

=head2 function get_marker_count()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub get_marker_count {
    my $self   = shift;
    my $chr_nr = shift;
    my $query =
"SELECT count(distinct(individual.individual_id)) FROM phenome.phenome_genotype JOIN phenome.genotype_experiment using(genotype_experiment_id) JOIN phenome.genotype_region on (phenome_genotype.phenome_genotype_id=genotype_region.genotype_id) JOIN sgn.linkage_group on (genotype_region.lg_id=linkage_group.lg_id) JOIN phenome.individual on (individual.individual_id=phenome_genotype.individual_id) WHERE population_id=? AND lg_name=? AND zygocity_code='h'";
    my $sth = $self->get_dbh()->prepare($query);
    my ( $pop_id, $map_id ) = $self->get_db_ids();

    #    $id =~ s/.*?(\d+)/$1/i;
    $sth->execute( $pop_id, $chr_nr );

    my ($count) = $sth->fetchrow_array();
    return $count;
}

=head2 function get_marker_link()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub get_marker_link {
    my $self   = shift;
    my $marker = shift;

    my $chr_nr = 0;

    # the IL markers have names of the form IL3-4 (3 would be the chromosome)
    if ( $marker =~ /\w+(\d+)\-(.*)/ ) {
        $chr_nr = $1;
    }
    my $map_version_id = $self->get_id();
    return
"/cview/view_chromosome.pl?map_version_id=$map_version_id&amp;chr_nr=$chr_nr";
}

sub get_db_ids {
    my $self             = shift;
    my $population_id    = 6;
    my $reference_map_id = 5;

    if ( $self->get_id() =~ /il(\d+)\.?(\d*)?/ ) {
        $population_id    = $1;
        $reference_map_id = $2;
    }
    if ( !$reference_map_id ) { $reference_map_id = 5; }
    if ( !$population_id )    { $population_id    = 6; }

#print STDERR "Population ID: $population_id, reference_map_id = $reference_map_id\n";

    return ( $population_id, $reference_map_id );
}

return 1;
