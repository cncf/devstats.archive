#!/bin/bash
echo "You need to have example set of JSONs from < 2015 in jsons/ directory"
# To generate them, use for example:
# GHA2DB_OLDFMT=1 GHA2DB_JSON=1 GHA2DB_NODB=1 gha2db 2014-06-10 17 2014-06-10 19
ruby ./analysis/analysis.rb old '' 'dirre:jsons:\.json$' | tee analysis/old.txt
ruby ./analysis/analysis.rb old_repository 'repository' 'dirre:jsons:\.json$' | tee analysis/old_repository.txt
ruby ./analysis/analysis.rb old_payload 'payload' 'dirre:jsons:\.json$' | tee analysis/old_payload.txt
ruby ./analysis/analysis.rb old_payload_pages 'payload,pages,i:0' 'dirre:jsons:\.json$' | tee analysis/old_payload_pages.txt
ruby ./analysis/analysis.rb old_payload_member 'payload,member' 'dirre:jsons:\.json$' | tee analysis/old_payload_member.txt
ruby ./analysis/analysis.rb old_payload_comment 'payload,comment' 'dirre:jsons:\.json$' | tee analysis/old_payload_comment.txt
ruby ./analysis/analysis.rb old_payload_comment_user 'payload,comment,user' 'dirre:jsons:\.json$' | tee analysis/old_payload_comment_user.txt
ruby ./analysis/analysis.rb old_payload_release 'payload,release' 'dirre:jsons:\.json$' | tee analysis/old_payload_release.txt
ruby ./analysis/analysis.rb old_payload_release_author 'payload,release,author' 'dirre:jsons:\.json$' | tee analysis/old_payload_release_author.txt
ruby ./analysis/analysis.rb old_payload_release_assets 'payload,release,assets,i:0' 'dirre:jsons:\.json$' | tee analysis/old_payload_release_assets.txt
ruby ./analysis/analysis.rb old_payload_release_assets_uploader 'payload,release,assets,i:0,uploader' 'dirre:jsons:\.json$' | tee analysis/old_payload_release_assets_uploader.txt
ruby ./analysis/analysis.rb old_payload_repository 'payload,repository' 'dirre:jsons:\.json$' | tee analysis/old_payload_repository.txt
ruby ./analysis/analysis.rb old_payload_repository_owner 'payload,repository,owner' 'dirre:jsons:\.json$' | tee analysis/old_payload_repository_owner.txt
ruby ./analysis/analysis.rb old_payload_team 'payload,team' 'dirre:jsons:\.json$' | tee analysis/old_payload_team.txt
ruby ./analysis/analysis.rb old_payload_pull_request 'payload,pull_request' 'dirre:jsons:\.json$' | tee analysis/old_payload_pull_request.txt
ruby ./analysis/analysis.rb old_payload_pull_request_base 'payload,pull_request,base' 'dirre:jsons:\.json$' | tee analysis/old_payload_pull_request_base.txt
ruby ./analysis/analysis.rb old_payload_pull_request_head 'payload,pull_request,head' 'dirre:jsons:\.json$' | tee analysis/old_payload_pull_request_head.txt
ruby ./analysis/analysis.rb old_payload_pull_request_merged_by 'payload,pull_request,merged_by' 'dirre:jsons:\.json$' | tee analysis/old_payload_pull_request_merged_by.txt
ruby ./analysis/analysis.rb old_payload_pull_request_user 'payload,pull_request,user' 'dirre:jsons:\.json$' | tee analysis/old_payload_pull_request_user.txt
ruby ./analysis/analysis.rb old_payload_pull_request_assignee 'payload,pull_request,assignee' 'dirre:jsons:\.json$' | tee analysis/old_payload_pull_request_assignee.txt
ruby ./analysis/analysis.rb old_payload_pull_request_milestone 'payload,pull_request,milestone' 'dirre:jsons:\.json$' | tee analysis/old_payload_pull_request_milestone.txt
ruby ./analysis/analysis.rb old_payload_pull_request_base_repo 'payload,pull_request,base,repo' 'dirre:jsons:\.json$' | tee analysis/old_payload_pull_request_base_repo.txt
ruby ./analysis/analysis.rb old_payload_pull_request_base_user 'payload,pull_request,base,user' 'dirre:jsons:\.json$' | tee analysis/old_payload_pull_request_base_user.txt
ruby ./analysis/analysis.rb old_payload_pull_request_head_repo 'payload,pull_request,head,repo' 'dirre:jsons:\.json$' | tee analysis/old_payload_pull_request_head_repo.txt
ruby ./analysis/analysis.rb old_payload_pull_request_head_user 'payload,pull_request,head,user' 'dirre:jsons:\.json$' | tee analysis/old_payload_pull_request_head_user.txt
ruby ./analysis/analysis.rb old_payload_pull_request_base_repo_owner 'payload,pull_request,base,repo,owner' 'dirre:jsons:\.json$' | tee analysis/old_payload_pull_request_base_repo_owner.txt
ruby ./analysis/analysis.rb old_payload_pull_request_head_repo_owner 'payload,pull_request,head,repo,owner' 'dirre:jsons:\.json$' | tee analysis/old_payload_pull_request_head_repo_owner.txt
ruby ./analysis/analysis.rb old_payload_pull_request_milestone_creator 'payload,pull_request,milestone,creator' 'dirre:jsons:\.json$' | tee analysis/old_payload_pull_request_milestone_creator.txt
for f in analysis/*.json; do cat "$f" | jq -rS '.' >> temp; mv temp "$f"; done
