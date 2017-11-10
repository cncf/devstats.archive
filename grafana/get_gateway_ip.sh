#!/bin/sh
ip route | awk '/default/ { print $3 }'
