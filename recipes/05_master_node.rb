#
# Cookbook:: icp
# Recipe:: 05_master_node
# For master node only
# Copyright:: 2017, The Authors, All Rights Reserved.

# This recipe is for the master node.

# Set vm.max_map_count=262144 on master node
node.default['sysctl']['params']['vm']['max_map_count'] = 262144
include_recipe 'sysctl::apply'
