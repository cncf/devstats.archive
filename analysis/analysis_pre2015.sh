#!/bin/bash
echo "You need to have example set of JSONs from < 2015 in jsons/ directory"
# To generate them, use for example:
# GHA2DB_OLDFMT=1 GHA2DB_JSON=1 GHA2DB_NODB=1 gha2db 2014-06-10 17 2014-06-10 19
ruby analysis.rb old '' jsons/*.json | tee analysis/old.txt
ruby analysis.rb old_repository 'repository' jsons/*.json | tee analysis/old_repository.txt
ruby analysis.rb old_payload 'payload' jsons/*.json | tee analysis/old_payload.txt
ruby analysis.rb old_payload_pages 'payload,pages,i:0' jsons/*.json | tee analysis/old_payload_pages.txt
ruby analysis.rb old_payload_member 'payload,member' jsons/*.json | tee analysis/old_payload_member.txt
ruby analysis.rb old_payload_comment 'payload,comment' jsons/*.json | tee analysis/old_payload_comment.txt
ruby analysis.rb old_payload_comment_user 'payload,comment,user' jsons/*.json | tee analysis/old_payload_comment_user.txt
ruby analysis.rb old_payload_release 'payload,release' jsons/*.json | tee analysis/old_payload_release.txt
ruby analysis.rb old_payload_release_author 'payload,release,author' jsons/*.json | tee analysis/old_payload_release_author.txt
ruby analysis.rb old_payload_release_assets 'payload,release,assets,i:0' jsons/*.json | tee analysis/old_payload_release_assets.txt
ruby analysis.rb old_payload_release_assets_uploader 'payload,release,assets,i:0,uploader' jsons/*.json | tee analysis/old_payload_release_assets_uploader.txt
ruby analysis.rb old_payload_repository 'payload,repository' jsons/*.json | tee analysis/old_payload_repository.txt
ruby analysis.rb old_payload_repository_owner 'payload,repository,owner' jsons/*.json | tee analysis/old_payload_repository_owner.txt
ruby analysis.rb old_payload_team 'payload,team' jsons/*.json | tee analysis/old_payload_team.txt
ruby analysis.rb old_payload_pull_request 'payload,pull_request' jsons/*.json | tee analysis/old_payload_pull_request.txt
ruby analysis.rb old_payload_pull_request_base 'payload,pull_request,base' jsons/*.json | tee analysis/old_payload_pull_request_base.txt
ruby analysis.rb old_payload_pull_request_head 'payload,pull_request,head' jsons/*.json | tee analysis/old_payload_pull_request_head.txt
ruby analysis.rb old_payload_pull_request_merged_by 'payload,pull_request,merged_by' jsons/*.json | tee analysis/old_payload_pull_request_merged_by.txt
ruby analysis.rb old_payload_pull_request_user 'payload,pull_request,user' jsons/*.json | tee analysis/old_payload_pull_request_user.txt
ruby analysis.rb old_payload_pull_request_assignee 'payload,pull_request,assignee' jsons/*.json | tee analysis/old_payload_pull_request_assignee.txt
ruby analysis.rb old_payload_pull_request_milestone 'payload,pull_request,milestone' jsons/*.json | tee analysis/old_payload_pull_request_milestone.txt
ruby analysis.rb old_payload_pull_request_base_repo 'payload,pull_request,base,repo' jsons/*.json | tee analysis/old_payload_pull_request_base_repo.txt
ruby analysis.rb old_payload_pull_request_base_user 'payload,pull_request,base,user' jsons/*.json | tee analysis/old_payload_pull_request_base_user.txt
ruby analysis.rb old_payload_pull_request_head_repo 'payload,pull_request,head,repo' jsons/*.json | tee analysis/old_payload_pull_request_head_repo.txt
ruby analysis.rb old_payload_pull_request_head_user 'payload,pull_request,head,user' jsons/*.json | tee analysis/old_payload_pull_request_head_user.txt
ruby analysis.rb old_payload_pull_request_base_repo_owner 'payload,pull_request,base,repo,owner' jsons/*.json | tee analysis/old_payload_pull_request_base_repo_owner.txt
ruby analysis.rb old_payload_pull_request_head_repo_owner 'payload,pull_request,head,repo,owner' jsons/*.json | tee analysis/old_payload_pull_request_head_repo_owner.txt
ruby analysis.rb old_payload_pull_request_milestone_creator 'payload,pull_request,milestone,creator' jsons/*.json | tee analysis/old_payload_pull_request_milestone_creator.txt
