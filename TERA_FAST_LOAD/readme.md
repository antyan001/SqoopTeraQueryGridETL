## `FASTLOAD`: Added script for parallel transfort loading into Teradata from user-defined csv files
- /TERA_FAST_LOAD:
  - /csv: location of user files to be loaded by FL utility
  - `genFLConfig.py`: main py script for data exporting and autogeneration of config file `run.fld` containing all instructions for Tera bulk loader
  - `run.sh`: shell script to run `genFLConfig.py` supplying TERADATA and KERBEROS User's password

### HOWTO use *FastLoad* utiity:
- Run `run.sh`
- Change the following params depending on your configuration:
  `tmp_tbl_name` = "tmp_hive2tera_cast" : *temp table name for local exporting via pySpark (can be left as is)*
  `EXPORT_PATH` = "/opt/workspace/{curruser}/notebooks/TERA_FAST_LOAD/csv": *path to local storage of exported data*
  `CONF_OUT_PATH__` = "/opt/workspace/{curruser}/notebooks/TERA_FAST_LOAD/run.fld" : *path to export FL config*
  `numdays` = 15: set the fix number of sorted patitions to catch from metastore (in the case of partitioned tbl)
  `BATCH_SPLIT__` = 2: set number of batches to split the origin Hive table and provide RDD batches into `mapPartitionsWithIndex` function
- Copy the content of current `/opt/workspace/../TERA_FAST_LOAD` folder into VARM disk `U:\FAST_LOAD\`
- CHDIR /D U:\FAST_LOAD\
- Run `Teradata` fast loader by executing the following command: `fastload -c utf8 <run.fld> log.txt`

File exporting process is optimized by using HDFS sorage and `com.databricks.spark.csv` driver. Pyspark dataframe of interest is loaded into HDFS
user sorage and then copied into thw specified local space.
The following function is used for local export csv file from HDFS:

```python
    def save_to_csv(self, df, sep:str, username:str,  hdfs_path:str, local_path:str=None, isHeader='true'):
        """
        Сохраняет Spark DataFrame с csv и создает линк на этот файл в файловой системе Jupyter

        Parameters
        ----------
        username:
            Имя пользователя в ЛД
        hdfs_path:
            Путь для сохранения файла в HDFS относительно папки пользователя (например notebooks/data)
        local_path:
            Путь, по которому будет доступен файл в файловой системе Jupyter (/home)
            Если None - запись производится только в hdfs
        """
        import subprocess
        import os

        path_to_hdfs = os.path.join('/user', username, hdfs_path)

        df.write \
            .format('com.databricks.spark.csv') \
            .mode('overwrite') \
            .option('sep', sep) \
            .option('header', isHeader) \
            .option("quote", '\u0000') \
            .option('timestampFormat', 'yyyy-MM-dd HH:mm:ss') \
            .save(path_to_hdfs)

        if local_path!=None:
            path_to_local = os.path.join('/home', username, local_path)
            print(path_to_local)
            proc = subprocess.call(['hdfs', 'dfs', '-getmerge', path_to_hdfs, path_to_local])
            proc = subprocess.call(['hdfs', 'dfs', '-rm', '-r', '-skipTrash', path_to_hdfs])
            #proc.communicate()
            columns_row = sep.join(df.columns)
            if not isHeader:
              os.system("sed -i -e 1i'" + columns_row + "\\' " + path_to_local)

        return self
```
In the case of successfull export into Teradata FastLoad utility will print the following termination RDBMS message into appropriate log file.
Consider that one shoud receive encountered return code that is equal to 0 in this case.
```bash
**** 23:10:57 END LOADING COMPLETE

     Total Records Read              =  60475989
      - skipped by RECORD command    =  1
      - sent to the RDBMS            =  60475988
     Total Error Table 1             =  1
     Total Error Table 2             =  0  ---- Table has been dropped
     Total Inserts Applied           =  60475798
     Total Duplicate Rows            =  189

     Start:   Mon Apr 04 23:10:38 2022
     End  :   Mon Apr 04 23:10:57 2022

**** 23:10:57 Application Phase statistics:
              Elapsed time: 00:00:19 (in hh:mm:ss)

0016     logoff;

     ===================================================================
     =                                                                 =
     =          Logoff/Disconnect                                      =
     =                                                                 =
     ===================================================================

**** 23:10:58 Logging off all sessions
**** 23:10:58 Total processor time used = '112.859 Seconds'
     .        Start : Mon Apr 04 23:06:18 2022
     .        End   : Mon Apr 04 23:10:58 2022
     .        Highest return code encountered = '0'.
**** 23:10:58 FDL4818 FastLoad Terminated
```
