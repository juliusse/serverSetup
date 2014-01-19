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

define add_play22_application($name,$configFile,$loggerFile,$port,$app_secret) {
	$username = "$name"
	$folder_artifact = "/home/import/$username"
	$folder_home = "/var/$username"
	$folder_current = "$folder_home/current"
	$config_file = "$configFile"

	add_user { "$username":
	  username => "$username",
	  full_name => "username server",
	  home => $folder_home,
	}

	add_init_script {"$username":
		 name => "$username",
		 application_path => $folder_home,
		 start_command => "$folder_current/bin/$username -Dconfig.resource=$config_file -Dlogger.resource=$loggerFile -Dhttp.port=$port -Dhttp.address=127.0.0.1 -Dapplication.secret=$app_secret",
		 user => "$username",
		 group => "$username",
		 pid_file => "$folder_current/RUNNING_PID",
		 current_working_dir =>"$folder_home",
		 require => [Add_user[$username], File["$folder_current bin rights"]]
	}
	
	$artifact = "${folder_artifact}/${app_version}.zip"
	
	file {"$folder_artifact":
	  ensure => "directory",
	  group => "import",
	  owner => "import",
	  mode => 770,
	  require => Add_user["import"]
	}
	
	
	add_redeploy_init_script {"$username redeploy daemon":
	  name => "${username}"
	  redeploy_name => ${name}
	}

	file {"$folder_home rights":
		  path => $folder_current,
		  ensure  => 'directory',
		  mode  => '0660',
		  owner => $username,
		  group => $username,
		  recurse => true,
		  require => [Package["packages"], Add_user["$username"], File["$folder_artifact"]],
	}

	file {"$folder_current bin rights":
		path => "${folder_current}/bin/$username",
		owner => $username,
		group => $username,
		mode  => '0750',
		require => [File["$folder_home rights"]]
	}

	file {"$username-log-folder":
		ensure  => 'directory',
		path => "/var/log/$username/",
		owner => $username,
		group => $username,
		mode  => '0770',
		require => Add_user[$username],
	}
}

