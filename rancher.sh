#!/usr/bin/env bash
#
# Forked with updates from https://gist.github.com/anapsix/25a5a66696f14806a4686ec1c707d2d2

set -u
set -o pipefail

RANCHER_CONTAINER_NAME="rancher-with-k8s"
RANCHER_HTTP_HOST_PORT=$[$[RANDOM%9000]+30000]
RANCHER_HTTPS_HOST_PORT=$[$[RANDOM%9000]+30000]
: ${K8S_CLUSTER_NAME:="docker-desktop"}

info() {
  if [[ ${QUIET:-0} -eq 0 ]] || [[ ${DEBUG:-0} -eq 1 ]]; then
    echo >&2 -e "\e[92mINFO:\e[0m $@"
  fi
}

warn() {
  if [[ ${QUIET:-0} -eq 0 ]] || [[ ${DEBUG:-0} -eq 1 ]]; then
    echo >&2 -e "\e[33mWARNING:\e[0m $@"
  fi
}

debug(){
  if [[ ${DEBUG:-0} -eq 1 ]]; then
    echo >&2 -e "\e[95mDEBUG:\e[0m $@"
  fi
}

error(){
  local msg="$1"
  local exit_code="${2:-1}"
  echo >&2 -e "\e[91mERROR:\e[0m $1"
  if [[ "${exit_code}" != "-" ]]; then
    exit ${exit_code}
  fi
}

getval() {
  local x="${1%%=*}"
  if [[ "$x" = "$1" ]]; then
    echo "${2}"
    return 2
  else
    echo "${1##*=}"
    return 1
  fi
}

usage() {
cat <<EOF
Usage: $0 [FLAGS] [ACTIONS]
  FLAGS:
    -h | --help | --usage   displays usage
    -q | --quiet            enabled quiet mode, no output except errors
    --debug                 enables debug mode, ignores quiet mode
  ACTIONS:
    create                create new Rancher
    destroy               destroy Rancher
  Examples:
    \$ $0 create
    \$ $0 destroy

EOF
}

case $(uname -s) in
  Darwin)
    localip="$(ipconfig getifaddr en0)"
  ;;
  Linux)
    localip="$(hostname -i)"
  ;;
  *)
    echo >&2 "Unsupported OS, exiting.."
    exit 1
  ;;
esac

## Get CLI arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help|--usage)
      usage
      exit 0
    ;;

    -d|--debug)
      DEBUG=1
      shift 1
    ;;

    -q|--quiet)
      QUIET=1
      shift 1
    ;;

    create|init)
      MODE="create"
      shift 1
    ;;

    destroy|cleanup)
      MODE="destroy"
      shift 1
    ;;

    *)
      error "Unexpected option \"$1\"" -
      usage
      exit 1
    ;;
  esac
done

set -e

# check docker binary availability
if ! which docker >/dev/null; then
  error "Docker binary cannot be found in PATH" -
  error "Install Docker or check your PATH, exiting.."
fi

if [[ "${MODE:-}" == "destroy" ]]; then
  info "Destroying Rancher container.."
  if ! docker rm -f ${RANCHER_CONTAINER_NAME}; then
    error "failed to remove Rancher container \"${RANCHER_CONTAINER_NAME}\".." -
  fi
  exit 0
elif [[ "${MODE:-}" != "create" ]]; then
  usage
  exit 0
fi

# Launch Rancher server
if [[ $(docker ps -f name=${RANCHER_CONTAINER_NAME} -q | wc -l) -ne 0 ]]; then
  error "Rancher container already present, delete it before trying again, exiting.."
fi
info "Launching Rancher container"
if docker run -d \
              --restart=unless-stopped \
              --name ${RANCHER_CONTAINER_NAME}  \
              -p ${RANCHER_HTTP_HOST_PORT}:80   \
              -p ${RANCHER_HTTPS_HOST_PORT}:443 \
              rancher/rancher; then
  info "Rancher UI will be available at https://${localip}:${RANCHER_HTTPS_HOST_PORT}"
  info "It might take few up to 60 seconds for Rancher UI to become available.."
fi

echo https://${localip}:${RANCHER_HTTPS_HOST_PORT} > rancher_url_$(date +%Y%m%d%H%M)

# set Rancher admin password and add kubernetes cluster
./add-cluster.sh "${localip}:${RANCHER_HTTPS_HOST_PORT}" ${K8S_CLUSTER_NAME}

# Open Rancher UI in browser
open https://${localip}:${RANCHER_HTTPS_HOST_PORT}
