#!/bin/sh
set -e
set -o pipefail

test -z "${RESTIC_DIRS}"       && echo "RESTIC_DIRS is missing"       && exit 1
test -z "${RESTIC_PASSWORD}"   && echo "RESTIC_PASSWORD is missing"   && exit 1
test -z "${RESTIC_REPOSITORY}" && echo "RESTIC_REPOSITORY is missing" && exit 1
test -z "${RESTIC_TAGS}"       && echo "RESTIC_TAGS is missing"       && exit 1

test -z "${HOOK_PRE}"          && HOOK_PRE="echo restore started"
test -z "${HOOK_OK}"           && HOOK_OK="echo restore succeeded"
test -z "${HOOK_FAIL}"         && HOOK_FAIL="echo restore failed"
test -z "${HOOK_POST}"         && HOOK_POST="echo restore ended"

eval ${HOOK_PRE}

for exclude in $RESTIC_EXCLUDES; do
  EXCLUDE_ARGS="${EXCLUDE_ARGS} -e ${exclude}"
done

ERROR=0
for DIR in ${RESTIC_DIRS}; do
  restic restore --tag ${RESTIC_TAGS},dir:${DIR} ${EXCLUDE_ARGS} ${RESTIC_EXTRA_FLAGS} -t $DIR latest \
  || ERROR=1
done

if [[ $ERROR == 1 ]]; then
  eval ${HOOK_FAIL}
else
  eval ${HOOK_OK}
fi

eval ${HOOK_POST}

exit $ERROR
