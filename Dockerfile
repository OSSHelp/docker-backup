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

FROM alpine:3.13
# hadolint ignore=DL3018,DL3013
RUN apk add --no-cache bash python3 py3-setuptools py3-yaml tzdata tar bzip2 \
	coreutils ssmtp mailx rclone redis mysql-client postgresql mongodb-tools \
	&& apk add --no-cache --virtual .build-deps py-pip \
	&& pip install --no-cache-dir j2cli pymongo \
	&& mkdir -p /root/.config/rclone /usr/local/include /var/backups \
	&& apk del --no-cache .build-deps

COPY templates/* /usr/local/src/
COPY helpers/* /usr/local/bin/
COPY entrypoint.sh /usr/local/bin/
COPY --from=pbzip2 /usr/bin/pbzip2 /usr/bin/
ADD https://oss.help/scripts/backup/backup-functions/backup-functions.sh /usr/local/include/

ENV TIMEZONE="Europe/Moscow" \
	CRON_TIME="{min: 15, hour: 3}" \
	REMOTE_SCHEME="{daily: 7, weekly: 4, monthly: 3}" \
	LOCAL_DAYS="0" \
	COMPRES_DIRS="[]" \
	COMPRES_DIRS_EXCLUDE="[]" \
	SYNC_DIRS="[]" \
	POSTGRES_IGNORE_DBS="[template]" \
	MYSQL_IGNORE_DBS="[information_schema, performance_schema, pinba, phpmyadmin, sys]" \
	MONGO_IGNORE_DBS="[]"

ENTRYPOINT ["entrypoint.sh"]
