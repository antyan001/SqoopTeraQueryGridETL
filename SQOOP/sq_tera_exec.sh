#/usr/bin/env sh
PASS=$(cat /home/$(whoami)/pass/terapswrd | sed 's/\r//g')
pass_hdfs=hdfs:///user/$(whoami)/terapswrd

if [ -d "${pass_hdfs}" ]; then
    printf "pass directory exist"
else
    hdfs dfs -mkdir -p ${pass_hdfs}
fi

if [ -s "${pass_hdfs}/terapswrd" ]; then
    hdfs dfs -rm -f --skipTrash "${pass_hdfs}/terapswrd"
    hdfs dfs -put ~/pass/terapswrd "${pass_hdfs}/terapswrd" && \
    hdfs dfs -chmod 744 "${pass_hdfs}/terapswrd"
fi

printf "${PASS}" | sqoop job --exec cvm_hdfs2tera_job -- --username ektov1-av --password-file "${pass_hdfs}/terapswrd"
# printf "${PASS}\n${PASS}" | sqoop job --exec cvm_hdfs2tera_job -- --username ektov1-av -P
