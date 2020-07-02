package CXGN::Cview::ChrMarkerImage;
=head1 NAME

CXGN::Cview::ChrMarkerImage - a class for drawing small chromosome image with a specific marker highlighted

=head1 DESCRIPTION

Inherits from L<CXGN::Cview::MapImage>.

=head1 AUTHOR(S)

Lukas Mueller (lam87@cornell.edu)
Naama Menda (nm249@cornell.edu)

=head1 FUNCTIONS


=cut

use strict;
use warnings;

use Carp;

use CXGN::Cview;
use CXGN::Cview::Chromosome;
use CXGN::Cview::MapImage;

use File::Temp qw/ tempfile /;
use File::Basename qw/ basename /;
use CXGN::Cview::Config;


use base "CXGN::Cview::MapImage";

=head2 new

 Usage: my $chromosome= CXGN::Cview::ChrmarkerImage->new("map name", width,height,$dbh, $lg_name, $map, $marker_name);
 Desc: 
 Ret: 
 Args: name of a map, width and height of the image in pixles, linkage group name, map object (my $map=CXGN::Map->new($dbh,$map_version_id);), $marker_name.
 Side Effects:
 Example:

=cut

sub new {
    my $class=shift;
    my $name = shift;
    my $width = shift;
    my $height = shift;

    my $self= $class->SUPER::new($name, $width, $height);

    my $dbh=shift;
    my $lg_name= shift;
    my $map = shift;
    my $marker_name= shift;
    my $basedir = shift
        or croak 'must provide basedir';
    my $tempdir = shift
        or croak 'must provide tempdir';

    $self->set_dbh($dbh);
    $self->set_lg_name($lg_name);
    $self->set_map($map);
    $self->set_marker_name($marker_name);
    $self->{basedir} = $basedir;
    $self->{tempdir} = $tempdir;
    
    my $chromosome = $map->get_chromosome($lg_name);

    $chromosome->set_horizontal_offset(50);
    $chromosome->set_vertical_offset(25);
    $chromosome->set_height(100);
    $chromosome->set_caption($self->get_lg_name);
    $chromosome->set_width(12);
    my $map_version_id= $self->get_map()->get_id();
    $marker_name= $self->get_marker_name();
    $lg_name=$self->get_lg_name();
    $chromosome->set_url("/cview/view_chromosome.pl?map_version_id=$map_version_id&amp;chr_nr=$lg_name&amp;hilite=$marker_name");

    my @markers= $chromosome->get_markers();
  
    foreach my $m(@markers) {
        no warnings 'uninitialized';
	if ($m->get_name() eq $self->get_marker_name()) { 
	    $m->hilite();
	    $m->set_label_spacer(20);
	}
	else { $m->hide_label(); }
	$m->set_color(150, 80, 50);
    }
    
    $self->add_chromosome($chromosome);
 
    return $self;
}


=head2 get_image_filename

 Usage: my ($image_path, $image_url)=$chromosome->get_image_filename();
 Desc: returns a tmp .png file of the chromosome image object
 Ret: $image_path, $image_url
 Args:
 Side Effects:
 Example:

=cut

sub get_image_filename {
    my $self=shift;

    my $vhost_conf=CXGN::Cview::Config->new;
    my $dir = $vhost_conf->get_conf('basepath').$vhost_conf->get_conf('tempfiles_subdir')."/cview/";
    if ( !-d $dir ) {
        mkdir $dir;
    }

    my $template = 'tempXXXX'; #not needed. The function tempfile seems to generate a default TEMPLATE 'XXXXXXXXXX$suffix'
    my $suffix = '.png';
    my ($fh, $image_path) = File::Temp::tempfile( DIR => $dir,
						  SUFFIX => $suffix
						  );   
    
    #my $filename = time().".$$.png";    
    
    my $filename = File::Basename::basename($image_path);
 
    #print STDERR "IMAGE PATH: $image_path\n";
    my $image_url = File::Spec->catfile($self->{tempdir}, $filename);

    $self -> render_png_file($image_path);
    return ($image_path, $image_url);

}

=head2 get_dbh

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_dbh {
  my $self=shift;
  return $self->{dbh};

}

=head2 set_dbh

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_dbh {
  my $self=shift;
  $self->{dbh}=shift;
}



=head2 get_lg_name

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_lg_name {
  my $self=shift;
  return $self->{lg_name};

}

=head2 set_lg_name

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_lg_name {
  my $self=shift;
  $self->{lg_name}=shift;
}

=head2 get_map

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_map {
  my $self=shift;
  return $self->{map};

}

=head2 set_map

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_map {
  my $self=shift;
  $self->{map}=shift;
}


=head2 get_marker_name

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_marker_name {
  my $self=shift;
  return $self->{marker_name};

}

=head2 set_marker_name

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_marker_name {
  my $self=shift;
  $self->{marker_name}=shift;
}


1;


