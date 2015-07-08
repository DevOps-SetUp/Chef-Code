#
# Cookbook Name:: saas_bizx_seb
# Recipe:: default
#
# Copyright 2015, SAP Bizx
#
# All rights reserved - Do Not Redistribute
#

# Create sfuser group for SEB installton

group node[:saas_bizx_seb][:groupName] do
 action :create
end

# create sfuser user for SEB installation

user node[:saas_bizx_seb][:userName] do
 action :create
end

# get the Installation file from moo repo to application home dir

directory "#{node["saas_bizx_seb"]["homeDir"]}" do
 action :create
 recursive true
 owner node["saas_bizx_seb"]["userName"]
end

# download file from moo repo

remote_file "#{node["saas_bizx_seb"]["homeDir"]}/#{node["saas_bizx_seb"]["file_name"]}.tar" do
 source "#{node["saas_bizx_seb"]["repo"]}/#{node["saas_bizx_seb"]["file_name"]}.tar"
 mode '0644'
 owner node["saas_bizx_seb"]["userName"]
 group node["saas_bizx_seb"]["groupName"]
# not_if { ::File.exists?("#{node["saas_bizx_seb"]["homeDir"]}/#{node["saas_bizx_seb"]["file_name"]}.tar" )}
 notifies :run, 'bash[Untar]', :immediately 
# subscribes :run, 'bash[Untar]', :immediately
end

#extract the tar file

bash "Untar" do
 action :nothing
 cwd "#{node["saas_bizx_seb"]["homeDir"]}"
 user node["saas_bizx_seb"]["userName"]
 group node["saas_bizx_seb"]["groupName"]
 code <<-EOH
  tar xvf "#{node["saas_bizx_seb"]["homeDir"]}/#{node["saas_bizx_seb"]["file_name"]}.tar"
 EOH
end

# Create csv file with hornet server details

template "#{node["saas_bizx_seb"]["homeDir"]}/serverlist.csv" do
 source "serverlist.csv.erb"
 action :create
 owner node["saas_bizx_seb"]["userName"]
 group node["saas_bizx_seb"]["groupName"]
 mode '0644'
  variables ({
	:HOSTNAME => node["saas_bizx_seb"]["hostName"],
	:HOST_IP =>  node["saas_bizx_seb"]["hostIP"],
	:SEB_USER => node["saas_bizx_seb"]["sebUser"],
	:SEB_PASSWD => node["saas_bizx_seb"]["sebPassword"],
	:BACKUP_FLAG => node["saas_bizx_seb"]["backupFlag"],
	:SEB_PRIMARY1_IP => node["saas_bizx_seb"]["sebPrimary1_IP"],
	:SEB_BACKUP1_IP => node["saas_bizx_seb"]["sebBackup1_IP"],
	:SEB_PRIMARY2_IP => node["saas_bizx_seb"]["sebPrimary2_IP"],
	:SEB_BACKUP2_IP  => node["saas_bizx_seb"]["sebBackup2_IP"]
      })
end 

# execute the commands to install SEB Server

execute "install SEB" do
 cwd "#{node["saas_bizx_seb"]["homeDir"]}"
 user node["saas_bizx_seb"]["userName"]
 group node["saas_bizx_seb"]["groupName"]
 command "./Install_SEB_jboss-eap-6.2.sh serverlist.csv"
 action :run
 not_if { ::File.exists? ("#{node["saas_bizx_seb"]["homeDir"]}/jboss-eap-6.2" )}
end 

# UPdate Java Environment variables

template "#{node["saas_bizx_seb"]["homeDir"]}/.profile" do
 source ".profile.erb"
 mode '0644'
 owner node["saas_bizx_seb"]["userName"]
 group node["saas_bizx_seb"]["groupName"]
end
