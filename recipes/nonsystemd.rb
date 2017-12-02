
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

package 'apache2' do
  package_name apache
end

package 'mysql' do
  package_name mysql_package
end

package 'python packages' do
  package_name python_package
  ignore_failure true
end

package %w(python2-pip MySQL-python python-devel) do
  only_if { node['platform_family'] == "rhel" }
end

package %w(wget unzip) do
end


service 'httpd' do
  #service_name apache
  action [:enable, :start]
  #not_if { node['platform_version'] <= "14.04"}
end


service 'mysql' do
  service_name mysql_service
  action [:start, :enable]
  only_if { node['platform_family'] == "rhel"}
end


#bash 'start mysql/apache2 service on debian-based non-systemD systems' do
#  code <<-EOH
#    sudo service mysql start
#    sudo service apache2 start
#  EOH
#  not_if { ::File.exist?('/tmp/Awesome-Appliance-') }
#  end

bash 'start mysql/apache2 service on debian-based systems' do
  code <<-EOH
    sudo service mysql start
    sudo service apache2 start
  EOH
  not_if { node['platform_family'] == "rhel" }
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

bash 'run script' do
  code <<-EOH
    cd /tmp/Awesome-Appliance-Repair-master

    sudo python AARinstall.py

    sudo apachectl graceful
   EOH
  not_if { ::File.exist?('/var/www/AAR/AAR_config.py') }
end

