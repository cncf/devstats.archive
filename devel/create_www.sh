#!/bin/bash
# CERT=1 (setup SSL cert via certbot)
# WW=1 (update www index files)
set -o pipefail
if [ ! -z "$WWW" ]
then
  host=`hostname`
  if [ "$host" = "devstats.cncf.io" ]
  then
    cp apache/www/index_prod.html /var/www/html/index.html || exit 32
    cp apache/prod/sites-enabled/000-default-le-ssl.conf /etc/apache2/sites-enabled/ || exit 34
    cp apache/prod/sites-enabled/000-default.conf /etc/apache2/sites-enabled/ || exit 35
  else
    cp apache/www/index_test.html /var/www/html/index.html || exit 36
    cp apache/test/sites-enabled/000-default-le-ssl.conf /etc/apache2/sites-enabled/ || exit 37
    cp apache/test/sites-enabled/000-default.conf /etc/apache2/sites-enabled/ || exit 38
  fi
fi

if [ ! -z "$CERT" ]
then
  echo 'obtaining SSL certs'
  if [ "$host" = "devstats.cncf.io" ]
  then
    sudo certbot -d `cat apache/prod/sites.txt` -n --expand --authenticator standalone --installer apache --pre-hook 'service apache2 stop' --post-hook 'service apache2 start' || exit 39
  else
    sudo certbot -d `cat apache/test/sites.txt` -n --expand --authenticator standalone --installer apache --pre-hook 'service apache2 stop' --post-hook 'service apache2 start' || exit 40
  fi
fi
