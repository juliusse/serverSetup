#http://docs.mongodb.org/manual/tutorial/install-mongodb-on-debian/
class mongodb {
  file { "10gen.list":
      path => "/etc/apt/sources.list.d/10gen.list",
      content => "deb http://downloads-distro.mongodb.org/repo/debian-sysvinit dist 10gen",
  }

  exec { "add MongoDB key server":
      command => "apt-key adv --keyserver keyserver.ubuntu.com --recv 7F0CEB10",
      require => File["10gen.list"],
  }

  exec { 'apt-get-update for MongoDB':
      command => '/usr/bin/apt-get update',
      require => Exec["add MongoDB key server"],
  }

  package { "mongodb-10gen":
      ensure => present,
      require => Exec['apt-get-update for MongoDB'],
  }

  file { "/etc/mongodb.conf":
      content => template("$stuff_folder/manifests/mongodb-conf.erb"),
      notify  => Service["mongodb"],
      require => [Package["mongodb-10gen"]],
  }

  service { "mongodb":
      ensure => running,
      enable  => "true",
      require => [Package["mongodb-10gen"]],
  }
}