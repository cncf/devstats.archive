#!/bin/bash
if ( [ -z "$1" ] || [ -z "$2" ] )
then
  echo "$0: required hostname and port parameters"
  exit 1
fi
openssl s_client -crlf -debug -connect "$1:$2" -status -servername "$1"
