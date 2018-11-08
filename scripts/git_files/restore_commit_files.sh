#!/bin/bash
if [ -z "$PG_HOST" ]
then
  PG_HOST=127.0.0.1
fi

if [ -z "$PG_PORT" ]
then
  PG_PORT=5432
fi
sudo -u postgres psql -h "$PG_HOST" -p "$PG_PORT" gha < gha.sql
sudo -u postgres psql -h "$PG_HOST" -p "$PG_PORT" prometheus < prometheus.sql
sudo -u postgres psql -h "$PG_HOST" -p "$PG_PORT" opentracing < opentracing.sql
sudo -u postgres psql -h "$PG_HOST" -p "$PG_PORT" fluentd < fluentd.sql
sudo -u postgres psql -h "$PG_HOST" -p "$PG_PORT" linkerd < linkerd.sql
sudo -u postgres psql -h "$PG_HOST" -p "$PG_PORT" grpc < grpc.sql
sudo -u postgres psql -h "$PG_HOST" -p "$PG_PORT" coredns < coredns.sql
sudo -u postgres psql -h "$PG_HOST" -p "$PG_PORT" containerd < containerd.sql
