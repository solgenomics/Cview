
=head1 NAME

CXGN::Cview::MapImage - an interface for Cview map images.

=head1 DESCRIPTION

Inherits from L<CXGN::Cview::ImageI>. 

=head1 AUTHOR(S)

Lukas Mueller (lam87@cornell.edu)

=head1 FUNCTIONS


=cut

use strict;

package CXGN::Cview::MapImage;

use GD;
use CXGN::Cview::ImageI;

use base qw / CXGN::Cview::ImageI /;



=head2 function MapImage::new()
    
    MapImage -> new(map name, map_width [pixels], map_height [pixels])
    
    Creates a new map object.

=cut

sub new { 
    my $class = shift;
    my $map_name = shift;
    my $width = shift;  # the image width in pixels
    my $height = shift; # the image height in pixels
    
    my $self = $class->SUPER::new();
    GD::Image->trueColor(1);
    my $image = GD::Image->new($width, $height);
   # $image || die "Can't generate image...";
    $self->set_image($image); # make it truecolor (the last argument =1)
    $self->{chromosomes} = ();
    $self->{chr_links} = ();
    $self->set_width($width);
    $self->set_height($height);
    $self->set_name($map_name);

    return $self;
}




=head2 function render()

    $map -> render()   # takes no parameters

    renders the map on the internal image.

=cut

sub render {
    my $self = shift;
    # the first color allocated is the background color.
    $self->{white} = $self->get_image()->colorResolve(255,255,255);
    $self->get_image()->filledRectangle(0,0 ,$self->{width}, $self->{height}, $self->{white});

    
    foreach my $c (@{$self->{chromosomes}}) {
      #print STDERR "Calling layout...\n";
	$c -> layout();
	$c -> draw_chromosome($self->get_image());
    }
    foreach my $l (@{$self->{chr_links}}) {
	$l -> render($self->get_image());
    }
    foreach my $r (@{$self->{rulers}}) {
	$r -> render($self->get_image());
    }
    foreach my $p (@{$self->{physical}}) {
	$p -> render($self->get_image());
    }
    foreach my $o (@{$self->{image_objects}}) { 
	$o -> render ($self->get_image());
    }
    
    foreach my $c (@{$self->{chromosomes}}) { 
	
	$c -> render_markers($self->get_image());
    }
}



=head2 function render_png()

    $map->render_png(); # no parameters

    renders the image as a png to STDOUT.

=cut

sub render_png {
    my $self= shift;
    $self->render();
    print $self->get_image()->png();
}

=head2 function render_png_string()

    renders the png and returns it as a string.

=cut



sub render_png_string {
    my $self =shift;
    $self->render();
    return $self->get_image()->png();
}

=head2 function render_png_file()

    $map->render_png_file ($filepath)

    render the image as a png saving the image at $filepath.

=cut

sub render_png_file {
    my $self = shift;
    my $filename = shift;
    $self -> render();
    open my $f, '>', $filename
        or die "Can't open $filename for writing!!! Check write permission in dest directory.";
    print $f $self->get_image()->png();
}

=head2 function render_jpg()

    $map->render_jpg()

    renders the image as a jpg to STDOUT.

=cut


sub render_jpg {
    my $self = shift;
    $self->render();
    print $self->get_image()->jpeg();
}    

=head2 function render_jpg_file()

    $map->render_jpg_file(filepath)

    renders the image as a jpg file at filepath

=cut

sub render_jpg_file {
    my $self = shift;
    my $filename = shift;
    #print STDERR "cview.pm: render_jpg_file.\n";
    $self ->render();
    #print STDERR "rendering. Now writing file..\n";
    open (F, ">$filename") || die "Can't open $filename for writing!!! Check write permission in dest directory.";
    print F $self->get_image()->jpeg();
    close(F);
    #print STDERR "done...\n";
}


sub render_gif_file { 
    my $self = shift;

    my $filename = shift;
    $self->render();
    open(F, ">$filename") || die "Can't open $filename for writing. Check permissions.";
    print F $self->get_image()->gif();
    close(F);
}

=head2 function get_image_map()

    $string = $map->get_image_map()

    Get the image map as a string. Calls get_image_map for all the objects contained 
    in the MapImage.

=cut 

sub get_image_map {
    my $self = shift;
    my $map_name = shift;
    #print STDERR "get_image_map map\n";
    #as of 1/6/07, must use both NAME and ID to have both Mozilla and IE conformance, although standard xhtml uses ID only -- Evan
    my $imagemap = "<map name=\"$map_name\" id=\"$map_name\">";
    foreach my $c (@{$self->{chromosomes}}) {
	#print STDERR "getting the chromosome image maps...\n";
	$imagemap .= $c -> get_image_map();
    }
    foreach my $p (@{$self->{physical}}) {
	$imagemap .= $p -> get_image_map();
    }
    
	#in xhtml 1.0+, a <map> must have child nodes, so if it doesn't, don't print it -- Evan, 1/6/07
	if(scalar(@{$self->{chromosomes}}) > 0 or scalar(@{$self->{physical}}) > 0)
	{
		return $imagemap."</map>";
	}
	else
	{
		return "";
	}
}

=head2 function add_chromosome()

    $map->add_chromosome($chromosome_object)

    adds the chromosome object to the map. Obviously works also for subclasses of 
    chromosomes such as physical and IL. 

=cut

sub add_image_object { 
    my $self = shift;
    my $object = shift;
    push @{$self->{image_objects}}, $object;
}

sub add_chromosome {
    my $self = shift;
    my $chromosome = shift;
   
    push @{$self->{chromosomes}}, $chromosome;
}

sub get_chromosomes  { 
    my $self = shift;
    return @{$self->{chromosomes}};
}

=head2 function add_chr_link()

    $map->add_chr_link($chr_link)

    adds the chromosome linking object $chr_link to the map.

=cut

sub add_chr_link {
    my $self = shift;
    my $chr_link = shift;
    push @{$self->{chr_links}}, $chr_link;
}

=head2 function add_ruler()

    $map->add_ruler($ruler)

    adds the ruler $ruler to the map.

=cut 
 
sub add_ruler {
    my $self = shift;
    my $ruler = shift;
    push @{$self->{rulers}}, $ruler;
}

=head2 function add_physical()

    $map->add_physical($physical)

    adds the physical map $physical to the map. 

    Note: The physical object has to be populated both in terms of marker 
    positions and physical map.

=cut

sub add_physical {
    my $self = shift;
    my $physical = shift;
    push @{$self->{physical}}, $physical;
}


return 1;
