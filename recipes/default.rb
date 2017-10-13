#
# Cookbook:: icp
# Recipe:: default
#
# Copyright:: 2017, The Authors, All Rights Reserved.

apt_update 'Update the apt cache daily' do
  frequency 86_400
  action :periodic
end

%w{python python-pip openssh-client socat ntp}.each do |pkg|
  package pkg do
    action :install
  end
end

# Install NTP & Set clocks to UTC
#     timedatectl set-timezone UTC
bash 'set_tz_2_utc' do
  code <<-EOH
    timedatectl set-timezone America/Los_Angeles
  EOH
end

# Setup common /etc/hosts for all ICP nodes using the IP addresses which chef
# uses. This avoids tripping over multiple network interface cards.
template '/etc/hosts' do
  source 'etc_hosts.erb'
end
