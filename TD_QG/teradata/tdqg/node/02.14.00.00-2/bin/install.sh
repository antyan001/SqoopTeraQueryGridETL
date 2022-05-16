#!/usr/bin/env bash

TDQG_NODE_VERSION=02.14.00.00-2

NODE_DIR=/opt/teradata/tdqg/node
ETC_NODE_DIR=/etc/${NODE_DIR}

# we don't have write access to directory where tdqg-node file lives so we can't just cp into place
# but we do have write access to file itself (since we created it) so we can replace all contents with new file
# if this file does not exist then we are in systemd support mode and need to copy to different
# location
COPY_LOCATION=/etc/init.d/tdqg-node
if [ ! -f $COPY_LOCATION ] ; then
    COPY_LOCATION=${ETC_NODE_DIR}
    cat tdqg-node.service > /etc/systemd/system/tdqg-node.service
fi
# tdqg-node is used by tdqg-monitor even with systemd support so it needs to copied where tdqg-monitor looks for it
cat tdqg-node > ${COPY_LOCATION}

# copy files into place (as they might not have been there for previous versions or are now updated)
cp TeraJDBC.conf /etc/opt/teradata/tdconfig/tdqg/
cp locate_java.sh ${ETC_NODE_DIR}
cp tdqg-node.env ${ETC_NODE_DIR}
cp tdqg-node-dir-mgmt.sh ${ETC_NODE_DIR}
cp tdqg-reconfig.sh ${ETC_NODE_DIR}
cp tdqg-image.sh ${ETC_NODE_DIR}
cp tdqg-monitor ${NODE_DIR}

# make the log directory and setup permissions
BASE_DIR=/var/opt/teradata/tdqg/
mkdir -p ${BASE_DIR}

# make sure base directory has correct permissions
chmod 755 ${BASE_DIR}

# make the temp directory and set permissions
# all users can write to tdqg tmp dir (needed so connectors can write temp libqgngudsmessagesjni.so file)
# NOTE : added in 02.06, once no one is using version prior to this remove the mkdir
mkdir -p ${BASE_DIR}/tdqg/tmp
chmod 777 ${BASE_DIR}/tmp

NODE_LOG_DIR=/var/opt/teradata/tdqg/node/
SPILLED_LOG_DIR=${NODE_LOG_DIR}/spilledLogs
FABRIC_LOG_DIR=/var/opt/teradata/tdqg/fabric/
SPILLED_FABRIC_LOG_DIR=${FABRIC_LOG_DIR}/spilledLogs
VER_DIR=${NODE_LOG_DIR}/${TDQG_NODE_VERSION}
LOG_DIR=${VER_DIR}/logs/

mkdir -m 750 ${SPILLED_LOG_DIR}
mkdir -m 750 ${SPILLED_FABRIC_LOG_DIR}
mkdir -m 750 ${VER_DIR}
mkdir -m 750 ${LOG_DIR}

# set up future permissions for log directory so that any file created has rwx permissions for TDQG_NODE_USER
# NOTE : this only applies to files we can currently read/write
setfacl -Rdm u:tdqg:rwx ${BASE_DIR} >/dev/null 2>&1

# try to locate java
. $ETC_NODE_DIR/locate_java.sh

# go back to where tdqg-node binary is
cd ..
NODE_HOME=`pwd`

# save off last couple of error logs
mv ${LOG_DIR}/tdqg-node.error.log.1 ${LOG_DIR}/tdqg-node.error.log.2 >/dev/null 2>&1
mv ${LOG_DIR}/tdqg-node.error.log ${LOG_DIR}/tdqg-node.error.log.1 >/dev/null 2>&1

# startup the new tdqg-node in background
GOTRACEBACK=crash ${NODE_HOME}/tdqg-node -javapathFromEnv ${TDQG_NODE_JAVA_HOME} -javapathFromEnvError "${JAVA_PATH_ERROR}" >${LOG_DIR}/tdqg-node.error.log 2>&1 &
