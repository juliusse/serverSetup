if [[ $EUID -ne 0 ]]; then
  echo "You must be a root user. Call with sudo." 2>&1
  exit 1
fi

#http://docs.puppetlabs.com/guides/installation.html#installing-from-gems-not-recommended
apt-get remove --assume-yes puppet
apt-get --assume-yes autoremove
apt-get install --assume-yes rubygems && \
gem install --no-rdoc --no-ri puppet -v 2.7.19 && \
ln /var/lib/gems/1.8/bin/puppet /sbin/puppet && \
puppet resource group puppet ensure=present && \
puppet resource user puppet ensure=present gid=puppet shell='/sbin/nologin' && \
cp /var/lib/gems/1.8/gems/puppet-2.7.19/conf/auth.conf /etc/puppet/auth.conf && \
puppet --version