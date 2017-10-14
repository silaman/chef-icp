#
# Cookbook:: icp
# Recipe:: os_parms_master
# For master node only
# Copyright:: 2017, The Authors, All Rights Reserved.

# This recipe is only master+boot node. This cluster model puts both master &
# boot functions on the same node. Some commands should run as "sudo", others should not.

# Set vm.max_map_count=262144 on master node
# "-w" should update /etc/sysctl.conf
node.default['sysctl']['params']['vm']['max_map_count'] = 262144
include_recipe 'sysctl::apply'

# Create ssh key in boot (usually master & boot are the same node)
# Create /root/.ssh folder and append the pub key to root's authorized_keys

bash 'ssh_keygen' do
  code <<-EOH
    whoami
    ssh-keygen -b 4096 -t rsa -f ~/.ssh/master.id_rsa -N ''
    sudo mkdir /root/.ssh
    sudo cat ~/.ssh/master.id_rsa.pub >> /root/.ssh/authorized_keys
    EOH
  not_if { ::File.exist?(::File.expand_path("~/.ssh/master.id_rsa")) }
end

ruby_block 'ssh_store_key' do
  block do
    ssh_public_key = ::File.open(::File.expand_path("~/.ssh/master.id_rsa.pub")).readline
    node.normal['ibm']['icp_master_pub_key'] = ssh_public_key
    node.save
    Chef::Log.info("ssh_public_key:  #{ssh_public_key}")
    Chef::Log.info("node.ibm.icp_master_pub_key:  #{node['ibm']['icp_master_pub_key']}")
  end
end

# Set attribute node_type as master
ruby_block 'icp_node_type' do
  block do
    icp_node_type = "master_node"
    node.normal['ibm']['icp_node_type'] = icp_node_type
    node.save
    Chef::Log.info("icp_node_type: #{'icp_node_type'}")
    Chef::Log.info("node.ibm.icp_node_type: #{node['ibm']['icp_node_type']}")
  end
end
