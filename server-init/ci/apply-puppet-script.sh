set -x

if [[ $EUID -ne 0 ]]; then
  echo "You must be a root user. Call with sudo." 2>&1
  exit 1
fi

BASEDIR=$(dirname $0)
cd ${BASEDIR}

deploy_env=prod

echo "applying puppet scripts"
export FACTER_deploy_environment=$deploy_env
stuff_older='/root/puppet-stuff'
export FACTER_stuff_folder="$stuff_older"
manifest_folder=$stuff_older/puppet/manifests
export FACTER_manifest_folder="$manifest_folder"
puppet apply --modulepath "${FACTER_stuff_folder}/puppet/modules" "${FACTER_stuff_folder}/puppet/manifests/ci.pp"
