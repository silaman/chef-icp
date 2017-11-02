#
# Cookbook:: icp
# Recipe:: 00_boot_node
# For boot node only
# Copyright:: 2017, The Authors, All Rights Reserved.

# This recipe is for the boot node. A cluster has only one boot node and could
# have several master nodes. Hence, the separation of recipes. You can combine
# the master & boot nodes in the ICP installer cluster/hosts file by placing the
# boot IP address in the [master] stanza.

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
    icp_node_type = "master"
    node.normal['ibm']['icp_node_type'] = icp_node_type

    # @todo get cluster name from "icp_cluster" data bag
    node.normal['ibm']['icp_cluster_name'] = "mycluster"

    node.save
    #notifies :restart, 'service[sshd]', :delayed
  end
  not_if { node['ibm']['icp_master_pub_key'].length > 1 }
end

# Add worker, master, proxy & management nodes to boot's known_hosts Logic will
# add all cluster members including boot to known_hosts -- silly, but makes the
# logic simpler. Should this be idempotent? Need to collect the current keys.
# May not be worth the effort to make this idempotent.
search(:node, 'icp_cluster_name:mycluster',
    :filter_result => { 'nd_ip' => ['chef_ip']
                      } ).each do |nd|
  node_ip = nd['nd_ip']
  if !nd_ip.to_s.empty?
    ssh_known_hosts node_ip
  else
    raise "EXITING: Cannot determine icp worker hostname"
  end
end

service 'sshd' do
  action :restart
end
