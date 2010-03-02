
use strict;

package CXGN::Cview::Legend::Genetic;

use CXGN::Cview::Legend;

use base qw | CXGN::Cview::Legend | ;

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
    my $self = $class->SUPER::new(@_);

    return $self;

}

=head2 function get_legend_html()

  Synopsis: 
  Parameters:   none
  Returns:      a string containing html code for the marker color legend 
  Side effects: none
  Status:       implemented
  Example:

=cut

sub get_legend_html {
    my $self= shift;
    my $string = "<table border = \"0\" cellspacing=\"0\" cellpadding=\"0\" ><tr valign=\"middle\"><td>";

    my $state = $self->get_state_hashref();

    my $link = "view_chromosome.pl?map_version_id=$state->{map_version_id}&amp;chr_nr=$state->{chr_nr}&amp;show_physical=$state->{show_physical}&amp;show_IL=$state->{show_IL}&amp;show_offsets=$state->{show_offsets}&amp;show_ruler=$state->{show_ruler}&amp;color_model=$state->{color_model}&amp;comp_map_version_id=$state->{comp_map_version_id}&amp;comp_chr=$state->{comp_chr}&amp;show_zoomed=$state->{show_zoomed}&amp;size=$state->{size}&amp;cM=$state->{cM}&amp;cM_start=$state->{cM_start}&amp;cM_end=$state->{cM_end}&amp;hilite=$self->{hilite}&amp;zoom=$state->{zoom}";
    if ($self->get_mode() eq "marker_types") {
	$string .= "<b>Marker color by type:</b> 
                   <a href=\"$link\&marker_type=RFLP\" style=\"color:#FF0000\">RFLP</a> | 
                   <a href=\"$link\&marker_type=SSR\" style=\"color:#00FF00\">SSR</a> | 
                   <a href=\"$link\&marker_type=CAPS\" style=\"color:#0000FF\">CAPS</a> | 
                   <a href=\"$link\&marker_type=COS\" style=\"color:#FF00FF\">COS</a> | 
                   <font color=#000000>other</font>
	                   [<a href=\"$link\&marker_type=\" style=\"color:#111111\">show all</a>]";
    
    }
    else {
	$string .= "<b>Marker color by LOD score:</b> 
                   <a href=\"$link\&amp;confidence=3\" style=\"color:#FF0000\">F(LOD3)</a> |
                   <a href=\"$link\&amp;confidence=2\" style=\"color:#00FF00\">CF(LOD>=3</a> | 
                   <a href=\"$link\&amp;confidence=1\" style=\"color:#0000FF\">I(LOD2)</a> | 
                   <a href=\"$link\&amp;confidence=0\" style=\"color:#000000\">I(LOD&lt;2)</a> |
                   <a href=\"$link\&amp;confidence=-2\" style=\"color:#777777\">uncalculated</a>  ";
    }


    my $toggle_color_model = "";
    my $toggle_color_button = "";
    if ($self->get_mode() eq "marker_types") { 
	$toggle_color_model="";
	$toggle_color_button = "Color LOD scores"; 
    }

    else {
	$toggle_color_model="marker_types";
	$toggle_color_button = "Color marker types";
    }
    
    my $color_toggle_button = CXGN::Cview::Chromosome_view::toolbar_button -> new($toggle_color_button, $state);
    $color_toggle_button -> set_property("color_model", $toggle_color_model);
    my $color_toggle_html = $color_toggle_button -> render_string();

    $string .= "</td><td>".$color_toggle_html;

    $string .= "</td></tr></table>";
    return $string;
}



return 1;
