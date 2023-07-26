#!/bin/bash

source "$(dirname "$0")/options.sh"

if ! echo "$URL" | grep -Eo 'trojan://[^/]+' > /dev/null; then
	echo "trojan: Invalid URI scheme."
	exit 1
fi

source "$(dirname "$0")/stream-settings.sh"

PARSE_ME=$(echo "$URL" | awk -F'://' '{print $2}')
QUERY=$(echo "$PARSE_ME" | awk -F '[?#]' '{print $2}')
REMARKS=$(echo "$PARSE_ME" | awk -F '[#]' '{print $2}')
PASSWORD=$(echo "$PARSE_ME" | awk -F '[@?=&#]' '{print $1}')
SERVER_ADDRESS=$(echo "$PARSE_ME" | awk -F '[@:?=&#]' '{print $2}')
SERVER_PORT=$(echo "$PARSE_ME" | awk -F '[@:?=&#]' '{print $3}')

eval "$(echo $QUERY | awk -F '&' '{
        for(i=1;i<=NF;i++) {
		      print $i
	      }
}')"

NET_TYPE="$type"
ALPN="$alpn"
FINGERPRINT="$fp"
SNI="$sni"
SECURITY="$security"
TLS="$security"
HEADER_TYPE="$headerType"
USER_METHOD="chacha20-poly1305"

if [ "$NET_TYPE" == "tcp" ]; then
	STREAM_SETTINGS=$(gen_tcp)
elif [ "$NET_TYPE" == "ws" ]; then
	STREAM_SETTINGS=$(gen_ws)
elif [ "$NET_TYPE" == "quic" ]; then
	STREAM_SETTINGS=$(gen_quic)
else
	echo "Unsupported network type! Supported net types: (tcp | quic | ws)."
	exit 1
fi

cat <<EOF > "$DIR_PATH/config.json"
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
      "protocol": "trojan",
      "settings": {
        "servers": [
          {
            "address": "$SERVER_ADDRESS",
            "flow": "",
            "level": 8,
            "method": "$USER_METHOD",
            "ota": "false",
            "password": "$PASSWORD",
            "port": $SERVER_PORT
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
