
use Modern::Perl;

package CXGN::Cview::Map::SGN::Image;

use base 'CXGN::Cview::Map';
use File::Basename;

use CXGN::Cview::Chromosome::Image;

sub new { 
    my $class = shift;
    my $dbh = shift;
    my $id = shift;
    my @files = @_;


    my $self = $class->SUPER::new($dbh);
    
    $self->set_id($id);
    $self->set_units('');
    @{$self->{files}} = @files;

    my @chr_names = ();
    foreach my $f (@files) { 
	if (! -e $f) { warn "Can't find file $f."; }
	##print STDERR "CHR: ".(basename($f, ".png"))."\n";
	push @chr_names, basename($f, ".png");
    }
    $self->set_chromosome_names(@chr_names);
    $self->set_chromosome_count(scalar(@chr_names));
    
    my @chr_lens;
    foreach my $f (@files) { 
	# use length in pixels as map length
	my $length = `file $f`;
	$length =~ s/.*x (.\d+),.*/$1/;
	push @chr_lens, $length;
    }
	
    $self->set_chromosome_lengths(@chr_lens);
	
    
    return $self;

}

sub can_overlay { 
    return 0;
}

sub get_chromosome { 
    my $self = shift;
    my $chr_nr = shift;

    my $file_index;
    my @chr_names = $self->get_chromosome_names();
    for (my $n=0; $n< (@chr_names); $n++) { 
	if ($chr_names[$n] eq $chr_nr) { 
	    $file_index = $n;
	}
    }
    my $chr = CXGN::Cview::Chromosome::Image->new($chr_nr, $self->{files}->[$file_index]);

    $chr->set_length(100);
    $chr->_calculate_chromosome_length();
    $chr->set_caption($chr_nr);
    
    
    return $chr;

}

sub get_chromosome_count { 
    my $self = shift;
    return scalar(@{$self->{files}});
}


sub get_chromosome_connections { 
    my $self = shift;
    my $chr_nr = shift;

    $chr_nr =~ s/.*(\d+).*/$1/;
    return { map_version_id         => 25,
	     lg_name        => $chr_nr,
	     marker_count   => '?',
	     short_name     => 'FISH map',
    };
}


sub show_ruler{ 
    return 0;
}

1;
