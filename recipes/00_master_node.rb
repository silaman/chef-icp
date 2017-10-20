#
# Cookbook:: icp
# Recipe:: 00_master_node
# For master node only
# Copyright:: 2017, The Authors, All Rights Reserved.

# This recipe is for the master+boot node.

# Set vm.max_map_count=262144 on master node
node.default['sysctl']['params']['vm']['max_map_count'] = 262144
include_recipe 'sysctl::apply'

# Create ssh key in boot (usually master & boot are the same node) and append
# the pub key to root's authorized_keys
# Create .ssh folder for non-root & root accounts
directory "#{ENV['HOME']}/.ssh" do
  action :create
end
directory '/root/.ssh' do
  action :create
end

bash 'ssh_keygen' do
  code <<-EOH
    ssh-keygen -b 4096 -t rsa -f ~/.ssh/master.id_rsa -N ''
    cat ~/.ssh/master.id_rsa.pub | sudo tee -a /root/.ssh/authorized_keys
    EOH
  not_if { ::File.exist?(::File.expand_path("~/.ssh/master.id_rsa")) }
end

ruby_block 'ssh_store_key' do
  block do
    ssh_public_key = ::File.open(::File.expand_path("~/.ssh/master.id_rsa.pub")).readline
    node.normal['ibm']['icp_master_pub_key'] = ssh_public_key
    Chef::Log.info("ssh_public_key:  #{ssh_public_key}")
    Chef::Log.info("node.ibm.icp_master_pub_key:  #{node['ibm']['icp_master_pub_key']}")

    icp_node_type = "master_node"
    node.normal['ibm']['icp_node_type'] = icp_node_type
    Chef::Log.info("icp_node_type: #{'icp_node_type'}")
    Chef::Log.info("node.ibm.icp_node_type: #{node['ibm']['icp_node_type']}")

    # @todo get cluster name from "icp_cluster" data bag
    node.normal['ibm']['icp_cluster_name'] = "mycluster"

    node.save
    notifies :restart, "service[sshd]", :delayed
  end
  not_if { !node['ibm']['icp_node_type'].to_s.empty? }
end

service 'sshd' do
  action :nothing
end
