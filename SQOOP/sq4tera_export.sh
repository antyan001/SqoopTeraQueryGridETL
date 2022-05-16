#/usr/bin/env sh

#--driver oracle.jdbc.driver.OracleDriver \
# --hive-overwrite \
# --target-dir /user/hive/warehouse/ma_cmdm_ma_deal/ \
# -Dmapreduce.input.fileinputformat.split.maxsize=1024000000;

realm="DF.SBRF.RU"
PASS=$(cat /home/$(whoami)/pass/terapswrd | sed 's/\r//g')
KERBEROS_PASS=$(cat /home/$(whoami)/pass/userpswrd | sed 's/\r//g')

printf "$KERBEROS_PASS" | kinit $(whoami)@$realm

sqoop job --list | grep -E 'cvm_hdfs2tera_job*' | { xargs -r sqoop job --delete >&2; [ $? -eq 0 ]; }

sqoop job \
-libjars ${LIBJARS} \
-Doracle.sessionTimeZone=Europe/Moscow \
-Dmapreduce.map.cpu.vcores=8 \
-Dmapreduce.map.memory.mb=35000 \
-Dmapreduce.map.java.opts=-Xmx7200m \
-Dmapreduce.task.io.sort.mb=2400 \
-Dmapreduce.map.max.attempts=10 \
-Dorg.apache.sqoop.export.text.dump_data_on_error=true \
-Dsqoop.export.records.per.statement=100000 \
-Dsqoop.export.statements.per.transaction=100000 \
-fs 'hdfs://nsld3' \
--create cvm_hdfs2tera_job \
-- export \
--connection-manager org.apache.sqoop.manager.GenericJdbcManager \
--connect "jdbc:teradata://TDSB15.cgs.sbrf.ru/database=PRD_DB_CLIENT4D_DEV1, LOGMECH=LDAP, CHARSET=UTF8, TYPE=FASTEXPORT, COLUMN_NAME=ON, MAYBENULL=ON" \
--driver com.teradata.jdbc.TeraDriver \
--username ektov1-av \
--password "$PASS" \
--table "LAL_DB_HIST_OUT" \
--export-dir "/user/hive/warehouse/lal_db_hist_out/" \
--input-fields-terminated-by ',' \
--num-mappers 4 \
--mapreduce-job-name "__SqooP_HDFS2Tera__" \
--batch \
--verbose
# --input-null-string '\\N' \
# --input-null-non-string '\\N' \


