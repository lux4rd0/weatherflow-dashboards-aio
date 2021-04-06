#!/bin/bash

export UID_GID="$(id -u):$(id -g)" 
#export UID_GID="2000:1000"
echo "$UID_GID"
docker-compose stop
