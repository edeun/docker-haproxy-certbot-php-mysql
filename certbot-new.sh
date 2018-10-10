#!/bin/bash
# certbot-new.sh dockerComposeFile

if [ -z "$1" ]; then
  echo 'dockerComposeFile required.'
  echo 'Usage: ./certbot-new.sh dockerComposeFile'
  exit 1
fi

docker-compose -f $1 run --rm certbot 
