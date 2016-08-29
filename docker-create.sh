#!/bin/bash
set -e 

name="letsencrypt"

sudo -s -- <<////
docker ps -l -q -f "name=$name" | xargs -n1 -r docker stop
docker ps -l -q -f "name=$name" | xargs -n1 -r docker rm
docker images -q $name | xargs -n1 -r docker rmi
docker build -t $name:latest .
docker run -d --restart always --name $name -v /etc/localtime:/etc/localtime:ro -v /config/letsencrypt:/config $name
docker logs -f $name
////
