#!/bin/bash

set -eu

echo "Installing needed software"
apt-get update
apt-get install -y --no-install-recommends \
  ca-certificates \
  curl \
  jq \
  tzdata \
  unzip

# AWS CLI v2 asennetaan virallisesta paketista, koska Debianin awscli-paketti on v1.
curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-$(uname -m).zip" -o /tmp/awscliv2.zip
unzip -q /tmp/awscliv2.zip -d /tmp
/tmp/aws/install
rm -rf /tmp/awscliv2.zip /tmp/aws

apt-get purge -y unzip
apt-get autoremove -y
rm -rf /var/lib/apt/lists/*

echo "Listing contents of /root folder"
ls -Al /root

echo "Listing contents of /root/dbt folder"
ls -Al /root/dbt

cd dbt
python -m venv venv
. venv/bin/activate
pip install -r requirements.txt

dbt deps
