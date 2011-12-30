
package Cview::Controller::Ambikon;

use Moose;

BEGIN { extends 'Catalyst::Controller::REST'; }

use Ambikon::Xref;
use Ambikon::XrefSet;

sub xrefs : Local : ActionClass('REST') { }

sub xrefs_GET :Path('/cview/ambikon/xrefs/search') :Args(0) { 
    my ($self, $c) = @_;

    my $q = $c->req->param('q');

    if ($q =~ /^SGN-M\d+$/) { 
    
	$self->status_ok( $c,
	    entity => Ambikon::XrefSet->new({ 
		xrefs => [ $self->marker_xrefs( $q ) ],
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
    my $q = shift;
    
    my @xrefs;

    my $a = Ambikon::Xref->new( { url => '/cview/map.pl?map_id=9&chr_nr=4', 
				  text => $q,
				} );
    push @xrefs, $a;

    return @xrefs;
    
}

    
1;
    
