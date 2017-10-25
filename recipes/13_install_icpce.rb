#
# Cookbook:: icp
# Recipe:: 13_master_node
# For master node only
# Copyright:: 2017, The Authors, All Rights Reserved.

# This recipe is for the master+boot node.
# Install ICP-ce installer

if !node['ibm']['icp_node_type'] == "master_node"
  raise "EXITING: This recipe should be run only on ICP master node"
end

icpce_ver = '2.1.0'
# docker pull command is idempotent by nature. Will pull only if needed.
docker_image 'ibmcom/icp-inception' do
  tag icpce_ver
  action :pull
end

directory '/opt/ibm-cloud-private-ce' do
  action :create
end

bash 'extract icp cluster data' do
  code <<-EOH
    cd /opt/ibm-cloud-private-ce
    sudo docker run -e LICENSE=accept \
  -v "$(pwd)":/data ibmcom/icp-inception:#{icpce_ver} cp -r cluster /data
    EOH
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
