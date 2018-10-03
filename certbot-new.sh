#!/bin/bash

# certbot-new.sh userEmail certDomain

if [ -z "$1" ]; then
  echo 'Email required.'
  echo 'Usage: ./certbot-new.sh userEmail certDomain'
  exit 1
fi

if [ -z "$2" ]; then
  echo 'Domain required.'
  echo 'Usage: ./certbot-new.sh userEmail certDomain'
  exit 1
fi

userEmail=$1
certDomain=$2

docker-compose -f docker-compose-certbot.yml run --rm certbot certonly --standalone --email $userEmail --agree-tos --non-interactive -d $certDomain --http-01-port=8888