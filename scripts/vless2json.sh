#!/bin/bash

source "$(dirname "$0")/lib/options.sh"
function urldecode() { : "${*//+/ }"; echo -e "${_//%/\\x}"; }

if ! echo "$URL" | grep -Eo 'vless://[^/]+' > /dev/null; then
	echo "vless: Invalid URI scheme."
	exit 1
fi

PARSE_ME=$(echo "$URL" | awk -F'://' '{print $2}')
QUERY=$(echo "$PARSE_ME" | awk -F '[?#]' '{print $2}')
USER_ID=$(echo "$PARSE_ME" | awk -F'[@:?]' '{print $1}')
SERVER_ADDRESS=$(echo "$PARSE_ME" | awk -F'[@:?]' '{print $2}')
SERVER_PORT=$(echo "$PARSE_ME" | awk -F'[@:?]' '{print $3}' | sed 's/[^0-9]*//g')
REMARKS=$(echo "$PARSE_ME" | awk -F '[#]' '{print $2}')

eval "$(echo "$QUERY" | awk -F '&' '{
        for(i=1;i<=NF;i++) {
                print $i
        }
}')"

NET_TYPE="$type"
TLS="$security"
SECURITY="$security"
ENCRYPTION=${encryption:-none}
HEADER_TYPE=${headerType:-none}
FINGERPRINT="$fp"
SNI="$sni"
SID="$sid"
SPX=$(urldecode "$spx")
PUBLICKEY="$pbk"
FLOW="$flow"
ALPN=$(urldecode "$alpn")
HEADERS_HOST="$host"
SETTINGS_PATH=$(urldecode "$path")
if [ -z "${SETTINGS_PATH}" ]; then
  SETTINGS_PATH=$(urldecode "$serviceName")
fi

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

jq . <<EOF > "${PREFIX_DIR}config.json"
{
  "dns": {
    "hosts": {
		"geosite:category-ads-all": "127.0.0.1",
		"domain:googleapis.cn": "googleapis.com",
		"dns.alidns.com": [
		  "223.5.5.5",
		  "223.6.6.6",
		  "2400:3200::1",
		  "2400:3200:baba::1"
		],
		"one.one.one.one": [
		  "1.1.1.1",
		  "1.0.0.1",
		  "2606:4700:4700::1111",
		  "2606:4700:4700::1001"
		],
		"dot.pub": [
		  "1.12.12.12",
		  "120.53.53.53"
		],
		"dns.google": [
		  "8.8.8.8",
		  "8.8.4.4",
		  "2001:4860:4860::8888",
		  "2001:4860:4860::8844"
		],
		"dns.quad9.net": [
		  "9.9.9.9",
		  "149.112.112.112",
		  "2620:fe::fe",
		  "2620:fe::9"
		],
		"common.dot.dns.yandex.net": [
		  "77.88.8.8",
		  "77.88.8.1",
		  "2a02:6b8::feed:0ff",
		  "2a02:6b8:0:1::feed:0ff"
		]
    },
    "servers": [
		"1.1.1.1",
		{
		  "address": "1.1.1.1",
		  "domains": [
			"domain:googleapis.cn",
			"domain:gstatic.com"
		  ]
		},
		{
		  "address": "223.5.5.5",
		  "domains": [
			"domain:dns.alidns.com",
			"domain:doh.pub",
			"domain:dot.pub",
			"domain:doh.360.cn",
			"domain:dot.360.cn",
			"geosite:cn",
			"geosite:geolocation-cn"
		  ],
		  "expectIPs": [
			"geoip:cn"
		  ],
		  "skipFallback": true
		}
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
        "enabled": true,
		    "routeOnly": false
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
        "concurrency": -1,
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
      "settings": {
        "domainStrategy": "UseIP"
      },
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
		},
		{
		  "ip": [
			"223.5.5.5"
		  ],
		  "outboundTag": "direct",
		  "port": "53",
		  "type": "field"
		},
		{
		  "domain": [
			"domain:googleapis.cn",
			"domain:gstatic.com"
		  ],
		  "outboundTag": "proxy",
		  "type": "field"
		},
		{
		  "network": "udp",
		  "outboundTag": "block",
		  "port": "443",
		  "type": "field"
		},
		{
		  "domain": [
			"geosite:category-ads-all"
		  ],
		  "outboundTag": "block",
		  "type": "field"
		},
		{
		  "domain": [
			"geosite:private"
		  ],
		  "outboundTag": "direct",
		  "type": "field"
		},
		{
			"ip": [
          "geoip:private"
        ],
        "outboundTag": "direct",
        "type": "field"
      },
      {
        "domain": [
          "domain:dns.alidns.com",
          "domain:doh.pub",
          "domain:dot.pub",
          "domain:doh.360.cn",
          "domain:dot.360.cn",
          "geosite:cn",
          "geosite:geolocation-cn"
        ],
        "outboundTag": "direct",
        "type": "field"
      },
      {
        "ip": [
          "223.5.5.5/32",
          "223.6.6.6/32",
          "2400:3200::1/128",
          "2400:3200:baba::1/128",
          "119.29.29.29/32",
          "1.12.12.12/32",
          "120.53.53.53/32",
          "2402:4e00::/128",
          "2402:4e00:1::/128",
          "180.76.76.76/32",
          "2400:da00::6666/128",
          "114.114.114.114/32",
          "114.114.115.115/32",
          "180.184.1.1/32",
          "180.184.2.2/32",
          "101.226.4.6/32",
          "218.30.118.6/32",
          "123.125.81.6/32",
          "140.207.198.6/32",
          "geoip:cn"
        ],
        "outboundTag": "direct",
        "type": "field"
      },
      {
        "outboundTag": "proxy",
        "port": "0-65535",
        "type": "field"
      }
    ]
  }
}
EOF
