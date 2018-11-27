#!/bin/bash
if [ -z "$ONLY" ]
then
  host=`hostname`
  if [ -z "${TEST_SERVER_NAME}" ]
  then
    TEST_SERVER_NAME="teststats.cncf.io"
  fi
  if [ -z "${PROD_SERVER_NAME}" ]
  then
    PROD_SERVER_NAME="devstats.cncf.io"
  fi
  if [ "${TEST_SERVER_NAME}" = "${PROD_SERVER_NAME}" ]
  then
    echo "$0: test server cannot be the same as prod server: ${TEST_SERVER_NAME}"
    exit 1
  fi
  if [ -z "${LIST_FN_PREFIX}" ]
  then
    LIST_FN_PREFIX="./devel/all_"
  fi
  if [ $host = "${TEST_SERVER_NAME}" ]
  then
    all=`cat "${LIST_FN_PREFIX}test_dbs.txt"`
    if [ -z "$all" ]
    then
      echo "$0: no data retrieved"
      exit 2
    fi
  fi
  if [ $host = "${PROD_SERVER_NAME}" ]
  then
    all=`cat "${LIST_FN_PREFIX}prod_dbs.txt"`
    if [ -z "$all" ]
    then
      echo "$0: no data retrieved"
      exit 3
    fi
  fi
  if [ -z "${all}" ]
  then
    echo "$0: hostname ${host} is neither ${TEST_SERVER_NAME} nor ${PROD_SERVER_NAME}"
    exit 4
  fi
else
  all=$ONLY
fi
