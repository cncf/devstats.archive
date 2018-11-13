#!/bin/bash
./devel/db.sh psql gha < gha.sql
./devel/db.sh psql prometheus < prometheus.sql
./devel/db.sh psql opentracing < opentracing.sql
./devel/db.sh psql fluentd < fluentd.sql
./devel/db.sh psql linkerd < linkerd.sql
./devel/db.sh psql grpc < grpc.sql
./devel/db.sh psql coredns < coredns.sql
./devel/db.sh psql containerd < containerd.sql
