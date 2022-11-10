#!/bin/sh
set -e
set -o pipefail

test -z "${MYSQL_HOST}"        && echo "MYSQL_HOST is missing"        && exit 1
test -z "${MYSQL_USER}"        && echo "MYSQL_USER is missing"        && exit 1
test -z "${MYSQL_PASSWORD}"    && echo "MYSQL_PASSWORD is missing"    && exit 1
test -z "${MYSQL_DBS}"         && echo "MYSQL_DBS is missing"         && exit 1
test -z "${MYSQL_PORT}"        && MYSQL_PORT=3306
test -z "${_MYSQLDUMP_FLAGS}"  && _MYSQLDUMP_FLAGS="--single-transaction"

test -z "${RESTIC_PASSWORD}"   && echo "RESTIC_PASSWORD is missing"   && exit 1
test -z "${RESTIC_REPOSITORY}" && echo "RESTIC_REPOSITORY is missing" && exit 1
test -z "${RESTIC_TAGS}"       && echo "RESTIC_TAGS is missing"       && exit 1

test -z "${HOOK_PRE}"          && HOOK_PRE="echo backup started"
test -z "${HOOK_OK}"           && HOOK_OK="echo backup succeeded"
test -z "${HOOK_FAIL}"         && HOOK_FAIL="echo backup failed"
test -z "${HOOK_POST}"         && HOOK_POST="echo backup ended"

eval ${HOOK_PRE} || true

BACKUP_FAILED=0
for DB in ${MYSQL_DBS}; do
  mysqldump -u${MYSQL_USER} -p${MYSQL_PASSWORD} -h${MYSQL_HOST} -P ${MYSQL_PORT} ${_MYSQLDUMP_FLAGS} ${MYSQLDUMP_FLAGS} $DB | \
    restic backup -v --stdin --tag ${RESTIC_TAGS},db:${DB} --stdin-filename ${DB}.sql ${RESTIC_EXTRA_FLAGS} \
    || BACKUP_FAILED=1
done

if [[ $BACKUP_FAILED == 1 ]]; then
  eval ${HOOK_FAIL}
else
  eval ${HOOK_OK}
fi

eval ${HOOK_POST} || true
