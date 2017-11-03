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

docker_container 'icpce_extract_installer' do
  action      :run
  repo        icp['repo']
  tag         icp['tag']
  env         icp['env']
  command     icp['command']
  working_dir '/opt/ibm-cloud-private-ce'
  volumes     '/opt/ibm-cloud-private-ce:/data'
  not_if { ::File.exist?(::File.expand_path("/opt/ibm-cloud-private-ce/cluster/hosts")) }
end

# Replace icp-ce cluster/hosts file with fixed values in the template. Need to
# make the template flexible -- later.
template '/opt/ibm-cloud-private-ce/cluster/hosts' do
  source 'icpce_cluster_hosts.erb'
end

# Copy master.id_rsa to ICPce installer
execute 'copy ssh_key' do
  command 'sudo cp ~/.ssh/master.id_rsa /opt/ibm-cloud-private-ce/cluster/ssh_key'
end
