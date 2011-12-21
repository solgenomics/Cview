package CXGN::Cview::Map::SGN::AGP;

use strict;
use warnings;

use File::Spec;
use Cache::File;

use CXGN::Cview::Chromosome::AGP;
use CXGN::Cview::Marker::Physical;
use CXGN::Cview::Map::Tools;
use CXGN::Genomic::Clone;
use CXGN::Genomic::BACMarkerAssoc;

use base qw | CXGN::Cview::Map |;

our $ENDMARKER = "END OF DRAFT";

sub new {
    my $class = shift;
    my $dbh   = shift;
    my $id    = shift;
    my $args  = shift;

    my $self = $class->SUPER::new($dbh);

    $self->set_id($id);

    $self->set_short_name($args->{short_name});
    $self->set_long_name( $args->{long_name} );
    $self->set_abstract( $args->{abstract} );
    $self->set_temp_dir( $args->{temp_dir} || "/tmp" );
    $self->set_file( $args->{file} );
    $self->set_units("MB");
    $self->{chr}={};
    $self->{cache_dir} = $args->{cache_dir};
    
    my @lengths;
    my @names;

    $self->get_basic_stats();
    
    return $self;
}

sub get_chromosome {
    my $self   = shift;
    my $chr_nr = shift;

    print STDERR "Getting chr $chr_nr..\n";
    
    # manufacture a new chromosome based on cached data...
    my $chr = $self->fetch_chromosome($chr_nr);
    $chr->set_height(100);
    
    $chr->_calculate_chromosome_length();
    $chr->_calculate_scaling_factor();

    return $chr;
}


sub get_basic_stats { 
    my $self = shift;
    
    my $cache = Cache::File->new(cache_root=>$self->{cache_dir});
    if ($cache->exists($self->get_id())) { 
	my $entry = $cache->entry($self->get_id());
	my $p = $entry->thaw();
	
	$self->set_chromosome_lengths(@{$p->{chromosome_lengths}});
	$self->set_chromosome_names(@{$p->{chromosome_names}});
	$self->set_chromosome_count(scalar(@{$p->{chromosome_lengths}}));
    }
    else { 
	$self->calculate_basic_stats();
	my $p;
	$cache->set($self->get_id());
	my $entry = $cache->entry($self->get_id());
	@{$p->{chromosome_lengths}} = $self->get_chromosome_lengths();
	@{$p->{chromosome_names}}   = $self->get_chromosome_names();
	$entry->freeze($p);
    }
}

sub calculate_basic_stats { 
    my $self = shift;
    open(my $F, '<', $self->get_file()) || die "Can't open file ".$self->get_file();
    my $old_chr = "";
    my @chr_names;
    my @chr_len;
    my $max_len = 0;
    my ($chr, $start, $end);
    while (<$F>) { 
	chomp;
	($chr, $start, $end) = split /\t/;
	if ($end>$max_len) { $max_len=$end; }
	if ($chr ne $old_chr && $old_chr) { 
	    #print STDERR "$chr pushed... $max_len..\n";
	    push @chr_names, $old_chr;
	    push @chr_len, $max_len / 1_000_000;
	    $max_len=0;
	}
	$old_chr=$chr;
    }
   push @chr_len, $max_len / 1_000_000;
    push @chr_names, $chr;
    $self->set_chromosome_lengths(@chr_len);
    $self->set_chromosome_names(@chr_names);
    $self->set_chromosome_count(scalar(@chr_len));
}


sub fetch_chromosome { 
    my $self = shift;
    my $chr_nr = shift;

    open (my $AGP, '<', $self->get_file()) || die "Can't open file ".$self->get_file().": $!";
    my $largest_offset = 0;
    my $old_chr = "";
    my $chr;
    my $count=-1;

    #print STDERR "Generating new chromosome $chr_nr\n";
    $chr = CXGN::Cview::Chromosome::AGP->new($chr_nr, 100, 20, 20);    
    
    while (<$AGP>) { 
	chomp;
	last if /END OF DRAFT/;
	next if /^\s*\#/;
	
	my ($chr_name, $start, $end, $count, $dir, $size_or_clone_name, $overlap_or_type, $clone_size_or_yesno, $orientation) = split /\t/;
	
	next if ($chr_nr ne $chr_name);

	
	my $gap_size = 0;
	my $clone_name = "";
	if ($size_or_clone_name =~ /^\d+$/) { 
	    $gap_size = $size_or_clone_name;
	}
	else { 
	    $clone_name = $size_or_clone_name;
	}
	
	my $overlap = 0;
	my $type = "";
	if ($overlap_or_type =~ /clone|contig/i) { 
	    $type=$overlap_or_type;
	}
	else { 
	    $overlap = $overlap_or_type;
	}
	
	my $yesno = "";
	my $clone_size = 0;
	if ($clone_size_or_yesno =~/Y|N/i) { 
	    $yesno = $clone_size_or_yesno;
	}
	else { 
	    $clone_size = $clone_size_or_yesno;
	}	
	
	if ($dir eq "W") { 
	    # if dir is not N (meaning it is R or F), then add
	    # a marker. Otherwise we deal with a gap.
	    #print STDERR "READ AGP file line: $start\t$end\$count\t$dir\n";
	    my $bac = CXGN::Cview::Marker::Physical->new($chr);
	    $bac->set_hilite_chr_region(1);
	    my $offset = ($start+$end)/2;
	    
	    # convert numbers to MBases
	    #
	    my $MB = 1e6;
	    $offset = $offset / $MB;
	    $start = $start / $MB;
	    $end = $end / $MB ;
	    
	    if ($offset > $largest_offset) { $largest_offset = $offset; }
	    
	    $bac->set_offset($offset);
	    $bac->set_north_range($offset-$start);
	    $bac->set_south_range($end-$offset);
	    $bac->set_marker_name($clone_name);
	    $bac->get_label()->set_name($clone_name);
	    # to do: $bac->set_url();
	    
	    $chr->add_marker($bac);
	    
	    #print STDERR "Added a bac at $offset, north = ".($offset-$start).", end = ".($end-$offset)." to $chr_name\n";
	}
	else { 
	    # also include gaps in the calculation of the largest offset
	    my $gap_offset = int(($start+$end)/2);
	    $gap_offset = $gap_offset/1_000_000;
	    
	    if ($gap_offset>$largest_offset) { 
		$largest_offset = $gap_offset;
	    }
	    
	}
    }
    
    $chr->set_length($largest_offset);
    $chr->set_height(100);
    close($AGP);
    return $chr;
}

sub get_overview_chromosome {
    my $self   = shift;
    my $chr_nr = shift;
    
    #print STDERR "Generating overview chromosome for chr $chr_nr\n";
    my $chr = $self->get_chromosome($chr_nr);

    foreach my $m ( $chr->get_markers() ) {
        $m->hide_label();
       $m->set_show_tick(0);
        $m->set_url("");
       
    }
    if ( !$chr->get_markers() ) {

        #	 $chr->set_url("");
    }
    $chr->set_name($chr_nr=~s/.*(\d+)$/$1/g);
    return $chr;
}

sub get_chromosome_section {
    my $self       = shift;
    my $chr_nr     = shift;
    my $start      = shift;
    my $end        = shift;
    my $comparison = shift;

    my $chr = $self->get_chromosome($chr_nr);

    $chr->set_section( $start, $end );

    foreach my $m ( $chr->get_markers() ) {
        $m->unhide();
        if ($comparison) { $m->get_label()->set_hidden(1); }
        $m->set_hilite_chr_region(1);
    }
    return $chr;
}

sub show_stats {
    return 1;
}


=head2 accessors get_file, set_file

 Usage:
 Desc:         the agp file to be used for display, containing all the 
               chromosomes.
 Property
 Side Effects:
 Example:

=cut

sub get_file {
  my $self = shift;
  return $self->{file}; 
}

sub set_file {
  my $self = shift;
  $self->{file} = shift;
}


sub get_marker_type_stats {
    my $self = shift;

}

sub get_map_stats {
    return "Only fully sequenced BACs are shown on this map.";
}

sub get_marker_count {
    my $self   = shift;
    my $chr_nr = shift;
    my @markers = $self->get_chromosome($chr_nr)->get_markers();
    return scalar(@markers);

}

sub get_filename {
    my $self     = shift;
    my $filename = shift;
    my @files    = `ls -t $filename`;
    return undef unless @files;
    #print STDERR "unversioned name = $filename. versioned name = $files[0]\n";
    chomp( $files[0] );
    return $files[0];
}

# show no markers on the overview
sub collapsed_marker_count {
    return 0;
}

sub can_zoom {
    return 1;
}


=head2 get_chromosome_connections

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_chromosome_connections {
    my $self   = shift;
    my $chr_nr = shift;
    my $map_version_id =
      CXGN::Cview::Map::Tools::find_current_version( $self->get_dbh(),
        CXGN::Cview::Map::Tools::current_tomato_map_id() );

    my $connections = {
        map_version_id => $map_version_id,
        lg_name        => $chr_nr,
        marker_count   => "?",
        short_name     => "F2-2000"
    };
    return ($connections);
}



sub initial_zoom_height { 
    return 5.0;
}


1;
