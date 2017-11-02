#
# Cookbook:: icp
# Recipe:: 00_boot_node
# For boot node only
# Copyright:: 2017, The Authors, All Rights Reserved.

# This recipe is for the boot node. A cluster has only one boot node but could
# have several master nodes. Hence, the separation of recipes. You can combine
# the master & boot nodes in the ICP installer cluster/hosts file by placing the
# boot IP address in the [master] stanza AND set boot_is_master to true in
# icp_cluster boot.json  *** NOTE *** boot becomes master, not vice versa.

# We need one boot node. icp_node_type is set by recipe[icp:default]
if node['ibm']['icp_node_type'].to_s != "boot"
  raise "EXITING: This is not the boot node"
end

# We should have only one boot node
# @todo Should this be in a test recipe?
boot_count = 0
cluster_name = node['ibm']['icp_cluster_name']
search(:node, "icp_cluster_name:#{cluster_name}",
    :filter_result => { 'nd_node_type' => ['ibm']['icp_node_type']
                      } ).each do |nd|
  node_type = nd['nd_node_type']
  if node_type.to_s == "boot"
    boot_count += 1
  end
end

if boot_count > 1
  raise "EXITING: More than one boot node in icp_cluster"
end

# Create ssh key in boot and append the pub key to root's authorized_keys.
# Create .ssh folder for non-root & root accounts

# Extract SSH User who logged into the OS
user_name = "#{ENV['HOME']}".to_s[6..-1]
directory "#{ENV['HOME']}/.ssh" do
  owner user_name
  group user_name
  action :create
end

# Setup docker repository
include_recipe 'chef-apt-docker'

# Install Docker version 17.06 (Oct 2017) required by ICP using cookbook:docker
# LWRP:docker_installation_package
# @todo make the docker version an input variable
docker_service 'default' do
  action [:create, :start]
  version "17.06.2"
  install_method 'package'
  package_name 'docker-ce'
end

# Add SSH User who logged into the OS to group:docker
group 'docker' do
  action :modify
  members user_name
  append true
end

directory '/root/.ssh' do
  action :create
end

# The second ssh-keygen command puts the core (secret) pub key, without the
# leading "ssh-rsa " or the trailing comments, in /tmp/master_pub_key. Strange,
# but the Chef Supermarket LWRP ssh_authorized_keys (see other recipes) rejects
# the default format of the pub key.
bash 'ssh_keygen' do
  code <<-EOH
    ssh-keygen -b 4096 -t rsa -f ~/.ssh/master.id_rsa -N ''
    ssh-keygen -y -f  ~/.ssh/master.id_rsa | sed 's/ssh-rsa //' > /tmp/master_pub_key
    chown #{user_name}:#{user_name} ~/.ssh/master.id_rsa*
    cat ~/.ssh/master.id_rsa.pub | sudo tee -a /root/.ssh/authorized_keys
    EOH
  not_if { ::File.exist?(::File.expand_path("~/.ssh/master.id_rsa")) }
end

ruby_block 'get master_pub_key' do
  block do
    master_pub_key = ::File.open(::File.expand_path("/tmp/master_pub_key")).readline
    node.normal['ibm']['icp_master_pub_key'] = master_pub_key
    node.save
    #notifies :restart, 'service[sshd]', :delayed
  end
  not_if { node['ibm']['icp_master_pub_key'].length > 1 }
end

# Add worker, master, proxy & management nodes to boot's known_hosts Logic will
# add all cluster members including boot to known_hosts -- silly, but makes the
# logic simpler. Need to collect current keys. May not be worth the effort to
# make this idempotent. *** NOTE *** Logic uses hostname (fqdn) to collect
# known_hosts. We need local DNS with /etc/hosts unless corporate DNS is
# reliable. @todo Should we use IP addresses instead of hostnames?

cluster_name = node['ibm']['icp_cluster_name']
search(:node, "icp_cluster_name:#{cluster_name}",
    :filter_result => { 'nd_fqdn' => ['fqdn']
                      } ).each do |nd|
  node_hostname = nd['nd_fqdn']
  if !node_hostname.to_s.empty?
    ssh_known_hosts node_hostname
  else
    raise "EXITING: Cannot determine icp node hostname"
  end
end

service 'sshd' do
  action :restart
end
