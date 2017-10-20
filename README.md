# icp

This cookbook will not work if the boot and master nodes are in separate VMs.

Currently, the cluster model puts both master & boot & proxy functions on the same node. Separating the proxy from the master+boot node is possible.

## Cookbook Notes

Configured three VMs with hostname and static IP addresses. See template etc_hosts for details.

### Bootstrap nodes
Chef makes node's NAT as the default "ipaddress". The custom attribute "chef_ip" stores the HostOnly IP for use by chef commands. Need to specify -P password in the command line for the option "--use-sudo-password".

- `knife bootstrap 192.168.56.30 -x labrat -N icp-mbp --sudo --json-attributes '{ "chef_ip": "192.168.56.30" }' --use-sudo-password -P Obj#ct00`
- `knife bootstrap 192.168.56.31 -x labrat -N icp-work1 --sudo --json-attributes '{ "chef_ip": "192.168.56.31" }' --use-sudo-password -P Obj#ct00`
- `knife bootstrap 192.168.56.32 -x labrat -N icp-work2 --sudo --json-attributes '{ "chef_ip": "192.168.56.32" }' --use-sudo-password -P Obj#ct00`

### Add run list to node
- `knife node run_list set icp-mbp 'recipe[icp::default],recipe[icp::00_master_node],recipe[icp::12_master_node]'`
- `knife node run_list set icp-work1 'recipe[icp::default],recipe[icp::10_worker_node]'`
- `knife node run_list set icp-work2 'recipe[icp::default],recipe[icp::10_worker_node]'`

### Run chef-client
- `knife ssh 'name:icp-mbp' 'sudo chef-client' --ssh-user labrat --ssh-password 'Obj#ct00' --attribute chef_ip`
- `knife ssh 'name:icp-work1' 'sudo chef-client' --ssh-user labrat --ssh-password 'Obj#ct00' --attribute chef_ip`
- `knife ssh 'name:icp-work2' 'sudo chef-client' --ssh-user labrat --ssh-password 'Obj#ct00' --attribute chef_ip`
