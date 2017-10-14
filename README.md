# icp

# @todo Enter the cookbook description here.

Cookbook Notes
==============

Configured three VMs with hostname and static IP addresses. See template etc_hosts for details.

Bootstrap nodes
---------------
Chef makes node's NAT as the default "ipaddress". The custom attribute "chef_ip" stores the HostOnly IP for use by chef commands. Need to specify -P password in the command line for the option "--use-sudo-password".

`knife bootstrap 192.168.56.32 -x labrat -N icp-work2 --sudo --json-attributes '{ "chef_ip": "192.168.56.32" }' --use-sudo-password -P Obj#ct00`

Add run list to node
--------------------
`knife node run_list set icp-mbp 'recipe[icp::default],recipe[icp::00_master_node]'`

`knife node run_list set icp-work1 'recipe[icp::default],recipe[icp::10_work_proxy_node]'`

`knife ssh 'name:icp-mbp' 'sudo chef-client' --ssh-user labrat --ssh-password 'Obj#ct00' --attribute chef_ip`
