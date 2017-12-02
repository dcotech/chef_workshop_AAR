###############################################################################################################
## variables - we have a variable because these packages needed to be installed first before we can 
## install pip and use the AAR script. Note this also differentiates the package names between platforms
###############################################################################################################
if node['platform_family'] == "rhel"
	apache = "httpd"
	mysql_package = "mariadb-server"
	mysql_service = "mariadb"
	python_package = %w(mod_wsgi python-setuptools epel-release)
elsif node['platform_family'] == "debian"
	apache = "apache2"
	mysql_package = "mysql-server"
	mysql_service = "mysql"
	python_package = %w(libapache2-mod-wsgi python-pip python-mysqldb)
end

###################
## Apache resources
###################
package 'apache2' do 
  package_name apache #This will evaulate the platform and install the correct pakage
end


############################
## MySQL(/MariaDB) resources
############################
package 'mysql' do
  package_name mysql_package
end

service 'mysql' do
  service_name mysql_service
  action [:enable, :start]
end


###############################################################
## Pre-requiste python packages + other utilities for RHEL/CenOS
################################################################
package 'python packages' do
  package_name python_package
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
service 'apache2' do
  action [:start, :enable]
  service_name apache
  subscribes :reload, 'bash[runs the script]', :immediately
end
