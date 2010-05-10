
SGN Comparative Viewer (stand-alone)
Version 2.1, Sept 2007.

INSTALLATION

Note: the installation of the Perl libraries will go with the standard Perl libraries. The installation assumes that the final location of the web scripts will reside in the directory /data/local/website/cview . The cgi code will be copied to /data/local/website/cview/cgi-bin. If these directories are already present for other systems, conflicts may occur.

Requirements: 
apache 1.2 with mod_perl installed. 
postgresql 8.1
Perl library dependencies: 
GD.pm
DBI.pm

o Unpack the archive:

  tar xvf cview_release.tar 

o cd into the cview_release directory.

o build and install the distribution

  perl Makefile.PL
  sudo make

o run the script post_install.sh as superuser (this creates the dirs mentioned above).

o copy the information in vhosts.conf contents into your virtual apache server configuration and  adapt it for you use.

o install the database, if necessary.

o further edit the configuration files and adapt for your needs

