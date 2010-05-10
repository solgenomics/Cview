#!/bin/bash

VERSION=`perl -e 'use CXGN::Cview; print $CXGN::Cview::VERSION; ' `;

echo "Generating the distribution for cview version $VERSION.";

LIB_ROOT=/sgn_website/perllib/
CGI_ROOT=/sgn_website/sgn/
RELEASEDIR=cview_release

echo "Removing old files...";
rm -Rf $RELEASEDIR;

# generating target directories
echo "Generating the target directories..."
mkdir $RELEASEDIR;
mkdir $RELEASEDIR/CXGN;
mkdir $RELEASEDIR/cgi-bin/

echo "Export the svn repository...";

svn export $LIB_ROOT/CXGN/Cview $RELEASEDIR/CXGN/Cview
cp -v $LIB_ROOT/CXGN/Cview.pm $RELEASEDIR/CXGN
cp -v $LIB_ROOT/CXGN/Version.pm $RELEASEDIR/CXGN
cp -v $LIB_ROOT/CXGN/Login.pm $RELEASEDIR/CXGN
svn export $LIB_ROOT/CXGN/Page $RELEASEDIR/CXGN/Page
cp -v $LIB_ROOT/CXGN/Page.pm $RELEASEDIR/CXGN

svn export $LIB_ROOT/CXGN/Map $RELEASEDIR/CXGN/Map
svn export $LIB_ROOT/CXGN/Phylo $RELEASEDIR/CXGN/Phylo

svn export $LIB_ROOT/JSAN $RELEASEDIR/JSAN
cp -v $LIB_ROOT/CXGN/JSAN.pm $RELEASEDIR/CXGN
svn export $LIB_ROOT/CXGN/Marker $RELEASEDIR/CXGN/Marker
cp -v $LIB_ROOT/CXGN/Marker.pm $RELEASEDIR/CXGN

svn export $LIB_ROOT/CXGN/VHost $RELEASEDIR/CXGN/VHost
cp -v $LIB_ROOT/CXGN/VHost.pm $RELEASEDIR/CXGN

svn export $LIB_ROOT/CXGN/Garbage $RELEASEDIR/CXGN/Garbage

svn export $LIB_ROOT/CXGN/Configuration $RELEASEDIR/CXGN/Configuration
cp -v $LIB_ROOT/CXGN/Configuration.pm $RELEASEDIR/CXGN/Configuration.pm

cp -v $LIB_ROOT/CXGN/Contact.pm $RELEASEDIR/CXGN/
svn export $LIB_ROOT/CXGN/Accession $RELEASEDIR/CXGN/Accession
cp -v $LIB_ROOT/CXGN/Accession.pm $RELEASEDIR/CXGN/Accession.pm
svn export $LIB_ROOT/CXGN/AJAX $RELEASEDIR/CXGN/AJAX
svn export $LIB_ROOT/CXGN/DB $RELEASEDIR/CXGN/DB
cp $LIB_ROOT/CXGN/Fish.pm $RELEASEDIR/CXGN/Fish.pm

cp $LIB_ROOT/CXGN/Cookie.pm $RELEASEDIR/CXGN
svn export $LIB_ROOT/CXGN/Tools $RELEASEDIR/CXGN/Tools

svn export $LIB_ROOT/CXGN/Apache $RELEASEDIR/CXGN/Apache

svn export $LIB_ROOT/CXGN/Chromatogram $RELEASEDIR/CXGN/Chromatogram
cp $LIB_ROOT/CXGN/Image.pm $RELEASEDIR/CXGN

svn export $LIB_ROOT/CXGN/Genomic $RELEASEDIR/CXGN/Genomic

svn export $LIB_ROOT/CXGN/Chado $RELEASEDIR/CXGN/Chado
svn export $LIB_ROOT/CXGN/People $RELEASEDIR/CXGN/People
cp -v $LIB_ROOT/CXGN/People.pm $RELEASEDIR/CXGN

cp -v $LIB_ROOT/CXGN/Phenome.pm $RELEASEDIR/CXGN
svn export $LIB_ROOT/CXGN/Phenome $RELEASEDIR/CXGN/Phenome

svn export $LIB_ROOT/CXGN/Physical $RELEASEDIR/CXGN/Physical

cp -v $LIB_ROOT/CXGN/LICENSE $RELEASEDIR/CXGN

cp -v $LIB_ROOT/CXGN/Primers.pm $RELEASEDIR/CXGN

svn export $LIB_ROOT/CXGN/Class $RELEASEDIR/CXGN/Class
svn export $LIB_ROOT/CXGN/Error $RELEASEDIR/CXGN/Error
svn export $LIB_ROOT/CXGN/Scrap $RELEASEDIR/CXGN/Scrap
cp $LIB_ROOT/CXGN/Scrap.pm $RELEASEDIR/CXGN

svn export $LIB_ROOT/CXGN/Search $RELEASEDIR/CXGN/Search
svn export $LIB_ROOT/CXGN/Searches $RELEASEDIR/CXGN/Searches
cp -v $LIB_ROOT/CXGN/Tag.pm $RELEASEDIR/CXGN

svn export $LIB_ROOT/CXGN/Transcript $RELEASEDIR/CXGN/Transcript
svn export $LIB_ROOT/CXGN/Unigene $RELEASEDIR/CXGN/Unigene

svn export $LIB_ROOT/CXGN/UserPrefs $RELEASEDIR/CXGN/UserPrefs
cp -v $LIB_ROOT/CXGN/UserPrefs.pm $RELEASEDIR/CXGN

svn export $CGI_ROOT/cgi-bin/cview $RELEASEDIR/cgi-bin/cview/
svn export $CGI_ROOT/cgi-bin/search $RELEASEDIR/cgi-bin/search
svn export $CGI_ROOT/cgi-bin/markers $RELEASEDIR/cgi-bin/markers

echo "Copying the Makefile and other stuff...";

cp files/Makefile.PL $RELEASEDIR/
cp -R files/conf $RELEASEDIR/conf
cp -R files/doc $RELEASEDIR/doc
cp files/post_install.sh $RELEASEDIR/
cp files/README.txt $RELEASEDIR/

echo "tar-ing up the distribution...";
tar cf cview_release.v$VERSION.tar --exclude "*~" --exclude "*Default.HostConf*" --exclude "*Page/SGN.pm" --exclude "*CGN.pm" --exclude "*FGN.pm" "cview_release";

echo "Done."
