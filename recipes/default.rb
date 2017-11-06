#
# Cookbook:: icp
# Recipe:: default
#
# Copyright:: 2017, IBM, All Rights Reserved.
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

# Extract SSH User who logged into the OS
user_name = "#{ENV['HOME']}".to_s[6..-1]
# Create .ssh folder for non-root & root accounts
directory "#{ENV['HOME']}/.ssh" do
  owner user_name
  group user_name
  action :create
end

directory '/root/.ssh' do
  action :create
end

cluster_name = ""
# Get the cluster name from the data_bag_item with node_type = "boot"
data_bag('icp_cluster').each do |icp_node|
  nd = data_bag_item('icp_cluster', icp_node)
  if nd['icp_node_type'] == "boot"
    cluster_name = nd['icp_cluster_name']
  end
end

# Supermarket cookbook hostsfile adds entries to /etc/hosts for nodes defined in
# the icp_cluster data bag. Do we really need local DNS resolution in each node.
# Is corporate DNS adequate?
data_bag('icp_cluster').each do |icp_node|
  nd = data_bag_item('icp_cluster', icp_node)
  # Select nodes in the same cluster as boot
  if nd['icp_cluster_name'] == cluster_name
    # Add entries for all nodes into /etc/hosts
    hostsfile_entry "#{nd['ip_address']}" do
      hostname  nd['fqdn']
      aliases   [nd['alias']]
      action    :create
    end
  end
end

# Remove entry 127.0.1.1 from /etc/hosts
hostsfile_entry "127.0.1.1" do
  action    :remove
end

# Get node properties using ['ibm']['icp_node_id'], which is set by bootstrap
# Set ICP attributes for boot node
if node['ibm']['icp_node_type'].length <= 1
  icp_node = node['ibm']['icp_node_id']
  nd = data_bag_item('icp_cluster', icp_node )
  node.normal['ibm']['icp_node_type'] = nd['icp_node_type']
  node.normal['ibm']['icp_cluster_name'] = nd['icp_cluster_name']
  node.save
end
