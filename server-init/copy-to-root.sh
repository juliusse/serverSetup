set -x

root_puppet_folder=/root/puppet-stuff
sudo rm -rf $root_puppet_folder && \
sudo mkdir $root_puppet_folder && \
sudo cp -r ~/puppet-stuff/* $root_puppet_folder
