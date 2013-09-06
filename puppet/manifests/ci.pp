notify{"using the ci.pp": }

Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/", "/usr/local/bin", ] }

import "common.pp"

import "users/*.pp"

$jenkinsPort = "9290"
$jenkinsContextPath = "ci"

#this approaches didn't worked:
#using http://pkg.jenkins-ci.org/debian/
#using https://wiki.jenkins-ci.org/display/JENKINS/Puppet
#beware of bug http://projects.puppetlabs.com/issues/13858


class jenkins {
  package { "jenkins-packages":
      name => ["openjdk-6-jdk", "unzip", "coreutils", "xvfb", "screen", "vim", "sudo", "ant", "git", "daemon", "inotify-tools"],
      ensure => present,
      require => Exec['apt-get-update'],
  }

  $debName = "jenkins_1.514_all.deb"

  exec { "get deb jenkins":
    command => "wget -c http://pkg.jenkins-ci.org/debian/binary/$debName",
    cwd => "/tmp",
    creates  => "/tmp/$debName",
    onlyif => "test ! -f tmp/$debName",
    require => [Package["jenkins-packages"]]
  }

  exec { "install deb":
    command => "dpkg -i $debName",
    cwd => "/tmp",
    require => Exec["get deb jenkins"]
  }

  $jenkinsConfigFile = "/etc/default/jenkins"

  file {"/var/lib/jenkins/.ssh":
      ensure => directory,
      recurse => true,
      purge => false,
      owner => "jenkins",
      group => "root",
      mode => 0600,
      source => "$manifest_folder/secrets/ci/ssh-jenkins",
      require => Exec["install deb"],
  }

  file {"/tmp/FULL-2013-05-19_12-04":
      ensure => directory,
      recurse => true,
      purge => true,
      force => true,
      owner => "jenkins",
      group => "root",
      mode => 0600,
      source => "$manifest_folder/secrets/ci/thin-backup",
  }

  file {"jvm-repo":
      path => "/var/www/repo",
      ensure => directory,
      owner => "jenkins",
      group => "root",
      mode => 644,
      require => Exec["install deb"],
  }

  file {"$jenkinsConfigFile":
      content => template("$manifest_folder/jenkins.conf.erb"),
      ensure => present,
      group => "root",
      owner => "root",
      mode => 644,
      require => Exec["install deb"],
      notify => Service["jenkins"]
  }

  service { "jenkins":
    ensure => running,
  }
}

include jenkins

class apache() {
  $domain = $deploy_environment ? {
      'dev' =>  "localhost",
      'prod' => "ci.docear.org"
  }

  package { "apache2":
    ensure => present,
    require => Exec['apt-get-update'],
  }

  file {"/var/log/apache2":
      ensure => "directory",
      group => "root",
      owner => "root"
  }

  define module ( $ensure = 'present') {
    case $ensure {
     'present' : {
        exec { "/usr/sbin/a2enmod $name":
          unless => "/bin/readlink -e ${apache2_mods}-enabled/${name}.load",
          require => Package["apache2"],
        }
      }
      'absent': {
         exec { "/usr/sbin/a2dismod $name":
           onlyif => "/bin/readlink -e ${apache2_mods}-enabled/${name}.load",
             require => Package["apache2"],
         }
      }
       default: { err ( "Unknown ensure value: '$ensure'" ) }
    }
  }

  exec { "reload-apache2":
      command => "/etc/init.d/apache2 reload",
      refreshonly => true,
  }

  exec { "force-reload-apache2":
      command => "/etc/init.d/apache2 force-reload",
      refreshonly => true,
  }

  module { "proxy":  }
  module { "proxy_http":  }
  module { "proxy_balancer":  }
  module { "ssl":  }
  module { "headers":  }
  module { "rewrite":  }

  file { "ssl-server-crt ":
      path    => "/etc/ssl/certs/server.crt",
      source => "$manifest_folder/secrets/ci/docear-ci.pem",
      require  => Package["apache2"],
      replace => false,
  }

  file { "ssl-server-key ":
      path    => "/etc/ssl/private/server.key",
      source => "$manifest_folder/secrets/ci/docear-ci.key",
      require  => Package["apache2"],
      replace => false,
  }

  file { "apache-conf":
      path    => "/etc/apache2/sites-available/default",
      content => template("$manifest_folder/apache-virtual-host-ci.erb"),
      require  => [Package["apache2"], Module["proxy"], Module["proxy_http"], Module["proxy_balancer"], Module["ssl"], Module["headers"], File["ssl-server-crt "], File["ssl-server-key "]],
      notify => Exec["force-reload-apache2"],
  }

  service { "apache2":
      ensure => running,
          require => [Package["apache2"], File["apache-conf"]],
  }
}

include apache
