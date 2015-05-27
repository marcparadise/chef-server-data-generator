#!/bin/bash

mkdir -p testdata/keys
# Create some data
sudo /opt/opscode/embedded/bin/knife exec "scripts/setup-data-1.rb" -c .chef/knife-in-guest.rb

