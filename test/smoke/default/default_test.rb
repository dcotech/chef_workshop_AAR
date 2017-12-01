# # encoding: utf-8

# Inspec test for recipe ARR::default

# The Inspec reference, with examples and extensive documentation, can be
# found at http://inspec.io/docs/reference/resources/

unless os.windows?
  # This is an example test, replace with your own test.
  describe user('root'), :skip do
    it { should exist }
  end
end

# This is an example test, replace it with your own test.
describe port(80), :skip do
  it { should_not be_listening }
end

%w( apache2 wget unzip mysql-server libapache2-mod-wsgi python-pip python-mysqldb ).each do |pkg|
   describe package(pkg) do
      it { should be_installed }
   end
end

%w( apache2 mysql).each do |service|
   describe service(service) do 
      it { should be_running }
   end
end
describe file('/tmp/master.zip') do
  it { should exist }
end

