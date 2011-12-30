package CXGN::Cview::Chromosome::AGP;

=head1 NAME

CXGN::Cview::Chromosome::AGP - a chromosome class visualizing the AGP file

=head1 DESCRIPTION

The AGP chromosome object is populated by flat files that the sequencing projects upload to SGN and that are available from the SGN FTP site. 

The constructor looks whether it has a locally cached copy of the AGP file, and uses it if it is available. Otherwise, it invokes wget to get a fresh copy fromthe FTP site.

This class inherits from CXGN::Cview::Chromosome.

=head1 AUTHOR(S)

Lukas Mueller <lam87@cornell.edu>

=head1 FUNCTIONS

This class implements the following functions:

=cut

use strict;
use warnings;

use File::Spec;
use CXGN::Cview::Chromosome;
use CXGN::Cview::Marker::AGP;

use base qw | CXGN::Cview::Chromosome |;


=head2 function new

  Synopsis:	my $agp = CXGN::Cview::Chromosome::AGP->new(
                   $chr_nr, $height, $x, $y, $agp_file);
  Arguments:	* a chromosome id (usually a int, but can by anything)
                * the height of the chromosome in pixels [int]
                * the horizontal offset in pixels [int]
                * the vertical offset in pixels [int]
                * the filename of the file containing the agp info.
  Returns:	a CXGN::Cview::Chromosome::AGP object
  Side effects:	generates some cache files on disk
  Description:	this parses the file $agp_file and creates a new AGP
                object. For faster access, cache files are generated
                in a temp location.

=cut

sub new {
    my $class = shift;
    my ($chr_nr, $height, $x, $y, $agp_file) = @_;
    my $self = $class->SUPER::new($chr_nr, $height, $x, $y);
    
    $self->set_name($chr_nr);
    $self->set_units("MB");
    $self->rasterize(0);
    $self->set_rasterize_link("");
    $self->set_url("");
    $self->set_height(100);

    return $self;
}

1;
