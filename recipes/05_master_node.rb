#
# Cookbook:: icp
# Recipe:: 05_master_node
# For master node only
# Copyright:: 2017, IBM, All Rights Reserved.

# This recipe is for the master node.

return if node['ibm']['icp_node_type'] != "master" || node['ibm']['icp_node_type'] != "boot"

# Are boot & master on the same node?
nd = data_bag_item('icp_cluster', "boot")
if nd['boot_is_master'] == "true"
  if node['ibm']['icp_node_type'] == "boot"
    # Set vm.max_map_count=262144 on master node
    node.default['sysctl']['params']['vm']['max_map_count'] = 262144
    include_recipe 'sysctl::apply'
  else
    raise "EXITING: Review & correct boot_is_master attribute in icp_cluster data bag"
  end
else
  if node['ibm']['icp_node_type'] == "master"
    # Master node, not a combined boot+master
    # Set vm.max_map_count=262144 on master node
    node.default['sysctl']['params']['vm']['max_map_count'] = 262144
    include_recipe 'sysctl::apply'
  else
    raise "EXITING: This is not a master node"
  end
end
