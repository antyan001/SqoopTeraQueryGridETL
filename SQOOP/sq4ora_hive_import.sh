#/usr/bin/env sh

#--driver oracle.jdbc.driver.OracleDriver \
# --hive-overwrite \
# --target-dir /user/hive/warehouse/ma_cmdm_ma_deal/ \
# -Dmapreduce.input.fileinputformat.split.maxsize=1024000000;

PASS=$(cat /home/$(whoami)/pass/orapass | sed 's/\r//g')

sqoop job --list | grep -E 'cvm_*' | { xargs -r sqoop job --delete >&2; [ $? -eq 0 ]; }

sqoop job \
-Doracle.sessionTimeZone=Europe/Moscow \
-Doraoop.timestamp.string=false \
-Doracle.row.fetch.size=100000 \
-Dmapreduce.map.cpu.vcores=8 \
-Dmapreduce.map.memory.mb=10000 \
-Dmapreduce.map.java.opts=-Xmx7200m \
-Dmapreduce.task.io.sort.mb=2400 \
-Dmapreduce.map.max.attempts=10 \
--create cvm_ora2hive_job \
-- import \
--connection-manager org.apache.sqoop.manager.OracleManager \
--connect jdbc:oracle:thin:@//$ip:$port/$schema \
--username  \
--password "$PASS" \
--table "" \
--split-by "to_number(to_char(CREATE_DT, 'yyyymmddhh24miss'))" \
--verbose \
--direct \
--hive-import \
--hive-database default \
--hive-table ma_cmdm_ma_deal \
--incremental append \
--check-column "CREATE_DT" \
--last-value "2021-01-01 00:00:00" \
--num-mappers 12 \
--mapreduce-job-name "__SqooP_Ora2Hive__"\
--compression-codec=snappy \
--as-parquetfile

#--where "CREATE_DT >= to_timestamp('2016-01-01 00:00:00', 'yyyy-mm-dd hh24:mi:ss') AND CREATE_DT <= to_timestamp('2025-01-01 00:00:00', 'yyyy-mm-dd hh24:mi:ss')" \

