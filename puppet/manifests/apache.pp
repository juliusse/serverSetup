#http://projects.puppetlabs.com/projects/1/wiki/Debian_Apache2_Recipe_Patterns
class apache($htpasswd_file_path = "/etc/apache2/.htpasswd") {
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
  module { "headers":  }
  module { "rewrite":  }


  file { "apache htpasswd":
      path => "$htpasswd_file_path",
      content => file("$stuff_folder/manifests/htpasswd"),
      require => Package["apache2"],
  }

  file { "apache-conf":
      path    => "/etc/apache2/sites-available/default",
      content => template("$stuff_folder/manifests/apache-virtual-host.erb"),
      require  => [Package["apache2"], Module["proxy"], Module["proxy_http"], Module["proxy_balancer"], Module["headers"]],
      notify => Exec["force-reload-apache2"],
  }

  service { "apache2":
    ensure => running,
    require => [Package["apache2"], File["apache-conf"]],
  }
}