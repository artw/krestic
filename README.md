# krestic
Simple shell wrappers for [restic](https://github.com/restic/restic) and a set of examples for backing up persistent data from kubernetes to s3

The thing does not do much apart from passing arguments to restic. Please refer to [Restic Documentation](https://restic.readthedocs.io/en/stable/index.html) for actual docs

## containers / scripts
| image                    | script          | purpose                                                              |
|--------------------------|-----------------|----------------------------------------------------------------------|
| artw/krestic-base        |                 | just restic and curl, useful for restore and maintenance             |
| artw/krestic-dir         | backup-dir.sh   | runs restic backup for every dir                                     |
| artw/krestic-mysql       | backup-mysql.sh | runs mysqldump and streams it to restic backup --stdin               |
| artw/krestic-cron        | backup-cron.sh  | run backup-dir.sh in alpines busybox crond (e.g. sidecar for Volume) |
| artw/krestic-dir-restore | restore-dir.sh  | restores latest snapshot matching tags (e.g. initContainer)          |


## config
**krestic** is configured using env variables, some of which are actually processed implicitly, of which only the required are listed

| var                 | purpose                                                                  | only  | required |
|---------------------|--------------------------------------------------------------------------|-------|----------|
| RESTIC_PASSWORD     | restic repo encryption passphrase (restic standard)                      | *     | x        |
| RESTIC_REPOSITORY   | restic repo path (restic standard)                                       | *     | x        |
| RESTIC_HOST         | restic hostname for pruning (passed to --host)                           | *     | x        |
| RESTIC_TAGS         | restic tags, (csv, passed as --tag)                                      | *     | x        |
| HOOK_PRE            | command to run before the run (e.g. webhooks)                            | *     |          |
| HOOK_OK             | command to run on success                                                | *     |          |
| HOOK_FAIL           | command to run on failure                                                | *     |          |
| HOOK_POST           | command to run after the run                                             | *     |          |
| RESTIC_FORGET_FLAGS | flags to pass to restic forget e.g. (enables cleanup) e.g. `-l3 --prune` | *     |          |
| RESTIC_BACKUP_FLAGS | extra flags to add for restic backup                                     | *     |          |
| RESTIC_DIRS         | restic backup dir (space separated, loops each, adds "dir:/dir" tag)     | dir   | x        |
| RESTIC_EXCLUDES     | restic (space separated, each passed with --exclude)                     | dir   |          |
| MYSQL_HOST          | mysql endpoint hostname (used implicitly by mysqldump)                   | mysql | x        |
| MYSQL_TCP_PORT      | mysql password (used implicitly by mysqldump)                            | mysql | x        |
| MYSQL_USER          | mysql username (passed with -p)                                          | mysql | x        |
| MYSQL_PWD           | mysql password (used implicitly by mysqldump)                            | mysql | x        |
| MYSQL_DBS           | list of databases to backup (space separated,loops each)                 | mysql |          |
| MYSQLDUMP_FLAGS     | any extra flags (i.e. skip tables)                                       | mysql |          |
| _MYSQLDUMP_FLAGS    | can be used to override defaults (--single-transaction)                  | mysql |          |


## examples
### kubernetes
| example               | scenario                                                                                  |
|-----------------------|-------------------------------------------------------------------------------------------|
| cron-sidecar.yml      | run a sidecar that backs up a kubernetes volume every minute                              |
| cron-sidecar-init.yml | same as above, but restore the latest snapshot on startup (poor man's persistent storage) |   
| mysql-cronjob.yml     | backup a db with mysqldump with a kubernetes cronjob                                      |

### adhoc
run a base container with env preset for running restic manually e.g, restoring or doing maintenance on the repo
```
cat << EOF > my-repo.env
AWS_ACCESS_KEY_ID="minio"
AWS_SECRET_ACCESS_KEY="MyVerySecureAccessKey"
RESTIC_REPOSITORY="s3:http://s3.minio.wtf:9000"
RESTIC_PASSWORD="MyVeryLongAndVerySecureResticPassword"
EOF

docker run -ti --rm  --env-file=my-repo.env -v /data:/data artw/krestic-base
restic snapshots
```

run a pod with mysql image and set env from secrets to restore the database
```
kubectl run --rm -ti restic --image=artw/restic-mysql --overrides='{"apiVersion":"v1","spec":{"containers":[{"name":"restic","envFrom":[{"secretRef":{"name":"restic-secrets"}},{"secretRef":{"name":"mysql-secrets"}},{"configMapRef":{"name":"restic-config"}}]}]}}' --override-type='strategic' -- sh

restic dump --tags mysupercluster,db:mydb latest /mydb.sql | mysql mydb
```

## building
`make` builds images for *linux/amd64* and *linux/aarch64* and pushes them to hub.docker.com registry. Requires *Docker* with *buildx* plugin
