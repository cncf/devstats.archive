#!/bin/bash
wd=`pwd`
cd ~/dev/cncf/artwork || exit 1
git pull || exit 2
cd ~/dev/cdfoundation/artwork || exit 3
git pull || exit 4
cd $wd || exit 5
echo 'OK'
