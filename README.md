# icp

# @todo Enter the cookbook description here.

Cookbook Notes
==============
knife bootstrap 192.168.56.30 -x labrat [-P password] -N icp-mbp --sudo -- ssh-gateway 192.168.56.30
  Prompts for ssh login password and then for the sudo password. Should we have NOPASSWD sudo for "labrat" in nodes?

knife node run_list add icp-mbp 'icp'

knife ssh 'name:icp-mbp' 'sudo chef-client' --ssh-user labrat --ssh-password 'Obj#ct00' --attribute ipaddress

knife ssh 'name:icp-mbp' 'hostname' --ssh-user labrat --ssh-password 'Obj#ct00' --attribute ipaddress

Configured three VMs with hostname and static IP addresses. See template etc_hosts for details.

Bootstrap nodes
---------------
Chef makes node's NAT as the default "ipaddress". The custom attribute "chef_ip" stores the HostOnly IP for use by chef commands. Need to specify -P password in the command line for the option "--use-sudo-password".

`knife bootstrap 192.168.56.32 -x labrat -N icp-work2 --sudo --json-attributes '{ "chef_ip": "192.168.56.32" }' --use-sudo-password -P Obj#ct00`

Add run list to node
--------------------
`knife node run_list set icp-mbp 'recipe[icp],recipe[icp::etc_hosts]'`
`knife node run_list add icp-mbp 'icp::etc_hosts'`

`knife ssh 'name:icp-mbp' 'sudo chef-client' --ssh-user labrat --ssh-password 'Obj#ct00' --attribute chef_ip`
