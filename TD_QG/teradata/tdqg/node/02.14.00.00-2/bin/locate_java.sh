#!/usr/bin/env bash

# check that java is installed (we might need it for java driver)
# if not then check default teradata jdk 8 and jre 8 directories
# if that not found then continue because failure to start driver will appear in viewpoint

TDQG_NODE_JAVA_HOME=""
JAVA_PATH=""
JAVA_PATH_ERROR="''"
MIN_SUPPORTED_JAVA_VERSION="8"

# Load environment variables from Teradata OpenJDK/JRE or older Teradata JDK/JRE packages
if [ -e /etc/profile.d/teradata-openjdk-jdk8.sh ]; then
    . /etc/profile.d/teradata-openjdk-jdk8.sh
elif [ -e /etc/profile.d/teradata-openjdk-jre8.sh ]; then
    . /etc/profile.d/teradata-openjdk-jre8.sh
elif [ -e /etc/profile.d/teradata-jdk8.sh ]; then
    . /etc/profile.d/teradata-jdk8.sh
elif [ -e /etc/profile.d/teradata-jre8.sh ]; then
    . /etc/profile.d/teradata-jre8.sh
fi

#Find tdqg-node Java home path
if [ -z "$TDQG_NODE_JAVA_HOME" ]; then
    if [ -n "$TDWDOG_JAVA_HOME" ]; then
        # TDWDOG_JAVA_HOME was supported by old QGLWatchDog
        TDQG_NODE_JAVA_HOME="$TDWDOG_JAVA_HOME"
    elif [ -n "$OPENJDK_JDK8_64_HOME" ]; then
        TDQG_NODE_JAVA_HOME="$OPENJDK_JDK8_64_HOME/bin/java"
    elif [ -n "$OPENJDK_JRE8_64_HOME" ]; then
        TDQG_NODE_JAVA_HOME="$OPENJDK_JRE8_64_HOME/bin/java"
    elif [ -n "$JDK8_64_HOME" ]; then
        TDQG_NODE_JAVA_HOME="$JDK8_64_HOME/bin/java"
    elif [ -n "$JRE8_64_HOME" ]; then
        TDQG_NODE_JAVA_HOME="$JRE8_64_HOME/bin/java"
    elif [ -n "$JAVA_HOME" ]; then
        TDQG_NODE_JAVA_HOME="$JAVA_HOME/bin/java"
    else
        TDQG_NODE_JAVA_HOME=$(which java 2> /dev/null)
    fi
fi

if [ -n "$TDQG_NODE_JAVA_HOME" ]; then
    JAVA_VERSION=$($TDQG_NODE_JAVA_HOME -version 2>&1)
    RESULT=$?
    if [ $RESULT -ne 0 ]; then
        JAVA_PATH_ERROR="Unable to identify java version: $JAVA_VERSION"
    elif [ -z "$JAVA_VERSION" ]; then
        JAVA_PATH_ERROR="Unable to determine java version, 'java -version' returned empty value"
    else
        JAVA_VERSION=$(echo $JAVA_VERSION | awk -F '"' '/version/{print $2}')
        if [ $RESULT -ne 0 ]; then
            JAVA_PATH_ERROR="Unable to parse java version \"$JAVA_VERSION\""
        else
            # older java versions have form "1.X.X.X", whereas newer ones drop the "1"
            MINOR_VERSION=$(echo "$JAVA_VERSION" | awk -F. '{print $1}')
            if [ "$MINOR_VERSION" -eq "1" ]; then
                MINOR_VERSION=$(echo "$JAVA_VERSION" | awk -F. '{print $2}')
            fi

            if [ "$MINOR_VERSION" -lt "$MIN_SUPPORTED_JAVA_VERSION" ]; then
                JAVA_PATH_ERROR="Java path ($TDQG_NODE_JAVA_HOME) found from environment variables but java version \"$JAVA_VERSION\" less than minimum supported version 1.$MIN_SUPPORTED_JAVA_VERSION"
            fi
        fi
    fi
else 
    JAVA_PATH_ERROR="Unable to find java $MIN_SUPPORTED_JAVA_VERSION+ in PATH or via environment variables"
    # we need to pass a non empty string as the go node requires command line options have values
    TDQG_NODE_JAVA_HOME="''"
fi