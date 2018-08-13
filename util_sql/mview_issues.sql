create materialized view current_state.issues as
with issue_latest as (
          select issues.id,
             issues.dup_repo_id as repo_id,
             issues.dup_repo_name as repo_name,
             issues.number,
             issues.is_pull_request,
             issues.milestone_id,
             milestones.milestone,
             issues.state,
             issues.title,
             issues.user_id as creator_id,
             issues.assignee_id,
             issues.created_at as created_at,
             issues.updated_at,
             issues.closed_at,
             issues.body,
             issues.comments,
             row_number() over (partition by issues.id order by issues.updated_at desc, issues.event_id desc) as rank
            from (gha_issues issues
              left join current_state.milestones on issues.milestone_id = milestones.id)
         )
select issue_latest.id,
     issue_latest.repo_id,
     issue_latest.repo_name,
     issue_latest.number,
     issue_latest.is_pull_request,
     issue_latest.milestone_id,
     issue_latest.milestone,
     issue_latest.state,
     issue_latest.title,
     issue_latest.creator_id,
     issue_latest.assignee_id,
     issue_latest.created_at,
     issue_latest.updated_at,
     issue_latest.closed_at,
     issue_latest.body,
     issue_latest.comments
    from issue_latest
   where (issue_latest.rank = 1)
   order by issue_latest.repo_name, issue_latest.number;
