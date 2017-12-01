#
# Cookbook:: ARR
# Recipe:: default
#
# Copyright:: 2017, The Authors, All Rights Reserved.
#
apt_package %w(apache2 wget unzip mysql-server) do 
end


bash 'start mysql/apache2 service' do
  code <<-EOH
    sudo service mysql start

    sudo service apache2 start
  EOH
  not_if { ::File.exist?('/var/www/AAR') }
end

remote_file '/tmp/master.zip' do
  source 'https://github.com/colincam/Awesome-Appliance-Repair/archive/master.zip'
  mode '0755'
  action :create
end


bash 'unzip master.zip and installing flask' do
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
