# icp

# @todo Enter the cookbook description here.

Cookbook Notes
==============

Configured three VMs with hostname and static IP addresses. See template etc_hosts for details.

Bootstrap nodes
---------------
Chef makes node's NAT as the default "ipaddress". The custom attribute "chef_ip" stores the HostOnly IP for use by chef commands. Need to specify -P password in the command line for the option "--use-sudo-password".

`knife bootstrap 192.168.56.30 -x labrat -N icp-mbp --sudo --json-attributes '{ "chef_ip": "192.168.56.30" }' --use-sudo-password -P Obj#ct00`

`knife bootstrap 192.168.56.31 -x labrat -N icp-work1 --sudo --json-attributes '{ "chef_ip": "192.168.56.31" }' --use-sudo-password -P Obj#ct00`

Add run list to node
--------------------
`knife node run_list set icp-mbp 'recipe[icp::default],recipe[icp::00_master_node]'`

`knife node run_list set icp-work1 'recipe[icp::default],recipe[icp::10_worker_node]'`

`knife ssh 'name:icp-mbp' 'sudo chef-client' --ssh-user labrat --ssh-password 'Obj#ct00' --attribute chef_ip`

`knife ssh 'name:icp-work1' 'sudo chef-client' --ssh-user labrat --ssh-password 'Obj#ct00' --attribute chef_ip`
