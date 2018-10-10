#!/bin/bash
#
# Update certbot & Create .pem files
# @see https://serversforhackers.com/c/letsencrypt-with-haproxy

#######################################
# Get abstract path from current relative path
#
# Arguments
#  relative path
#
# Return
#  abstract path
#
# Reference
#  https://stackoverflow.com/questions/4175264/bash-retrieve-absolute-path-given-relative/51264222#51264222
#######################################
to_abs_path() {
  local target="$1"

  if [ "$target" == "." ]; then
    echo "$(pwd)"
  elif [ "$target" == ".." ]; then
    echo "$(dirname "$(pwd)")"
  else
    echo "$(cd "$(dirname "$1")"; pwd)/$(basename "$1")"
  fi
}

#######################################
# Get the value from dotenv(.env) file
#
# Arguments
#   env var name
#
# Returns
#   env value
#   empty string if not exists
#######################################
get_value_from_env() {
  local env_var="$1"
  echo "$(grep "$env_var" .env | cut -d '=' -f2)"
}

main() {
  # 1. get .env vars
  port_certbot=$(get_value_from_env 'PORT_CERTBOT')
  url_app=$(get_value_from_env 'URL_APP')
  url_phpmyadmin=$(get_value_from_env 'URL_PHPMYADMIN')
  certbot_certs=$(get_value_from_env 'VOLUME_CERTBOT_CERTS')

  # 2. update certbot certs
  docker-compose -f docker-compose-certbotyml run --rm certbot renew --force-renewal --tls-sni-01-port=$port_certbot

  # 3. create pem for haproxy
  # @see https://serversforhackers.com/c/letsencrypt-with-haproxy
  certs_live_path=$(to_abs_path $certbot_certs'/live')
  cert_app_path=$certs_live_path'/'$url_app
  cert_phpmyadmin_path=$certs_live_path'/'$url_phpmyadmin

  # @see https://serversforhackers.com/c/letsencrypt-with-haproxy
  cat $cert_app_path'/fullchain.pem' $cert_app_path'/privkey.pem' | tee $cert_app_path'/'$url_app'.pem'
  cat $cert_phpmyadmin_path'/fullchain.pem' $cert_phpmyadmin_path'/privkey.pem' | tee $cert_phpmyadmin_path'/'$url_phpmyadmin'.pem'

  # 4. restart haproxy
  #docker exec -it haproxy haproxy -f /usr/local/etc/haproxy/haproxy.cfg -c
  #docker kill -s HUP haproxy
  docker-compose restart haproxy
}

main
