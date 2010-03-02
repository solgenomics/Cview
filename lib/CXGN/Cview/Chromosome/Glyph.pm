
=head1 NAME

CXGN::Cview::Chromosome::Glyph - a class for drawing chromosome glyphs.

=head1 DESCRIPTION

The chromosomes are represented as small glyphs that can be partially filled with a color to represent the state of a chromosome sequencing project, for example. This class inherits from L<CXGN::Cview::Chromosome>. 

=head1 SEE ALSO

See also the documentation in L<CXGN::Cview>.

=head1 AUTHOR(S)

Lukas Mueller (lam87@cornell.edu)

=head1 FUNCTIONS


=cut

1;

use strict;
use CXGN::Cview::Chromosome;


package CXGN::Cview::Chromosome::Glyph;

use base qw |  CXGN::Cview::Chromosome |; 

=head2 function new()

  Synopsis:	constructor
  Arguments:	see L<CXGN::Cview::Chromosome>

=cut

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    $self->set_outline_color(0,0,0);
    $self->set_color(255, 255, 255);
    $self->set_hilite_color(50, 255, 50);
    $self->set_width(10);
    $self->{curved_height} = 8;
    $self->set_track_colors( [  0, 255,   0], 
			     [200, 255, 200], 

			     [200, 200, 200], 
			     [100, 150, 100], );
    return $self;
    
}

=head2 function set_fill_level()

  Synopsis:	
  Arguments:	the track number and the fill level of the chromosome in % 
                (eg, 50, not 0.5, to represent 50%).
                tracks: 0 for available and htgs3
                        1 for available and < htgs3
                        2 for complete, not submitted
                        3 for in progress
  Returns:	nothing
  Side effects:	the chromosome will be displayed with % filled in.
                For fill levels specified above 100, the fill level value
                will be capped at 100. (Yay! nice problem to have!).
  Description:	

=cut

sub set_fill_level {
    # 
    # set the percentage level to be displayed as finished in the chromosome. 50% would be 50, not 0.5
    #
    my $self=shift;
    my $track = shift;
    my $level = shift;
    
    if ($level>100) { $level = 100; }
    if (!defined($track)) { die "set_fill_level: Need a track"; }
    $self->{fill_level}->[$track] = $level;
}

sub get_fill_level { 
    my $self = shift;
    my $track = shift;
    return $self->{fill_level}->[$track];
}

=head2 function set_bac_count()

  Synopsis:	
  Arguments:	an integer reflecting the BACs sequenced.
                is displayed below the glyph.
  Returns:	
  Side effects:	
  Description:	

=cut


sub set_bac_count { 
    #
    # set the number of bacs sequenced for that chromosome
    #
    my $self=shift;
    $self->{bac_count} = shift;
}

=head2 accessors get_track_colors(), set_track_colors()

 Usage:        $glyph->set_track_colors([255,255,0], [0,0,255]);
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_track_colors {
  my $self=shift;
  return @{$self->{track_colors}};

}

sub set_track_colors {
  my $self=shift;
  @{$self->{track_colors}}=@_;
}

=head2 get_track_color

 Usage:        my ($r, $g, $b) = $glyph->get_track_color($track1)
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_track_color { 
    my $self = shift;
    my $track = shift;
    return $self->{track_colors}->[$track];
}

=head2 function render()

  Synopsis:	
  Arguments:	a GD image object.
  Returns:	
  Side effects:	generates the image representing the glyph
  Description:	

=cut

sub render {
    # 
    # draw the chromosome
    #
    my $self= shift;
    
    $self->_calculate_scaling_factor();
    
    my $image = shift;
    
    # allocate colors
    #
    my $outline_color = $image -> colorResolve($self->{outline_color}->[0], $self->{outline_color}->[1], $self->{outline_color}->[2]);
    my $hilite_color = $image -> colorResolve($self->{hilite_color}->[0], $self->{hilite_color}->[1], $self->{hilite_color}->[2]);
    my $color = $image -> colorResolve($self->{color}->[0], $self->{color}->[1], $self->{color}->[2]);
    
    my $halfwidth = $self ->{width}/2;
    
    $image -> line($self->get_horizontal_offset() - $halfwidth, $self->get_vertical_offset() , $self->get_horizontal_offset()-$halfwidth, $self->get_vertical_offset()+$self->{height}, $outline_color);
    $image -> line($self->get_horizontal_offset() + $halfwidth, $self->get_vertical_offset() , $self->get_horizontal_offset()+$halfwidth, $self->get_vertical_offset()+$self->{height}, $outline_color);
    $image -> arc ($self->get_horizontal_offset(), $self->get_vertical_offset(), $self->{width}, $self->{curved_height}, 180, 0, $outline_color);
    $image -> arc ($self->get_horizontal_offset(), $self->get_vertical_offset()+$self->{height}, $self->{width}, $self->{curved_height}, 0, 180, $outline_color);
    $image -> fill ($self->get_horizontal_offset(), $self->get_vertical_offset(), $color);
    
    my @track_color = ();
    foreach my $track (0..(scalar($self->get_track_colors())-1)) { 
	
	#if ($track ==4) { die "TRACK=$track!!!!!"; }
	my $colorRef = $self->get_track_color($track);
	#print STDERR "TRACK COLOR: $colorRef->[0], $colorRef->[1], $colorRef->[2]\n";
	$track_color[$track] = $image->colorResolve($colorRef->[0], $colorRef->[1], $colorRef->[2]);
    }

    my $start_level = $self->get_vertical_offset() + $self->mapunits2pixels(0);
    foreach my $track (0..(scalar($self->get_track_colors())-1)) { 
	my $level = $self->get_vertical_offset() + $self->mapunits2pixels($self->get_fill_level($track));
	#print STDERR "LEVEL: $level\n";

	$image ->filledRectangle($self->get_horizontal_offset()-$halfwidth+1, $level,
				 $self->get_horizontal_offset()+$halfwidth-1, $start_level, 
				 $track_color[$track]);

	if ($self->get_fill_level($track) >= 99) { 
	    $image->fill($self->get_horizontal_offset(), $self->get_vertical_offset()-2, $track_color[$track]);
	}
	$start_level = $level;
    }

    $image->fill($self->get_horizontal_offset(), $self->get_vertical_offset()+$self->mapunits2pixels(0)+1, $track_color[0]);
    
    if ($self->{caption}) {
	my $bigfont = GD::Font->Large();
	$image -> string($bigfont, $self->get_horizontal_offset()- $bigfont->width() * length($self->{caption})/2, $self->get_vertical_offset()-$bigfont->height()-$self->{curved_height}/2, "$self->{caption}", $outline_color);
    }
    my $percent_finished =  $self->get_fill_level(2);
#    my $percent_finished_caption = (sprintf "%3d", $self->get_fill_level(0)."\%"); #+$self->get_fill_level(1))."\%";
    my $percent_finished_caption = (sprintf "%3d", $percent_finished)."\%"; 
    $image -> string($self->{font}, $self->get_horizontal_offset()- $self->{font}->width() * length($percent_finished_caption)/2, $self->get_vertical_offset() + $self->get_height()+$self->{curved_height}, "$percent_finished_caption", $outline_color);
    
    
}

sub draw_chromosome { 
    my $self = shift;
    my $image = shift;
    $self->render($image);
}
    
sub mapunits2pixels { 
    my $self = shift;
    my $mapunits = shift;
    
    my $pixels = $self->get_height() * (100-$mapunits)/100;
    #print STDERR "Mapunits2pixels: $mapunits are $pixels pixels\n";
    return $pixels;
}
