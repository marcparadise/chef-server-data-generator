#!/bin/bash

mkdir -p testdata/keys
mkdir testdata/admin-config
# Create some data
sudo /opt/opscode/embedded/bin/knife exec "scripts/ec/setup-data-1.rb" -c .chef/knife-in-guest.rb
# Create org-specific data
FILES=testdata/admin-config/*
for f in $FILES
do
  echo "Generating data via $f..."
  # Test uploading the cron cookbook
  sudo /opt/opscode/embedded/bin/knife cookbook upload cron -c $f
  sudo /opt/opscode/embedded/bin/knife exec "scripts/ec/setup-org-specific-data-1.rb" -c $f
done
