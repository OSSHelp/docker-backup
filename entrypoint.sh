#!/bin/bash

hostname=$(hostname)
host_ip=$(ip r | awk '/^def/{print $3}')

prepare_yaml_vars_file() {
  test -z "$SSMTP_MAILHUB" && export SSMTP_MAILHUB="$host_ip"
  test -z "$SSMTP_HOSTNAME" && export SSMTP_HOSTNAME="$hostname"

  echo "" > /etc/env.yml
  for var in $(env | grep '=' | awk -F'=' '{print $1}' | grep -vE '^(CUSTOM_BACKUP_COMMANDS|PATH|_)$'); do
    echo "$var: ${!var}" >> /etc/env.yml
  done

  test -n "${CUSTOM_BACKUP_COMMANDS+x}" && { 
    echo "CUSTOM_BACKUP_COMMANDS: |" >> /etc/env.yml
    # shellcheck disable=SC2001
    echo "$CUSTOM_BACKUP_COMMANDS" | sed 's/^/  /g' | grep -vE '^\s+$' >> /etc/env.yml
  }

  return 0
}

set_timezone() {
  cp "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime \
  && echo "$TIMEZONE" > /etc/timezone
}

generate_backup_script() {
  j2 -f yaml /usr/local/src/backup.sh.j2 /etc/env.yml > /usr/local/bin/backup.sh \
  && chmod 700 /usr/local/bin/backup.sh
}

generate_crond_file() {
  j2 -f yaml /usr/local/src/cron.j2 /etc/env.yml > /etc/crontabs/root
}

generate_storage_config() {
  test -z "$RCLONE_STORAGE" && return 0
  j2 -f yaml /usr/local/src/rclone.j2 /etc/env.yml > /root/.config/rclone/rclone.conf
}

generate_mycnf() {
  j2 -f yaml /usr/local/src/my.cnf.j2 /etc/env.yml > /root/.my.cnf
}

generate_ssmtp_conf() {
  j2 -f yaml /usr/local/src/ssmtp.j2 /etc/env.yml > /etc/ssmtp/ssmtp.conf
}

set_timezone \
&& prepare_yaml_vars_file \
&& generate_backup_script \
&& generate_crond_file \
&& generate_storage_config \
&& generate_mycnf \
&& generate_ssmtp_conf \
|| exit 1

if [ -z "$1" ]; then
  exec crond -f -d "${CRON_LOGLEVEL:-8}" -c /etc/crontabs
fi

exec "$@"
