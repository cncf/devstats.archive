#!/bin/bash
# CERT=1 (setup SSL cert via certbot)
# WW=1 (update www index files)
set -o pipefail
if [ ! -z "$WWW" ]
then
  host=`hostname`
  if [ "$host" = "devstats.cncf.io" ]
  then
    cp apache/www/index_prod.html /var/www/html/index.html || exit 1
    cp apache/prod/sites-enabled/000-default-le-ssl.conf /etc/apache2/sites-enabled/ || exit 2
    cp apache/prod/sites-enabled/000-default.conf /etc/apache2/sites-enabled/ || exit 3
  else
    cp apache/www/index_test.html /var/www/html/index.html || exit 4
    cp apache/test/sites-enabled/000-default-le-ssl.conf /etc/apache2/sites-enabled/ || exit 5
    cp apache/test/sites-enabled/000-default.conf /etc/apache2/sites-enabled/ || exit 6
  fi
  cp apache/www/favicon.ico /var/www/html/favicon.ico || exit 13
fi

if [ ! -z "$CERT" ]
then
  echo 'obtaining SSL certs'
  if [ "$host" = "devstats.cncf.io" ]
  then
    cp apache/prod/sites-enabled/000-default-le-ssl.conf /etc/apache2/sites-enabled/ || exit 7
    cp apache/prod/sites-enabled/000-default.conf /etc/apache2/sites-enabled/ || exit 8
    sudo certbot -d `cat apache/prod/sites.txt` -n --expand --authenticator standalone --installer apache --pre-hook 'service apache2 stop' --post-hook 'service apache2 start' || exit 9
  else
    cp apache/test/sites-enabled/000-default-le-ssl.conf /etc/apache2/sites-enabled/ || exit 10
    cp apache/test/sites-enabled/000-default.conf /etc/apache2/sites-enabled/ || exit 11
    sudo certbot -d `cat apache/test/sites.txt` -n --expand --authenticator standalone --installer apache --pre-hook 'service apache2 stop' --post-hook 'service apache2 start' || exit 12
  fi
fi
