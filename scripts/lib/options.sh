#!/bin/bash

# Default values
SOCKS5_PROXY_PORT="10808"
HTTP_PROXY_PORT="10809"

display_help() {
  echo "Usage: $0 [--http-proxy PORT] [--socks5-proxy PORT] URL"
  echo "Options:"
  echo "  --http-proxy PORT   Set the HTTP proxy to the specified PORT"
  echo "  --socks5-proxy PORT Set the SOCKS5 proxy to the specified PORT"
  echo "  --allow-insecure    Set allowInsecure to true"
  echo "  -d, --directory DIR Set the config.json directory to the specified DIR"
  echo "  -h, --help          Show this help message and exit"
  exit 1
}

is_valid_port() {
  local re='^[0-9]+$'
  if ! [[ $1 =~ $re ]] || (( $1 < 1 || $1 > 65535 )); then
    return 1
  else
    return 0
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --http-proxy)
      HTTP_PROXY_PORT="$2"
      shift 2
      ;;
    --socks5-proxy)
      SOCKS5_PROXY_PORT="$2"
      shift 2
      ;;
    --allow-insecure)
      ALLOW_INSECURE="true"
      shift 1
      ;;
    -h|--help)
      display_help
      ;;
    -d|--directory)
      PREFIX_DIR="${2%/}/"
      shift 2
      ;;
    *)
      if [ -z "$URL" ]; then
        URL="$1"
        shift
      else
        display_help
      fi
      ;;
  esac
done

if [ -z "$URL" ]; then
  echo "Please provide a URL."
  display_help
fi

if [ -n "$HTTP_PROXY_PORT" ]; then
  if ! is_valid_port "$HTTP_PROXY_PORT"; then
    echo "Invalid HTTP_PROXY_PORT port number: $HTTP_PROXY_PORT"
    exit 1
  fi
fi

if [ -n "$SOCKS5_PROXY_PORT" ]; then
  if ! is_valid_port "$SOCKS5_PROXY_PORT"; then
    echo "Invalid SOCKS5_PROXY_PORT port number: $SOCKS5_PROXY_PORT"
    exit 1
  fi
fi
