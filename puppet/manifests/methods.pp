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

