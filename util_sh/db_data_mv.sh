#!/bin/bash
cp -Rv $1 /storage/psql/$1
rm -rf $1
ln -s /storage/psql/$1 $1
chown -R postgres /storage/psql/$1
chgrp -R postgres /storage/psql/$1
chmod -R go+rx /storage/psql/$1
