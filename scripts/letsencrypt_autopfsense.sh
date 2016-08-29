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
pushd $dir/letsencrypt.sh
. ./letsencrypt.sh -c -t dns-01 -k ../letsencrypt-cloudflare-hook/hook.py -o $certsdir $domains

# Obtain the cert information
cdir=$(find $certsdir -maxdepth 2 -mindepth 1 -type d)
if [ ! -f "$cdir/fullchain.pem" ]; then
    echo "Could not find fullchain"
    exit 1
fi
if [ ! -f "$cdir/privkey.pem" ]; then
    echo "Could not find privkey"
    exit 1
fi
crt=$(base64 "$cdir/fullchain.pem")
prv=$(base64 "$cdir/privkey.pem")

config=/tmp/letsencrypt_pfsense_config.xml
if [ -f $config ]; then
    rm -rf $config
fi

echo "Obtaining config xml from pfsense"
sftp -F $SSHCONF -q $SSHHOST:/conf/config.xml $config

echo "Modifying cert information inside the xml"
xmlstarlet edit -L -u "//cert[contains(descr/text(),\"$CERTNAME\")]/prv" -v "$prv" $config
xmlstarlet edit -L -u "//cert[contains(descr/text(),\"$CERTNAME\")]/crt" -v "$crt" $config

echo "Uploading modified config xml to pfsense"
sftp -F $SSHCONF -q $SSHHOST <<< "put $config $config"

echo "Replacing existing pfsense config with uploaded config"
ssh -F $SSHCONF $SSHHOST <<////
sudo cp $config /conf/config.xml
rm $config
sudo rm /tmp/config.cache
exit
////

echo "Cleaning up temporary files"
rm -rf $config
