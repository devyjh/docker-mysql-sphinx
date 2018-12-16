#!/bin/bash

## variable for path
DEV_PATH=$(pwd)
SPHINX_CONF="$DEV_PATH/dev/sphinx-conf"

USER="ec2-user"
SPHINX_IMAGE="mustit/sphinx"
SPHINX_DATA="/home/$USER/sphinx"

## docker pull & run
mkdir -p $SPHINX_DATA
docker pull $SPHINX_IMAGE

docker run --name sphinx \
            -v $SPHINX_DATA:/var/idx/sphinx \
            -v $SPHINX_CONF:/usr/local/etc \
            --net host \
            -d $SPHINX_IMAGE