#!/bin/bash

date >/config/last_run

export SSHCONF='/config/ssh_config'
export OPENSSL_CNF="/config/openssl.cnf"

if [ -f ~/.ssh/known_hosts ]; then
	ssh-keyscan -H $SSHHOST -F $SSHCONF >~/.ssh/known_hosts
	chmod 600 ~/.ssh/known_hosts
fi

echo " Checking for configuration"
if [ ! -f $OPENSSL_CNF ]; then
	echo "ERROR: Cannot access /config/openssl.cnf"
	exit 1
fi
if [ ! -f /config/domainlist ]; then
	echo "ERROR: Cannot access /config/domainlist	this file should be a flatfile of all domains, separated by newlines"
	exit 1
fi

if [ ! -x /config/config.sh ]; then
	config=0
else
	# Couldn't figure out how to execute a script (sourced or not) that would allow
	# environment variables to be read from it, then also scoped to be sent to any
	# other scripts; possibly letsencrypt calls its dns hook without scoping?
	# So, this is a total hack to read in all the lines that aren't blank or 
	# comments and declares them.
	while read line; do
		if [[ $line =~ ^\# ]]; then continue; fi
		if [[ ${#line} == 0 ]]; then continue; fi
	
		declare -x "$line"
	done </config/config.sh 

	if [ ! -v CF_EMAIL ] || [ ! -v CF_KEY ] || [ ! -v SSHHOST ] || [ ! -v CERTNAME ]
	then
		config=0
	fi
fi
if [ "$config" == "0" ]; then
	echo "
	ERROR: Misconfigured.	Ensure /config/config.sh exists, is executable, and contains the following:

	# letsencrypt.sh options
	KEYSIZE="4096"	# optional, example of letsencrypt options

	# Cloudflare information
	CF_EMAIL='your@email.com'
	CF_KEY='hunter2'
	CF_DNS_SERVERS='8.8.8.8 8.8.4.4'	# optional

	# PFSense information
	SSHHOST='pfsense'			# pfsense; Host in ssh_config 
	CERTNAME='letsencrypt_cert'		# name of the certificate in pfsense
	"
fi

if [ ! -f $SSHCONF ]; then
	echo "
	ERROR: ssh_config file does not exist; ensure this file exists in the config directory, such as /config

	Example:
	Host pfsense
	HostName pfsense.domain.com
	IdentityFile /config/id_rsa
	User your_pfsense_username


	----- This is used for reading/writing the config.xml file
	"
fi

. /scripts/letsencrypt_autopfsense.sh
