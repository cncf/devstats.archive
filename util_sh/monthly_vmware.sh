#!/bin/bash
if [ -z "$PG_PASS" ]
then
  echo "$0: you need to specify PG_PASS env variable"
  exit 1
fi
./util_sh/monthly.sh '2014-01-01' "'VMware', 'VMWare'" "'IssueCommentEvent', 'CommitCommentEvent', 'PullRequestReviewCommentEvent', 'PullRequestReviewEvent'" id vmware_comments.csv
./util_sh/monthly.sh '2014-01-01' "'VMware', 'VMWare'" "'IssueCommentEvent', 'CommitCommentEvent', 'PullRequestReviewCommentEvent', 'PullRequestReviewEvent'" actor_id vmware_commenters.csv
