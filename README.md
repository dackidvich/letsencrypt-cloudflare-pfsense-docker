# letsencrypt-cloudflare-pfsense-docker
Docker container that uses Let's Encrypt with DNS-01 validation on CloudFlare to change a cert on a pfSense router.

# Pre-requirements:
* pfSense
  * SSH open to connection from LAN
  * User with access to SSH using a certificate
  * Package `sudo` with `NOPASSWD` set for the user
* Configuration files (All in `/config`)
  * config.sh (must be executable `chmod 700`)
    * Example content:
```
    KEYSIZE="4096"                    # optional: example for showing how to set options specific to letsencrypt.sh
    
    CF_EMAIL='your@email.com'         # required: your cloudflare email
    CF_KEY='hunter2'                  # required: your cloudflare api key
    CF_DNS_SERVERS='8.8.8.8 8.8.4.4'  # optional: useful if you override your pfSense hosts for your LAN
    
    SSHHOST='pfsense'                 # required: this must match up with your ssh_config file (explained later)
    CERTNAME='letsencrypt_cert'       # required: the name of your certificate in the pfSense configuration
```

  * ssh_config (must be read-only `chmod 400`)
    * This file is the configuration for ssh, and /config/id_rsa must be your ssh key
    * The Host `pfsense` must line up with the `SSHHOST` in `config.sh`
    * Example content:
```
Host pfsense
  HostName pfsense.your.lan
  IdentityFile /config/id_rsa
  User user
````
  * id_rsa (must be read-only `chmod 400`)  Your SSH key for pfSense
  * domainlist
    * Flat file with your domains for a single cert
    * Since all domains are for a single cert, the first one is the primary and all domains listed after are subdomains.
    * If you have multiple domains, such as mydomain.com and mydomain.io then use multiple containers
    * Example content:
```
mydomain.com
www.mydomain.com
ftp.mycomain.com
```

  * openssl.cnf (suggest read-only `chmod 400`)
    * Start with a template, most likely from `/etc/ssl/openssl.cnf` or `/usr/lib/ssl/openssl.cnf`
    * This is provided as an example, you may have additional fields required for your certificate
    * Put the following cert information in the section `[ req_distinguished_name ]`
```
countryName                     = yourcountry
stateOrProvinceName             = yourstate/province
localityName                    = yourcity/town/etc
0.organizationName              = yourorganization
organizationalUnitName          = yourunit (or `None`)
commonName                      = mydomain.com
emailAddress                    = admin@mydomain.com
```

# Installing/Using
Edit `docker-create.sh` to make it fit your needs, namely the `/config` mounting.
Execute `./docker-create.sh` after editing.

An example `letsencrypt-shell` is included to allow getting root shell access to the container.
