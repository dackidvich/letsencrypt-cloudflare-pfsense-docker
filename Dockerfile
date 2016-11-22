FROM quantumobject/docker-baseimage:16.04

ENV PYTHONIOENCODING=UTF-8
ENV LC_ALL C.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE=en_US.UTF-8

ADD scripts/ /scripts

RUN mkdir -p /etc/apt/apt.conf.d \
	&& echo 'Acquire::ForceIPv4 "true";' | tee /etc/apt/apt.conf.d/99force-ipv4 \
	&& echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections \
	&& apt-get update -q \
	&& apt-get install -qy --no-install-recommends wget git python3 openssh-client xmlstarlet \
	&& apt-get autoremove -y \
	&& apt-get autoclean -y \
	&& git clone https://github.com/lukas2511/dehydrated.git /scripts/dehydrated \
	&& git clone https://github.com/kappataumu/letsencrypt-cloudflare-hook /scripts/letsencrypt-cloudflare-hook \
	&& ln -s /usr/bin/python3 /usr/bin/python \
	&& wget -nv -O/tmp/get-pip.py "https://bootstrap.pypa.io/get-pip.py" \
	&& python /tmp/get-pip.py \
	&& rm /tmp/get-pip.py \
	&& pip3 install -r /scripts/letsencrypt-cloudflare-hook/requirements.txt \
	&& mkdir /root/.ssh \
	&& chmod 700 /root/.ssh \
	&& chmod 777 /scripts/letsencrypt_*.sh \
	&& echo "17 5 * * * /bin/bash /scripts/letsencrypt_cron.sh >>/config/cron_output 2>&1" | crontab - \
	&& rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

VOLUME /config

CMD ["/sbin/my_init"]
