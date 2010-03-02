
use strict;

package CXGN::Cview::Legend;

=head2 new

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub new {
    my $class = shift;
    my $viewer = shift;
    my $self = bless {}, $class;
    $self->set_viewer($viewer);
    return $self;
}

=head2 accessors get_viewer, set_viewer

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_viewer {
  my $self = shift;
  return $self->{viewer}; 
}

sub set_viewer {
  my $self = shift;
  $self->{viewer} = shift;
}



=head2 accessors get_legend_html, set_legend_html

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_legend_html {
  my $self = shift;
  return $self->{legend_html}; 
}

sub set_legend_html {
  my $self = shift;
  $self->{legend_html} = shift;
}

=head2 accessors get_name, set_name

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_name {
  my $self = shift;
  return $self->{name}; 
}

sub set_name {
  my $self = shift;
  $self->{name} = shift;
}


=head2 accessors get_mode, set_mode

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_mode {
  my $self = shift;
  return $self->{mode}; 
}

sub set_mode {
  my $self = shift;
  $self->{mode} = shift;
}



=head2 accessors get_value, set_value

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_value {
  my $self = shift;
  return $self->{value}; 
}

sub set_value {
  my $self = shift;
  $self->{value} = shift;
}

=head2 accessors get_state_hashref, set_state_hashref

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_state_hashref {
  my $self = shift;
  return $self->{state_hashref}; 
}

sub set_state_hashref {
  my $self = shift;
  $self->{state_hashref} = shift;
}

return 1;
