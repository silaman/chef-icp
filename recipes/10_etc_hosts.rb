#
# Cookbook:: icp
# Recipe:: etc_hosts
#
# Copyright:: 2017, The Authors, All Rights Reserved.

template '/etc/hosts' do
  source 'etc_hosts.erb'
end
