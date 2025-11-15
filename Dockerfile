# Base Image
FROM ubuntu:noble

ARG DEBIAN_FRONTEND=noninteractive
RUN apt update \
    && apt upgrade -y \
    && apt install -y \
        libapache2-mod-php \
        && apt install -y --no-install-recommends ffmpeg \
        && apt install -y --no-install-recommends zoneminder \
        && apt install -y --no-install-recommends python3-opencv \
        && apt install -y mariadb-client \
        nano \
        gnupg2 \
        lsb-release\
        

        python3-requests \
        python3-pip \
        
        liblwp-protocol-https-perl \
        libcrypt-mysql-perl \
        libmodule-build-perl \
        libcrypt-eksblowfish-perl \
        git \
        gifsicle \
        cpanminus \
        libyaml-perl \
        libjson-perl \
        libgeos-dev \
        s6 \
    
    && pip install --break-system-packages pyzm \
    && apt clean \
    && a2enmod rewrite \
    && a2enmod cgi \
    && a2enmod headers \
    && a2enmod expires

RUN /usr/bin/cpanm -i 'Net::WebSocket::Server'

COPY ./content/ /tmp/

RUN install -m 0644 -o root -g root /tmp/zm-site.conf /etc/apache2/sites-available/zm-site.conf \
    && install -m 0644 -o www-data -g www-data /tmp/zmcustom.conf /etc/zm/conf.d/zmcustom.conf \
    && install -m 0755 -o root -g root -d /etc/services.d /etc/services.d/zoneminder /etc/services.d/apache2 \
    && install -m 0755 -o root -g root /tmp/zoneminder-run /etc/services.d/zoneminder/run \
    && install -m 0755 -o root -g root /tmp/zoneminder-finish /etc/services.d/zoneminder/finish \
    && install -m 0755 -o root -g root /tmp/apache2-run /etc/services.d/apache2/run \
    && install -m 0644 -o root -g root /tmp/status.conf /etc/apache2/mods-available/status.conf \
    && a2dissite 000-default \
    && a2ensite zm-site \
    && bash -c 'install -m 0755 -o www-data -g www-data -d /var/lib/zmeventnotification /var/lib/zmeventnotification/{bin,contrib,images,mlapi,known_faces,unknown_faces,misc,push}' \
    && install -m 0755 -o www-data -g www-data /tmp/zmeventnotification/zmeventnotification.pl /usr/bin/zmeventnotification.pl \
    && install -m 0755 -o www-data -g www-data /tmp/zmeventnotification/pushapi_plugins/pushapi_pushover.py /var/lib/zmeventnotification/bin/pushapi_pushover.py \
    && install -m 0755 -o www-data -g www-data /tmp/zmeventnotification/hook/zm_event_start.sh /var/lib/zmeventnotification/bin/zm_event_start.sh \
    && install -m 0755 -o www-data -g www-data /tmp/zmeventnotification/hook/zm_event_end.sh /var/lib/zmeventnotification/bin/zm_event_end.sh \
    && install -m 0755 -o www-data -g www-data /tmp/zmeventnotification/hook/zm_detect.py /var/lib/zmeventnotification/bin/zm_detect.py \
    && install -m 0755 -o www-data -g www-data /tmp/zmeventnotification/hook/zm_train_faces.py /var/lib/zmeventnotification/bin/zm_train_faces.py \
    && pip install --break-system-packages newrelic \
    && cd /tmp/zmeventnotification/hook && pip -v install --break-system-packages . \
    && rm -Rf /tmp/*

VOLUME /var/cache/zoneminder
VOLUME /var/log/zm

# Copy default files for ZMES
COPY es_rules.json /etc/zm/
COPY secrets.ini /etc/zm/
COPY zmeventnotification.ini /etc/zm/
COPY objectconfig.ini /etc/zm/

# Copy entrypoint make it as executable and run it
COPY entrypoint.sh /opt/
RUN chmod +x /opt/entrypoint.sh

ENTRYPOINT [ "/bin/bash", "-c", "source ~/.bashrc && /opt/entrypoint.sh ${@}", "--" ]

EXPOSE 80
EXPOSE 9000
