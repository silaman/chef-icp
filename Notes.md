## VirtualBox Ubuntu network interfaces
Create VBox VM with #1 NAT & #2 HostOnly network interfaces. Boot the machine. `ifconfig` will show only the NAT is active. `ifconfig -a` shows the second interface as `enp0s8`. Edit `/etc/network/interfaces` and assign a static IP to the HostOnly interface:

```
# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

source /etc/network/interfaces.d/*

# The loopback network interface
auto lo
iface lo inet loopback

# The primary network interface
auto enp0s3
iface enp0s3 inet dhcp

# Secondary network interface has static IP (added manually)
auto enp0s8
iface enp0s8 inet static
address 192.168.56.10
netmask 255.255.255.0
network 192.168.56.0
```
Restart the networking service:

`sudo systemctl restart networking.service`

Make doubly sure with a reboot and `ping google.com`.

### IP Address, Hostname & /etc/hosts

After setting the IP address for the node, modify `/etc/hostname` and `/etc/hosts`. 
```
labrat@boot:~$ cat /etc/hosts
127.0.0.1	localhost
127.0.1.1	boot.icp.site	boot

# The following lines are desirable for IPv6 capable hosts
::1     localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
```
```
labrat@boot:~$ cat /etc/hostname
boot.icp.site
```


## Watch Out
These scenarios can cause a problem. It might be possible to develop a solution to eliminate the problem. Until then, watch out.

### VM Restore
- When a VM is restored to a snapshot before it became a chef node through a bootstrap, the corresponding node should be deleted. If the node is not deleted and we run the recipe 12_master_node, the ssh_known_hosts function will create a known_hosts entry with the node's client key, which is invalid as the corresponding VM does not exist. When we bootstrap the restored VM, chef will create a new node and client key, compounding the problem.

***Correction. This does NOT seem to be a problem. See test results below***

 * Restore all VM to pre bootstrap. Do not delete nodes from Chef. Start mbp & work1 (work2 powered off). Node mpb: bootstrap, set run list, run chef client. `ssh_known_hosts` creates an entry for `work1` in `/etc/ssh/ssh_known_hosts` and states `action add up to date` for `work2` -- the message is a surprise, but in the correct direction.
 * Node work1: bootstrap, set run list, run chef client. Log into mbt as labrat. `ssh -i ~/.ssh/master.id_rsa root@work1.icp.site` logs into `work1` as `root`. Surprised, but pleased at the result.
 * Node work1: bootstrap, set run list, run chef client. Log into mbt as labrat. `ssh -i ~/.ssh/master.id_rsa root@work1.icp.site`. work2 is an unknown host.
 #4: Node mbp: run chef client. Chef adds `/etc/ssh/ssh_known_hosts` entries for work1 & work2. `ssh -i ~/.ssh/master.id_rsa root@work1.icp.site` logs into `work1` as `root`. Surprised, but pleased at the result.

## Notes
- v0.6.31 -- Installs the ICPce installer in the master/boot node. Will work on the ICPce installation code next. The code needs polish. Could improve the idempotent score in some spots. Need to separate the boot node from the master node. Current 00_master_node really creates the boot node. Should use parameters in templates for the ICP hosts and /etc/hosts files. Supply the ICPce version as a parameter. Rename the variable "user" to "login_user". Include the cluster name as a node parameter in the bootstrap and use it associate ssh keys with members of the ICP cluster.
