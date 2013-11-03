notify{"The deploy_environment is: ${deploy_environment}": }

Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/", "/usr/local/bin", ] }

import "common.pp"
import "methods.pp"

import "mongodb.pp"
include mongodb


import "apache.pp"
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


$vanime_username = "vanime"
$vanime_artifact_folder = "/home/import/$vanime_username"
$vanime_home = "/var/$vanime_username"
$vanime_home_path = "$vanime_home/current"
$vanime_config_resource = "prod.conf"
$vanime_version = "vanime-1.0.0"

add_user { "$vanime_username":
  username => "$vanime_username",
  full_name => "vanime server",
  home => $vanime_home,
}

add_init_script {"$vanime_username":
  name => "$vanime_username",
  application_path => $vanime_home_path,
  start_command => "$vanime_home_path/bin/$vanime_username -Xms128M -Xmx512m -Dconfig.resource=$vanime_config_resource -Dlogger.resource=prod-logger.xml -Dhttp.port=9002 -Dhttp.address=127.0.0.1 -Dapplication.secret=eiogasaegagAGaga4nn340v834vn23fß23c2f233",
  user => "$vanime_username",
  group => "$vanime_username",
  pid_file => "$vanime_home_path/RUNNING_PID",
  current_working_dir =>"$vanime_home",
  unzipped_foldername => $vanime_version,
  require => [Add_user[$vanime_username], File["$vanime_home_path start rights"]]
}

$vanime_artifact = "${vanime_artifact_folder}/${vanime_version}.zip"

file {"$vanime_artifact_folder":
  ensure => "directory",
  group => "import",
  owner => "import",
  mode => 770,
  require => Add_user["import"]
}

add_redeploy_init_script {"play redeploy daemon":
  name => "${vanime_username}",
  artifact => $vanime_artifact,
}

file {"$vanime_home rights":
      path => $vanime_home_path,
      ensure  => 'directory',
      mode  => '0660',
      owner => $vanime_username,
      group => $vanime_username,
      recurse => true,
      require => [Package["packages"], Add_user["$vanime_username"], File["$vanime_artifact_folder"]],
}

file {"$vanime_home_path start rights":
    path => "${vanime_home_path}/start",
    owner => $vanime_username,
    group => $vanime_username,
    mode  => '0750',
    require => [File["$vanime_home rights"]]
}

file {"$vanime_username-log-folder":
    ensure  => 'directory',
    path => "/var/log/$vanime_username/",
    owner => $vanime_username,
    group => $vanime_username,
    mode  => '0770',
    require => Add_user[$vanime_username],
}
	
import "users/*.pp"