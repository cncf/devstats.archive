#!/bin/sh
sudo -u postgres psql gha < util_sql/tables_commits_files.sql
sudo -u postgres psql prometheus < util_sql/tables_commits_files.sql
sudo -u postgres psql opentracing < util_sql/tables_commits_files.sql
sudo -u postgres psql fluentd < util_sql/tables_commits_files.sql
sudo -u postgres psql linkerd < util_sql/tables_commits_files.sql
sudo -u postgres psql grpc < util_sql/tables_commits_files.sql
sudo -u postgres psql coredns < util_sql/tables_commits_files.sql
sudo -u postgres psql containerd < util_sql/tables_commits_files.sql
