#!/bin/bash
# certbot-new.sh dockerComposeFile

if [ -z "$1" ]; then
  echo 'dockerComposeFile required.'
  echo 'Usage: ./certbot-new.sh dockerComposeFile'
  exit 1
fi

# PORT_CERTBOT=$(grep PORT_CERTBOT .env | cut -d '=' -f2)

docker-compose -f $1 run --rm 