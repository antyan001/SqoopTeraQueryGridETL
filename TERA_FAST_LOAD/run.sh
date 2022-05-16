#!/bin/bash

realm="DF.SBRF.RU"
KERBEROSPASS=$(cat /home/$(whoami)/pass/userpswrd | sed 's/\r//g')
TERAPASS=$(cat /home/$(whoami)/pass/terapswrd | sed 's/\r//g')

printf "$KERBEROSPASS\n" | kinit $(whoami)@$realm
hdfs dfs -mkdir -p /user/$(whoami)/csv

./genFLConfig.py --terapswrd "${TERAPASS}"

