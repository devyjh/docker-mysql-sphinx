#!/bin/bash

## variable for path
PROD_PATH=$(pwd)
MYSQL_MASTER_CONF="$PROD_PATH/prod/mysql-master-conf"
MYSQL_SLAVE_CONF="$PROD_PATH/prod/mysql-slave-conf"

USER="ec2-user"
MYSQL_IMAGE="mysql:5.7.24"
MYSQL_DATA="/home/$USER/mysql"

MYSQL_MASTER_ROOT_PASSWORD="root"
MYSQL_MASTER_ADDRESS="127.0.0.1"
MYSQL_MASTER_PORT="3306"
MYSQL_REPLICATION_USER="repl_user"
MYSQL_REPLICATION_PASSWORD="repl_pwd"

MYSQL_DATABASE_NAME="yongmangu100"

## docker pull & run
mkdir -p $MYSQL_DATA
docker pull $MYSQL_IMAGE

docker run --name mysql-master \
        -v $MYSQL_MASTER_CONF:/etc/mysql/conf.d \
        -v $MYSQL_DATA:/var/lib/mysql \
        -e MYSQL_ROOT_PASSWORD=$MYSQL_MASTER_ROOT_PASSWORD \
        -p $MYSQL_MASTER_PORT:3306 \
        -d $MYSQL_IMAGE
 
## mysql setting
echo "waiting mysql for 60sec"
sleep 60

echo "creating replication user in MASTER MYSQL"
mysql --host $MYSQL_MASTER_ADDRESS -P $MYSQL_MASTER_PORT -uroot -p$MYSQL_MASTER_ROOT_PASSWORD -AN -e "create user '$MYSQL_REPLICATION_USER'@'%';"
mysql --host $MYSQL_MASTER_ADDRESS -P $MYSQL_MASTER_PORT -uroot -p$MYSQL_MASTER_ROOT_PASSWORD -AN -e "grant replication slave on *.* to '$MYSQL_REPLICATION_USER'@'%' identified by '$MYSQL_REPLICATION_PASSWORD';"
mysql --host $MYSQL_MASTER_ADDRESS -P $MYSQL_MASTER_PORT -uroot -p$MYSQL_MASTER_ROOT_PASSWORD -AN -e "flush privileges;"

echo "creating database & dump"
mysql --host $MYSQL_MASTER_ADDRESS -P $MYSQL_MASTER_PORT -uroot -p$MYSQL_MASTER_ROOT_PASSWORD -AN -e "create database $MYSQL_DATABASE_NAME"
mysql --host $MYSQL_MASTER_ADDRESS -P $MYSQL_MASTER_PORT -uroot -p$MYSQL_MASTER_ROOT_PASSWORD -AN -e "SET GLOBAL log_bin_trust_function_creators=ON;"