#
# Cookbook:: icp
# Recipe:: 13_master_node
# For master node only
# Copyright:: 2017, IBM, All Rights Reserved.

# This recipe is for the boot node.
# Install Docker, ICPce installer and extract the ICPce installer

return if node['ibm']['icp_node_type'] != "boot"

# Setup docker repository
include_recipe 'chef-apt-docker'

# Install Docker using cookbook:docker LWRP:docker_service will pull down the
# image (as needed), install and start docker. @todo ICPee image comes from IBM
# Passport Advantage
dk = data_bag_item('icp_parts_list', "docker")


docker_service 'default' do
  action          [:create, :start]
  version         dk['version']
  install_method  'package'
  package_name    dk['package_name']
end

# Extract SSH User who logged into the OS
user_name = "#{ENV['HOME']}".to_s[6..-1]
# Add SSH User who logged into the OS to group:docker
group 'docker' do
  action :modify
  members user_name
  append true
end

# @todo Enable icpee installation
icp = data_bag_item('icp_parts_list', "icpce")
icp_repo = icp['repo']

docker_image icp_repo do
  action    :pull
  tag       icp['tag']
end

directory '/opt/ibm-cloud-private-ce' do
  action :create
end

docker_container 'icp_extract_installer' do
  action      :run
  repo        icp['repo']
  tag         icp['tag']
  env         icp['env']
  command     icp['command']
  working_dir '/opt/ibm-cloud-private'
  volumes     '/opt/ibm-cloud-private:/data'
  not_if { ::File.exist?(::File.expand_path("/opt/ibm-cloud-private/cluster/hosts")) }
end

# Replace icp-ce cluster/hosts file with fixed values in the template. Need to
# make the template flexible -- later.
master_nodes = ["[master]"]
worker_nodes = ["[worker]"]
proxy_nodes = ["[proxy]"]
mgmt_nodes = ["[management]"]

data_bag('icp_cluster').each do |icp_node|
  nd = data_bag_item('icp_cluster', icp_node)
  # Add IP addresses to node type arrays
  if nd['icp_node_type'].to_s == "master"
    master_nodes = master_nodes + [ nd['ip_address'] ]
  elsif nd['icp_node_type'].to_s == "worker"
    worker_nodes = worker_nodes + [ nd['ip_address'] ]
  elsif nd['icp_node_type'].to_s == "proxy"
    proxy_nodes = proxy_nodes + [ nd['ip_address'] ]
  elsif nd['icp_node_type'].to_s == "management"
    mgmt_nodes = mgmt_nodes + [ nd['ip_address'] ]
  end
end

master_nodes = master_nodes + worker_nodes + proxy_nodes + mgmt_nodes

template '/opt/ibm-cloud-private/cluster/hosts' do
  source 'icp_cluster_hosts.erb'
  variables( :cluster_hosts => master_nodes )
end

# Copy master.id_rsa to ICPce installer
execute 'copy ssh_key' do
  command 'sudo cp ~/.ssh/master.id_rsa /opt/ibm-cloud-private/cluster/ssh_key'
end
