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
  py3-pip

ln -sf /usr/bin/python3 /usr/bin/python
ln -sf /usr/bin/pip3 /usr/bin/pip

echo "Listing contents of /root folder"
ls -Al /root

echo "Listing contents of /root/dbt folder"
ls -Al /root/dbt

cd dbt
python -m venv venv
. venv/bin/activate
pip install -r requirements.txt
