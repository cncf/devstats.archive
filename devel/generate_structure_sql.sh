#!/bin/bash
sudo -u postgres pg_dump -s gha > structure.sql
