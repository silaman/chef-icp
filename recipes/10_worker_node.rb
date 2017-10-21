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

ruby_block 'ssh_store_key' do
  block do
    # Add SSH KEY to non-root & root authorized_keys
    def add_key_to_authorized_keys(key)
      open(File.expand_path('~/.ssh/authorized_keys'), 'a') do |f|
        if File.readlines(f).grep("#{key}").any?
          Chef::Log.info("key is already in non-root authorized keys")
        else
          Chef::Log.info("Adding SSH KEY to non-root authorized keys")
          f << key
        end
      end
      open(File.expand_path('/root/.ssh/authorized_keys'), 'a') do |f|
        if File.readlines(f).grep("#{key}").any?
          Chef::Log.info("key is already in root authorized keys")
        else
          Chef::Log.info("Adding SSH KEY to root authorized keys")
          f << key
        end
      end
    end

    # Get the ICP cluster's master_pub_key from the master_node. Place it in
    # the current (worker or proxy) node's master_pub_key attribute, in
    # /root/.ssh/authorized_keys and current user's ~/.ssh/authorized_keys
    master_pub_key = ""
    search(:node, 'icp_node_type:master_node') do |n|
      master_pub_key = n['ibm']['icp_master_pub_key']
    end

    if !master_pub_key.to_s.empty?
      Chef::Log.info("-- master_pub_key: #{master_pub_key}")
      add_key_to_authorized_keys(master_pub_key)
      node.normal['ibm']['icp_master_pub_key'] = master_pub_key
      icp_node_type = "worker_node"
      node.normal['ibm']['icp_node_type'] = icp_node_type
      Chef::Log.info("icp_node_type: #{'icp_node_type'}")
      # @todo get cluster name from "icp_cluster" data bag
      node.normal['ibm']['icp_cluster_name'] = "mycluster"
      Chef::Log.info("cp_cluster_name: #{'cp_cluster_name'}")
      node.save
      # notifies :restart, 'service[sshd]', :delayed
    else
      raise "EXITING: Cannot determine master_pub_key"
    end
  end
  not_if { ::File.exist?(::File.expand_path("~/.ssh/authorized_keys")) }
end

file "#{ENV['HOME']}/.ssh/authorized_keys" do
  owner user_name
  group user_name
end

service 'sshd' do
  action :restart
end
