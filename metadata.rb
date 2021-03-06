name 'icp'
maintainer 'IBM'
maintainer_email 'ravi.ramnarayan@us.ibm.com'
license 'All Rights Reserved'
description 'Installs/Configures icp'
long_description 'Installs/Configures icp'
version '0.7.54'
chef_version '>= 12.1' if respond_to?(:chef_version)

depends 'sysctl', '>= 0.10.1'
depends 'ssh'
depends 'chef-apt-docker', '~> 2.0.4'
depends 'docker', '~> 2.16.2'
depends 'hostsfile', '~> 3.0.1'

# The `issues_url` points to the location where issues for this cookbook are
# tracked.  A `View Issues` link will be displayed on this cookbook's page when
# uploaded to a Supermarket.
#
# issues_url 'https://github.com/<insert_org_here>/icp/issues'

# The `source_url` points to the development repository for this cookbook.  A
# `View Source` link will be displayed on this cookbook's page when uploaded to
# a Supermarket.
#
# source_url 'https://github.com/<insert_org_here>/icp'
