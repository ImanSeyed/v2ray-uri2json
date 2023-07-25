#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root or with superuser privileges."
  exit 1
fi

install_path="/usr/local/bin"
mkdir -p "$install_path"
chmod +x scripts/*.sh
cp -v scripts/*.sh "$install_path/"
cd "$install_path" || exit
echo "Installation completed. Scripts are available in: $install_path"
