#
# Cookbook:: icp
# Recipe:: os_parms
#  ICP Workder Nodes
# Copyright:: 2017, The Authors, All Rights Reserved.

# Create .ssh folder for non-root & root accounts
# Extract SSH User who logged into the OS
user_name = "#{ENV['HOME']}".to_s[6..-1]
directory "#{ENV['HOME']}/.ssh" do
  owner user_name
  group user_name
  action :create
end

directory '/root/.ssh' do
  action :create
end

# Get the ICP cluster's master_pub_key from the master_node. Place it in
# the current (worker or proxy) node's master_pub_key attribute, in
# /root/.ssh/authorized_keys and current user's ~/.ssh/authorized_keys
master_pub_key = ""
search(:node, 'icp_node_type:master_node') do |n|
  master_pub_key = n['ibm']['icp_master_pub_key']

  if !master_pub_key.to_s.empty?
    ssh_authorized_keys 'non-root user' do
      user user_name
      key master_pub_key
      type 'ssh-rsa'
    end
    ssh_authorized_keys 'root user' do
      user 'root'
      key master_pub_key
      type 'ssh-rsa'
    end
    node.normal['ibm']['icp_master_pub_key'] = master_pub_key
    icp_node_type = "worker_node"
    node.normal['ibm']['icp_node_type'] = icp_node_type
    # @todo get cluster name from "icp_cluster" data bag
    node.normal['ibm']['icp_cluster_name'] = "mycluster"
    node.save
    #notifies :restart, 'service[sshd]', :delayed
  else
    raise "EXITING: Cannot determine master_pub_key"
  end
end

file "#{ENV['HOME']}/.ssh/authorized_keys" do
  owner user_name
  group user_name
end

service 'sshd' do
  action :restart
end
