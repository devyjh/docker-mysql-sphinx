#!/bin/bash

## variable for path
DEV_PATH=$(pwd)
MYSQL_MASTER_CONF="$DEV_PATH/dev/mysql-master-conf"
MYSQL_SLAVE_CONF="$DEV_PATH/dev/mysql-slave-conf"

USER="ec2-user"
MYSQL_IMAGE="mysql:5.7.24"
MYSQL_DATA="/home/$USER/mysql"

MYSQL_MASTER_ROOT_PASSWORD="root"
MYSQL_MASTER_ADDRESS="127.0.0.1"
MYSQL_MASTER_PORT="3306"
MYSQL_SLAVE_ROOT_PASSWORD="root"
MYSQL_SLAVE_ADDRESS="127.0.0.1"
MYSQL_SLAVE_PORT="3312"
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
        
docker run --name mysql-slave \
        -v $MYSQL_SLAVE_CONF:/etc/mysql/conf.d \
        -e MYSQL_ROOT_PASSWORD=$MYSQL_SLAVE_ROOT_PASSWORD \
        -p $MYSQL_SLAVE_PORT:3306 \
        --link mysql-master \
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
mysqldump --host $MYSQL_MASTER_ADDRESS -P $MYSQL_MASTER_PORT -uroot -p$MYSQL_MASTER_ROOT_PASSWORD $MYSQL_DATABASE_NAME  > dump.sql
docker cp dump.sql mysql-slave:.
mysql --host $MYSQL_MASTER_ADDRESS -P $MYSQL_SLAVE_PORT -uroot -p$MYSQL_MASTER_ROOT_PASSWORD -AN -e "create database $MYSQL_DATABASE_NAME"
mysql --host $MYSQL_MASTER_ADDRESS -P $MYSQL_SLAVE_PORT -uroot -p$MYSQL_MASTER_ROOT_PASSWORD $MYSQL_DATABASE_NAME < dump.sql
rm -rf dump.sql

echo "getting MASTER MYSQL config"
Master_Position="$(mysql --host $MYSQL_MASTER_ADDRESS -P $MYSQL_MASTER_PORT -uroot -p$MYSQL_MASTER_ROOT_PASSWORD -e 'show master status \G' | grep Position | grep -o '[0-9]*')"
Master_File="$(mysql --host $MYSQL_MASTER_ADDRESS -P $MYSQL_MASTER_PORT -uroot -p$MYSQL_MASTER_ROOT_PASSWORD -e 'show master status \G' | grep File | sed -n -e 's/^.*: //p')"

echo "set SLAVE to upstream MASTER"
mysql --host $MYSQL_SLAVE_ADDRESS -P $MYSQL_SLAVE_PORT -uroot -p$MYSQL_SLAVE_ROOT_PASSWORD -AN -e "change master to master_host='mysql-master',master_user='$MYSQL_REPLICATION_USER',master_password='$MYSQL_REPLICATION_PASSWORD',master_log_file='$Master_File',master_log_pos=$Master_Position;"

echo "start sync: MASTER to SLAVE"
mysql --host $MYSQL_SLAVE_ADDRESS -P $MYSQL_SLAVE_PORT -uroot -p$MYSQL_SLAVE_ROOT_PASSWORD -AN -e "start slave;"
mysql --host $MYSQL_SLAVE_ADDRESS -P $MYSQL_SLAVE_PORT -uroot -p$MYSQL_SLAVE_ROOT_PASSWORD -e "show slave status \G;"