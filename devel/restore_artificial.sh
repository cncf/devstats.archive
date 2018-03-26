#!/bin/bash
cp gha_events.csv /tmp/ || exit 1
cp gha_payloads.csv /tmp/ || exit 2
cp gha_issues.csv /tmp/ || exit 3
cp gha_issues_labels.csv /tmp/ || exit 4
sudo -u postgres psql gha -c "copy gha_events from '/tmp/gha_events.csv';" || exit 5
sudo -u postgres psql gha -c "copy gha_payloads from '/tmp/gha_payloads.csv';" || exit 6
sudo -u postgres psql gha -c "copy gha_issues from '/tmp/gha_issues.csv';" || exit 7
sudo -u postgres psql gha -c "copy gha_issues_labels from '/tmp/gha_issues_labels.csv';" || exit 8
