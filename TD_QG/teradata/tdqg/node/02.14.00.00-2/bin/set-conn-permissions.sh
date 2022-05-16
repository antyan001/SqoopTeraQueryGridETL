#!/usr/bin/env bash
# set-conn-permissions is used to give a connector permission to read and execute on all log directories
# also connector is given permission to write to its version log directory
# NOTE : in tdqg-node install we used setfacl to give rwx access to all files created in '/var/opt/teradata/tdqg'

usage()
{
    echo "Usage: $0 [conn_name] [conn_ver]"
    echo "  - conn_name     -- The connector name"
    echo "  - con_ver       -- The connector version"
}

if [ $# -ne 2 ]
then
    echo "Illegal number of arguments $# != 2"
    usage
    exit 1
fi

CONN_NAME=$1
CONN_VER=$2
CONN_DIR=/opt/teradata/tdqg/connector/${CONN_NAME}/${CONN_VER}/bin/

# source connector.conf to get group variable
source ${CONN_DIR}/connector.conf

# test if group variable exists and if not then we can't continue
if [ -z "${group}" ]; then
    echo "No variable 'group' defined, can't continue"
    exit 2
fi

baseLogDir=/var/opt/teradata/tdqg/
connBaseDir=${baseLogDir}/connector/
connDir=${connBaseDir}/${CONN_NAME}/
connVerDir=${connDir}/${CONN_VER}/
connLogDir=${connVerDir}/logs

#separate user groups if it has multiple
#using parenthesis to create subshell for modifying IFS var
(IFS=','; for groupname in ${group};

do
    # NOTE : the first test will pass if groupname is a number, if not redirecting output to 
    # /dev/null so that it doesn't print error because groupname is not a number
    if [ "${groupname}" -eq "${groupname}" ] &> /dev/null || [ "$(getent group ${groupname})" ]; then
        # set 'group' to have rx permission on all dirs it needs to traverse through
        setfacl -m group:${groupname}:rx ${baseLogDir}
        setfacl -m group:${groupname}:rx ${connBaseDir}
        setfacl -m group:${groupname}:rx ${connDir}
        setfacl -m group:${groupname}:rx ${connVerDir}

        # set 'group' to have rwx permission on logs dir so that it can write files
        setfacl -m group:${groupname}:rwx ${connLogDir}
    else
        echo "group \"${groupname}\" does not exist on node, can't continue"
        exit 3
    fi
done
)
