#!/opt/workspace/ektov1-av_ca-sbrf-ru/bin/python35

import os, sys
import argparse

curruser = os.environ.get('USER')

sys.path.insert(0, './src')
sys.path.insert(0, '/opt/workspace/{user}/notebooks/support_library/'.format(user=curruser))
sys.path.insert(0, '/opt/workspace/{user}/libs/python3.5/site-packages/'.format(user=curruser))
sys.path.insert(0, '/opt/workspace/{user}/notebooks/labdata/lib/'.format(user=curruser))


import warnings
warnings.filterwarnings('ignore')

# import logging
# logging.basicConfig(filename='./logs/__create_nonpart_replica__.log',level=logging.INFO,
#                     format='%(asctime)s %(levelname)s %(name)s %(message)s')
# logger = logging.getLogger(__name__)


from getpass import getpass
from itertools import cycle

from spark_connector import SparkConnector
from connector import OracleDB, TeraDB
from sparkdb_loader import spark
import pyspark
from pyspark.sql.window import Window
from pyspark.sql.functions import *
import pyspark.sql.functions as f
from pyspark.sql.types import *
from pyspark.sql.utils import AnalysisException
from pyspark.sql.dataframe import DataFrame
from pyspark import SparkContext, SparkConf, HiveContext
from pyspark.sql import SparkSession
from pyspark.sql.catalog import Catalog

import re
from pathlib import Path

import jaydebeapi

def print_and_log(message: str):
    print(message)
    logger.info(message)
    return None

#*******************************************************************************
#*******************************************************************************

parser = argparse.ArgumentParser(add_help=False)
parser.add_argument('-tbl_name', '--tableName', type=str, required=True, default=False)
parser.add_argument('-out_format', '--OutFormat', type=str, required=True, default=False)
parser.add_argument('-h', '--help',
                    action='help', default=argparse.SUPPRESS,
                    help='set tableName param to the actual name of table to be replicated into default schema from sbx schema')

args = parser.parse_args()

TBL_NAME = args.tableName
tmp_tbl_name = "tmp_"+TBL_NAME

#*******************************************************************************
#*******************************************************************************

#*******************************************************************************
#*******************************************************************************
conn_schema = 'sbx_t_team_cvm' #'sbx_team_digitcamp' #'sbx_t_team_cvm'

print("### Starting spark context. Run!")

sp = spark(schema=conn_schema,
           dynamic_alloc=False,
           kerberos_auth=False,
           numofinstances=8,
           numofcores=8,
           executor_memory='30g',
           driver_memory='25g'
           )
hive = sp.sql

print(sp.sc.version)
#*******************************************************************************
#*******************************************************************************

hive.setConf("mapreduce.input.fileinputformat.input.dir.recursive","true")
hive.setConf("mapred.input.dir.recursive","true")
hive.setConf("hive.mapred.supports.subdirectories","true")
# hive.setConf('spark.sql.parquet.binaryAsString', 'true')
# hive.setConf('spark.sql.hive.convertMetastoreParquet', 'false')

hive.setConf('hive.metastore.fshandler.threads', 30)
hive.setConf('hive.msck.repair.batch.size', 1000)
hive.setConf('hive.merge.smallfiles.avgsiz', 256000000)
hive.setConf('hive.merge.size.per.task', 256000000)

#*******************************************************************************
#*******************************************************************************

TERADATA_HOST = "TDSB15"
DB = ""
# DATABASE_NAME = "report_all_voronka"
USERNAME = ""
PASSWORD = getpass()
db = TeraDB(TERADATA_HOST, DB, USERNAME, PASSWORD)

#*******************************************************************************
#*******************************************************************************

JDBC_ARGUMENTS = "LOGMECH=LDAP, CHARSET=UTF8,TYPE=FASTEXPORT, COLUMN_NAME=ON, MAYBENULL=ON"
#DB = 'PRD_DB_CLIENT4D_DEV1'
conn = jaydebeapi.connect(
    jclassname="com.teradata.jdbc.TeraDriver",
    url="jdbc:teradata://{}/database={} , {}".format(TERADATA_HOST, DB, JDBC_ARGUMENTS),
    driver_args={"user": USERNAME, "password": PASSWORD},
    jars=['/home/{}/notebooks/drivers/tdgssconfig.jar'.format(curruser),
          '/home/{}/notebooks/drivers/terajdbc4.jar'.format(curruser)]
)
curs = conn.cursor()

my_sql = '''SELECT TOP 1
                 *
             FROM PRD_DB_CLIENT4D_DEV1.{}
             --WHERE CREATE_DT_DAY = '2021-10-18'
         '''.format(TBL_NAME)

curs.execute(my_sql)
cols = [desc[0] for desc in curs.description]

hive.sql("DROP TABLE IF EXISTS {} PURGE".format(TBL_NAME))

sdf = hive.table("{}.{}".format(conn_schema, TBL_NAME))
sdf = sdf.withColumn("ROW_ID", f.monotonically_increasing_id().cast(IntegerType()))

for col, type in sdf.dtypes:
    sdf = sdf.withColumn(col, f.regexp_replace(col,'[\,]', "."))

sdf = sdf.select(cols)
sdf = sdf.coalesce(5)
sdf.registerTempTable(tmp_tbl_name)

if args.OutFormat =='parquet':

    print("STORE DATA AS PARQUETS...")
    query_cr = \
    '''
    CREATE TABLE {}
    --ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
    ROW FORMAT SERDE
      'org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe'
    WITH SERDEPROPERTIES (
      'field.delim'=',',
      'line.delim'='\n',
      'serialization.encoding'='UTF-8',
      'serialization.format'=',')
    STORED AS INPUTFORMAT
      'org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat'
    OUTPUTFORMAT
      'org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat'
    --STORED AS PARQUET
    AS SELECT * FROM {}
    '''.format(TBL_NAME, tmp_tbl_name)

elif args.OutFormat =='text':

    query_cr=\
    '''
    CREATE TABLE {}
    ROW FORMAT SERDE
      'org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe'
    WITH SERDEPROPERTIES (
      'field.delim'=',',
      'line.delim'='\n',
      'serialization.encoding'='UTF-8',
      'serialization.format'=',')
    STORED AS INPUTFORMAT
      'org.apache.hadoop.mapred.TextInputFormat'
    OUTPUTFORMAT
      'org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat'
    TBLPROPERTIES("serialization.null.format"="")
    AS SELECT * FROM {}
    '''.format(TBL_NAME, tmp_tbl_name)

hive.sql(query_cr)







