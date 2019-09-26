#!/bin/bash
# ONLY_ARTIFICIAL=1 - only backup artificial events
# SKIP_ARTIFICIAL=1 - skip backup artificial events
if [ ! -z "${NOBACKUP}" ]
then
  exit 0
fi
echo "Backup start:" && date
if [ -z "$ONLY_ARTIFICIAL" ]
then
  db.sh pg_dump -Fc $1 -f /tmp/$1.dump || exit 1
  mv /tmp/$1.dump /var/www/html/ || exit 2
fi
if [ -z "$SKIP_ARTIFICIAL" ]
then
  backup_artificial.sh "$1" || exit 3
fi
date && echo "Backup OK"

