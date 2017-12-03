###################
## Apache resources
###################
package node["apache_package"] do 
end


############################
## MySQL(/MariaDB) resources
############################
package node["mysql_package"] do
end

service node["mysql_service"] do
  action [:enable, :start]
end


###############################################################
## Pre-requiste python packages + other utilities for RHEL/CenOS
################################################################
package node["python_packages"] do
  ignore_failure true #So the receipe can proceed foward in case the Debian repos do not respond. 
		      #The AAR script will download the python/utility packages for Debian systems if the repos fail
end


package %w(python2-pip MySQL-python python-devel wget unzip) do
  only_if { node['platform_family'] == "rhel" }
end

#########################
## Downloading AAR script
#########################
remote_file '/tmp/master.zip' do
 source 'https://github.com/colincam/Awesome-Appliance-Repair/archive/master.zip'
 mode '0755'
 action :create
end

##################################################################
## Extracting and running the AAR script based off platform family
##################################################################
bash 'unzip master.zip' do
 code <<-EOH
   cd /tmp

   sudo unzip master.zip -d /tmp

   cd Awesome-Appliance-Repair-master/

   mv AAR /var/www/
  EOH
  not_if { ::File.exist?('/var/www/AAR') }
end

cookbook_file '/tmp/Awesome-Appliance-Repair-master/AARinstall.py' do
 source 'AARinstall_rhel.py'
 owner 'root'
 group 'root'
 mode '0755'
 only_if { node['platform_family'] == "rhel" }
end


cookbook_file '/tmp/Awesome-Appliance-Repair-master/AARinstall.py' do
  source 'AARinstall_ubuntu.py'
  owner 'root'
  group 'root'
  mode '0755'
  only_if { node['platform_family'] == "debian" }
end


bash 'runs the script' do
  code <<-EOH
   cd /tmp/Awesome-Appliance-Repair-master
   sudo python AARinstall.py
   EOH
  not_if { ::File.exist?('/var/www/AAR/AAR_config.py') }
end

######################################################################################
## Starting of Apache Service. This is last to show the logical flow of the recipe and
## to ensure proper order of execution of the receipe
######################################################################################
service node["apache_service"] do
  action [:start, :enable]
  subscribes :reload, 'bash[runs the script]', :immediately
end
