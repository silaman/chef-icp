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
# image (as needed), install and start docker.
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

# @todo ICPee image comes from IBM Passport Advantage
# @todo Enable icpee installation
icp = data_bag_item('icp_parts_list', "icp")

docker_image icp['repo'] do
  action    :pull
  tag       icp['tag']
end

directory icp['working_dir'] do
  action :create
end

docker_volume = icp['working_dir'] + ":/data"

docker_container 'icp_extract_installer' do
  action      :run
  repo        icp['repo']
  tag         icp['tag']
  env         icp['env']
  command     icp['command']
  working_dir icp['working_dir']
  volumes     icp['working_dir'] + ":/data"
  not_if { ::File.exist?(::File.expand_path(icp['working_dir'] + "/cluster/hosts")) }
end

# @todo make config.yaml a remote file
config_yaml_name = "icp_" + node['ibm']['icp_cluster_name'] + "_config.yaml_" + icp['icp_edition'] + "_" + icp['tag'] + ".erb"

template icp['working_dir'] + "/cluster/config.yaml" do
  source config_yaml_name
end

# Use icp_cluster items to compose cluster/hosts template
master_nodes = ["[master]"]
worker_nodes = ["[worker]"]
proxy_nodes = ["[proxy]"]
mgmt_nodes = ["[management]"]

# Note: If "boot_is_master" is true, there should be no master nodes in
# icp_cluster. However, the logic below does NOT enforce the rule. @todo Enforce
# rule in a chef test
data_bag('icp_cluster').each do |icp_node|
  nd = data_bag_item('icp_cluster', icp_node)
  # Select nodes in same cluster as the boot node
  if nd['icp_cluster_name'] == node['ibm']['icp_cluster_name']
    # Add IP addresses to node type arrays
    if nd['icp_node_type'].to_s == "boot" && nd['boot_is_master'] == "true"
      master_nodes = master_nodes + [ nd['ip_address'] ]
    elsif nd['icp_node_type'].to_s == "master"
      master_nodes = master_nodes + [ nd['ip_address'] ]
    elsif nd['icp_node_type'].to_s == "worker"
      worker_nodes = worker_nodes + [ nd['ip_address'] ]
    elsif nd['icp_node_type'].to_s == "proxy"
      proxy_nodes = proxy_nodes + [ nd['ip_address'] ]
    elsif nd['icp_node_type'].to_s == "management"
      mgmt_nodes = mgmt_nodes + [ nd['ip_address'] ]
    end
  end
end

# @todo Is an empty node_type stanza okay? Logic creates an empty stanza if
# there are no nodes for a node type.
template icp['working_dir'] + "/cluster/hosts" do
  source 'icp_cluster_hosts.erb'
  variables({ :master_hosts => master_nodes,
              :worker_hosts => worker_nodes,
              :proxy_hosts => proxy_nodes,
              :mgmt_hosts => mgmt_nodes
  })
end

# Copy master.id_rsa to ICPce installer
execute 'copy ssh_key' do
  command "sudo cp ~/.ssh/master.id_rsa " + icp['working_dir'] + "/cluster/ssh_key"
end
