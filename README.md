# docker-haproxy-certbot-php-mysql

docker를 이용해 1대의 서버에서 웹 서비스 운영에 필요한 Reverse Proxy, Web Service(PHP), Database, DB Administration Tool 을 구성하였습니다.

또한 Let's Encrypt의 certbot으로부터 https 인증서 발급 및 갱신 절차를 포함하였습니다.

## 개요

![docker 설정](/conf.png)

본 프로젝트에는 위의 그림과 같이 서버 1대에서 웹 서비스를 운영하기 위해 필요한 서비스들이 docker 기반으로 구성되어 있습니다.

본 프로젝트에 사용한 docker 컨테이너는 아래와 같습니다.

- Reverse Proxy
  - haproxy:1.8.14 (https://hub.docker.com/_/haproxy/)
- Web Service
  - php:7.2-apache (https://hub.docker.com/_/php/)
- Database
  - mysql:8.0.12 (https://hub.docker.com/_/mysql) 
- DB Administration Tool
  - phpmyadmin/phpmyadmin:latest (https://hub.docker.com/r/phpmyadmin/phpmyadmin/)
- Let's Encrypt 인증서 발급/갱신
  - certbot/certbot:latest (https://hub.docker.com/r/certbot/certbot/)

## 개발환경

본 프로젝트는 아래의 환경에서 구현되었습니다.

- ubuntu:18.04
- docker-ce (https://docs.docker.com/install/linux/docker-ce/ubuntu/)
- docker-compose (https://docs.docker.com/compose/install/)

## 사용방법

### 1. 프로젝트 Clone

아래의 `git clone` 명령어를 이용해 본 프로젝트를 복사합니다.

```bash
git clone https://github.com/twopple/docker-haproxy-server-conf.git 
```

### 2. .env 파일 생성

본 프로젝트는 .env 파일을 이용해 환경설정을 진행합니다. .env.template 파일을 .env 라는 이름으로 복사한 후 아래의 항목에 대한 설정 정보를 입력합니다.

### 2-1. .env.template 파일을 .env 로 복사

```bash
cp .env.template .env
```

### 2-2. .env 파일 환경설정

copy된 .env 파일에 기록된 아래 항목들에 대해 입력합니다.

```bash
# URLs
URL_APP=${YOUR_URL_APP}
URL_PHPMYADMIN=${YOUR_URL_PHPMYADMIN}

# Certbot
CERTBOT_ISSUER_EMAIL=${YOUR_EMAIL}

# MySQL
MYSQL_ROOT_PASSWORD=${YOUR_MYSQL_ROOT_PASSWORD}
MYSQL_USER=${YOUR_MYSQL_USER}
MYSQL_PASSWORD=${YOUR_MYSQL_PASSWORD}
MYSQL_DATABASE=${YOUR_MYSQL_DATABASE}
```

각 항목에 대한 내용은 아래와 같습니다.

- URLs
  - ${YOUR_URL_APP}: Web Service의 URL을 입력합니다.
  - ${YOUR_URL_PHPMYADMIN}: phpmyadmin 접속을 위해 사용할 URL을 입력합니다.
- Certbot
  - ${YOUR_EMAIL}: certbot을 이용해 app, phhpmyadmin 의 URL의 인증서를 발급받기 위해 사용할 사용자의 이메일 주소를 입력합니다.
- MySQL
  - ${YOUR_MYSQL_ROOT_PASSWORD}: 사용할 MySQL의 root 비밀번호를 입력합니다.
  - ${YOUR_MYSQL_USER}: 사용할 MySQL의 사용자 ID를 입력합니다.
  - ${YOUR_MYSQL_PASSWORD}: 사용할 MySQL의 사용자 ID에 해당하는 비밀번호를 입력합니다.
  - ${YOUR_MYSQL_DATABASE}: 사용자 ID가 접근가능할 database name을 입력합니다.

> 사용하고자 하는 app, phpmyadmin 도메인은 사전에 DNS 설정이 되어 있어야 합니다.

그 외 .env 파일에는 각 docker container에서 사용하는 환경설정파일, 데이터 공유 등에 사용되는 volume 설정과 내부 네트워크 설정 정보가 포함되어 있습니다.

자세한 내용은 하단의 Volumes, Network Section을 참조해주세요.

### 3. 실행

.env 파일이 설정 완료된 후 아래와 같이 `configure.sh` 쉘 스크립트를 이용해 실행하면 설정이 완료되며 사용자가 설정한 app, phpmyadmin 도메인을 이용해 https 접속이 가능합니다.

> 실행 전 `configure.sh` 실행하기 전 실행 권한이 필요합니다.

```bash
chmod +x configure.sh   # 실행 권한 추가
./configure.sh
```

위의 명령어 실행이 성공적으로 완료되면, 모든 과정이 완료됩니다.

### 4. Crontab

주기적인 Let's Encrypt https 갱신을 위해서 아래의 명령어를 crontab에 추가합니다.

- 아래 명령어는 매달 1일 0시 0분에 `certbot_update.sh` 를 실행함을 의미합니다.

```bash
0 0 1 * * root cd ${PROJECT_CLONE_PATH} && ./certbot_update.sh >> ${PROJECT_LOG_PATH}/cron_`date +\%Y\%m\%d_\%H\%M\%S`.log 2>&1
```

- ${PROJECT_CLONE_PATH}: 본 프로젝트를 clone한 path를 절대경로로 입력합니다.
- ${PROJECT_LOG_PATH}: crontab 결과를 저장할 log path를 절대경로로 입력합니다. 해당 디렉터리는 .env의 LOG_PATH와 일치해야 합니다. LOG_PATH는 참고사항의 5. Log 항목을 참조해주세요.

## 참고사항

### 1. Volumes

본 프로젝트에서 docker container와 사용하고 있는 공유 디렉터리 및 파일(Volume) 정보는 .env에 기록되어 있으며 내용은 아래와 같습니다.

```bash
# Volumes
VOLUME_HAPROXY_CFG=./conf/haproxy/haproxy.cfg
VOLUME_MYSQL_CONF=./conf/mysql/conf.d/mysql.cnf
VOLUME_MYSQL_DATA=./volume/mysql/data
VOLUME_CERTBOT_CERTS=./volume/certbot/certs
VOLUME_CERTBOT_LOG=./volume/certbot/logs
VOLUME_SSL=./volume/ssl
VOLUME_APP=./php/example
```

- VOLUME_HAPROXY_CFG: haproxy 컨테이너에서 사용하는 환경설정 파일입니다. 본 파일은 심볼릭 링크(Symbolic Link)로 설정되어 있습니다.
  - 프로젝트의 ./conf/haproxy 디렉터리 내에는 haproxy.http.cfg와 haproxy.https.cfg 2개의 파일이 존재합니다.
  - https 인증서 발급 전에는 haproxy.http.cfg 파일을 haproxy.cfg 파일로 심볼릭 링크로 설정하여 사용합니다.
  - 인증서 발급이 완료되면 기존 haproxy.cfg 파일을 삭제한 후 haproxy.https.cfg 파일을 haproxy.cfg 파일로 심볼릭 링크를 설정하여 사용합니다.
  - 심볼릭 링크 설정은 `./configure.sh` 에 기록되어 있습니다.
- VOLUME_MYSQL_CONF: mysql 환경설정 파일입니다.
- VOLUME_MYSQL_DATA: mysql 데이터가 저장되는 공간입니다.
- VOLUME_CERTBOT_CERTS: certbot이 발급하는 인증서가 저장되는 공간입니다.
- VOLUME_CERTBOT_LOG: certbot이 인증서 발급 / 갱신 시 log를 저장하는 공간입니다.
- VOLUME_SSL: certbot외 인증서를 저장하여 사용할 경우 사용자가 해당 디렉터리에 저장하여 사용하기 위한 공간입니다.
- VOLUME_APP: 사용자의 Web Service가 저장되는 공간입니다. 본 프로젝트에서는 `./php/example` 디렉터리를 예시로 사용하였습니다. 추후 사용자의 웹 서비스 프로젝트 디렉터리를 상대경로로 입력하여 사용합니다.

configure.sh 실행하면 volume 디렉터리 내용들은 ./volume 디렉터리에 공유됩니다.

### 2. Network

본 프로젝트에서는 자동화된 인증서 발급과 원활한 내부 컨테이너 참조를 위해 고정된 IP를 사용합니다.
> haproxy.http.cfg, haproxy.https.cfg 내부에는 certbot 인증서 발급 / 갱신 동작을 위해 고정 IP 정보를 이용합니다.

내부 네트워크 정보는 아래와 같으며 필요한 경우 해당 항목을 수정하여 사용 가능합니다.

```bash
# Network Config
NETWORK_CONFIG_SUBNET=172.18.0.0/24

# Container IP Addresses
IPV4_ADDR_HAPROXY=172.18.0.2
IPV4_ADDR_MYSQL=172.18.0.3
IPV4_ADDR_PHPMYADMIN=172.18.0.4
IPV4_ADDR_CERTBOT=172.18.0.5
IPV4_ADDR_APP=172.18.0.10

# Ports
PORT_CERTBOT=8888
```

- NETWORK_CONFIG_SUBNET: subnet mask를 입력합니다.
- IPV4_ADDR_HAPROXY: haproxy 컨테이너에서 사용하는 IP Address를 입력합니다.
- IPV4_ADDR_MYSQL: mysql 컨테이너에서 사용하는 IP Address를 입력합니다.
- IPV4_ADDR_PHPMYADMIN: phpmyadmin 컨테이너에서 사용하는 IP Address를 입력합니다.
- IPV4_ADDR_CERTBOT: certbot 컨테이너에서 사용하는 IP Address를 입력합니다.
- IPv4_ADDR_APP: app 컨테이너에서 사용하는 IP Address를 입력합니다. app 컨테이너는 사용자의 웹 서비스 입니다.
- PORT_CERTBOT: certbot이 인증서 발급 / 갱신을 위해 사용하는 port 번호입니다.

### 3. Certbot

본 프로젝트에서는 Certbot을 이용한 Let's Encrypt SSL 발급 / 갱신을 위해 별도의 docker compose 환경설정 파일인 docker-compose-certbot.yml 을 이용합니다.

- 인증서 발급: configure.sh에서 docker-compose-certbot.sh를 이용해 발급을 진행합니다.
- 인증서 갱신: certbot_update.sh에서 docker-compose-certbot.yml을 이용해 갱신을 진행합니다.

본 프로젝트에서 인증서는 도메인 당 발급하는 방식으로 진행하였으며 docker-compose-certbot.yml의 service 항목의 certbot-app, certbot-phpmyadmin 을 이용합니다.

인증서 갱신은 일괄 진행하며 docker-compose-certbot.yml 의 service 항목의 certbot-update 를 이용합니다.

### 4. HAProxy

Reverse Proxy인 HAProxy는 본 프로젝트에서 2개의 환경설정 파일(haproxy.http.cfg, haproxy.https.cfg) 파일을 이용하며 인증서 발급 전 / 후에 따라 각 파일을 haproxy.cfg로 심볼릭 링크로 생성하여 사용합니다. 해당 내용은 .env 파일의 HAProxy 항목에 설정항목으로 기록되어 있습니다.

```bash
# HAProxy
# HAProxy base file for http, https
CONF_HAPROXY_CFG_HTTP=./conf/haproxy/haproxy.http.cfg
CONF_HAPROXY_CFG_HTTPS=./conf/haproxy/haproxy.https.cfg
```

### 5. Log

본 프로젝트에서 로그는 crontab 의 결과를 저장하는 용도로 사용합니다.

.env 파일의 Log항목에 아래와 같이 기록되어 있습니다.

```bash
# log
LOG_PATH=./logs
```

- LOG_PATH: 로그 파일을 저장할 경로를 상대경로로 입력합니다. 해당 내용은 현재 certbot_update.sh에서 존재여부를 확인한 후 없으면 생성하는 용도로 사용합니다.

### 6. shutdown.sh, run.sh

`shutdown.sh`는 현재 실행중인 모든 docker container를 down 시킬 때 사용합니다. `run.sh` 는 반대로 down된 container들을 up 시키는데 사용합니다.

이 두개의 Shell Script 역시 실행 권한이 주어져야 하며 아래와 같이 설정합니다.

```bash
chmod +x shutdown.sh
chmod +x run.sh
```

## References

https://serversforhackers.com/c/letsencrypt-with-haproxy 

## LICENSE

WTFPL
