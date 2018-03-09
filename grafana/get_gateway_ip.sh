#!/bin/bash
ip route | awk '/default/ { print $3 }'
