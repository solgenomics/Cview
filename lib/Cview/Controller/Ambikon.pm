
package Cview::Controller::Ambikon;

use Moose;

BEGIN { extends 'Catalyst::Controller::REST'; }

use Ambikon::Xref;
use Ambikon::XrefSet;
use CXGN::Cview::ChrMarkerImage;

sub auto :Args(0) { 
    my ($self, $c) = @_;
    $c->forward('/cview/auto');
}

sub xrefs : Local : ActionClass('REST') { }

sub xrefs_GET :Path('/cview/ambikon/xrefs/search') :Args(0) { 
    my ($self, $c) = @_;

    my $q = $c->req->param('q');

    if ($q =~ /^SGN-M\d+$/) { 
    
	$self->status_ok( $c,
	    entity => Ambikon::XrefSet->new({ 
		xrefs => [ $self->marker_xrefs($c, $q ) ],
	    }),
        );
    }
    else {
	print STDERR "BAD REQUEST!\n\n\n";
	$self->status_bad_request( $c, message=>"BAD REQUEST!" );
    }
					      
}

sub marker_xrefs {
    my $self = shift;
    my $c = shift;
    my $q = shift;
    
    my @xrefs;

    my $marker_id = $q;
    $marker_id =~ s/SGN-M//ig;
    
    my $h = $c->stash->{dbh}->prepare("SELECT distinct(marker_location.map_version_id), lg_name, alias, map.short_name FROM sgn.marker_alias join sgn.marker_experiment using(marker_id) JOIN sgn.marker_location using(location_id) JOIN sgn.linkage_group using(lg_id) join sgn.map_version on(map_version.map_version_id=sgn.marker_location.map_version_id) join sgn.map using(map_id) where map_version.current_version='T' and marker_id=?");
    print STDERR "querying the database for marker_id $marker_id...\n";
    $h->execute($marker_id);

    while (my ($map_version_id, $lg_name, $alias, $short_name) = $h->fetchrow_array()) { 
	print STDERR "identified for $alias: map_version_id $map_version_id, chr $lg_name...\n";
	
	my $map = CXGN::Cview::MapFactory->new($c->stash->{dbh})->create({map_version_id=>$map_version_id});
	my $marker_name = CXGN::Marker->new($c->stash->{dbh}, $marker_id)->name_that_marker();

	CXGN::Cview::ChrMarkerImage->new(
	    "", 250, 150, $c->stash->{dbh}, $lg_name, $map, $marker_name,
	    $c->get_conf("basepath"),  $c->get_conf('tempfiles_subdir')."/cview",
	    );
            my ( $image_path, $image_url ) =
              $chromosome->get_image_filename();
            my $chr_link =
              qq|<img src="$image_url" usemap="#map$count" border="0" alt="" />|;
            $chr_link .=
              $chromosome->get_image_map("map$count") . "<br />";
            $chr_link .= $map_name;


	my $a = Ambikon::Xref->new( { url => "/cview/map.pl?map_version_id=$map_version_id&chr_nr=$lg_name", 
				      text => "$alias on map $short_name"
				    } );
	push @xrefs, $a;

    }
    return @xrefs;
    
}

    
1;
    
