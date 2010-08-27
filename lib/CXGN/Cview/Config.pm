package CXGN::Cview::Config;
use CatalystX::GlobalContext '$c';
use Moose;

=head1 NAME

CXGN::Cview::Config - Configuration for Cview

=head1 DESCRIPTION

Provides a backward-compatible wrapper to replace CXGN::VHost and provides and
abstraction for changing how configuration works in the future.

=head1 AUTHOR(S)

Jonathan "Duke" Leto

=cut

=head2 get_conf

 Usage: my $conf = CXGN::Cview::Config->new;
        my $stuff = $conf->get_conf('stuff')

=cut

sub get_conf {
    my ($self,$key) = @_;
    return $c->config->{$key};
}

1;
