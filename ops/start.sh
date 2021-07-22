#!/usr/bin/env bash
set -e

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null 2>&1 && pwd)
project=$(grep -m 1 '"name":' "$root/package.json" | cut -d '"' -f 4)

# turn on swarm mode if it's not already on
docker swarm init 2> /dev/null || true
docker network create --attachable --driver overlay "$project" 2> /dev/null || true

if grep -qs "$project" <<<"$(docker stack ls | tail -n +2)"
then echo "$project stack is already running" && exit
fi

####################
# External Env Vars

# shellcheck disable=SC1091
if [[ -f .env ]]; then source .env; fi

MEDIA_AUTH_PASSWORD="${MEDIA_AUTH_PASSWORD:-abc123}"
MEDIA_AUTH_USERNAME="${MEDIA_AUTH_USERNAME:-admin}"
MEDIA_DOMAINNAME="${MEDIA_DOMAINNAME:-}"
MEDIA_EMAIL="${MEDIA_EMAIL:-noreply@gmail.com}" # for notifications when ssl certs expire
MEDIA_HOST_DIR="${MEDIA_HOST_DIR:-$root/media}"
MEDIA_INTERNAL_DIR="${MEDIA_INTERNAL_DIR:-/media}"
MEDIA_LOG_LEVEL="${MEDIA_LOG_LEVEL:-info}"
MEDIA_MAX_UPLOAD_SIZE="${MEDIA_MAX_UPLOAD_SIZE:-100mb}"
MEDIA_PROD="${MEDIA_PROD:-false}"
MEDIA_SEMVER="${MEDIA_SEMVER:-false}"

# If semver flag is given, we should ensure the prod flag is also active
if [[ "$MEDIA_SEMVER" == "true" ]]
then export MEDIA_PROD=true
fi

echo "Launching $project in env:"
echo "- MEDIA_AUTH_PASSWORD=$MEDIA_AUTH_PASSWORD"
echo "- MEDIA_AUTH_USERNAME=$MEDIA_AUTH_USERNAME"
echo "- MEDIA_DOMAINNAME=$MEDIA_DOMAINNAME"
echo "- MEDIA_EMAIL=$MEDIA_EMAIL"
echo "- MEDIA_HOST_DIR=$MEDIA_HOST_DIR"
echo "- MEDIA_INTERNAL_DIR=$MEDIA_INTERNAL_DIR"
echo "- MEDIA_LOG_LEVEL=$MEDIA_LOG_LEVEL"
echo "- MEDIA_MAX_UPLOAD_SIZE=$MEDIA_MAX_UPLOAD_SIZE"
echo "- MEDIA_PROD=$MEDIA_PROD"
echo "- MEDIA_SEMVER=$MEDIA_SEMVER"

########################################
# Misc Config

if [[ "$MEDIA_HOST_DIR" == "/"* ]]
then mkdir -p "$MEDIA_HOST_DIR"
fi

commit=$(git rev-parse HEAD | head -c 8)
semver="v$(grep -m 1 '"version":' "$root/package.json" | cut -d '"' -f 4)"
if [[ "$MEDIA_SEMVER" == "true" ]]
then version="$semver"
elif [[ "$MEDIA_PROD" == "true" ]]
then version="$commit"
else version="latest"
fi

common="networks:
      - '$project'
    logging:
      driver: 'json-file'
      options:
          max-size: '10m'"

########################################
# IPFS config

ipfs_internal_port=5001

ipfs_image="ipfs/go-ipfs:v0.8.0"
bash "$root/ops/pull-images.sh" "$ipfs_image"

########################################
# Server config

server_internal_port=8080
server_env="environment:
      MEDIA_AUTH_PASSWORD: '$MEDIA_AUTH_PASSWORD'
      MEDIA_AUTH_USERNAME: '$MEDIA_AUTH_USERNAME'
      MEDIA_DOMAINNAME: '$MEDIA_DOMAINNAME'
      MEDIA_EMAIL: '$MEDIA_EMAIL'
      MEDIA_INTERNAL_DIR: '$MEDIA_INTERNAL_DIR'
      MEDIA_LOG_LEVEL: '$MEDIA_LOG_LEVEL'
      MEDIA_MAX_UPLOAD_SIZE: '$MEDIA_MAX_UPLOAD_SIZE'
      MEDIA_PORT: '$server_internal_port'
      MEDIA_PROD: '$MEDIA_PROD'
      IPFS_URL: 'ipfs:$ipfs_internal_port'"

if [[ "$MEDIA_PROD" == "true" ]]
then
  server_image="${project}_server:$version"
  server_service="server:
    image: '$server_image'
    $common
    $server_env
    volumes:
      - '$MEDIA_HOST_DIR:$MEDIA_INTERNAL_DIR'"

else
  server_image="${project}_builder:$version"
  server_service="server:
    image: '$server_image'
    $common
    $server_env
    entrypoint: 'bash modules/server/ops/entry.sh'
    ports:
      - '5000:5000'
    volumes:
      - '$root:/root'
      - '$MEDIA_HOST_DIR:$MEDIA_INTERNAL_DIR'"

fi
bash "$root/ops/pull-images.sh" "$server_image"

########################################
# Webserver config

webserver_internal_port=3000

if [[ "$MEDIA_PROD" == "true" ]]
then
  webserver_image="${project}_webserver:$version"
  webserver_service="webserver:
    image: '$webserver_image'
    $common"

else
  webserver_image="${project}_builder:$version"
  webserver_service="webserver:
    image: '$webserver_image'
    $common
    entrypoint: 'npm start'
    environment:
      NODE_ENV: 'development'
    volumes:
      - '$root:/root'
    working_dir: '/root/modules/client'"

fi
bash "$root/ops/pull-images.sh" "$webserver_image"

########################################
# Proxy config

proxy_image="${project}_proxy:$version"
bash "$root/ops/pull-images.sh" "$proxy_image"

if [[ -n "$MEDIA_DOMAINNAME" ]]
then
  public_url="https://$MEDIA_DOMAINNAME/git/config"
  proxy_ports="ports:
      - '80:80'
      - '443:443'"
  echo "${project}_proxy will be exposed on *:80 and *:443"

else
  public_port=${public_port:-3000}
  public_url="http://127.0.0.1:$public_port/git/config"
  proxy_ports="ports:
      - '$public_port:80'"
  echo "${project}_proxy will be exposed on *:$public_port"
fi

####################
# Launch It

docker_compose=$root/.docker-compose.yml
rm -f "$docker_compose"
cat - > "$docker_compose" <<EOF
version: '3.4'

networks:
  $project:
    external: true

volumes:
  certs:
  ipfs:

services:

  proxy:
    image: '$proxy_image'
    $common
    $proxy_ports
    environment:
      DOMAINNAME: '$MEDIA_DOMAINNAME'
      EMAIL: '$MEDIA_EMAIL'
      SERVER_URL: 'server:$server_internal_port'
      WEBSERVER_URL: 'webserver:$webserver_internal_port'
    volumes:
      - 'certs:/etc/letsencrypt'

  $webserver_service

  $server_service

  ipfs:
    image: '$ipfs_image'
    $common
    ports:
      - '4001:4001'
    volumes:
      - 'ipfs:/data/ipfs'

EOF

docker stack deploy -c "$docker_compose" "$project"

echo "The $project stack has been deployed, waiting for $public_url to start responding.."
timeout=$(( $(date +%s) + 60 ))
while true
do
  res=$(curl -k -m 5 -s "$public_url" || true)
  if [[ -z "$res" || "$res" == *"Waiting for proxy to wake up"* ]]
  then
    if [[ "$(date +%s)" -gt "$timeout" ]]
    then echo "Timed out waiting for $public_url to respond.." && exit
    else sleep 2
    fi
  else echo "Good Morning!"; break;
  fi
done
