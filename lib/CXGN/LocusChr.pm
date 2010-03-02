use strict;

use CXGN::Cview;
use CXGN::Cview::Chromosome;
use CXGN::Cview::Cview_data_adapter;
use CXGN::Configuration;
use CXGN::Cview::MapImage;

package CXGN::Cview::LocusChr;

use base qw/ CXGN::Cview::MapImage /;

=head2 new

 Usage:
 Desc:
 Ret:
 Args:
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
    $self->set_dbh($dbh);
    $self->set_lg_name($lg_name);
    $self->set_map($map);
    $self->set_marker_name($marker_name);
    return $self;
}


=head2 get_image_filename

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_image_filename {
    my $self=shift;

    my $filename = time().".$$.png";    
    my $vhost_conf=CXGN::VHost->new();
    my $image_path = $vhost_conf->get_conf('basepath').$vhost_conf->get_conf('tempfiles_subdir')."/cview/$filename";
    my $image_url = $vhost_conf->get_conf('tempfiles_subdir')."/cview/$filename";
   
    my $chromosome= CXGN::Cview::Chromosome->new($self->get_lg_name(), 100,50, 25 );
    CXGN::Cview::Cview_data_adapter::fetch_chromosome($self->get_dbh(), $chromosome, $self->get_map(), $self->get_lg_name());
    $chromosome->set_caption($self->get_lg_name);
    $chromosome->set_width(12);
    my $map_id= $self->get_map()->map_id();
    my $marker_name= $self->get_marker_name();
    my $lg_name=$self->get_lg_name();
    $chromosome->set_url("/cview/view_chromosome.pl?map_id=$map_id&amp;chr_nr=$lg_name&amp;hilite=$marker_name");

    my @markers= $chromosome->get_markers();
  
    foreach my $m(@markers) {
	if ($m->get_name() eq $self->get_marker_name()) { 
	    $m->hilite();
	    $m->set_label_spacer(20);
	}
	else { $m->hide_label(); }
	$m->set_color(150, 80, 50);
    }
    
    $self->add_chromosome($chromosome);

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



return 1;


