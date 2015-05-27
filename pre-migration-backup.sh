#!/bin/bash


mkdir -p testdata/pre-migration
# TODO - straighten this out...
# Deps seem screwy, but if we do a failed latest install followed by a successful 1.1.8 install, it seems to work :(
# if we don't first do the failed intsall, we get an error on backup because of missing chef_fs/config
sudo /opt/opscode/embedded/bin/gem install knife-ec-backup --no-ri --no-rdoc  -- --with-pg-config=/opt/opscode/embedded/postgresql/9.2/bin/pg_config
# Install backup 1.1.8 -- later versions use ohai with a ruby 2 dependency
sudo /opt/opscode/embedded/bin/gem install knife-ec-backup -v "1.1.8" --no-ri --no-rdoc  -- --with-pg-config=/opt/opscode/embedded/postgresql/9.2/bin/pg_config

# And run it.
sudo /opt/opscode/embedded/bin/knife ec backup testdata/pre-migration -c .chef/knife-in-guest.rb
