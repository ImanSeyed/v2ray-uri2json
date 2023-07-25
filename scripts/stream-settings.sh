#!/bin/sh

if [ ! -z $SECURITY ] && [ $SECURITY == "auto" ]; then
	SECURITY=$TLS
fi

gen_tls() {

  if [ ! -z "$ALPN" ]; then
	ALPN="\"alpn\": [ \"$ALPN\" ],"
  fi

  if [ ! -z "$TLS" ] && [ "$TLS" == "tls" ]; then
    printf '"tlsSettings": {
        "allowInsecure": false,
	%s
        "fingerprint": "%s",
        "serverName": "%s",
        "show": false
    },' "$ALPN" "$FINGERPRINT" "$SNI"
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
