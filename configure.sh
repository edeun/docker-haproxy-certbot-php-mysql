#!/bin/bash
#
# Configure initial server with let's encrypt ssl

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

#######################################
# main
# - entry function
#######################################
main() {
  # 0. get .env variables
  conf_haproxy_http_cfg=$(get_value_from_env 'CONF_HAPROXY_CFG_HTTP')
  conf_haproxy_https_cfg=$(get_value_from_env 'CONF_HAPROXY_CFG_HTTPS')
  volume_haproxy_cfg=$(get_value_from_env 'VOLUME_HAPROXY_CFG')
  url_app=$(get_value_from_env 'URL_APP')
  url_phpmyadmin=$(get_value_from_env 'URL_PHPMYADMIN')
  certbot_certs=$(get_value_from_env 'VOLUME_CERTBOT_CERTS')

  # 1. create symbolic link from haproxy.http.cfg to haproxy.cfg
  ln -sf $(to_abs_path $conf_haproxy_http_cfg) $(to_abs_path $volume_haproxy_cfg)

  # 1. docker containers up
  docker-compose up -d

  # 2. certbot certificate
  docker-compose -f docker-compose-certbot.yml run --rm certbot-app
  docker-compose -f docker-compose-certbot.yml run --rm certbot-phpmyadmin

  # 3. create pem for haproxy
  # 3-1. Get certbot live path
  certs_live_path=$(to_abs_path $certbot_certs'/live')

  # 3-2. get cert app, phpmyadmin path
  cert_app_path=$certs_live_path'/'$url_app
  cert_phpmyadmin_path=$certs_live_path'/'$url_phpmyadmin

  # 3-3. Make .pem file for haproxy
  # @see https://serversforhackers.com/c/letsencrypt-with-haproxy
  cat $cert_app_path'/fullchain.pem' $cert_app_path'/privkey.pem' | tee $cert_app_path'/'$url_app'.pem'
  cat $cert_phpmyadmin_path'/fullchain.pem' $cert_phpmyadmin_path'/privkey.pem' | tee $cert_phpmyadmin_path'/'$url_phpmyadmin'.pem'

  # 4. change haproxy.cfg symbolic link
  rm $(to_abs_path $volume_haproxy_cfg)
  ln -sf $(to_abs_path $conf_haproxy_https_cfg) $(to_abs_path $volume_haproxy_cfg)

  # 5. restart haproxy
  #docker exec -it haproxy haproxy -f /usr/local/etc/haproxy/haproxy.cfg -c
  #docker kill -s HUP haproxy
  docker-compose restart haproxy
}

main
