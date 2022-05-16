# Implementaion of Hererogeneous Import/Export with SQOOP backened by jDBC drivers

## Configure your `.bash_profile`:
```bash
export HADOOP_CONF_DIR=/etc/hive/conf
export SPARK_HOME=/opt/cloudera/parcels/SPARK2/lib/spark2/
export JAVA_HOME=/lib/jvm/java-1.8.0-openjdk/ #/usr/java/jdk1.8.0_171-amd64
export PYSPARK_DRIVER_PYTHON=/opt/cloudera/parcels/PYENV.ZNO0059623792/bin/python
export PYSPARK_PYTHON=/opt/cloudera/parcels/PYENV.ZNO0059623792/bin/python
export ACCUMULO_HOME=/opt/workspace/$USER/libs/accumulo
export SQOOP_HOME=/opt/cloudera/parcels/CDH/lib/sqoop
export LIBJARS=/opt/cloudera/parcels/PYENV.ZNO0059623792/usr/lib/oracle/12.2/client64/lib/ojdbc8.jar, \
               $HOME/notebooks/drivers/sqoop-connector-teradata-1.7c5.jar, \
               $HOME/notebooks/drivers/tdgssconfig.jar,$HOME/notebooks/drivers/terajdbc4.jar
export HADOOP_CLASSPATH=`echo ${LIBJARS} | sed s/,/:/g`
```

- `drivers`: directory containing all connectors and drivers needed to properly run SQQOP jobs

## Importing data with `SQQOP` from Oracle
- `Hive_External_Tbl`:
    - `EXT_TBL_CREATE.py`: script for `EXTERNAL` tbl creation over specific HDFS directory
- `sq4ora_hdfs_import.sh`: script for importing data from Oracle DWH to HDFS using `org.apache.sqoop.manager.OracleManager`
- `sq4ora_hive_import.sh`: script for importing data from Oracle DWH followed by Hive table creation
- `sq_ora_exec.sh`: *job runner*  - execute sqoop job for import from ORA storage

1. Create your `SQQOP` job with specified name and provide Hadoop `mapred` arguments preceeding any other sqoop job exporting arguments:
    ```bash
    sqoop job \
    -Doracle.sessionTimeZone=Europe/Moscow \
    -Doraoop.timestamp.string=false \
    -Doracle.row.fetch.size=100000 \
    -Dmapreduce.map.cpu.vcores=8 \
    -Dmapreduce.map.memory.mb=10000 \
    -Dmapreduce.map.java.opts=-Xmx7200m \
    -Dmapreduce.task.io.sort.mb=2400 \
    -Dmapreduce.map.max.attempts=10 \
    --create cvm_ora2hdfs_job \
    ```
1. List all created sqoop jobs via command line:
```bash
sqoop job --list
```
1. Create a shell wrapper for sqoop job execution with provided exported params:
    1. Copy local stored credentials to HDFS directory
    ```bash
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
    ```
    1. Execute shell script to accomplish all lazy steps specified at job file and fetch user password from HDFS storage by providing `--password-file` key:
    ```bash
    printf "${ORAPASS}" | sqoop job --exec cvm_ora2hdfs_job -- --username ISKRA_CVM --password-file "${pass_hdfs}/orapswrd"
    ```

## Exporting data from `Hive` to `Teradata` DWH
- `Hive_Copy_Part`:
    - `hive_cp_from_part_tbl.py`: script for replication of Hive table using different row formattig: `parquet.serde.ParquetHiveSerDe` or `lazy.LazySimpleSerDe`
- `sq4tera_export.sh`: script for exporting row formatted data from HDFS to Teradata using `sqoop-connector-teradata`
- `sq_tera_exec.sh`: *job runner*  - execute sqoop job for export into Teradata storage


## SQOOP Errors and solutions for their overpassing.

*ERROR*:
```
ERROR sqoop.Sqoop: Got exception running Sqoop: org.kitesdk.data.DatasetNotFoundException: Descriptor location does not exist: hdfs://<path>.metadata
org.kitesdk.data.DatasetNotFoundException: Descriptor location does not exist: hdfs://<path>.metadata
```
*Sqoop export HDFS file type auto detection can pick wrong type.*
It appears that Sqoop export tries to detect the file format by reading the first 3 characters of a file.
Based on that header, the appropriate file reader is used. However, if the result set happens to contain the header sequence,
the wrong reader is chosen resulting in a misleading error.
For example, if someone is exporting a table in which one of the field values is "PART". Since Sqoop sees the letters "PAR",
it is invoking the Kite SDK as it assumes the file is in Parquet format. This leads to a misleading error:
*SOLUTION*: ticket [SQOOP-3151](https://issues.apache.org/jira/browse/SQOOP-3151)

*ERROR*:
```
Error: java.lang.NullPointerException at com.teradata.tdgss.jtdgss.TdgssConfigApi.GetMechanisms(Unknown Source)
at com.teradata.tdgss.jtdgss.TdgssManager.<init>(Unknown Source)
at com.teradata.tdgss.jtdgss.TdgssManager.<clinit>(Unknown Source)
at com.teradata.jdbc.jdbc.GenericTeraEncrypt.getGSSM(GenericTeraEncrypt.java:577)
```
*SOLUTION*: add jar reference to /drivers/tdgssconfig.jar

*ERROR*:
```
2022-04-04 03:35:14,746 ERROR [main] org.apache.sqoop.mapreduce.AsyncSqlRecordWriter: Top level exception:
java.sql.SQLException: [Teradata JDBC Driver] [TeraJDBC 15.10.00.37] [Error 1339] [SQLState HY000]
A failure occurred while executing a PreparedStatement batch request.
The parameter set was not executed and should be resubmitted individually using the PreparedStatement executeUpdate method.
at com.teradata.jdbc.jdbc_4.util.ErrorFactory.makeDriverJDBCException(ErrorFactory.java:95)
at com.teradata.jdbc.jdbc_4.util.ErrorFactory.makeDriverJDBCException(ErrorFactory.java:65)
at com.teradata.jdbc.jdbc_4.statemachine.PreparedBatchStatementController.handleRunException(PreparedBatchStatementController.java:96)
at com.teradata.jdbc.jdbc_4.statemachine.StatementController.runBody(StatementController.java:145)
at com.teradata.jdbc.jdbc_4.statemachine.PreparedBatchStatementController.run(PreparedBatchStatementController.java:58)
at com.teradata.jdbc.jdbc_4.TDStatement.executeStatement(TDStatement.java:389)
at com.teradata.jdbc.jdbc_4.TDPreparedStatement.executeBatchDMLArray(TDPreparedStatement.java:250)
at com.teradata.jdbc.jdbc_4.TDPreparedStatement.executeBatch(TDPreparedStatement.java:2659)
at org.apache.sqoop.mapreduce.AsyncSqlOutputFormat$AsyncSqlExecThread.run(AsyncSqlOutputFormat.java:231)
2022-04-04 03:35:14,749 ERROR [main] org.apache.sqoop.mapreduce.AsyncSqlRecordWriter: Chained exception 1:
```
*SOLUTION*: remove `TD15.DB.TBL_NAME_err` table and decrease `BATCH_SIZE` value

*ERROR*:
```
2022-04-03 21:54:05,241 INFO [main] org.apache.hadoop.mapred.MapTask: Ignoring exception during close for org.apache.hadoop.mapred.MapTask$NewDirectOutputCollector@f5c79a6
java.io.IOException: java.sql.SQLException: [Teradata Database] [TeraJDBC 15.10.00.37] [Error 3706] [SQLState 42000] Syntax error: expected something between ')' and ','.
    at org.apache.sqoop.mapreduce.AsyncSqlRecordWriter.close(AsyncSqlRecordWriter.java:197)
    at org.apache.hadoop.mapred.MapTask$NewDirectOutputCollector.close(MapTask.java:676)
    at org.apache.hadoop.mapred.MapTask.closeQuietly(MapTask.java:2054)
    at org.apache.hadoop.mapred.MapTask.runNewMapper(MapTask.java:803)
    at org.apache.hadoop.mapred.MapTask.run(MapTask.java:341)
    at org.apache.hadoop.mapred.YarnChild$2.run(YarnChild.java:164)
```
*SOLUTION*: add `--batch` argument at sqoop job specification

## Sqoop Performance Tuning Best Practices

### Tune the following Sqoop arguments in JDBC connection or Sqoop mapping to optimize performance
- *batch*
- *split-by and boundary-query*
- *direct*
- *fetch-size*
- *num-mapper*
-*split-by* (Specifies the column name based on which Sqoop must split the work units)
- set property `sqoop.export.records.per.statement` to specify the number of records that will be used in each insert statemen
- set how many rows will be inserted per transaction with the `sqoop.export.statements.per.transaction` property
### Inserting Data in Batches
Specifies that you can group the related SQL statements into a batch when you export data.
The JDBC interface exposes an API for doing batches in a prepared statement with multiple sets of values. With the --batch parameter, Sqoop can take advantage of this. This API is present in all JDBC drivers because it is required by the JDBC interface.
Enable JDBC batching using the `--batch` parameter.

### Controlling Parallelism
Specifies number of map tasks that can run in parallel. Default is 4. To optimize performance, set the number of map tasks to a value lower than the maximum number of connections that the database supports.
Use the parameter `--num-mappers` if you want Sqoop to use a different number of mappers.
Controlling the amount of parallelism that Sqoop will use to transfer data is the main way to control the load on your database. Using more mappers will lead to a higher number of concurrent data transfer tasks, which can result in faster job completion.
However, it will also increase the load on the database as Sqoop will execute more concurrent queries.

## Syntax of Sqoop Job
```bash
$ sqoop job (generic-args) (job-args) [– [subtool-name] (subtool-args)]
$ sqoop-job (generic-args) (job-args) [– [subtool-name] (subtool-args)]
```
However, the Sqoop job arguments can be entered in any order with respect to one another. But the Hadoop generic arguments must precede any job arguments.
## Job management options

|Argument | Description |
| :------ | :------ |
| `–create <job-id>` | Define a new saved job with the specified job-id (name). A second Sqoop |
| `–delete <job-id>` | Delete a saved job |
| `–exec <job-id>` | Given a job defined with –create, run the saved job |
| `–show <job-id>` | Show the parameters for a saved job |
| `–list`| List all saved jobs |

## Choose the OraOop connector:
```bash
sqoop import \
--connection-manager com.quest.oraoop.OraOopConnManager \
--connect jdbc:oracle:thin:@oracle.example.com:1521/ORACLE \
--username SQOOP \
--password sqoop \
--table cities
```
## Choose the built-in Oracle connector:
```bash
sqoop import \
--connection-manager org.apache.sqoop.manager.OracleManager \
--connect jdbc:oracle:thin:@oracle.example.com:1521/ORACLE \
--username SQOOP \
--password sqoop \
--table cities
```
## And finally, choose the Generic JDBC Connector:
```bash
sqoop import \
--connection-manager org.apache.sqoop.manager.GenericJdbcManager \
--driver oracle.jdbc.OracleDriver \
--connect jdbc:oracle:thin:@oracle.example.com:1521/ORACLE \
--username SQOOP \
--password sqoop \
--table cities
```
## Exporting into Teradata
Problem
You are doing a Sqoop export to Teradata using the Generic JDBC Connector and it
fails with the following exception:
`Syntax error: expected something between ')' and ','.)`
Solution
Set the parameter `-Dsqoop.export.records.per.statement=1`:
```bash
sqoop export \
-Dsqoop.export.records.per.statement=1 \
--connect jdbc:teradata://teradata.example.com/DATABASE=database \
--username sqoop \
--password sqoop \
--table cities\
--export-dir cities
```
