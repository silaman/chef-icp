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

# @todo Make this idempotent. May have to use the "icp_cluster" data bag

icp_ce_ver = '2.1.0'
# docker pull command is idempotent by nature. Will pull only if needed.
execute 'pull ICP-ce Docker image' do
  command 'sudo docker pull ibmcom/icp-inception:#{icp_ce_ver}'
end

directory '/opt/ibm-cloud-private-ce-#{icp_ce_ver}' do
  action :create
end

bash 'extract icp cluster data' do
  code <<-EOH
    cd /opt/ibm-cloud-private-ce-#{icp_ce_ver}
    sudo docker run -e LICENSE=accept \
  -v "$(pwd)":/data ibmcom/icp-inception:2.1.0-beta-3 cp -r cluster /data
    EOH
  not_if { ::File.exist?(::File.expand_path("/opt/ibm-cloud-private-ce-#{icp_ce_ver}/cluster/hosts")) }
end

# Replace icp-ce cluster/hosts file with fixed values in the template. Need to
# make the template flexible -- later.
template '/opt/ibm-cloud-private-ce-#{icp_ce_ver}/cluster/hosts' do
  source 'ibm_ce_cluster_hosts.erb'
end

remote_file '/opt/ibm-cloud-private-ce-#{icp_ce_ver}/cluster/ssh_key' do
  source 'file:///~/.ssh/master.id_rsa'
end
