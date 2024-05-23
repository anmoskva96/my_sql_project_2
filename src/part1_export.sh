#!/bin/bash

# example: bash part1_export.sh my_db_info

DB_NAME=$1
cdate=$(date +'%Y_%m_%d_%H-%M-%S')  
dir="export_"$cdate

# предварительно создаем папку и пустые файлы
mkdir ../datasets/$dir
# далее записываем пробел для установке text свойства файла и одновременно его сосздаем
echo " " > ../datasets/$dir/peers.csv
echo " " > ../datasets/$dir/friends.csv
echo " " > ../datasets/$dir/recommendations.csv
echo " " > ../datasets/$dir/time_tracking.csv
echo " " > ../datasets/$dir/transferred_points.csv
echo " " > ../datasets/$dir/tasks.csv
echo " " > ../datasets/$dir/checks.csv
echo " " > ../datasets/$dir/xp.csv
echo " " > ../datasets/$dir/p2p.csv
echo " " > ../datasets/$dir/verter.csv

bash part1_trans.sh $DB_NAME EXPORT ";" peers ../datasets/$dir/peers.csv
bash part1_trans.sh $DB_NAME EXPORT ";" friends ../datasets/$dir/friends.csv
bash part1_trans.sh $DB_NAME EXPORT ";" recommendations ../datasets/$dir/recommendations.csv
bash part1_trans.sh $DB_NAME EXPORT ";" timetracking ../datasets/$dir/time_tracking.csv
bash part1_trans.sh $DB_NAME EXPORT ";" transferredpoints ../datasets/$dir/transferred_points.csv
bash part1_trans.sh $DB_NAME EXPORT ";" tasks ../datasets/$dir/tasks.csv
bash part1_trans.sh $DB_NAME EXPORT ";" checks ../datasets/$dir/checks.csv
bash part1_trans.sh $DB_NAME EXPORT ";" xp ../datasets/$dir/xp.csv
bash part1_trans.sh $DB_NAME EXPORT ";" p2p ../datasets/$dir/p2p.csv
bash part1_trans.sh $DB_NAME EXPORT ";" verter ../datasets/$dir/verter.csv