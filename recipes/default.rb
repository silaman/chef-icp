#
# Cookbook:: icp
# Recipe:: default
#
# Copyright:: 2017, The Authors, All Rights Reserved.
#

apt_update 'Update the apt cache daily' do
  frequency 86_400
  action :periodic
end

%w{python python-pip openssh-client socat ntp}.each do |pkg|
  package pkg do
    action :install
  end
end

# Set clocks to UTC. @todo Should we install NTP?
bash 'set_tz_2_utc' do
  code <<-EOH
    timedatectl set-timezone UTC
  EOH
  not_if "echo $(date +%Z) | grep UTC\n"
end

# Use Supermarket cookbook hostsfile to put icp_cluster can append entries to
# /etc/hosts, one entry per invocation. However, I am not sure there is a need
# for local DNS resolution in each node. Is corporate DNS adequate?

data_bag('icp_cluster').each do |icp_node|
  nd = data_bag_item('icp_cluster', icp_node)
  hostsfile_entry "#{nd['ip_address']}" do
    hostname  nd['fqdn']
    aliases   [nd['alias']]
    action    :create
  end
end
