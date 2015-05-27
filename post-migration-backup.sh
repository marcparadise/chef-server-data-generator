#!/bin/bash
mkdir -p testdata/post-migration
sudo /opt/opscode/embedded/bin/knife ec backup testdata/post-migration -c .chef/knife-in-guest.rb
