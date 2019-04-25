#!/bin/bash
wd=`pwd`
cd ~/dev/cncf/artwork || exit 1
git pull || exit 2
cd $wd || exit 3
echo 'OK'
