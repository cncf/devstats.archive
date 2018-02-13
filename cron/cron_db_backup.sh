#!/bin/sh
echo "Backup start:" && date
sudo -u postgres pg_dump -Fc $1 -f /tmp/$1.dump || exit 1
mv /tmp/$1.dump /var/www/html/
date && echo "Backup OK"

