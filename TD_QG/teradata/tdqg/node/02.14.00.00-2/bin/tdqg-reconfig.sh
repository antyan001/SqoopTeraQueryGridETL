#!/usr/bin/env bash
####################################################################
# This script starts and enable the tdqg-node service on the node. 
# Please run this script only on the newly added, removed, or 
# recovered instances.
####################################################################
# Initial validation
TDQG_NODE_VERSION=02.14.00.00-2

usage()
{
    echo "Usage: $0 [mode]"
    echo "  - mode     -- Node registration mode: [recover|fold|unfold]"
}

writeStateFile()
{
    echo "Writing tdqg-reconfig state file."
    fileName=$(echo $1 | tr '[a-z]' '[A-Z]')
    mkdir -p /etc/opt/teradata/tdqg/node
    echo "TDQG_NODE_VERSION=$TDQG_NODE_VERSION" > /etc/opt/teradata/tdqg/node/$fileName
}

if [ $# -ne 1 ]
then
    echo "Invalid number of arguments $# != 1"
    usage
    exit 1
fi

NODE_REGISTRATION_MODE=$1

if [[ $NODE_REGISTRATION_MODE != recover && $NODE_REGISTRATION_MODE != fold && $NODE_REGISTRATION_MODE != unfold ]]
then
    echo "Please use valid node registration mode: [recover|fold|unfold]"
    exit 1
fi

# Enable the service in case of a start 
# test if systemd is the init process (PID == 1)
initProc=$(readlink -f /sbin/init | sed 's!.*/!!')
if [ "$initProc" = "systemd" ]; then
    systemctl enable tdqg-node
else
    chkconfig --add tdqg-node
fi

# write state file
writeStateFile $NODE_REGISTRATION_MODE

# Get QG config from other nodes
QG_CONFIG_DIR=/tmp/tdqg-node-config
QG_CONFIG_LOG=$QG_CONFIG_DIR/out.txt
rm -rf $QG_CONFIG_DIR
mkdir -p $QG_CONFIG_DIR
chown tdqg $QG_CONFIG_DIR
/usr/pde/bin/pcl -force -collect /etc/opt/teradata/tdqg/node $QG_CONFIG_DIR &> $QG_CONFIG_LOG

# Start the tdqg-node service
if [ "$initProc" = "systemd" ]; then
    systemctl restart tdqg-node
else
    service tdqg-node restart
fi
