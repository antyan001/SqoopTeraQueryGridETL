export PIP_CONFIG_FILE=/home/$USER/pip/pip.conf
export NLS_LANG=RUSSIAN_CIS.AL32UTF8
export LD_LIBRARY_PATH=/opt/cloudera/parcels/PYENV.ZNO0059623792-3.5.pyenv.p0.2/usr/lib/oracle/12.2/client64/lib:/opt/cloudera/parcels/PYENV.ZNO0059623792-3.5.pyenv.p0.2/usr/lib:/opt/cloudera/parcels/PYENV.ZNO0059623792-3.5.pyenv.p0.2/usr/lib64:/opt/cloudera/parcels/PYENV.ZNO0059623792-3.5.pyenv.p0.2/bigartm/lib:/opt/cloudera/parcels/PYENV.ZNO0059623792/bigartm/lib64
export PATH=/opt/workspace/$USER/notebooks/drivers:/usr/local/bin:/usr/bin:/home/$USER/bin:/opt/python/virtualenv/jupyter/lib/node_modules/.bin:/opt/python/virtualenv/jupyter/bin:/opt/python/virtualenv/jupyter/bin:/sbin:/bin:/usr/sbin:/usr/bin:/opt/cloudera/parcels/PYENV.ZNO0059623792-3.5.pyenv.p0.2/bin:/opt/cloudera/parcels/PYENV.ZNO0059623792-3.5.pyenv.p0.2/sbin:/opt/cloudera/parcels/PYENV.ZNO0059623792-3.5.pyenv.p0.2/usr/bin:/opt/cloudera/parcels/PYENV.ZNO0059623792-3.5.pyenv.p0.2/bigartm/bin
export PYTHONPATH=/opt/workspace/$USER/libs:/opt/workspace/$USER/libs/python3.5/site-packages:/opt/workspace/$USER/libs/python3.6/site-packages:/home/$USER/python35-libs/lib/python3.5/site-packages:/home/$USER/.local/lib/python3.5/site-packages
export SPARK_HOME=/opt/cloudera/parcels/SPARK2-2.4.0.cloudera2-1.cdh5.13.3.p0.1041012/lib/spark2
export JAVA_HOME=/usr/java/jdk1.8.0_171-amd64
export PYSPARK_DRIVER_PYTHON=/opt/cloudera/parcels/PYENV.ZNO0059623792-3.5.pyenv.p0.2/bin/python
export PYSPARK_PYTHON=/opt/cloudera/parcels/PYENV.ZNO0059623792-3.5.pyenv.p0.2/bin/python

# export KRB5_CONFIG=/home/$USER/krb5/krb5.conf
kinit -kt /home/$USER/keytab/user.keytab $USER@DF.SBRF.RU
