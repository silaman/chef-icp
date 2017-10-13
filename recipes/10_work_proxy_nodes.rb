#
# Cookbook:: icp
# Recipe:: os_parms
#  For all nodes
# Copyright:: 2017, The Authors, All Rights Reserved.




ruby_block 'ssh_store_key' do
  block do

    def add_key_to_authorized_keys(key)
      open(File.expand_path('~/.ssh/authorized_keys'), 'a') do |f|
        if File.readlines(f).grep("#{key}").any?
          Chef::Log.info("key is already in authorized keys")
        else
          Chef::Log.info("Adding SSH KEY to authorized keys")
          f << key
        end
      end
    end

#    ssh_public_key = ::File.open(::File.expand_path("~/.ssh/id_rsa.pub")).readline
#    node.normal['ibm']['cluster_ssh_key'] = ssh_public_key
#    node.save

    master_pub_key = ""
    loop_max_tries = 100
    attempts = 1

    while attempts <= loop_max_tries
      Chef::Log.info("attempts: #{attempts} - loop_max_tries: #{loop_max_tries}")
      search(:node, "role:'icp_master_node'") do |n|
        master_pub_key = n['ibm']['icp_master_pub_key']
      end

      if !master_pub_key.to_s.empty?
        Chef::Log.info("-- master_pub_key #{master_pub_key}")
        break
      end

      sleep 10
      attempts += 1
    end

    if master_pub_key.to_s.empty?
      raise "EXITING: Cannot determine master_pub_key"
    end

    sleep 20

    if cluster_properties['primary'] == node.name
      add_key_to_authorized_keys(secondary_ssh_key)
    else
      add_key_to_authorized_keys(master_pub_key)
    end

  end

end
