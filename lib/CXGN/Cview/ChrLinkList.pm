
=head1 NAME

CXGN::Cview::ChrLinkList - a class to handle a list of CXGN::Cview::ChrLink objects

=head1 AUTHOR

Lukas Mueller <lam87@cornell.edu>

=head1 FUNCTIONS

This class implements the following functions:

=cut

use strict;

package CXGN::Cview::ChrLinkList;

=head2 new

 Usage:        my $link_list = CXGN::Cview::ChrLinkList->new();
 Desc:         generates a new link list object.
 Args:         none
 Side Effects: none
 Example:

=cut

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    return $self;
}

=head2 function add_link()

 Usage:        $link_list->add_link($marker_name, $link_object)
 Desc:         adds another CXGN::Cview::ChrLink object to the list
 Ret:          nothing
 Args:         a marker name [string], a link list object 
               [CXGN::Cview::ChrList]
 Side Effects: the link is added to the list...
 Example:

=cut

sub add_link {
    my $self = shift;
    my $marker_name = shift;
    my $link_object = shift;
    print STDERR "adding link for marker $marker_name...\n";
    $self->{links}->{$marker_name} = $link_object;

}

=head2 function has_link()

 Usage:        my $flag = $map_link->has_link($marker_name)
 Desc:         checks if the marker named $marker_name has
               a corresponding link object in the list
 Ret:          a boolean
 Args:         a marker name [string
 Side Effects: none
 Example:

=cut

sub has_link {
    my $self = shift;
    my $marker_name = shift;
    if (exists($self->{links}->{$marker_name})) { 
	return 1;
    }
    return 0;

}

=head2 function get_link_list()

 Usage:        my @link_list = $link_list->get_link_list()

 Ret:          returns the list of link objects as a list          
 Args:         none
 Side Effects: none
 Example:

=cut

sub get_link_list {
    my $self = shift;
#    if (!exists($self->{links}) || !defined($self->{links})) { 
#	return ();
#    }
    my @link_objects = ();
    foreach my $name (keys(%{$self->{links}})) { 
	print STDERR "Pushing $name...\n\n";
	push @link_objects, $self->{links}->{$name};
    }

    return @link_objects;
}


return 1;
