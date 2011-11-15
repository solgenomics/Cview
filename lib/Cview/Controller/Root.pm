package Cview::Controller::Root;

use Moose;
BEGIN { extends 'Catalyst::Controller'; }

use CXGN::DB::Connection;
#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config->{namespace} = '';

=head1 NAME

CviewApp::Controller::Root - Root Controller for CviewApp

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=cut

=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    # Hello World
    $c->response->body( $c->welcome_message );
}


sub cview_map :Path('/cview/map/version') :Args(5) { 
    my $self = shift;
    my $c = shift;

    my $map_id= shift;
    my $hilite = shift;
    my $size = shift;
    my $force = shift;
    my $map_items = shift;
    my $dbh = CXGN::DB::Connection->new();
    
    $c->stash->{dbh} = $dbh;
    $c->stash->{map_id} = $map_id;
    $c->stash->{map_version_id} = $map_id;
    $c->stash->{hilite} = $hilite;
    $c->stash->{size} = $size;
    $c->stash->{physical} = 0;
    $c->stash->{force} = $force;
    $c->stash->{referer} = "";
    $c->stash->{tempdir} = '/static/images/';
    print STDERR "URI: ".$c->uri_for('/static/images/')."\n";
    $c->stash->{basepath} = '/home/mueller/cxgn/CviewApp/root';
    $c->stash->{map_items} = $map_items;
    $c->stash->{template} = '/map/index.mas';


}

sub cview_chromosome :Path("/cview/chromosome/") :Args(0) { 
    my $self = shift;
    my $c = shift;


    
}

sub default :Path {
    my ( $self, $c ) = @_;
    $c->response->body( 'Page not found :-(' );
    $c->response->status(404);
    
}

=head2 end

Attempt to render a view, if needed.

=cut 

sub end : ActionClass('RenderView') {}


=head2 auto

runs for every request. 
Makes $c valid everywhere (to be compatible with the current configuration)

=cut

sub auto : Private {
    my ($self, $c) = @_;
    CatalystX::GlobalContext->set_context( $c );
    $c->stash->{c} = $c;
    1;
}


=head1 AUTHOR

Lukas Mueller,,,

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
