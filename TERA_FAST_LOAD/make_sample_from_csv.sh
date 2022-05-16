#/usr/bin/env sh
sed -n '1,100000p' ./csv/lal_db_hist_out.csv > ./csv/lal_db_hist_out_part.csv
