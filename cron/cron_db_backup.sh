#!/bin/sh
echo "Backup start:" && date
cd /tmp || exit 1
sudo -u postgres pg_dump $1 > /tmp/$1.sql || exit 2
xz -7 /tmp/$1.sql || exit 3
mv /tmp/$1.sql.xz /var/www/html/$1.sql.xz || exit 4
date && echo "Backup OK"

