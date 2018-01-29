#!/bin/sh
cron_db_backup.sh gha 2>> /tmp/gha2db_backup_kubernetes.err 1>> /tmp/gha2db_backup_kubernetes.log
cron_db_backup.sh prometheus 2>> /tmp/gha2db_backup_prometheus.err 1>> /tmp/gha2db_backup_prometheus.log
cron_db_backup.sh opentracing 2>> /tmp/gha2db_backup_opentracing.err 1>> /tmp/gha2db_backup_opentracing.log
cron_db_backup.sh fluentd 2>> /tmp/gha2db_backup_fluentd.err 1>> /tmp/gha2db_backup_fluentd.log
cron_db_backup.sh linkerd 2>> /tmp/gha2db_backup_linkerd.err 1>> /tmp/gha2db_backup_linkerd.log
cron_db_backup.sh grpc 2>> /tmp/gha2db_backup_grpc.err 1>> /tmp/gha2db_backup_grpc.log
cron_db_backup.sh coredns 2>> /tmp/gha2db_backup_coredns.err 1>> /tmp/gha2db_backup_coredns.log
cron_db_backup.sh containerd 2>> /tmp/gha2db_backup_containerd.err 1>> /tmp/gha2db_backup_containerd.log
cron_db_backup.sh rkt 2>> /tmp/gha2db_backup_rkt.err 1>> /tmp/gha2db_backup_rkt.log
cron_db_backup.sh cni 2>> /tmp/gha2db_backup_cni.err 1>> /tmp/gha2db_backup_cni.log
cron_db_backup.sh envoy 2>> /tmp/gha2db_backup_envoy.err 1>> /tmp/gha2db_backup_envoy.log
cron_db_backup.sh jaeger 2>> /tmp/gha2db_backup_jaeger.err 1>> /tmp/gha2db_backup_jaeger.log
cron_db_backup.sh notary 2>> /tmp/gha2db_backup_notary.err 1>> /tmp/gha2db_backup_notary.log
cron_db_backup.sh tuf 2>> /tmp/gha2db_backup_tuf.err 1>> /tmp/gha2db_backup_tuf.log
cron_db_backup.sh rook 2>> /tmp/gha2db_backup_rook.err 1>> /tmp/gha2db_backup_rook.log
# cron_db_backup.sh all 2>> /tmp/gha2db_backup_all.err 1>> /tmp/gha2db_backup_all.log
# cron_db_backup.sh cncf 2>> /tmp/gha2db_backup_cncf.err 1>> /tmp/gha2db_backup_cncf.log
cron_db_backup.sh devstats 2>> /tmp/gha2db_backup_devstats.err 1>> /tmp/gha2db_backup_devstats.log
