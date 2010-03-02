
=head1 NAME

CXGN::Cview::Label::SequencedBACLabel - a class for drawing sequence BAC labels.

=head1 DESCRIPTION

The sequenced BAC labels should always be rendered in yellow. Therefore, this class overrides the get_text_color() and the get_line_color() methods of the CXGN::Cview::Label class to always returns yellow. The setter has no effect in this class. This class is used by the CXGN::Cview::Marker::SequencedBAC class.

=head1 AUTHOR(S)

Lukas Mueller (lam87@cornell.edu)

=head1 FUNCTIONS

This class implements the following functions:

=cut

use strict;

use CXGN::Cview::Label;

package CXGN::Cview::Label::SequencedBACLabel;

use base qw / CXGN::Cview::Label /;


=head2 function new()

  Synopsis:	constructor
  Arguments:	same as CXGN::Cview::Label class.
  Returns:	
  Side effects:	
  Description:	

=cut

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    return $self;
}

=head2 function get_text_color()

  Synopsis:	overridden to always return yellow.
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub get_text_color { 
    my $self = shift;
    return (200, 200, 80);
}

=head2 function get_line_color()

  Synopsis:	overridden to always return yellow.
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub get_line_color { 
    my $self = shift;
    return (200, 200, 80);
}


1;

