#!/bin/bash
git checkout master && git pull && git checkout production && git pull && git merge master && git push && make install && git checkout master && git diff production
