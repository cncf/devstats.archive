#!/bin/bash
if [ ! -z "${VAGRANT}" ]
then
  echo "Vagrant deployment start"
  ./vagrant/vagrant_test_all.sh
  r=$?
  echo "Vagrant deployment end"
elif [ ! -z "${DOCKER}" ]
then
  # See docker/README.md
  echo "Docker deployment start"
  ./docker/docker_test_all.sh
  r=$?
  echo "Docker deployment end"
else
  echo "Unknown deployment mode"
  r=1
fi
exit $r
