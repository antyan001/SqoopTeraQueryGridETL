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

import logging
logging.basicConfig(filename='./logs/__ma_cdmd_ma_deal__.log',level=logging.INFO,
                    format='%(asctime)s %(levelname)s %(name)s %(message)s')
logger = logging.getLogger(__name__)


from getpass import getpass
from itertools import cycle

from spark_connector import SparkConnector
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

def print_and_log(message: str):
    print(message)
    logger.info(message)
    return None

#*******************************************************************************
#*******************************************************************************
print("### Starting spark context. Run!")
conn_schema = 'sbx_team_digitcamp' #'sbx_t_team_cvm'
sp = spark(process_label="EXT_TBL_CR_",
           numofinstances=5,
           numofcores=8,
           executor_memory='20g',
           driver_memory='20g',
           dynamic_alloc=False,
           kerberos_auth=False
          )
print(sp.sc.version)
hive = sp.sql
#*******************************************************************************
#*******************************************************************************


parser = argparse.ArgumentParser(add_help=False)
parser.add_argument('-create', '--createExtTbl', type=bool, required=True, default=False)
parser.add_argument('-tbl_name', '--tableName', type=str, required=True, default=False)
parser.add_argument('-h', '--help',
                    action='help', default=argparse.SUPPRESS,
                    help='set createExtTbl param to True if you wanna recreate external table')
args = parser.parse_args()

TBL_NAME = args.tableName


hive.setConf("mapreduce.input.fileinputformat.input.dir.recursive","true")
hive.setConf("mapred.input.dir.recursive","true")
hive.setConf("hive.mapred.supports.subdirectories","true")
# hive.setConf('spark.sql.parquet.binaryAsString', 'true')
# hive.setConf('spark.sql.hive.convertMetastoreParquet', 'false')

hive.setConf('hive.metastore.fshandler.threads', 30)
hive.setConf('hive.msck.repair.batch.size', 1000)
hive.setConf('hive.merge.smallfiles.avgsiz', 256000000)
hive.setConf('hive.merge.size.per.task', 256000000)


if args.createExtTbl == True:
    ## CREATE EXTERNAL TABLE
    print("DROP OLD {} TABLE AND CREATE NEW ONE".format(TBL_NAME))

    HDFS_LOC = "/user/hive/warehouse/ma_cmdm_ma_deal/"
    sdf = hive.read.option('dropFieldIfAllNull',True).parquet(HDFS_LOC)

    tbl_descr = ", ".join(["{} {}".format(col, tp) for col, tp in sdf.dtypes])

    hive.sql("DROP TABLE IF EXISTS {} PURGE".format(TBL_NAME))

    create_ext_tbl_sql = \
    '''
    CREATE EXTERNAL TABLE {} ({})
    --ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
    ROW FORMAT SERDE
      'org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe'
    STORED AS INPUTFORMAT
      'org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat'
    OUTPUTFORMAT
      'org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat'
    --STORED AS PARQUET
    LOCATION '{}'
    '''.format(TBL_NAME, tbl_descr, HDFS_LOC)

    hive.sql(create_ext_tbl_sql)

# print("UPDATE METASTORE WITH NEW PARTITIONS")
# Catalog(SparkSession(sp.sc)).recoverPartitions(TBL_NAME)
# # hive.sql("MSCK REPAIR TABLE GOOGLE_ANALYTICS_VISIT")
# print("{} HAS BEEN UPDATED SUCCESFULLY".format(TBL_NAME))


