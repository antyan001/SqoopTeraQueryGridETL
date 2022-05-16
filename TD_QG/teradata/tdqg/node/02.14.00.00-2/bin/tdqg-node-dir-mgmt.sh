#!/bin/bash

# make the directories needed for tdqg software
makeDirs() {
    # NOTE : this directory is no longer used but needs to exist in case of downgrade
    mkdir -p ${TDQG_PROFILE_DIR}

    mkdir -p ${TDQG_NODE_NODE_CONFIG_DIR}
    mkdir -p ${TDQG_NODE_VER_LOG_DIR}
    mkdir -p ${TDQG_NODE_SPILLED_LOG_DIR}
    mkdir -p ${TDQG_NODE_INSTALL_DIR}
    mkdir -p ${TDQG_NODE_CONN_CONFIG_DIR}

    mkdir -p ${TDQG_FABRIC_DIR}
    mkdir -p ${TDQG_FABRIC_LOG_DIR}
    mkdir -p ${TDQG_FABRIC_SPILLED_LOG_DIR}

    mkdir -p ${TDQG_CONN_DIR}
    mkdir -p ${TDQG_CONN_LOG_DIR}

    mkdir -p $TDQG_SHM_DIR
    mkdir -p ${TDQG_TMP_DIR}

    # create the dump directory
    # useful only if the core pattern is set to /var/opt/teradata/core
    if [ ! -z "${TDQG_DUMP_DIR}" ]; then
        mkdir -p ${TDQG_DUMP_DIR}
    fi
}

# change directory ownership/permissions
# NOTE : connector log subdirs are left out because other users could have files in them
#      : shm dir not recursive as shm files shouldn't be readable be all 
setDirOwnershipAndPermissions() {
    chown -R ${TDQG_NODE_USER}:${TDQG_NODE_GROUP}  ${TDQG_BASE_DIR} &> /dev/null
    chown ${TDQG_NODE_USER}:${TDQG_NODE_GROUP}  ${TDQG_LOG_DIR} &> /dev/null
    chown ${TDQG_NODE_USER}:${TDQG_NODE_GROUP}  ${TDQG_TMP_DIR} &> /dev/null
    chown -R ${TDQG_NODE_USER}:${TDQG_NODE_GROUP}  ${TDQG_ETC_BASE_DIR} &> /dev/null
    chown -R ${TDQG_NODE_USER}:${TDQG_NODE_GROUP}  ${TDQG_NODE_CONN_CONFIG_DIR} &> /dev/null
    chown -R ${TDQG_NODE_USER}:${TDQG_NODE_GROUP}  ${TDQG_SHM_DIR} &> /dev/null

    chown ${TDQG_NODE_USER}:${TDQG_NODE_GROUP}  ${TDQG_CONN_LOG_DIR} &> /dev/null
    chown -R ${TDQG_NODE_USER}:${TDQG_NODE_GROUP}  ${TDQG_NODE_LOG_DIR} &> /dev/null
    chown -R ${TDQG_NODE_USER}:${TDQG_NODE_GROUP}  ${TDQG_FABRIC_LOG_DIR} &> /dev/null

    chown -R ${TDQG_NODE_USER}:${TDQG_NODE_GROUP}  ${TDQG_NODE_INSTALL_DIR} &> /dev/null
    chown -R ${TDQG_NODE_USER}:${TDQG_NODE_GROUP}  ${TDQG_CONN_DIR} &> /dev/null
    chown -R ${TDQG_NODE_USER}:${TDQG_NODE_GROUP}  ${TDQG_FABRIC_DIR} &> /dev/null

    # set directory permissions
    chmod -R 755 ${TDQG_BASE_DIR}
    chmod 755 ${TDQG_LOG_DIR}
    chmod -R 750 ${TDQG_NODE_LOG_DIR}
    chmod -R 750 ${TDQG_FABRIC_LOG_DIR}
    # for connector make sure we only add permissions and not take them away (for connector logs 
    # port directory needs to be 777 so we don't want to reduce the permissons there)
    chmod -R u+rwx,g+rx ${TDQG_CONN_LOG_DIR}
    chmod -R 750 ${TDQG_ETC_BASE_DIR}
    chmod -R 755 ${TDQG_NODE_CONN_CONFIG_DIR}
    chmod 755 ${TDQG_SHM_DIR}
    
    # all users can write to tdqg tmp dir (needed so connectors can write temp libqgngudsmessagesjni.so file)
    chmod -R 777 ${TDQG_TMP_DIR}

    # permissions on the dump directory
    # useful only if the core pattern is set to /var/opt/teradata/core
    if [ ! -z "${TDQG_DUMP_DIR}" ]; then
        chmod -R 755 ${TDQG_DUMP_DIR}
        chown -R ${TDQG_NODE_USER}:${TDQG_NODE_GROUP} ${TDQG_DUMP_DIR}
    fi

    # set up future permissions when tarballs are extracted so that group and others have rx permission on all contents
    setfacl -Rdm g:${TDQG_NODE_GROUP}:rx ${TDQG_BASE_DIR} &> /dev/null
    setfacl -Rdm o::rx ${TDQG_BASE_DIR} &> /dev/null

    # set up future permissions for tdqg-node.json file which could be written by QGM
    setfacl -Rdm u:${TDQG_NODE_USER}:rw ${TDQG_NODE_NODE_CONFIG_DIR} &> /dev/null

    # set up future permissions for log directory so that any file created has rwx permissions for TDQG_NODE_USER
    setfacl -Rdm u:${TDQG_NODE_USER}:rwx ${TDQG_LOG_DIR} &> /dev/null

    # set up future permissions so that every file written here has rx permission set for group and others
    # regardless of umask
    setfacl -Rdm g:${TDQG_NODE_GROUP}:rx ${TDQG_NODE_CONN_CONFIG_DIR} &> /dev/null
    setfacl -Rdm o::rx ${TDQG_NODE_CONN_CONFIG_DIR} &> /dev/null
}