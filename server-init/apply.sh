set -x

if [[ $EUID -ne 0 ]]; then
  echo "You must be a root user. Call with sudo." 2>&1
  exit 1
fi

BASEDIR=$(dirname $0)
cd ${BASEDIR}

deploy_env=prod

service js_homepage-redeploy stop
service js_homepage stop
service vanime-redeploy stop
service vanime stop

echo "applying puppet scripts"
export FACTER_deploy_environment=$deploy_env

export FACTER_stuff_folder="/root/puppet"
puppet apply --modulepath "/puppet/modules" "../puppet/manifests/default.pp"

service js_homepage-redeploy start
service js_homepage start
service vanime-redeploy start
service vanime start