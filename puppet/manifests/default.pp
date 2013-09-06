notify{"The deploy_environment is: ${deploy_environment}": }

Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/", "/usr/local/bin", ] }

import "common.pp"

import "mongodb.pp"
include mongodb

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

include apache

#coreutils contains nohup
package { "packages":
  name => ["openjdk-6-jre", "unzip", "coreutils", "vim", "sudo"],
  ensure => present,
  require => Exec['apt-get-update'],
}

$js_homepage_username = "js_homepage"
$js_homepage_artifact_folder = "/home/import/$js_homepage_username"
$js_homepage_home = "/var/$js_homepage_username"
$js_homepage_home_path = "$js_homepage_home/current"
$js_homepage_config_resource = "prod.conf"
$js_homepage_version = "js_homepage-3.0"

add_user { "$js_homepage_username":
  username => "$js_homepage_username",
  full_name => "js_homepage server",
  home => $js_homepage_home,
}

define add_init_script($name, $application_path, $start_command, $user, $group, $pid_file, $current_working_dir, $unzipped_foldername) {

  file {"/etc/init.d/$name":
      content => template("$stuff_folder/manifests/init-with-pid.erb"),
      ensure => present,
      group => "root",
      owner => "root",
      mode => 750,
  }

  exec {"activate /etc/init.d/$name":
      command => "update-rc.d $name defaults",
      require => File["/etc/init.d/$name"]
  }
}

package {"inotify-tools":
    require => Exec['apt-get-update'],
}

define add_redeploy_init_script($name, $artifact) {
  $redeploy_name="$name-redeploy"

  file {"/etc/init.d/$redeploy_name":
      content => template("$stuff_folder/manifests/redeploy-daemon.erb"),
      ensure => present,
      group => "root",
      owner => "root",
      mode => 750,
      require => Package["inotify-tools"],
  }

  exec {"activate /etc/init.d/$redeploy_name":
      require => File["/etc/init.d/$redeploy_name"],
      command => "update-rc.d $redeploy_name defaults",
      notify => Service["$redeploy_name"],
  }

  service { "$redeploy_name":
      ensure => "running",
      enable  => "true",
      hasstatus => false,
      require => Exec["activate /etc/init.d/$redeploy_name"]
  }
}

add_init_script {"$js_homepage_username":
  name => "$js_homepage_username",
  application_path => $js_homepage_home_path,
  start_command => "$js_homepage_home_path/start -Xms128M -Xmx512m -Dconfig.resource=$js_homepage_config_resource -Dlogger.resource=prod-logger.xml -Dhttp.port=9000 -Dhttp.address=127.0.0.1 -Dapplication.secret=eiogwneiognw308g34g34nn340v834vn23fß23c2f233",
  user => "$js_homepage_username",
  group => "$js_homepage_username",
  pid_file => "$js_homepage_home_path/RUNNING_PID",
  current_working_dir =>"$js_homepage_home",
  unzipped_foldername => $js_homepage_version,
  require => [Add_user[$js_homepage_username], File["$js_homepage_home_path start rights"]]
}

$js_homepage_artifact = "${js_homepage_artifact_folder}/${js_homepage_version}.zip"

file {"$js_homepage_artifact_folder":
  ensure => "directory",
  group => "import",
  owner => "import",
  mode => 770,
  require => Add_user["import"]
}

add_redeploy_init_script {"play redeploy daemon":
  name => "${js_homepage_username}",
  artifact => $js_homepage_artifact,
}

file {"$js_homepage_home rights":
      path => $js_homepage_home_path,
      ensure  => 'directory',
      mode  => '0660',
      owner => $js_homepage_username,
      group => $js_homepage_username,
      recurse => true,
      require => [Package["packages"], Add_user["$js_homepage_username"], File["$js_homepage_artifact_folder"]],
}

file {"$js_homepage_home_path start rights":
    path => "${js_homepage_home_path}/start",
    owner => $js_homepage_username,
    group => $js_homepage_username,
    mode  => '0750',
    require => [File["$js_homepage_home rights"]]
}

file {"$js_homepage_username-log-folder":
    ensure  => 'directory',
    path => "/var/log/$js_homepage_username/",
    owner => $js_homepage_username,
    group => $js_homepage_username,
    mode  => '0770',
    require => Add_user[$js_homepage_username],
}	
	
import "users/*.pp"