#/usr/bin/env sh
ORAPASS=$(cat /home/$(whoami)/pass/orapass | sed 's/\r//g')
pass_hdfs=hdfs:///user/$(whoami)/orapswrd

if [ -d "${pass_hdfs}" ]; then
    printf "pass directory exist"
else
    hdfs dfs -mkdir -p ${pass_hdfs}
fi

if [ -s "${pass_hdfs}/orapswrd" ]; then
    hdfs dfs -rm -f --skipTrash "${pass_hdfs}/orapswrd"
    hdfs dfs -put ~/pass/terapswrd "${pass_hdfs}/orapswrd" && \
    hdfs dfs -chmod 744 "${pass_hdfs}/orapswrd"
fi

printf "${ORAPASS}" | sqoop job --exec cvm_ora2hdfs_job -- --username ISKRA_CVM --password-file "${pass_hdfs}/orapswrd"

# printf "$PASS\n" | sqoop job --exec cvm_ora2hdfs_job -- --username ISKRA_CVM --password "$PASS"
