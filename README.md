# backup

[![Build Status](https://drone.osshelp.ru/api/badges/docker/backup/status.svg)](https://drone.osshelp.ru/docker/backup)

## Description

Based on [official alpine image](https://hub.docker.com/_/alpine) with backup utils.

## Deploy examples

### Typical

``` yaml
  backup:
    image: osshelp/backup:stable
    restart: always
    environment:
      CRON_TIME: "{min: 17, hour: 2}"
      MAILTO: $PD_EMAIL
      SERVER_NAME: project-server
      POSTGRES_PASSWORD: $POSTGRES_PASSWORD
      COMPRES_DIRS: "[/mnt/dir1, /mnt/dir2]"
      SYNC_DIRS: "[/mnt/bigdir]"
      RCLONE_STORAGE: "{name: b2_storage_name, type: b2, account: $B2_ACCOUNT, key: $B2_KEY}"
    volumes:
      - /mnt/docker/backup:/backup
      - /mnt/docker/someservice1/dir:/mnt/dir1
      - /mnt/docker/someservice2/dir:/mnt/dir2
      - /mnt/docker/someservice3/bigdir:/mnt/bigdir
    networks:
      - net
```

### With custom script

``` yaml
  backup:
    image: osshelp/backup:stable
    restart: always
    environment:
      CRON_TIME: "{min: 17, hour: 2}"
      CUSTOM_BACKUP_COMMANDS: |
        ls -1 /mnt/gitlab-backups | tail -1 | grep -q "$$(date +%Y_%m_%d)" || show_error "Backup archive doesn't exist"
        mkdir -p "$$backup_dir/$$current_date"
        mv "/mnt/gitlab-backups/$$(ls -1 /mnt/gitlab-backups | tail -1)" "$$backup_dir/$$current_date/"
      MAILTO: $PD_EMAIL
      SERVER_NAME: project-server
      RCLONE_STORAGE: "{name: b2_storage_name, type: b2, account: $B2_ACCOUNT, key: $B2_KEY}"
    volumes:
      - /mnt/docker/backup:/backup
      - /mnt/docker/gitlab/var/opt/gitlab/backups:/mnt/gitlab-backups
    networks:
      - net
```

Internal vars in CUSTOM_BACKUP_COMMANDS must be escaped like `$$`.

## Parameters

Setting|Default|Description
---|---|---
`ARCHIVER_OPTS`|`-`|Additional optioins for archiver
`COMPRES_DIRS`|`[]`|List of directories for backup
`COMPRES_DIRS_EXCLUDE`|`[]`|List of direcotries for exlude
`CRON_TIME`|`{min: 15, hour: 3}`|Backup task cron time
`CRON_LOGLEVEL`|`8`|Cron Log Level. Most verbose 0
`CUSTOM_BACKUP_COMMANDS`|-|Custom command(s) for backup function
`FILES_FOR_COUNT`|`[]`|List of files for manual counting
`GITLAB_DIR`|-| Path for Gitlab backup dir (mounted from gitlab container)
`LOCAL_DAYS`|`0`|Number of local copies +1
`MONGO_HOST`|-|MongoDB host
`MONGO_AUTH_DB`|`admin`|MongoDB authentication database
`MONGO_USER`|`admin`|MongoDB user
`MONGO_PASSWORD`|-|MongoDB password
`MONGO_IGNORE_DBS`|`[]`|List of ignored databases
`MAILTO`|-|Notify email address
`MYSQL_HOST`|-|MySQL host
`MYSQL_PORT`|`3306`|MySQL port
`MYSQL_USER`|`root`|MySQL user
`MYSQL_PASSWORD`|-|MySQL password (not added to my.cnf if it's not defineded)
`MYSQL_OPTS`|-|Additional optioins for mysqldump
`MYSQL_IGNORE_DBS`|`[information_schema, performance_schema, pinba, phpmyadmin, sys]`|List of ignored databases
`NO_PUSHGATEWAY` |`0`|Disable send metrics to Pushgateway if `1`
`POSTGRES_HOST`|`postgres`|PostgreSQL host
`POSTGRES_PORT`|`5432`|PostgreSQL port
`POSTGRES_CONNECTION_DB`|`postgres`|PostgreSQL connection db
`POSTGRES_USER`|`postgres`|PostgreSQL user
`POSTGRES_PASSWORD`|-|PostgreSQL password
`POSTGRES_IGNORE_DBS`|`[template]`|List of ignored databases
`POSTGRES_SKIP_GLOBALS`|-|Skip dump globals objects if `1`. Useful for managed PostgreSQL servers
`PUSHGATEWAY_URL`|`http://pushgateway:9091`|Pushgateway URL
`PUSHGATEWAY_OPTS`|`-`|Additional curl parameters, which is used by functions to transfer data to Pushgateway
`RCLONE_STORAGE`|-|Rclone remote storage
`RCLONE_ALT_STORAGE`|-|Rclone alternative remote storage (additional)
`REMOTE_SCHEME`|`{daily: 7, weekly: 4, monthly: 3}`|Number of remote copies by type
`REDIS_HOST`|-|Redis host
`REDIS_PASSWORD`|-|Redis password
`SSMTP_MAILHUB`|container default gateway|Mail relay host
`SSMTP_HOSTNAME`|`hostname -f`|SSMTP hostname
`SSMTP_REWRITE_DOMAIN`|-|SSMTP  rewrite domain
`SSMTP_FROM_LINE_OVERRIDE`|-|SSMTP From line override
`STORAGE_UPLOAD_DIR/ALT_STORAGE_UPLOAD_DIR`|-|Target directory to upload to the storage/alternative storage
`STORAGE_SYNC_MODE`|`default`|Rclone sync function mode, set no_check if you need disable checking files in storage
`SYNC_DIRS`|`[]`|List of directories for sync
`SERVER_NAME`|-|Server for notifies
`TIMEZONE`|`Europe/Moscow`|Timezone

### Cron time format

Setting|Default|Description
---|---|---
`min`|`15`|Minute
`hour`|`3`|Hour
`day`|`*`|Day of mounth
`mounth`|`*`|Mounth
`day_of_week`|`*`|Day of week

Example:

```yaml
    environment:
      CRON_TIME: "{min: 34, hour: 1, day: '*/2'}"
```

### Rclone storage format

The format is the same as in [the Ansible role](https://gitea.osshelp.ru/ansible/rclone):

Setting|Default|Description
---|---|---
`name`|-|Storage name
`bucket`|-|Storage bucket name, if not set then equals name
`key`|-|Key:value for rclone storage

Example:

```yaml
    environment:
      RCLONE_STORAGE: "{name: b2_storage_name, type: b2, account: $B2_ACCOUNT, key: $B2_KEY}"
      RCLONE_ALT_STORAGE: "{name: osshelp_storage, bucket: client-backup, type: s3, endpoint: scanros.ossdata.ru, region: local, provider: Minio, access_key_id: $OSS_ACCOUNT, secret_access_key: $OSS_KEY}"
```

### Internal usage

For internal purposes and OSSHelp customers we have an alternative image url:

``` yaml
  image: oss.help/pub/backup:stable
```

There is no difference between the DockerHub image and the oss.help/pub image.

## Links

- [Rclone](https://rclone.org/)

## TODO

- Tests
- Add RethinkDB support (Python)
- Add log file /backup/backup.log (last backup only)
- Add stderr_exclude support if needed
- Add healthcheck by ERROR messages in logs
- Add readable errors on files generation functions
