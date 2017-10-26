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
- `knife node run_list set icp-mbp 'recipe[icp::default],recipe[icp::00_master_node],recipe[icp::13_extract_icpce_installer]'`
- `knife node run_list set icp-work1 'recipe[icp::default],recipe[icp::10_worker_node]'`
- `knife node run_list set icp-work2 'recipe[icp::default],recipe[icp::10_worker_node]'`

### Run chef-client
- `knife ssh 'name:icp-mbp' 'sudo chef-client' --ssh-user labrat --ssh-password 'Obj#ct00' --attribute chef_ip`
- `knife ssh 'name:icp-work1' 'sudo chef-client' --ssh-user labrat --ssh-password 'Obj#ct00' --attribute chef_ip`
- `knife ssh 'name:icp-work2' 'sudo chef-client' --ssh-user labrat --ssh-password 'Obj#ct00' --attribute chef_ip`

## Watch Out
These scenarios can cause a problem. It might be possible to develop a solution to eliminate the problem. Until then, watch out.

- ***Correction. This does NOT seem to be a problem. See test results below*** When a VM is restored to a snapshot before it became a chef node through a bootstrap, the corresponding node should be deleted. If the node is not deleted and we run the recipe 12_master_node, the ssh_known_hosts function will create a known_hosts entry with the node's client key, which is invalid as the corresponding VM does not exist. When we bootstrap the restored VM, chef will create a new node and client key, compounding the problem.

 * Restore all VM to pre bootstrap. Do not delete nodes from Chef. Start mbp & work1 (work2 powered off). Node mpb: bootstrap, set run list, run chef client. `ssh_known_hosts` creates an entry for `work1` in `/etc/ssh/ssh_known_hosts` and states `action add up to date` for `work2` -- the message is a surprise, but in the correct direction.
 * Node work1: bootstrap, set run list, run chef client. Log into mbt as labrat. `ssh -i ~/.ssh/master.id_rsa root@work1.icp.site` logs into `work1` as `root`. Surprised, but pleased at the result.
 * Node work1: bootstrap, set run list, run chef client. Log into mbt as labrat. `ssh -i ~/.ssh/master.id_rsa root@work1.icp.site`. work2 is an unknown host.
 #4: Node mbp: run chef client. Chef adds `/etc/ssh/ssh_known_hosts` entries for work1 & work2. `ssh -i ~/.ssh/master.id_rsa root@work1.icp.site` logs into `work1` as `root`. Surprised, but pleased at the result.

## Notes
- v0.6.31 -- Installs the ICPce installer in the master/boot node. Will work on the ICPce installation code next. The code needs polish. Could improve the idempotent score in some spots. Need to separate the boot node from the master node. Current 00_master_node really creates the boot node. Should use parameters in templates for the ICP hosts and /etc/hosts files. Supply the ICPce version as a parameter. Rename the variable "user" to "login_user". Include the cluster name as a node parameter in the bootstrap and use it associate ssh keys with members of the ICP cluster.
