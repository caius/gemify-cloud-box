# All this done as root

# Add a rails user with sudo access & ssh copied from ubuntu user
# todo: figure out how to automate it, currently interactive
adduser rails
cp -r /home/ubuntu/.ssh /home/rails/.ssh
chown -R rails:rails /home/rails/.ssh

# Add to admin group for automatic sudo access
usermod -a -G admin rails

# Add rails to ssh allowed users
echo "AllowUsers ubuntu@*" >> /etc/ssh/sshd_config
echo "AllowUsers rails@*" >> /etc/ssh/sshd_config
restart ssh

# Add brightbox repositories
wget http://apt.brightbox.net/release.asc -O - | apt-key add -
wget -c http://apt.brightbox.net/sources/lucid/brightbox.list -P /etc/apt/sources.list.d/
wget -c http://apt.brightbox.net/sources/lucid/rubyee.list -P /etc/apt/sources.list.d/
# Grab the packages
aptitude update

# Install ruby/ruby-ee/rubygems
aptitude -y install ruby1.8 ruby1.8-dev ri1.8 rdoc1.8 irb1.8 ruby1.8-examples libdbm-ruby1.8 libgdbm-ruby1.8 libtcltk-ruby1.8 libopenssl-ruby1.8 libreadline-ruby1.8 ruby ri rdoc irb rubygems1.8 rubygems

# Stop gem burning cpu cycles for no reason
sudo -u rails sh -c 'echo "gem: --no-ri --no-rdoc --no-user-install" >> /home/rails/.gemrc'
sudo -u ubuntu sh -c 'echo "gem: --no-ri --no-rdoc --no-user-install" >> /home/ubuntu/.gemrc'

# Install some basic gems
gem install rake bundler brightbox-server-tools

# Install git & db stuff
aptitude -y install git-core sqlite3 libsqlite3-dev libmysqlclient-dev mysql-client

# Install apache
mkdir -p /var/log/web
aptitude -y install apache2 apache2-utils apache2-mpm-worker

# Setup config & restart apache
curl -s -o /etc/apache2/apache2.conf ./apache2.conf
/etc/init.d/apache2 restart

# Install postfix for monit to use
DEBIAN_FRONTEND=noninteractive aptitude -y install postfix

# Install monit
aptitude -y install monit
mv /etc/monit/monitrc /etc/monit/monitrc.dpkg-dist

# Setup some monit config
curl -s -o /etc/monit/monitrc ./monitrc
curl -s -o /etc/monit/conf.d/disk-space.monitrc ./disk-space.monitrc
curl -s -o /etc/monit/conf.d/general.monitrc ./general.monitrc
curl -s -o /etc/monit/conf.d/email-alerts.monitrc ./email-alerts.monitrc

# Mark monit as being ok to start
sed -e "s/startup=0/startup=1/" -i /etc/default/monit
# Start monit
/etc/init.d/monit start
