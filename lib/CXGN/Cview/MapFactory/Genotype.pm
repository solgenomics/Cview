
use strict;

package CXGN::Cview::MapFactory::Genotype;

use JSON::Any;
use Bio::Chado::Schema;

sub new { 
    my $class = shift;
    my $dbh = shift;
    my $id = shift;
    
    my $schema = Bio::Chado::Schema->connect( sub { $dbh } );
    
    my $self = SUPER::new($dbh);
    $self->set_id($id);

    my $database_id =$id;
    $database_id =~ s/g(\d+)/$1/i;
    my $row = $schema->resultset("Genotype::Genotypeprop")->find( { genotypeprop_id => $database_id });

    if (!$row) { 
	die "The specified genotype does not exist!\n";
    }

    my $json = $row->value();
    my $marker_data = JSON::Any->decode($json);

    my $previous_chr = 0;
    my $chromosome;
    foreach my $m (keys %$marker_data) { 
	my $chr_nr = $m;
	$chr_nr =~ s/(S\d+)\_\d+/$1/i;
	my $offset =~ s/Sd+\_(\d+)/$1/i;
	my $score = $marker_data->{$m};
	
	if ($chr != $previous_chr) { 
	    if ($previous_chr) { push @chromosomes, $chromosome;}
	    $chromosome = CXGN::Cview::Chromosome->new();
	    $chromosome->chr_nr($chr_nr);
	    $chromosome->set_units('bp');

	}
	my $marker = CXGN::Cview::Marker->new($chromosome);
	$marker->offset($offset);
	$marker->name($m);
	$marker->score($score);
	$chromosome->add_marker($marker);    
	$previous_chr = $chr_nr;
    }
    return $self;
}


1;
