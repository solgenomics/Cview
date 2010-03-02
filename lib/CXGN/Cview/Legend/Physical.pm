
use strict;

package CXGN::Cview::Legend::Physical;

use CXGN::Cview::Legend;

use base qw | CXGN::Cview::Legend |;


sub get_legend_html { 
    my $self = shift;

    my $s = "<table><tr>";
    $s.= qq { <td><b>Anchoring color legend:<b>&nbsp;</td> };
    $s.= qq { <td><font style="background-color:#00FF00">&nbsp;&nbsp;</font></td><td>sequenced&nbsp;</td> };
    $s.= qq { <td><font style="background-color:#0000FF">&nbsp;&nbsp;</font></td><td>in progress&nbsp;</td> };
    $s.= qq { <td><font style="background-color:#772222">&nbsp;&nbsp;</font></td><td>computational&nbsp;</td> };
    $s.= qq { <td><font style="background-color:#AAAA00">&nbsp;&nbsp;</font></td><td>experimental&nbsp;</td> };
    $s.= qq { <td><font style="background-color:#AAAAAA">&nbsp;&nbsp;</font></td><td>overgo&nbsp;</td> };
    $s.= qq { <td><font style="background-color:#22AAAA">&nbsp;&nbsp;</font></td><td>S. pennellii BAC&nbsp;</td> };
    $s.="</tr></table>";
    
    return $s;
}



return 1;

