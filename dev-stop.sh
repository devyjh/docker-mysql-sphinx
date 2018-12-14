#!/bin/bash

docker rm -f mysql-master
docker rm -f mysql-slave
sudo rm -rf /home/ec2-user/mysql