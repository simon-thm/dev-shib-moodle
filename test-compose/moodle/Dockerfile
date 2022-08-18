FROM moodlehq/moodle-php-apache:7.4
WORKDIR /var/www/html
VOLUME /etc/shibboleth/
RUN mkdir ../certs
RUN apt-get update && apt-get install -y wget libapache2-mod-shib
RUN service shibd start
RUN wget https://download.moodle.org/download.php/direct/stable311/moodle-latest-311.tgz
RUN tar -xvf moodle-latest-311.tgz
RUN mv moodle/* .
RUN rm -rf moodle-latest-311.tgz moodle
COPY --chown=www-data:www-data ./config.php /var/www/html/config.php
