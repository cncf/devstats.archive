#!/bin/sh
sudo -u postgres psql gha < util_sql/table_gha_commits_files.sql
sudo -u postgres psql prometheus < util_sql/table_gha_commits_files.sql
sudo -u postgres psql opentracing < util_sql/table_gha_commits_files.sql
sudo -u postgres psql fluentd < util_sql/table_gha_commits_files.sql
sudo -u postgres psql linkerd < util_sql/table_gha_commits_files.sql
sudo -u postgres psql grpc < util_sql/table_gha_commits_files.sql
sudo -u postgres psql coredns < util_sql/table_gha_commits_files.sql
sudo -u postgres psql containerd < util_sql/table_gha_commits_files.sql
