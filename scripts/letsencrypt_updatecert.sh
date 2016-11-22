#!/bin/bash
set -e

certsdir='/config/certs'
mkdir -p $certsdir

domains=''
while read line; do
    domains="$domains -d $line"
done </config/domainlist

script=$(readlink -f "$0")
dir=$(dirname "$script")
pushd $dir/dehydrated
. ./dehydrated -c -t dns-01 -k ../letsencrypt-cloudflare-hook/hook.py -o $certsdir $domains
