
Usage:

1. vagrant up
2. ssh into the box and install the chef server flavor
   of your choice via dpkg
3. cd /vagrant
4. ./setup.sh

Optional:

- before running setup.sh, copy setup.yml.example to setup.yml and customize

=== Notes:

- The default setting of 10 orgs takes a while, because we keep running
  out of precreated orgs under EC 11.  It still finishes, it just takes
  some retries. There is a private-chef.rb in this directory that you
  can copy in to /etc/opscode before initial reconfigure that will
  org precreation speed and depth.

=== What it Does
This tool will generate orgs, users on a server using the pivotal user.
It will select users at random to put into each org (using the
configured number of per-org users), and from those users will randomly
pick the configured number of admins and add them to the admins group.

It will capture everything it generates into one or more yml files
(currently just created-orgs-and-users.yml) so that this data can be
retrieved and compared compared after an upgrade or migration for any discrepencies.

=== TODO - Short Term
- [x] add support for creating clients per org
- [x] add support for creating groups
- [x] add support for group within group memebrshi
- [ ] add support for setting custom acls, at minimum on groups but
      ideally across the range of supported objects.
- [ ] add support to grab all the data afterwords, and compare it to
      what we've created and captured in 'created-orgs-and-users.yml' and
      any additional output files.
- [ ] alt2 - can we just knife ec backup and compare before/after?

=== TODO - Longer Term
- [ ] better directory structure. Better names for files...
- [ ] generate knife.rb for each created user/client. Directories for
  each?
- [ ] node creation and runlists
- [ ] simple cookbook generation and upload per-org
- [ ] as node client, grab the resolved runlist and make sure it's right
      - maybe even a whyrun-mode CCR?
