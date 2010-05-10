#!/bin/bash

echo "Creating the /etc/cxgn directory..."
mkdir -p /etc/cxgn

echo "Copying the configuration file..."
cp conf/CVIEW.HostConf /etc/cxgn/

echo "Creating the /data/local/website/cview directory..."
mkdir -p /data/local/website/cview

echo "Copying the cgi-bin directory to its final destination ";
cp -R cgi-bin/ /data/local/website/cview
