FROM alpine:3.13 as pbzip2

WORKDIR /tmp
# hadolint ignore=DL3018,DL3003
RUN apk add --no-cache --virtual .build-deps bzip2-dev g++ make \
        && wget -q https://launchpad.net/pbzip2/1.1/1.1.13/+download/pbzip2-1.1.13.tar.gz \
        && tar -xzf pbzip2-1.1.13.tar.gz \
        && cd pbzip2-1.1.13 \
        && make install \
        && apk del --no-cache .build-deps \
        && rm -r /tmp/pbzip2-1.1.13

FROM alpine:3.17
# hadolint ignore=DL3018,DL3013
RUN apk add --no-cache bash python3 py3-setuptools py3-yaml tzdata tar bzip2 grep \
        coreutils curl ssmtp mailx rclone redis mysql-client postgresql openssh \
        mariadb-connector-c \
        && apk add --no-cache --virtual .build-deps py-pip \
        && pip install --no-cache-dir j2cli \
        && mkdir -p /root/.config/rclone /usr/local/include /var/backups \
        && echo 'http://dl-cdn.alpinelinux.org/alpine/v3.9/main' >> /etc/apk/repositories \
        && echo 'http://dl-cdn.alpinelinux.org/alpine/v3.9/community' >> /etc/apk/repositories \
        && apk add --no-cache mongodb mongodb-tools yaml-cpp=0.6.2-r2 \
        && apk del --no-cache .build-deps

COPY templates/* /usr/local/src/
COPY entrypoint.sh /usr/local/bin/
COPY --from=pbzip2 /usr/bin/pbzip2 /usr/bin/
ADD https://oss.help/scripts/backup/backup-functions/2-latest/backup-functions.sh /usr/local/include/osshelp/
ADD https://oss.help/scripts/pushgateway/pushgateway-functions/1-latest/pushgateway-functions.sh /usr/local/include/osshelp/

ENV TIMEZONE="Europe/Moscow" \
        CRON_TIME="{min: 15, hour: 3}" \
        REMOTE_SCHEME="{daily: 7, weekly: 4, monthly: 3}" \
        LOCAL_DAYS="0" \
        COMPRES_DIRS="[]" \
        COMPRES_DIRS_EXCLUDE="[]" \
        SYNC_DIRS="[]" \
        POSTGRES_IGNORE_DBS="[template]" \
        MYSQL_IGNORE_DBS="[information_schema, performance_schema, pinba, phpmyadmin, sys]" \
        MONGO_IGNORE_DBS="[]" \
        NO_PUSHGATEWAY="0" \
        STORAGE_UPLOAD_DIR='""' \
        ALT_STORAGE_UPLOAD_DIR='""'

ENTRYPOINT ["entrypoint.sh"]
