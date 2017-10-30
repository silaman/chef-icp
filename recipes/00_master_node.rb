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
    icp_node_type = "master_node"
    node.normal['ibm']['icp_node_type'] = icp_node_type

    # @todo get cluster name from "icp_cluster" data bag
    node.normal['ibm']['icp_cluster_name'] = "mycluster"

    node.save
    #notifies :restart, 'service[ssh]', :delayed
  end
  not_if { node['ibm']['icp_master_pub_key'].length > 1 }
end

# Add worker nodes to master's known_hosts
# @todo Make this idempotent. May have to use the "icp_cluster" data bag
search(:node, 'icp_node_type:worker_node',
    :filter_result => {'hostname' => ['fqdn']} ).each do |worker|
  worker_hostname = worker['hostname']
  if !worker_hostname.to_s.empty?
    ssh_known_hosts worker_hostname
  else
    raise "EXITING: Cannot determine icp worker hostname"
  end
end

service 'ssh' do
  action :restart
end
