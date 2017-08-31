
use strict;

package CXGN::Cview::Map::Genotype;

use Data::Dumper;
use JSON::Any;
use CXGN::Cview::Marker::Genotype;

use base qw | CXGN::Cview::Map |;


sub new_minimal { 
    my $class = shift;
    my $dbh = shift;
    my $id = shift;
    my $schema = Bio::Chado::Schema->connect( sub { $dbh } );
    
    my $database_id =$id;
    $database_id =~ s/g(\d+)/$1/i;
    my $row = $schema->resultset("Genetic::Genotypeprop")->find( { genotypeprop_id => $database_id });
    
    if (!$row) { 
	die "The specified genotype does not exist!\n";
    }

    my $self = $class->SUPER::new($dbh, $id, @_);
    
    $self->set_id($id);
    $self->set_chromosome_lengths([ 0 ]);
    $self->set_chromosome_names( [ 'unknown ']);
    $self->set_short_name("genotype$id");
    $self->set_long_name("genotype$id");
    $self->set_units('bp');
    return $self;
}

sub new { 
    my $class = shift;
    my $dbh = shift;
    my $id = shift;
    
    my $schema = Bio::Chado::Schema->connect( sub { $dbh } );
   
    my $database_id =$id;
    $database_id =~ s/g(\d+)/$1/i;
    my $row = $schema->resultset("Genetic::Genotypeprop")->find( { genotypeprop_id => $database_id });
    
    if (!$row) { 
	die "The specified genotype does not exist!\n";
    }

    
    my $json = $row->value();

    my $marker_data = JSON::Any->decode($json);
    
    my $chromosome;
    my %chromosome_lengths;
    my @chromosome_names;
    my %marker_counts;
    my %chromosomes;

    my $self = $class->SUPER::new($dbh, $id, @_);
    foreach my $m (keys %$marker_data) { 
	my $chr_nr = $m;
	$chr_nr =~ s/((S|C)\d+)\_\d+/$1/i;
	my $offset = $m;
	$offset =~ s/(S|C)\d+\_(\d+)/$2/i;
	my $score = $marker_data->{$m};

	if (! exists($chromosomes{$chr_nr})) { 
	    #print STDERR "Generating new chr $chr_nr...\n";
	    $chromosome = CXGN::Cview::Chromosome->new();
	    $chromosome->set_name($chr_nr);
	    $chromosome->set_units('bp');
	    push @chromosome_names, $chr_nr;	    
	    $chromosomes{$chr_nr}=$chromosome;
	    #print STDERR "Pushed chromosome $chr_nr.\n";
	}
	#print STDERR "Adding marker $m to chromosome $chr_nr...\n";
	my $marker = CXGN::Cview::Marker::Genotype->new($chromosome);
	$marker->set_offset($offset);
	$marker->set_name($m);
	$marker->set_score($score);
	$chromosomes{$chr_nr}->add_marker($marker);    
	$marker_counts{$chr_nr}++;
	print "Dealing with offset $offset on chr $chr_nr...\n";
	if ($offset > $chromosome_lengths{$chr_nr}) { 
	    print STDERR "$offset is larger than $chromosome_lengths{$chr_nr}...(on chr $chr_nr)\n";
	    $chromosome_lengths{$chr_nr}=$offset;
	    $chromosomes{$chr_nr}->set_length($offset);
	}
    }
    
    my @chromosome_lengths;
    foreach my $n (@chromosome_names) { 
	push @chromosome_lengths, $chromosome_lengths{$n};
    }
    

    
    $self->set_chromosome_names(@chromosome_names);
    $self->set_chromosome_lengths(@chromosome_lengths);

    $self->{chromosomes} = \%chromosomes;

#    foreach my $n (@chromosome_names) { 
#	print STDERR join ("\t", ($n, $chromosome_lengths{$n}, $marker_counts{$n}))."\n";
#    }
    
    return $self;
}

sub get_chromosome { 
    my $self = shift;
    my $id = shift;

    return $self->{chromosomes}->{$id};
}

    
    


1;
