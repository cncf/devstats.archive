#!/bin/bash
echo "You need to have example set of JSONs from >= 2015 in jsons/ directory"
# To generate them, use for example:
# GHA2DB_LOCAL=1 GHA2DB_JSON=1 GHA2DB_NODB=1 ./gha2db 2022-04-06 18 2022-04-06 18
ruby ./analysis/analysis.rb new '' 'dirre:jsons:\.json$' | tee analysis/new.txt
ruby ./analysis/analysis.rb new_actor 'actor' 'dirre:jsons:\.json$' | tee analysis/new_actor.txt
ruby ./analysis/analysis.rb new_repo 'repo' 'dirre:jsons:\.json$' | tee analysis/new_repo.txt
ruby ./analysis/analysis.rb new_org 'org' 'dirre:jsons:\.json$' | tee analysis/new_org.txt
ruby ./analysis/analysis.rb new_payload 'payload' 'dirre:jsons:\.json$' | tee analysis/new_payload.txt
ruby ./analysis/analysis.rb new_payload_comment 'payload,comment' 'dirre:jsons:\.json$' | tee analysis/new_payload_comment.txt
ruby ./analysis/analysis.rb new_payload_member 'payload,member' 'dirre:jsons:\.json$' | tee analysis/new_payload_member.txt
ruby ./analysis/analysis.rb new_payload_commits 'payload,commits,i:0' 'dirre:jsons:\.json$' | tee analysis/new_payload_commits.txt
ruby ./analysis/analysis.rb new_payload_release 'payload,release' 'dirre:jsons:\.json$' | tee analysis/new_payload_release.txt
ruby ./analysis/analysis.rb new_payload_issue 'payload,issue' 'dirre:jsons:\.json$' | tee analysis/new_payload_issue.txt
ruby ./analysis/analysis.rb new_payload_forkee 'payload,forkee' 'dirre:jsons:\.json$' | tee analysis/new_payload_forkee.txt
ruby ./analysis/analysis.rb new_payload_pull_request 'payload,pull_request' 'dirre:jsons:\.json$' | tee analysis/new_payload_pull_request.txt
ruby ./analysis/analysis.rb new_payload_comment_user 'payload,comment,user' 'dirre:jsons:\.json$' | tee analysis/new_payload_comment_user.txt
ruby ./analysis/analysis.rb new_payload_commits_author 'payload,commits,i:0,author' 'dirre:jsons:\.json$' | tee analysis/new_payload_commits_author.txt
ruby ./analysis/analysis.rb new_payload_release_author 'payload,release,author' 'dirre:jsons:\.json$' | tee analysis/new_payload_release_author.txt
ruby ./analysis/analysis.rb new_payload_release_assets 'payload,release,assets,i:0' 'dirre:jsons:\.json$' | tee analysis/new_payload_release_assets.txt
ruby ./analysis/analysis.rb new_payload_issue_assignee 'payload,issue,assignee' 'dirre:jsons:\.json$' | tee analysis/new_payload_issue_assignee.txt
ruby ./analysis/analysis.rb new_payload_issue_labels 'payload,issue,labels,i:0' 'dirre:jsons:\.json$' | tee analysis/new_payload_issue_labels.txt
ruby ./analysis/analysis.rb new_payload_issue_user 'payload,issue,user' 'dirre:jsons:\.json$' | tee analysis/new_payload_issue_user.txt
ruby ./analysis/analysis.rb new_payload_issue_pull_request 'payload,issue,pull_request' 'dirre:jsons:\.json$' | tee analysis/new_payload_issue_pull_request.txt
ruby ./analysis/analysis.rb new_payload_issue_milestone 'payload,issue,milestone' 'dirre:jsons:\.json$' | tee analysis/new_payload_issue_milestone.txt
ruby ./analysis/analysis.rb new_payload_forkee_owner 'payload,forkee,owner' 'dirre:jsons:\.json$' | tee analysis/new_payload_forkee_owner.txt
ruby ./analysis/analysis.rb new_payload_pull_request_assignee 'payload,pull_request,assignee' 'dirre:jsons:\.json$' | tee analysis/new_payload_pull_request_assignee.txt
ruby ./analysis/analysis.rb new_payload_pull_request_base 'payload,pull_request,base' 'dirre:jsons:\.json$' | tee analysis/new_payload_pull_request_base.txt
ruby ./analysis/analysis.rb new_payload_pull_request_head 'payload,pull_request,head' 'dirre:jsons:\.json$' | tee analysis/new_payload_pull_request_head.txt
ruby ./analysis/analysis.rb new_payload_pull_request_merged_by 'payload,pull_request,merged_by' 'dirre:jsons:\.json$' | tee analysis/new_payload_pull_request_merged_by.txt
ruby ./analysis/analysis.rb new_payload_pull_request_user 'payload,pull_request,user' 'dirre:jsons:\.json$' | tee analysis/new_payload_pull_request_user.txt
ruby ./analysis/analysis.rb new_payload_pull_request_milestone 'payload,pull_request,milestone' 'dirre:jsons:\.json$' | tee analysis/new_payload_pull_request_milestone.txt
ruby ./analysis/analysis.rb new_payload_release_assets_uploader 'payload,release,assets,i:0,uploader' 'dirre:jsons:\.json$' | tee analysis/new_payload_release_assets_uploader.txt
ruby ./analysis/analysis.rb new_payload_issue_milestone_creator 'payload,issue,milestone,creator' 'dirre:jsons:\.json$' | tee analysis/new_payload_issue_milestone_creator.txt
ruby ./analysis/analysis.rb new_payload_pull_request_base_repo 'payload,pull_request,base,repo' 'dirre:jsons:\.json$' | tee analysis/new_payload_pull_request_base_repo.txt
ruby ./analysis/analysis.rb new_payload_pull_request_base_user 'payload,pull_request,base,user' 'dirre:jsons:\.json$' | tee analysis/new_payload_pull_request_base_user.txt
ruby ./analysis/analysis.rb new_payload_pull_request_head_repo 'payload,pull_request,head,repo' 'dirre:jsons:\.json$' | tee analysis/new_payload_pull_request_head_repo.txt
ruby ./analysis/analysis.rb new_payload_pull_request_head_user 'payload,pull_request,head,user' 'dirre:jsons:\.json$' | tee analysis/new_payload_pull_request_head_user.txt
ruby ./analysis/analysis.rb new_payload_pull_request_milestone_creator 'payload,pull_request,milestone,creator' 'dirre:jsons:\.json$' | tee analysis/new_payload_pull_request_milestone_creator.txt
ruby ./analysis/analysis.rb new_payload_pull_request_base_repo_owner 'payload,pull_request,base,repo,owner' 'dirre:jsons:\.json$' | tee analysis/new_payload_pull_request_base_repo_owner.txt
ruby ./analysis/analysis.rb new_payload_pull_request_head_repo_owner 'payload,pull_request,head,repo,owner' 'dirre:jsons:\.json$' | tee analysis/new_payload_pull_request_head_repo_owner.txt
ruby ./analysis/analysis.rb new_payload_review 'payload,review' 'dirre:jsons:\.json$' | tee analysis/new_payload_review.txt
ruby ./analysis/analysis.rb new_payload_review_user 'payload,review,user' 'dirre:jsons:\.json$' | tee analysis/new_payload_review_user.txt
for f in analysis/*.json; do cat "$f" | jq -rS '.' >> temp; mv temp "$f"; done
