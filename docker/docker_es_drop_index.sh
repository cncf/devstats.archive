#!/bin/bash
if [ -z "${ES_URL}" ]
then
  ES_URL="http://localhost:19200"
fi
curl -XDELETE "${ES_URL}/${1}"
