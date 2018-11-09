#!/bin/bash
./devel/db.sh psql gha < util_sql/tables_commits_files.sql
./devel/db.sh psql prometheus < util_sql/tables_commits_files.sql
./devel/db.sh psql opentracing < util_sql/tables_commits_files.sql
./devel/db.sh psql fluentd < util_sql/tables_commits_files.sql
./devel/db.sh psql linkerd < util_sql/tables_commits_files.sql
./devel/db.sh psql grpc < util_sql/tables_commits_files.sql
./devel/db.sh psql coredns < util_sql/tables_commits_files.sql
./devel/db.sh psql containerd < util_sql/tables_commits_files.sql
./devel/db.sh psql cncf < util_sql/tables_commits_files.sql
