# IBM Cloud Private (ICP) Installation Cookbook
This cookbook can install ICP nodes (boot, master, worker, proxy & management) in separate virtual machines (VM) and can scale the installation to multiple nodes (except boot). Each item in data bag `icp_cluster` defines a node. To put the master into the boot node, set the parameter `boot_is_master` to `true` in the `icp_cluster` boot item. The data bag `icp_parts_list` enumerates components such as Docker and ICPce.

### `v0.7.38`
- Validated to install ICP ce across multiple Ubuntu 16.04 nodes
- `config.yaml` is the default file. The next cookbook version will pull in your custom file. No plans to make a chef template for `config.yaml`.
- `hosts` is pulled in from the chef templates folder. You should enter values into `icpce_cluster_hosts.erb`. The next cookbook version will compose the file using the data bag `icp_cluster`. If you set `boot_is_master` to `true`, you should put the boot node IP in the `master` stanza.  Ignore `icp_cluster_hosts.erb` -- nexgen template.
- You have to run the final ICPce installation command manually from the boot node.

## Issues, Bugs, Suggestions, Join Hands
Please post issues in github. Let me know if you have time to contribute ideas and implement features.

## Future plans
- Incorporate ICP installation command in a recipe. The installer should run only when boot can `ssh` into all nodes
- GlusterFS
- TLS Private CA
- HA architecture
- Chef Solo/Zero: Can we remove the Chef Server requirement?
- Support Redhat nodes

## Environment
Create Ubuntu 16.04 server VMs (no need for GUI) with static IP addresses and access to the public internet. Assuming you use VirtualBox, you have two choices for networking:
- Bridged: A single network interface for each VM. VirtualBox Bridged interfaces should be able to access the internet.
- NAT + HostOnly: Each VM should have two network interfaces: #1 NAT and #2 host-only. Put the host-only IP addresses in `templates/icpce_cluster_hosts.erb` and the corresponding `icp_cluster` item.

The cluster requires a fair amount of computer resources. My lab machine: Intel i7 CPU (circa 2013) with 32 GB
- boot node:      2CPU 6GB    4CPU 12GB if `boot_is_master`
- master node:    4CPU 12GB   -- N/A -- if `boot_is_master`
- worker, proxy:  1CPU 2GB
- management:     1CPU 4GB

You also need a Chef Server (1CPU 4GB). After you set up the chef-repo (starter kit), load the `icp` cookbook with `berks install` and `berks upload`.

### Define ICP Cluster
- `templates/icpce_cluster_hosts.erb`: Define nodes of the ICP cluster as you would for a manual installation. The cookbook will replace `cluster/hosts` in the boot node with this file.
- Data bag `icp_cluster`: Each item defines a node in the cluster. The boot node has an additional setting `boot_is_master`.

## Usage
The steps are simple for a small cluster. Run chef commands to bootstrap the nodes, assign run lists, and execute the recipes. We need to develop another layer of automation for large clusters.

If you use VirtualBox NAT+HostOnly network interfaces, Chef will make the node's NAT as the default "ipaddress". Hence, the custom attribute `ibm.icp_node_ip` in the command lines. The option `--use-sudo-password` requires `-P <pswd>` in the command line. You could define the run list in the bootstrap command. I prefer to separate them. The commands below were tested on Ubuntu VMs with two network interfaces, NAT & HostOnly.

- Bootstrap each node

  `knife bootstrap 192.168.56.20 -x <userid> -N icp-boot --sudo --json-attributes '{ "ibm": { "icp_node_id" : "boot", "icp_node_ip": "192.168.56.20" } }' --use-sudo-password -P <pswd>`

- Add run list. All nodes use the same run list (all recipes).

  `knife node run_list set icp-boot 'recipe[icp::default],recipe[icp::00_boot_node],recipe[icp::05_master_node],recipe[icp::10_w_p_m_node],recipe[icp::13_icp_installer]'`

- Process recipes on each node. And once again on the boot node to pick up the current known_hosts keys for the cluster.

  `knife ssh 'name:icp-boot' 'sudo chef-client' --ssh-user <userid> --ssh-password '<pswd>' --attribute ibm.icp_node_ip`

- Run ICP Installer
The final installation step is manual, and should be run after all the nodes have been prepared. Log into the boot node and run the two commands below. The installation takes between 20 to 35 minutes. The ICP console might take another 15 minutes to start, depending the master node's resources.

  `cd /opt/ibm-cloud-private-ce/cluster/`

  `sudo docker run -e LICENSE=accept --net=host -t -v "$(pwd)":/installer/cluster ibmcom/icp-inception:2.1.0 install`
