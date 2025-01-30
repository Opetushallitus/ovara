#!/bin/bash

set -eu

case "$(uname -m)" in
  aarch64) ARCHITECTURE="arm64" ;;
  x86_64) ARCHITECTURE="amd64" ;;
  *) ARCHITECTURE=$(uname -m) ;;
esac
echo $ARCHITECTURE

echo "Installing needed software"
apk --no-cache add \
  aws-cli \
  jq

echo "Listing contents of /root folder"
ls -Al /root
