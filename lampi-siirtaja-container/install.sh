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
  python3 \
  py3-pip \
  libpq-dev \
  g++ \
  make

echo "Listing contents of /root folder"
ls -Al /root

echo "Listing contents of /root/lampi-siirtaja folder"
ls -Al /root/lampi-siirtaja

echo "Installing dependencies with npm"
cd /root/lampi-siirtaja
npm ci
