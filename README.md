# Dependencies
Before using the URI to JSON scripts, ensure you have the following softwares installed:
- `jq`
- `base64` (coreutils)
- `awk`

# TODO
- [x] Add support for vless URIs
- [x] Add support for vmess URIs
- [x] Add support for trojan URIs
- [ ] Add a switch for setting SOCKS5 and HTTP proxy ports to bind
- [ ] Add a switch for setting config.json path
- [ ] Add support for gRPC

# Usage
Follow these steps to convert a URI to JSON format and set up the proxy client:
1. Run the following command to generate a file named config.json in your current directory:
```shell
$ bash scripts/vmess2json.sh <URI>
```
2. Execute the Xray or V2ray with the generated configuration in your current directory:
```shell
$ xray run -c config.json
```
3. Configure your application to use the host computer's IP address as the proxy server, with the following ports:
- **SOCKS5**: Port 10808
- **HTTP**: Port 10809

Now you should be able to use the proxy server for your desired applications.
