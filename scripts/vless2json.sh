#!/bin/bash

if [ -z $1 ];then
	echo "URI as an argument is required."
	exit 1
fi

URL="$1"

if ! echo "$URL" | grep -Eo 'vless://[^/]+' > /dev/null; then
	echo "vless: Invalid URI scheme."
	exit 1
fi

PARSE_ME=$(echo $URL | awk -F'://' '{print $2}')
QUERY=$(echo $PARSE_ME | awk -F '[?#]' '{print $2}')
USER_ID=$(echo $PARSE_ME | awk -F'[@:?]' '{print $1}')
SERVER_ADDRESS=$(echo $PARSE_ME | awk -F'[@:?]' '{print $2}')
SERVER_PORT=$(echo $PARSE_ME | awk -F'[@:?]' '{print $3}')
REMARKS=$(echo $PARSE_ME | awk -F '[#]' '{print $2}') 
SOCKS5_PROXY_PORT=10808
HTTP_PROXY_PORT=10809
TLS=tls

eval $(echo $QUERY | awk -F '&' '{                        
        for(i=1;i<=NF;i++) {                              
                print $i                                  
        }                                                 
}')
NET_TYPE=$type
TLS=$security
ENCRYPTION=$encryption
HEADER_TYPE=$headerType
FINGERPRINT=$fp
SNI=$sni
FLOW=$flow
ALPN=$alpn

source "$(dirname "$0")/stream-settings.sh"

if [ $NET_TYPE == "tcp" ]; then
        STREAM_SETTINGS=$(gen_tcp)
elif [ $NET_TYPE == "ws" ]; then
        STREAM_SETTINGS=$(gen_ws)
elif [ $NET_TYPE == "quic" ]; then
        STREAM_SETTINGS=$(gen_quic)
else
        echo "Unsupported network type! Supported net types: (tcp | quic | ws)."
        exit 1
fi

cat <<EOF > config.json
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
      "protocol": "vless",
      "settings": {
        "vnext": [
          {
            "address": "$SERVER_ADDRESS",
            "port": $SERVER_PORT,
            "users": [
              {
                "encryption": "$ENCRYPTION",
                "flow": "$FLOW",
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