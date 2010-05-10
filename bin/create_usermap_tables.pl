#!/usr/bin/perl

use strict;

use CXGN::DB::Connection;
use CXGN::People::UserMap;

my $mode = shift;

my $dbhost = "";
my $dbname = "";

if ($mode eq "cxgn") { 
    $dbhost = "hyoscine";
    $dbname = "cxgn";
}
elsif ($mode eq "sandbox" || $mode eq "trial") { 
    $dbhost = "scopolamine";
    $dbname = "sandbox";
}
else { 
    print "Usage: Need a mode parameter: either 'sandbox' or 'cxgn'. Cheers! \n";
}

my $dbh = CXGN::DB::Connection->new( {
    dbhost =>$dbhost,
    dbname =>$dbname,
    dbuser =>"postgres",
    dbpass => "Eise!Th9",
    dbschema => "sgn_people",
});

CXGN::People::UserMap::create_schema($dbh);


