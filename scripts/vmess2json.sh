#!/bin/bash

source "$(dirname "$0")/lib/options.sh"

if ! echo "$URL" | grep -Eo 'vmess://[^/]+' > /dev/null; then
	echo "vmess: Invalid URI scheme."
	exit 1
fi

DECODE_ME=$(echo "$URL" | awk -F'://' '{ print $2 }')
JSON_DATA=$(echo "$DECODE_ME" | base64 -d || exit 1)

SERVER_ADDRESS=$(echo "$JSON_DATA" | jq -r .add)
ALTER_ID=$(echo "$JSON_DATA" | jq -r .aid)
ALPN=$(echo "$JSON_DATA" | jq -r .alpn)
FINGERPRINT=$(echo "$JSON_DATA" | jq -r .fp)
HEADERS_HOST=$(echo "$JSON_DATA" | jq -r .host)
USER_ID=$(echo "$JSON_DATA" | jq -r .id)
NET_TYPE=$(echo "$JSON_DATA" | jq -r .net)
SETTINGS_PATH=$(echo "$JSON_DATA" | jq -r .path)
SERVER_PORT=$(echo "$JSON_DATA" | jq -r .port)
REMARKS=$(echo "$JSON_DATA" | jq -r  .ps)
SECURITY=$(echo "$JSON_DATA" | jq -r .scy)
SNI=$(echo "$JSON_DATA" | jq -r .sni)
TLS=$(echo "$JSON_DATA" | jq -r  .tls)
TYPE=$(echo "$JSON_DATA" | jq -r .type)
V=$(echo "$JSON_DATA" | jq -r .v)

source "$(dirname "$0")/lib/stream-settings.sh"

if [ "$NET_TYPE" == "tcp" ]; then
	STREAM_SETTINGS=$(gen_tcp)
elif [ "$NET_TYPE" == "ws" ]; then
	STREAM_SETTINGS=$(gen_ws)
elif [ "$NET_TYPE" == "quic" ]; then
	STREAM_SETTINGS=$(gen_quic)
elif [ "$NET_TYPE" == "grpc" ]; then
  STREAM_SETTINGS=$(gen_grpc)
else
	echo "Unsupported network type! Supported net types: (tcp | quic | ws | grpc)."
	exit 1
fi

cat <<EOF > "${PREFIX_DIR}config.json"
{
  "dns": {
    "hosts": {
      "domain:googleapis.cn": "googleapis.com"
    },
    "servers": [
      "1.1.1.1"
    ]
  },
  "inbounds": [
    {
      "listen": "0.0.0.0",
      "port": $SOCKS5_PROXY_PORT,
      "protocol": "socks",
      "settings": {
        "auth": "noauth",
        "udp": true,
        "userLevel": 8
      },
      "sniffing": {
        "destOverride": [
          "http",
          "tls"
        ],
        "enabled": true
      },
      "tag": "socks"
    },
    {
      "listen": "0.0.0.0",
      "port": $HTTP_PROXY_PORT,
      "protocol": "http",
      "settings": {
        "userLevel": 8
      },
      "tag": "http"
    }
  ],
  "log": {
    "loglevel": "warning"
  },
  "outbounds": [
    {
      "mux": {
        "concurrency": 8,
        "enabled": false
      },
      "protocol": "vmess",
      "settings": {
        "vnext": [
          {
            "address": "$SERVER_ADDRESS",
            "port": $SERVER_PORT,
            "users": [
              {
                "alterId": $ALTER_ID,
                "encryption": "",
                "flow": "",
                "id": "$USER_ID",
                "level": 8,
                "security": "auto"
              }
            ]
          }
        ]
      },
      "streamSettings":
	$STREAM_SETTINGS
      "tag": "proxy"
    },
    {
      "protocol": "freedom",
      "settings": {},
      "tag": "direct"
    },
    {
      "protocol": "blackhole",
      "settings": {
        "response": {
          "type": "http"
        }
      },
      "tag": "block"
    }
  ],
  "routing": {
    "domainStrategy": "IPIfNonMatch",
    "rules": [
      {
        "ip": [
          "1.1.1.1"
        ],
        "outboundTag": "proxy",
        "port": "53",
        "type": "field"
      }
    ]
  }
}
EOF
