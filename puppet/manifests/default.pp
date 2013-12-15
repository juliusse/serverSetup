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

$js_homepage_secret="eiogwneiognw308g34g34nn340v834vn23fd23c2f233"
add_play22_application {"homepage":
	name => "js_homepage",
	version => "3.0.0",
	configFile => "prod.conf",
	loggerFile => "prod-logger.xml",
	port => "9000",
	app_secret => "$js_homepage_secret"
}

$vanime_secret="sjfnweilbeibiuwb3892vn2ol3nqi3qi3cnqi3nquncc"
add_play22_application {"vanime":
	name => "vanime",
	version => "1.0.0",
	configFile => "prod.conf",
	loggerFile => "prod-logger.xml",
	port => "9010",
	app_secret => "$vanime_secret"}
	
import "users/*.pp"