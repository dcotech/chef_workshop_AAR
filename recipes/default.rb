#
# Cookbook:: ARR
# Recipe:: default
#
# Copyright:: 2017, The Authors, All Rights Reserved.
#

if node['platform_family'] == "rhel"
	apache = "httpd"
	mysql = "mariadb"
elsif node['platform_family'] == "ubuntu"
	apache = "apache2"
	mysql = "mysql-server"
end

#apt_package %w(apache2 wget unzip mysql-server) do 
#end

package 'apache2' do 
  package_name apache
end

package 'mysql' do
  package_name mysql
end


service 'apache2' do
  action :start
end

service 'mysql' do 
  action :start
#  start_command 'sudo service mysql start'
end

remote_file '/tmp/master.zip' do
  source 'https://github.com/colincam/Awesome-Appliance-Repair/archive/master.zip'
  mode '0755'
  action :create
end


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
  source 'AARinstall.py'
  owner 'root'
  group 'root'
  mode '0755'
end

bash 'run script and manually restart apache' do
  code <<-EOH
    cd /tmp/Awesome-Appliance-Repair-master

    sudo python AARinstall.py

    sudo apachectl graceful
   EOH
  not_if { ::File.exist?('/usr/local/bin/flask') }
end
