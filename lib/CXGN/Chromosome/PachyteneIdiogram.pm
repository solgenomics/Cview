



=head1 NAME

CXGN::Cview::PachyteneIdiogram - a class for drawing a schematic representation of chromosomes in the pachytene phase.

=head1 DESCRIPTION
    
This object renders a pachytene idiogram, which are currently only defined for each of the 12 tomato chromosomes. It inherits from CXGN::Cview::chromosome. Inherits from L<CXGN::Cview::Chromosome>. The description of the tomato pachytene chromosomes is available in a flat file version, and there is a function in L<CXGN::Cview::Cview_data_adatper> to load it.

=head1 SEE ALSO

See also the documentation in L<CXGN::Cview>.

=head1 AUTHOR(S)

Lukas Mueller (lam87@cornell.edu)

=head1 FUNCTIONS


=cut

use strict;

use CXGN::Cview::Chromosome;
use CXGN::Cview::Ruler::PachyteneRuler;

package CXGN::Cview::Chromosome::PachyteneIdiogram;

use base qw( CXGN::Cview::Chromosome );

=head2 function new()
    
Constructor. Takes the same parameters as CXGN::Cview::Chromosome::new().
    
=cut

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    $self->set_outline_color(0,0,0);
    $self->set_color(255, 255, 255);
    $self->set_hilite_color(50, 255, 50);
    $self->set_width(10);
    $self->set_vertical_offset_top_edge();
    $self->{curved_height} = 8;
    
    $self->{feature_color} = { 
	short_arm => "100 ,100,250",
	long_arm => "100,100,250",
	heterochromatin => "75,75,250",
	telomere => "25,75,200",
	satellite => "75,75,250",
    };
    $self->{feature_width} = {
	short_arm => 6,
	long_arm => 6,
	heterochromatin => 10,
	telomere => 8,
	satellite => 8,
    };
    
    @{$self->{render_order}} = ( 
				 "short_arm", 
				 "long_arm", 
				 "heterochromatin", 
				 "telomere", 
				 "satellite" 
				 );

    my $r = CXGN::Cview::Ruler::PachyteneRuler->new();
    $self->set_ruler($r);
    return $self;
}

=head2 function add_feature()

Add a feature to the pachytene idiogram. Allowed feature types are restricted to: 
telomere, satellite, long_arm, short_arm etc. This is used to construct the 
image representation of the idiogram.

Note: feature types are rendered in a specific order. See new().

=cut

sub add_feature {
    my $self = shift;
    my $type = shift;
    my $start_coord = shift;
    my $end_coord = shift;
    
    #print STDERR "Cview::pchytene::add_feature: Adding feature  $type, $start_coord, $end_coord\n";

    if (!exists($self->{feature_color}->{$type})) { 
	print STDERR "Cview.pm [pachytene_idiogram]: Unknown feature type: $type\n";
    }
    if ($type eq "short_arm") { 
	$self->set_short_arm_length(abs($end_coord-$start_coord));
	#print STDERR  "short arm length: $self->{short_arm_length}\n";
    }
    if ($type eq "long_arm") { 
	$self->set_long_arm_length(abs($end_coord-$start_coord));
    }
    
    my %h = ( type => $type,
	      start_coord => $start_coord,
	      end_coord => $end_coord,
	      );
    
    push @{$self->{features}}, \%h;
}

#
# Note: _calculate_scaling_factor is overridden to account for the differences in the representation
# of a pachytene chromosome.
#
sub _calculate_scaling_factor { 
    my $self = shift;
    $self->{scaling_factor} = ($self->get_height()/($self->get_short_arm_length()+$self->get_long_arm_length()));
    #print STDERR "pachytene_idiogram: _calculate_scaling_factor::scaling factor: $self->{scaling_factor}\n";
}

=head2 function mapunits2pixels()

Override the chromosome mapunits2pixels to reflect the different unit and representation of this map.

=cut

sub mapunits2pixels { 
    my $self = shift;
    my $percent = shift;
    my $pixels = 0;
    # note: give the pixels from the vertical_offset (centromere) to the percent marker positioin
    my $shortarmratio = $self->get_short_arm_length()/($self->get_short_arm_length()+$self->get_long_arm_length());
    my $longarmratio = 1-$shortarmratio;
    if ($percent < 0) { 
	$pixels = $self->get_height() * $shortarmratio * $percent / 100;
	# the result is a negative number, always measured from the centromere
    }
    else { 
	$pixels = $self->get_height()* $longarmratio * $percent / 100;
    }
    return $pixels;
}

=head2 function get_short_arm_length()

 Synopsis:	
 Arguments:     None	
 Returns:       the length of the short arm in arbitrary units.
 Side effects:	
 Description:	

=cut

sub get_short_arm_length { 
    my $self=shift;
    return $self->{short_arm_length};
}

=head2 function set_short_arm_length()

 Synopsis:	
 Arguments:	
 Returns:	
 Side effects:	
 Description:	

=cut

sub set_short_arm_length { 
    my $self=shift;
    $self->{short_arm_length}=shift;
}

=head2 function get_long_arm_length()

 Synopsis:	
 Arguments:	
 Returns:	The short arm length in arbitrary units.
 Side effects:	
 Description:	

=cut

sub get_long_arm_length	 { 
    my $self=shift;
    return $self->{long_arm_length};
}

=head2 function set_long_arm_length()

 Synopsis:	
 Arguments:	
 Returns:	
 Side effects:	
 Description:	

=cut

sub set_long_arm_length	 { 
    my $self=shift;
    $self->{long_arm_length}=shift;
}



sub draw_chromosome { 
    my $self  =shift;
   #print STDERR "Rendering the PACHYTENE business...\n";
    my $image = shift;
    $self->_calculate_scaling_factor();
    
    # calculate ruler properties...
    #
    $self->get_ruler()->set_height($self->get_height());
    $self->get_ruler()->set_short_arm_ruler_pixels($self->get_short_arm_length()*$self->get_scaling_factor());
    $self->get_ruler()->set_long_arm_ruler_pixels($self->get_long_arm_length()*$self->get_scaling_factor());

    #$image -> line(0, $self->get_vertical_offset(), 100, $self->get_vertical_offset(), $image->colorResolve(0, 0, 0));


    # features have to be rendered in the correct order -- first the arms and then the rest.
    foreach my $type (@{$self->{render_order}}) { 
	foreach my $f (@{$self->{features}}) {
	    if ($f->{type} eq $type) { 
		#print STDERR "Rendering feature $f->{type}, $f->{start_coord}, $f->{end_coord} | Color: $self->{feature_color}->{$f->{type}}\n";
		if (!exists($self->{feature_color}->{$f->{type}})) { print STDERR "$f->{type} HAS NO ASSOCIATED FEATURE COLOR!\n";}
		my ($red, $green, $blue) = split /\,/, $self->{feature_color}->{$f->{type}};
		my $color = $image-> colorResolve($red, $green,$blue);

		my $x = $self->get_horizontal_offset() - $self->{feature_width}->{$f->{type}}/2;
		my $y = $self->get_vertical_offset()+$f->{start_coord}*$self->get_scaling_factor();
		my $lx = $self->get_horizontal_offset()+ $self->{feature_width}->{$f->{type}}/2;
		my $ly = $self->get_vertical_offset()+$f->{end_coord}*$self->get_scaling_factor();

		#print STDERR "Featurescreencoords: $f->{type}, $x, $y, $lx, $ly, $color\n";
		# gd can't draw a filled rectangle with $y > $ly, so swap if that's the case.
		if ($y > $ly)  { my $z=$y; $y=$ly; $ly=$z; }
		$image -> filledRectangle(
					  $x, 
					  $y, 
					  $lx,  
					  $ly, 
					  $color);
	    }
	} 
    }
    
    $self->draw_centromere($image);
    
    $self->draw_caption($image); 
}

sub render_markers { 
    my $self = shift;
    my $image = shift;

    my @m = $self->get_markers();
    foreach my $m (@m) { 
	#print STDERR "Drawing marker ".$self->get_name()."\n";
	$m -> render($image);
    }
    
}

=head2 draw_centromere

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub draw_centromere {
    my $self = shift;
    my $image = shift;
    my $centromere_color = $image->colorResolve(80, 80, 150);
    $image->filledArc($self->get_X(),$self->get_Y(),10,10,0,360, $centromere_color);
}



=head2 function set_vertical_offset_centromere()

This function sets the vertical offset to the centromere (default).

=cut

sub set_vertical_offset_centromere { 
    my $self = shift;
    $self->{vertical_offset_type} = "centromere";    
}

sub set_vertical_offset_top_edge { 
    my $self = shift;
    $self->{vertical_offset_type} = "top_edge"; 
}
    

# sub get_vertical_offset { 
#     my $self = shift;
#     if ($self->{vertical_offset_type} eq "top_edge") { 
# 	return $self->SUPER::get_vertical_offset()+100;
#     }
# }

# The following method is overridden because the caption is rendered
# at a slightly different location (the vertical offset defines the 
# centromere and not the top edge)
#
sub draw_caption { 
    my $self = shift;
    my $image = shift;
    
    my $outline_color = $image -> colorResolve(
					       $self->{outline_color}[0], 
					       $self->{outline_color}[1], 
					       $self->{outline_color}[2]
					       );
    my $bigfont = GD::Font->Large();
    $image -> string(
		     $bigfont, 
		     $self->get_horizontal_offset()- $bigfont->width() * length($self->get_caption())/2, 
		     $self->get_vertical_offset()-$self->{scaling_factor}*$self->{short_arm_length}-$bigfont->height(), 
		     $self->get_caption(), $outline_color );

    #$image->string($bigfont, 50, 50, "HELLO", $outline_color);
}

sub layout { 
    my $self=shift;

    print STDERR "EXECUTING layout() in PachyteneIdiogram...\n";
    # determine the offset type
    if ($self->{vertical_offset_type} eq "top_edge") { 
	my $new_offset = $self->get_vertical_offset()-$self->mapunits2pixels(-100);
	#print STDERR "Setting the vertical offset to $new_offset..\n";
	$self->set_vertical_offset($new_offset);
    }

    $self->_calculate_scaling_factor();
    $self->distribute_labels();
    

}

sub get_enclosing_rect { 
    my $self = shift;
    if ($self->{vertical_offset_type} eq "top_edge") { 
	$self->set_vertical_offset($self->get_vertical_offset()-$self->mapunits2pixels(-100));
    }
    return ($self->get_horizontal_offset()-int($self->get_width()/2),
	    $self->get_vertical_offset()+$self->mapunits2pixels(-100),
	    $self->get_horizontal_offset()+int($self->get_width()/2),
	    $self->get_vertical_offset()+$self->mapunits2pixels(100)
	    );

}

return 1;
