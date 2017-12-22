#!/bin/sh
cron_db_backup.sh gha 2>> /tmp/gha2db_backup_kubernetes.err 1>> /tmp/gha2db_backup_kubernetes.log
cron_db_backup.sh prometheus 2>> /tmp/gha2db_backup_prometheus.err 1>> /tmp/gha2db_backup_prometheus.log
cron_db_backup.sh opentracing 2>> /tmp/gha2db_backup_opentracing.err 1>> /tmp/gha2db_backup_opentracing.log
cron_db_backup.sh fluentd 2>> /tmp/gha2db_backup_fluentd.err 1>> /tmp/gha2db_backup_fluentd.log
cron_db_backup.sh linkerd 2>> /tmp/gha2db_backup_linkerd.err 1>> /tmp/gha2db_backup_linkerd.log
cron_db_backup.sh grpc 2>> /tmp/gha2db_backup_grpc.err 1>> /tmp/gha2db_backup_grpc.log
cron_db_backup.sh cncf 2>> /tmp/gha2db_backup_cncf.err 1>> /tmp/gha2db_backup_cncf.log
cron_db_backup.sh devstats 2>> /tmp/gha2db_backup_devstats.err 1>> /tmp/gha2db_backup_devstats.log
