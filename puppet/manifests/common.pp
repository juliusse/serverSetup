exec { 'apt-get-update':
    command => '/usr/bin/apt-get update'
}

#Server Time NTP: http://articles.slicehost.com/2010/11/8/using-ntp-to-sync-time-on-debian
package { "ntp":
    ensure => present,
    require => Exec['apt-get-update'],
}

exec { "set timezone":
    command => 'echo "Europe/Berlin" > /etc/timezone && dpkg-reconfigure -f noninteractive tzdata'
}

service { 'ntp':
    ensure => "running",
    enable  => "true",
    require => [[Package["ntp"]], Exec["set timezone"]]
}

# disable password promp for sudo users
line { "nopasswd-sudo":
    file => "/etc/sudoers",
    line => "%sudo ALL=(ALL) NOPASSWD: ALL",
}
# disable ssh login via password
line { "no-pass-login":
    file => "/etc/ssh/sshd_config",
    line => "PasswordAuthentication no",
}
# disable root ssh login
line { "no-root-ssh":
    file => "/etc/ssh/sshd_config",
    line => "PermitRootLogin no",
}
#
line { "RSAAuthentication-ssh":
    file => "/etc/ssh/sshd_config",
    line => "RSAAuthentication yes",
}
#
line { "PubkeyAuthentication-ssh":
    file => "/etc/ssh/sshd_config",
    line => "PubkeyAuthentication yes",
}
#
line { "UsePAM-ssh":
    file => "/etc/ssh/sshd_config",
    line => "UsePAM no",
}
#
line { "ChallengeResponseAuthentication-ssh":
    file => "/etc/ssh/sshd_config",
    line => "ChallengeResponseAuthentication no",
}

exec { 'reload-ssh':
    command => '/etc/init.d/ssh reload',
    require => [Line['no-pass-login'],Line['no-root-ssh'],Line['RSAAuthentication-ssh'],Line['PubkeyAuthentication-ssh'],Line['UsePAM-ssh'],Line['ChallengeResponseAuthentication-ssh']]
}

define add_user($username, $full_name, $home, $shell = "/bin/bash", $main_group = "$username", $groups = [], $ssh_key = "", $ssh_key_type = "") {
  user { $username:
      comment => "$full_name",
      home    => "$home",
      shell   => "$shell",
      managehome => true,
          gid => "$main_group",
      groups => $groups,
          require => [Group["$username"]]
  }

  if $ssh_key {
      ssh_authorized_key{ $username:
          user => "$username",
          ensure => present,
              type => "$ssh_key_type",
          key => "$ssh_key",
          name => "$username",
          require => User[$username]
      }
  }

  group { $username:
      ensure => "present",
  }

  file {"$home init rights":
      path => $home,
  ensure  => "directory",
      mode  => '0660',
      owner => $username,
          group => $username,
          recurse => true,
          require => User[$username]
  }
}


# add a line to a file
# http://projects.puppetlabs.com/projects/1/wiki/Simple_Text_Patterns
define line($file, $line, $ensure = 'present') {
  case $ensure {
    default : { err ( "unknown ensure value ${ensure}" ) }
    present: {
      exec { "/bin/echo '${line}' >> '${file}'":
        unless => "/bin/grep -qFx '${line}' '${file}'"
      }
    }
    absent: {
      exec { "/bin/grep -vFx '${line}' '${file}' | /usr/bin/tee '${file}' > /dev/null 2>&1":
        onlyif => "/bin/grep -qFx '${line}' '${file}'"
      }
    }
  }
}