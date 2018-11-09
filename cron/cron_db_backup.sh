#!/bin/bash
echo "Backup start:" && date
db.sh pg_dump -Fc $1 -f /tmp/$1.dump || exit 1
mv /tmp/$1.dump /var/www/html/ || exit 2
backup_artificial.sh "$1" || exit 3
date && echo "Backup OK"

