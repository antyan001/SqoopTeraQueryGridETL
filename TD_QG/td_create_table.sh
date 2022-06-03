#!/bin/bash
tdqg_link=LD3_cdh_geraskin1-iv_ca-sbrf-ru_cvm_ds_cluster_bb0dac_H_td15_T
dbs_file=dbs
query=""
realm=DF.SBRF.RU

PASS=$(cat /home/$(whoami)/pass/userpswrd | sed 's/\r//g')

function runBeeline {
printf "$PASS" | kinit $(whoami)@$realm
beeline<<EOF
!connect jdbc:hive2://$HOSTNAME:10000/default;principal=hive/_HOST@${realm}
!add JAR /opt/workspace/${USER}/notebooks/TD_QG/teradata/tdqg/connector/tdqg-hive-connector/02.14.00.00-1/lib/hive-loaderfactory-02.14.00.00-1.jar
${1}
EOF
kdestroy
}

if [ -s "${dbs_file}" ]; then
    while read line; do
        database=`echo $line | cut -d '.' -f1 -s | tr -d '[[:space:]]'`
        table=`echo $line | cut -d '.' -f2 -s | tr -d '[[:space:]]'`
        if [[ -n "$database" && -n "$table" ]]; then
           printf -v query "${query}CREATE DATABASE IF NOT EXISTS TD15_${database};\nCREATE EXTERNAL TABLE IF NOT EXISTS TD15_${database}.${table} ROW FORMAT SERDE 'com.teradata.querygrid.qgc.hive.QGSerDe' STORED BY 'com.teradata.querygrid.qgc.hive.QGStorageHandler' TBLPROPERTIES ( \"link\"=\"${tdqg_link}\", \"version\"=\"active\", \"table\"=\"$database.$table\");\n"
        else
           printf "Database or table field is empty\n"
        fi
    done < <(grep -vE '^(\s*$|#)' $dbs_file)
    printf "QUERY IS:\n$query\n"
    if [ -n "$query" ]; then
       runBeeline "$query"
    else
       printf "Databases and tables not found in dbs file!\n"
    fi
else
  printf "dbs file does not exist or empty\n"
fi
