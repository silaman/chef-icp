#
# Cookbook:: icp
# Recipe:: 02_master_node
# For master node only
# Copyright:: 2017, The Authors, All Rights Reserved.

# This recipe is for the master+boot node.
# Add worker nodes to master's known_hosts

if !node['ibm']['icp_node_type'] == "master_node"
  raise "EXITING: This recipe should be run only on ICP master node"
end

ruby_block 'known_hosts' do
  block do
    icp_master_hostname = ""
    search(:node, 'icp_node_type:worker_node',
        :filter_result => {'hostname' => ['fqdn']} ).each do |worker|
      worker_hostname = worker['hostname']
      if !worker_hostname.to_s.empty?
        ssh_known_hosts_entry '#{worker_hostname}'
        Chef::Log.info("-- ICP worker hostname: #{worker_hostname}")
      else
        raise "EXITING: Cannot determine icp worker hostname"
      end
    end

    node.save
  end
end
