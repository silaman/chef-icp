# IBM Cloud Private (ICP) Installation Cookbook
This cookbook combines the the boot and master nodes in the same VM, and is suitable only for ICP clusters with a single master node. The cookbook automates the sharing of SSH keys, modifies sysctl parameters in the master node, installs Docker CE on the boot node, pulls down and extracts the ICPce 2.1.0 Inception installer. You will have to run the final ICPce installation command manually.

The files in the templates folder DO NOT (currently) use parameters. They will just replace the target files in the nodes.
- templates/icpce_cluster_hosts.erb will replace cluster/hosts file in the boot node
- templates/etc_hosts.erb will replace /etc/hosts in all nodes

*** Use a `markdown` reader *** Open the file in Atom and press `Ctrl-Shift-M`

## Issues, Bugs, Suggestions, Join Hands
Please post issues in github. Let me know if you have time to implement features.

## Future plans
- Separate the boot and master nodes in the cookbook. Will make it possible to define multiple master nodes.
- Incorporate ICPce installation command in a recipe. Complication: run the installation only when all nodes have been prepared
- Use parameters in templates to define the ICP cluster.
- Capture the ICP cluster name of the node in the chef bootstrap command.
- Capture the node's ICP role (boot, master, worker, proxy) in the bootstrap command.
- GlusterFS on master node
- TLS Private CA
- HA architecture
- Support Redhat nodes (cookbook tested on Ubuntu 16.04 nodes)

## Required Environment
Create Ubuntu 16.04 server VMs (no need for GUI). Recommend at least 4CPU & 12GB memory for the master node. The other nodes can make do with 1CPU & 4GB (maybe even 2GB). About 40GB disk space is adequate for dev. The nodes should have static IP addresses and access to the public internet. Assuming you are using VirtualBox, you have two choices for networking:
- Bridged: A single network interface for each VM. VirtualBox Bridged interfaces are usually able to access the internet.
- NAT + HostOnly: Each VM should have two network interfaces: #1 NAT and #2 host-only. Put the host-only IP addresses in both files in templates folder.

You will also need a Chef Server. I use a 2CPU 6GB VM, but 1CPU 4GB should be okay. After you set up the chef-repo (starter kit), load the `icp` cookbook with `berks upload`.

## Usage
The commands below were tested on Ubuntu VMs with two network interfaces, NAT & HostOnly.

### Setup DNS & Define ICP Cluster
These files are in the chef `templates` folder. You must setup `/etc/hosts` even if DNS resolution exists in the network. This cookbook is not yet ready for ICP production installations. Enter values into:
- templates/icpce_cluster_hosts.erb: Define nodes of the ICP cluster as this file will replace the  cluster/hosts file in the boot node
- templates/etc_hosts.erb: Setup DNS as this file will replace /etc/hosts in all nodes

### Bootstrap nodes
Chef makes node's NAT as the default "ipaddress". The custom attribute "chef_ip" stores the HostOnly IP for use by chef commands. Need to specify -P password in the command line for the option "--use-sudo-password".
- Master node

  `knife bootstrap 192.168.56.30 -x <userid> -N icp-mbp --sudo --json-attributes '{ "chef_ip": "192.168.56.30" }' --use-sudo-password -P <pswd>`

- Worker node 1

  `knife bootstrap 192.168.56.31 -x <userid> -N icp-work1 --sudo --json-attributes '{ "chef_ip": "192.168.56.31" }' --use-sudo-password -P <pswd>`

- Worker node 2

  `knife bootstrap 192.168.56.32 -x <userid> -N icp-work2 --sudo --json-attributes '{ "chef_ip": "192.168.56.32" }' --use-sudo-password -P <pswd>`

### Add run list to node
Chef can combine bootstrap with run-list and execute the recipes. Worked okay for node `mbp`, but threw error with `work1`. Inexplicable, as the discreet knife chef-client invocation worked smoothly with no changes to the cookbook. So, let's run bootstrap, run-list and chef-client separately.
- Master node

  `knife node run_list set icp-mbp 'recipe[icp::default],recipe[icp::00_master_node],recipe[icp::13_extract_icpce_installer]'`

- Worker node 1

  `knife node run_list set icp-work1 'recipe[icp::default],recipe[icp::10_worker_node]'`

- Worker node 2

  `knife node run_list set icp-work2 'recipe[icp::default],recipe[icp::10_worker_node]'`

### Run chef-client
- Master node

  `knife ssh 'name:icp-mbp' 'sudo chef-client' --ssh-user <userid> --ssh-password '<pswd>' --attribute chef_ip`

- Worker node 1 (put boot node's master.id_rsa.pub key into authorized_keys)

  `knife ssh 'name:icp-work1' 'sudo chef-client' --ssh-user <userid> --ssh-password '<pswd>' --attribute chef_ip`

- Worker node 2

  `knife ssh 'name:icp-work2' 'sudo chef-client' --ssh-user <userid> --ssh-password '<pswd>' --attribute chef_ip`

- Master node (yes, again, to pull in the latest `known_hosts` keys from ICP nodes)

  `knife ssh 'name:icp-mbp' 'sudo chef-client' --ssh-user <userid> --ssh-password '<pswd>' --attribute chef_ip`

### Run ICPce Installation
The final installation step is currently manual. It should be run after all ICPce nodes have been prepared by chef. I plan to integrate this step into chef soon. Log into the boot node and run the two commands below. The installation takes between 20 to 35 minutes. The ICP console might take another 15 minutes to start, depending the master node's resources.

  `cd /opt/ibm-cloud-private-ce/cluster/`

  `sudo docker run -e LICENSE=accept --net=host -t -v "$(pwd)":/installer/cluster ibmcom/icp-inception:2.1.0 install`

You should be able to log into the ICP console at `https://<master node ip>:8443` in about 45 minutes.
