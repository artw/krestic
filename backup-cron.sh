#!/bin/sh
set -e
test -z "${CRON_TIME}" && echo "CRON_TIME is missing" && exit 1

echo "=> testing restic config"
RESTIC_EXTRA_FLAGS="--dry-run" /backup.sh
echo "${CRON_TIME} /backup.sh 2>&1" | crontab -
echo "=> running crond"
crond -f -L /dev/stdout
