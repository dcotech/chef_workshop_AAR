
if node['platform_family'] == "rhel"
        apache = "httpd"
        mysql_package = "mariadb-server"
	mysql_service = "mariadb"
	python_package = %w(mod_wsgi python-setuptools epel-release)
	
elsif node['platform_family'] == "ubuntu"
        apache = "apache2"
        mysql_package = "mysql-server"
	mysql_service = "mysql"
	python_package = %w(libapache2-mod-wsgi python-pip python-mysqldb)
end

#apt_package %w(apache2 wget unzip mysql-server) do
#end

package 'apache2' do
  package_name apache
end

package 'mysql' do
  package_name mysql_package
end

package 'python packages' do
  package_name python_package
end

package %w(python2-pip MySQL-python python-devel) do
  only_if { node['platform_family'] == "rhel" }
end

package %w(wget unzip) do
end

service 'mysql' do
  service_name mysql_service
  action [:start, :enable]
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
  not_if { ::File.exist?('/var/www/AAR/AAR_config.py') }
end

#cookbook_file '/etc/httpd/conf.d/AAR-httpd.conf' do
 # source 'AAR-httpd.conf'
 #  owner 'apache'
 #  group 'apache'
 #  action :create_if_missing
#end

bash 'run script' do
  code <<-EOH
    cd /tmp/Awesome-Appliance-Repair-master
    sudo python AARinstall.py
   EOH
  not_if { ::File.exist?('/var/www/AAR/AAR_config.py') }
end

service 'apache2' do
  service_name apache
  action :start
end

