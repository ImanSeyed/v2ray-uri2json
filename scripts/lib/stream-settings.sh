#!/bin/bash

if [[ "$SECURITY" == "auto" ]]; then
	SECURITY=$TLS
fi

if [ -z "$ALLOW_INSECURE" ]; then
	ALLOW_INSECURE=false
fi

gen_tls() {

  if [ ! -z "$ALPN" ]; then
	ALPN="\"alpn\": [ \"$ALPN\" ],"
  fi

  if [ "$TLS" == "tls" ]; then
    printf '"tlsSettings": {
        "allowInsecure": %s,
	%s
        "fingerprint": "%s",
        "serverName": "%s",
        "show": false
    },' "$ALLOW_INSECURE" "$ALPN" "$FINGERPRINT" "$SNI"
  elif [ "$TLS" == "reality" ]; then
    printf '"realitySettings": {
        "allowInsecure": false,
        "fingerprint": "%s",
        "publicKey": "%s",
        "serverName": "%s",
        "shortId": "%s",
        "show": false,
        "spiderX": "%s"
    },\n' "$FINGERPRINT" "$PUBLICKEY" "$SNI" "$SID" "$SPX"
  fi
}

gen_ws() {
  tls_settings=$(gen_tls)

  printf '{
    "network": "ws",
    "security": "%s",
    %s
    "wsSettings": {
      "path": "%s",
      "headers": {
        "Host": "%s"
      }
    }
  },\n' "$SECURITY" "$tls_settings" "$SETTINGS_PATH" "$HEADERS_HOST"
}


gen_tcp() {
  tls_settings=$(gen_tls)

  printf '{
    "network": "tcp",
    "security": "%s",
    %s
    "tcpSettings": {
     "header": {
      	"type": "%s"
     }
   }
},\n' "$SECURITY" "$tls_settings" "$HEADER_TYPE"
}

gen_quic() {
  tls_settings=$(gen_tls)
  printf '{
    "network": "quic",
    "security": "%s",
    %s
    "quicSettings": {
      "security": "none",
      "key": "",
      "header": {
        "type": "%s"
      } 
   }
},\n' "$SECURITY" "$tls_settings" "$HEADER_TYPE"
}

gen_grpc() {
  tls_settings=$(gen_tls)
  printf '{
    "network": "grpc",
    "security": "%s",
    %s
    "grpcSettings": {
    	"authority": "",
			"health_check_timeout": 20,
			"idle_timeout": 60,
			"multiMode": false,
      "serviceName": "%s"
    }
},\n' "$SECURITY" "$tls_settings" "$SETTINGS_PATH"
}
