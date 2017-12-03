case node["platform_family"]
when "debian"
   default["apache_package"] = "apache2"   
   default["apache_service"] = "apache2"
   default["mysql_package"] = "mysql-server"
   default["mysql_service"] = "mysql"
   default["python_packages"] = %(libapache2-mod-wsgi python-pip python-mysqldb)
when "rhel"
   default["apache_package"] = "httpd"
   default["apache_service"] = "httpd"
   default["mysql_package"] = "mariadb-server"
   default["mysql_service"] = "mariadb"
   default["python_packages"] = %w(mod_wsgi python-setuptools epel-release) 
end


