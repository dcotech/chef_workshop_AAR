
###################
### Apache resources
####################
package node["apache_package"] do
end

###################################################################################################
### Pre-requiste python packages + other core utilities. Note, for RHEL systems, the EPEL repostiory 
### must be converged first before installing the other python packages
####################################################################################################
package node["python_packages"] do
  ignore_failure true #So the receipe can proceed foward in case the Debian repos do not respond.
		      #The AAR script will download the python/utility packages for Debian systems if the repos fail
end

package %w(python-pip MySQL-python python-devel) do
  only_if { node['platform_family'] == "rhel" }
end


package 'unzip' do #Add any platform agnostic utilities here
end


###################
### MySQL resources
###################
package node["mysql_package"] do
end

service node["mysql_service"] do
 action [:enable, :start]
 only_if { node['platform_family'] == "rhel" }
end

###################################################################################
### Older Debian-based systems seem to have a problem with the service resource.
### The bottom is a bash resource to issue the commands. When a solution is reached,
### the service resource will be used for both platforms.
####################################################################################
bash 'start mysql/apache2 service on debian-based systems' do
  code <<-EOH
    sudo service mysql start
    sudo service apache2 start
  EOH
  not_if { ::File.exist?('/var/www/AAR') }
end

###################################################################################
### Downloading the AAR script. This is for the other WSGI/python utilites to ensure
### the website functions 
####################################################################################
remote_file '/tmp/master.zip' do
  source 'https://github.com/colincam/Awesome-Appliance-Repair/archive/master.zip'
  mode '0755'
  action :create
end


#########################################################################################
### Extracting and running the AAR script based off platform family for proper permissions
### and directory placement
##########################################################################################
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
  only_if { node['platform_family'] == "rhel"}
end


cookbook_file '/tmp/Awesome-Appliance-Repair-master/AARinstall.py' do
  source 'AARinstall_ubuntu.py'
  owner 'root'
  group 'root'
  mode '0755'
  only_if { node['platform_family'] == "debian" }
end

bash 'run script and manual restart apache' do
  code <<-EOH
    cd /tmp/Awesome-Appliance-Repair-master

    sudo python AARinstall.py

    sudo apachectl graceful
   EOH
  not_if { ::File.exist?('/var/www/AAR/AAR_config.py') }
end

######################################################################################
### Starting of Apache Service. This is last to show the logical flow of the recipe and
### to ensure proper order of execution of the receipe
#######################################################################################
service node["apache_service"] do
  action [:enable, :start]
end


