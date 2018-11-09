#!/bin/bash
sudo -u postgres /usr/lib/postgresql/10/bin/pg_ctl start -D /var/lib/postgresql/10/main -l /var/log/postgresql/postgresql-10-main.log -s -o '-c config_file="/etc/postgresql/10/main/postgresql.conf"'
