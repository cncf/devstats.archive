#!/bin/bash
MODE=rr0 FROM='./ghapi2db($|[^\.]+)' TO='ghapi2db' ./find_and_replace.sh . '*' '\.\/ghapi2db'
FROM='./ghapi2db' TO='ghapi2db' ./find_and_replace.sh . '*' '\.\/ghapi2db($|[^\.]+)'
