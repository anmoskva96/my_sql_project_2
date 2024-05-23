#!/bin/bash

# example: bash part1_import.sh my_db_info

DB_NAME=$1

bash part1_trans.sh $DB_NAME IMPORT ";" peers ../datasets/peers.csv
bash part1_trans.sh $DB_NAME IMPORT ";" friends ../datasets/friends.csv
bash part1_trans.sh $DB_NAME IMPORT ";" recommendations ../datasets/recommendations.csv
bash part1_trans.sh $DB_NAME IMPORT ";" timetracking ../datasets/time_tracking.csv
bash part1_trans.sh $DB_NAME IMPORT ";" transferredpoints ../datasets/transferred_points.csv
bash part1_trans.sh $DB_NAME IMPORT ";" tasks ../datasets/tasks.csv
bash part1_trans.sh $DB_NAME IMPORT ";" checks ../datasets/checks.csv
bash part1_trans.sh $DB_NAME IMPORT ";" xp ../datasets/xp.csv
bash part1_trans.sh $DB_NAME IMPORT ";" p2p ../datasets/p2p.csv
bash part1_trans.sh $DB_NAME IMPORT ";" verter ../datasets/verter.csv