#!/usr/bin/env bash

# Setup env vars and folders for the ctl script
# This helps keep the ctl script as readable
# as possible

# Usage options:
# source /var/vcap/jobs/foobar/helpers/ctl_setup.sh JOB_NAME OUTPUT_LABEL
# source /var/vcap/jobs/foobar/helpers/ctl_setup.sh foobar
# source /var/vcap/jobs/foobar/helpers/ctl_setup.sh foobar foobar
# source /var/vcap/jobs/foobar/helpers/ctl_setup.sh foobar nginx

set -e # exit immediately if a simple command exits with a non-zero status
set -u # report the usage of uninitialized variables

JOB_NAME=$1
output_label=${2:-${JOB_NAME}}

export PACKAGE_DIR=/var/vcap/packages/$JOB_NAME
export JOB_DIR=/var/vcap/jobs/$JOB_NAME
chmod 755 $JOB_DIR # to access file via symlink

# Load some bosh deployment properties into env vars
# Try to put all ERb into data/properties.sh.erb
# incl $NAME, $JOB_INDEX, $WEBAPP_DIR
source $JOB_DIR/data/properties.sh

source $JOB_DIR/helpers/ctl_utils.sh
redirect_output ${output_label}

export HOME=${HOME:-/home/vcap}
function error() {
  echo " !     $*" >&2
  exit 1
}

function topic() {
  echo "-----> $*"
}

APT_OPTIONS="-o debug::nolocking=true"
topic "Updating apt caches"
apt-get $APT_OPTIONS update

export DEBIAN_FRONTEND="noninteractive"
debconf-set-selections <<< "postfix postfix/root_address string root@localhost"
debconf-set-selections <<< "postfix postfix/destinations string localhost, localhost.localdomain"
debconf-set-selections <<< "postfix postfix/relayhost string example.com"
debconf-set-selections <<< "postfix postfix/recipient_delim string +"
debconf-set-selections <<< "postfix postfix/mailname string mysmtpserver"
debconf-set-selections <<< "postfix postfix/protocols string all"
debconf-set-selections <<< "postfix postfix/main_mailer_type select Internet with smarthost"
debconf-set-selections <<< "postfix postfix/chattr boolean false"
debconf-set-selections <<< "postfix postfix/mynetworks string 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128"
debconf-set-selections <<< "postfix postfix/mailbox_limit string 0"
PACKAGES="postfix libsasl2-modules"
#for PACKAGE in $PACKAGES; do
#  topic "Fetching .debs for $PACKAGE"
#  apt-get $APT_OPTIONS -y install $PACKAGE
#done
apt-get $APT_OPTIONS -y install $PACKAGES
# Add all packages' /bin & /sbin into $PATH
for package_bin_dir in $(ls -d /var/vcap/packages/*/*bin)
do
  export PATH=${package_bin_dir}:$PATH
done

export LD_LIBRARY_PATH=${LD_LIBRARY_PATH:-''} # default to empty
for package_bin_dir in $(ls -d /var/vcap/packages/*/lib)
do
  export LD_LIBRARY_PATH=${package_bin_dir}:$LD_LIBRARY_PATH
done

# Setup log, run and tmp folders

export RUN_DIR=/var/vcap/sys/run/$JOB_NAME
export LOG_DIR=/var/vcap/sys/log/$JOB_NAME
export TMP_DIR=/var/vcap/sys/tmp/$JOB_NAME
export STORE_DIR=/var/vcap/store/$JOB_NAME
for dir in $RUN_DIR $LOG_DIR $TMP_DIR $STORE_DIR
do
  mkdir -p ${dir}
  chown vcap:vcap ${dir}
  chmod 775 ${dir}
done
export TMPDIR=$TMP_DIR

export CONF_DIR=$JOB_DIR/config
chown -R vcap:vcap "${CONF_DIR}"

export CERT_DIR=$CONF_DIR/certs/
chown root:root ${CERT_DIR}/*.{crt,key}

chmod 640 ${CERT_DIR}/*.crt
chmod 400 ${CERT_DIR}/*.key

# config main.cf
ln -fs ${JOB_DIR}/config/main.cf /etc/postfix/
ln -fs ${JOB_DIR}/config/master.cf /etc/postfix/
cp -f ${JOB_DIR}/config/aliases /etc/aliases
newaliases
