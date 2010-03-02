
=head1 NAME

CXGN::Cview::VectorViewer - a class to view and manipulate vectors

=head1 DESCRIPTION

This class implements a viewer/editor for circular vector sequences.

It can either use a genbank record as an input, or its native data format. It can also detect restriction sites in the sequence. 

A figure is produced that represents the vector. 

The native format contains a type column (containing either "FEATURE", "NAME", "SEQUENCE" etc.) and has the following comma delimited columns for the type FEATURE:

 FEATURE
 name
 start coord
 end coord
 orientation
 color

The columns for the type NAME:

 NAME
 the_name

Columns for type SEQUENCE:

 SEQUENCE
 the_sequence




=head1 AUTHOR

Lukas Mueller <lam87@cornell.edu>

=head1 METHODS

This class implements the following methods:

=cut

use strict;

package CXGN::Cview::VectorViewer;

use Bio::SeqIO;
use Bio::Restriction::Analysis;

use CXGN::Cview::MapImage;
use CXGN::Cview::Chromosome::Vector;
use CXGN::Cview::Marker::VectorFeature;

=head2 new

 Usage:        $vv = CXGN::Cview::VectorViewer->
                 new($map_name, $map_width, $map_height);
 Desc:         creates a new vector viewer object
 Args:         a map name, image width, image height
 Side Effects: 
 Example:

=cut

sub new {
    my $class = shift;
    my $name = shift;
    my $width = shift;
    my $height = shift;
    my $self = bless {}, $class;

    $self->{map_image} = CXGN::Cview::MapImage->new($name, $width, $height);

    return $self;
    
}


=head2 parse_native

 Usage:        $vv->parse_native(@commands)
 Desc:         parses the native commands given in 
               the lines of the list @commands
 Ret:          nothing
 Args:         a list of lines containing the commands
 Side Effects: stores the commands using set_commands_ref()
 Example:

=cut

sub parse_native {
    my $self = shift;
    my @input = @_;

    my @commands = ();

    foreach my $line (@input) { 
	chomp($line);
	$line =~ s/\r//g; 
	my @tokens = split /\s*,\s*/, $line;

	if (!$tokens[0]) { next(); }
	push @commands, \@tokens;
	
	if ($tokens[0] eq "SEQUENCE") { $self->set_sequence($tokens[1]); }
	if ($tokens[0] eq "LENGTH") { $self->set_seq_length($tokens[1]); }
    }
    $self->set_commands_ref(\@commands);
}




=head2 parse_genbank

 Usage:        $vv->parse_genbank($fh)
 Desc:         parses the genbank file at $fh.
 Ret:
 Args:
 Side Effects: modifies the internal drawing commands.
 Example:

=cut

sub parse_genbank {
    my $self = shift;
    my $fh = shift;

    my $sio = Bio::SeqIO->new( -fh => $fh, -format=>'genbank');
    my $s = $sio->next_seq();
    my @commands = ();
    my @features = $s -> get_SeqFeatures();
    foreach my $f (@features) { 
	my $dir = "F";
	if ($f->strand() != 1) { $dir = "R"; }
	push @commands, [ "FEATURE", $f->primary_tag(), $f->start(), $f->end(), $dir ];
    }
    $self->set_sequence($s->seq());
    push @commands, [ "SEQUENCE", $self->get_sequence() ];

    $self->set_commands_ref(\@commands);
}



=head2 accessors get_commands_ref, set_commands_ref

 Usage:        $c_ref = $vv -> get_commands_ref();
 Desc:         set/get the native drawing commands
               as a listref.
 Property:     the commands that are used to draw the vector.

=cut

sub get_commands_ref {
  my $self = shift;
  return $self->{commands}; 
}

sub set_commands_ref {
  my $self = shift;
  $self->{commands} = shift;
}

=head2 add_command

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub add_command {
    my $self = shift;
    my @tokens = @_;
    
    if (!$tokens[0]) { return; }
    
    if ($tokens[0] eq "SEQUENCE") { $self->set_sequence($tokens[1]); }
    if ($tokens[0] eq "LENGTH") {  $self->set_seq_len($tokens[1]); }
    
    push @{$self->{commands}}, \@tokens;
}



=head2 accessors get_seq_length, set_seq_length

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_seq_length {
  my $self = shift;
  return $self->{seq_length}; 
}

sub set_seq_length {
  my $self = shift;
  $self->{seq_length} = shift;
}

=head2 accessors get_sequence, set_sequence

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_sequence {
  my $self = shift;
  return $self->{sequence}; 
}

sub set_sequence {
  my $self = shift;
  $self->{sequence} = shift;
}

=head2 restriction_analysis

 Usage:        my $vv->restriction_analysis($ra_type)
 Desc:         performs the restriction analysis on the sequence.
               $ra_type can be any of the following:
               "all": all enzymes are shown. Usually overwhelming.
               "unique": the restriction enzymes that cut the sequence
                         only once are shown.
               "popular6bp": Popular 6bp restriction enzymes are shown
               "popular4bp": Popular 4bp restriction enzymes are shown
 Ret:
 Args:
 Side Effects: adds the restriction enzymes found to the drawing 
               commands.
 Example:

=cut

sub restriction_analysis {
    my $self = shift;
    my $ra_type = shift;

    my $seq = Bio::Seq->new( -seq=>$self->get_sequence());
    $seq->is_circular(1);
    if (!$seq->is_circular()) { die "It is not circular!"; }
    my $ra = Bio::Restriction::Analysis->new($seq);
    my $cutters;
    if ($ra_type eq "unique") { 
	$cutters = $ra->unique_cutters();
    }
    else {
	$cutters = $ra->cutters();
    }
    foreach my $c ($cutters->each_enzyme()) {
	my $enzyme = $c->name();
	if ($ra_type eq "popular6bp") { 
	    if (!(grep /^$enzyme$/, ($self->popular_6bp_enzymes()))) { 
		next();
	    }
	}
	if ($ra_type eq "popular4bp") {
	    if (!(grep /^$enzyme$/, ($self->popular_4bp_enzymes()))) { 
		next();
	    }
	}
		
	my @fragments = $ra ->fragment_maps($c->name());
	foreach my $f (@fragments) { 
	    $self->add_command( "FEATURE",  $c->name(), $f->{start}, $f->{end}, "F", "gray");
	}
	
    }
}


=head2 generate_image

 Usage:        $vv->generate_image()
 Desc:         generates the png and html map for the vector
 Ret:          returns the html to display the image and
               the image map.
 Args:         none
 Side Effects: none
 Example:      none

=cut

sub generate_image {
    my $self = shift;

    my $vh = CXGN::VHost->new();
    
    my $cache = CXGN::Tools::WebImageCache->new();
    $cache->set_key("abc");
    $cache->set_force(1);
    $cache->set_expiration_time(86400); # seconds, this would be a day.
    $cache->set_map_name("map_name"); # what's in the <map name='map_name' tag.
    $cache->set_temp_dir($vh->get_conf("tempfiles_subdir")."/cview");
    $cache->set_basedir($vh->get_conf("basepath"));
    
    my %color = ( red => [ 255, 0, 0], blue => [ 0, 0, 255], green=> [0, 255, 0], gray=>[100, 100, 100], yellow=>[255, 255, 0]);
    my $img_data;
    if (! $cache->is_valid()) {

	my ($img_data, $img_map_data) = $self->render();
	
	
	$cache->set_image_data($img_data);
	$cache->set_image_map_data($img_map_data);
    }
    
    my $image_html = $cache->get_image_html();
    return $image_html;
}

=head2 render

 Usage:        $vv->render()
 Desc:         renders the vector image on a GD::Image
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub render { 
    my $self = shift;

    my $image_width = $self->{map_image}->get_width();
    my $image_height = $self->{map_image}->get_height();

    my $vector = CXGN::Cview::Chromosome::Vector->new(0, $image_height/3, $image_width/2, $image_height/2);
    
    $vector->set_width(20);
    $vector->set_height($image_height/2);
    $vector->set_X($image_width/2);
    $vector->set_Y($image_height/2);
    $vector->set_length(length($self->get_sequence()));
    
    my $identifier = 1;
    
    foreach my $c (@{$self->get_commands_ref()}) { 
	if ($c->[0] eq "NAME") { $vector->set_name($c->[1]); next(); }
	if ($c->[0] ne "FEATURE") { next(); }
	my $marker = CXGN::Cview::Marker::VectorFeature->new($vector);
	#die " Now adding a marker...";
	$marker->set_range_coords($c->[2], $c->[3]);
	my $label = $c->[1] . " (".$c->[2]."-".$c->[3]." ".$c->[4].")" ;
	if (!$marker->has_range()) { $label = $c->[1]." (".$c->[2].")"; }
	$marker->get_label()->set_name($label);
	$marker->set_name($identifier);
	if ($c->[4] !~ /R|F/i) { $c->[4]="F"; }
	$marker->set_orientation( $c->[4]);
	if (!$c->[5]) { 
	    if ($marker->has_range()) { $c->[5] = "red"; }
	    else { $c->[5] = "gray"; }
	}

	$marker->set_color(@{$self->get_color($c->[5])});
	$marker->get_label()->set_text_color(@{$self->get_color($c->[5])});
	$marker->get_label()->set_line_color(@{$self->get_color($c->[5])});
	$marker->get_label()->set_url("");
	if ($c->[6] eq "hilite") { $marker->get_label()->set_hilited(1); }
	$vector->add_marker($marker);
	$vector->set_caption($self->{map_image}->get_name());
	$identifier++;
    }
	
    $self->{map_image}->add_chromosome($vector);
    
    $vector->layout();
    
    my $img_data = $self->{map_image}->render_png_string();
    my $img_map_data = $self->{map_image}->get_image_map();

    return ($img_data, $img_map_data);
}

=head2 popular_6bp_enzymes

 Usage:        my @enzymes = $vv->popular_6bp_enzymes()
 Desc:         returns a list of popular 6bp enzymes
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub popular_6bp_enzymes { 
    return qw | ClaI EcoRI EcoRV SmaI SmaIII HindIII BamHI KpnI SalI ScaI SphI PstI NotI XbaI XhoI SacI |;
}

=head2 popular_4bp_enzymes

 Usage:        my @enzymes = $vv->popular_4bp_enzymes()
 Desc:         returns a list of popular 4bp enzymes
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub popular_4bp_enzymes { 
    return qw | MboI AluI HaeIII Sau3A TaqI |;

}

=head2 get_color

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_color {
    my $self = shift;
    my $color = shift;
    my %color = ( red => [ 255, 0, 0], blue => [ 0, 0, 255], green=> [0, 255, 0], gray=>[100, 100, 100], yellow=>[255, 255, 0]);
    return $color{$color};

}



return 1;
