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

#######################################
# main
# - entry function
#######################################
main() {
  # 1. get .env vars
  log_path=$(get_value_from_env 'LOG_PATH')
  port_certbot=$(get_value_from_env 'PORT_CERTBOT')
  url_app=$(get_value_from_env 'URL_APP')
  url_phpmyadmin=$(get_value_from_env 'URL_PHPMYADMIN')
  certbot_certs=$(get_value_from_env 'VOLUME_CERTBOT_CERTS')

  # 2. check log path exists if not make log dir
  log_dir=$(to_abs_path $log_path)
  if [[ ! -e $log_dir ]]; then
    echo "Create log dir: "$log_dir
    mkdir $log_dir
  fi

  # 3. update certbot certs
  docker-compose -f docker-compose-certbot.yml run --rm certbot-update

  # 4. create pem for haproxy
  certs_live_path=$(to_abs_path $certbot_certs'/live')
  cert_app_path=$certs_live_path'/'$url_app
  cert_phpmyadmin_path=$certs_live_path'/'$url_phpmyadmin

  cat $cert_app_path'/fullchain.pem' $cert_app_path'/privkey.pem' | tee $cert_app_path'/'$url_app'.pem'
  cat $cert_phpmyadmin_path'/fullchain.pem' $cert_phpmyadmin_path'/privkey.pem' | tee $cert_phpmyadmin_path'/'$url_phpmyadmin'.pem'

  # 5. restart haproxy
  docker-compose restart haproxy
}

main
