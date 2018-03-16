#!/bin/bash
if ( [ -z "$1" ] || [ -z "$MODE" ] || [ ! -f ./FROM ] || [ ! -f ./TO ] )
then
  echo "$0 requires 'command' argument, MODE env variable, FROM and TO files."
  exit 1
fi
FROM=`cat ./FROM` TO=`cat ./TO` FILES=`$1` ./devel/mass_replace.sh
