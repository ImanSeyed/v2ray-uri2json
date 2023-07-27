# Dependencies
Before using the URI to JSON scripts, ensure you have the following softwares installed:
- `jq`
- `base64` (coreutils)
- `awk`

# Usage
Follow these steps to convert a URI to JSON format and set up the proxy client:
1. Run the following command to generate a file named config.json in your current directory:
```shell
# Default proxy ports -> SOCKS5: 10808, HTTP: 10809
$ bash scripts/vmess2json.sh <URI> # For vmess URIs
$ bash scripts/vless2json.sh <URI> # For vless URIs
$ bash scripts/trojan2json.sh <URI> # For trojan URIs
```
Or with custom proxy settings:
```shell
$ bash scripts/vmess2json.sh --http-proxy 1080 --socks5-proxy 1090 <URI>
$ bash scripts/vless2json.sh --http-proxy 1080 --socks5-proxy 1090 <URI>
$ bash scripts/trojan2json.sh --http-proxy 1080 --socks5-proxy 1090 <URI>
```
Run the command below to display all options:
```shell
$ bash scripts/lib/options.sh -h
```
2. Execute the Xray or V2ray with the generated configuration in your current directory:
```shell
$ xray run -c config.json
```
3. Configure your application to use the host computer's IP address as the proxy server, with the provided ports.
Now you should be able to use the proxy server for your desired applications.
