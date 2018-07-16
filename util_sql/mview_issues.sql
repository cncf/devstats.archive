create materialized view current_state.issues as
WITH issue_latest AS (
          SELECT issues.id,
             issues.dup_repo_id AS repo_id,
             issues.dup_repo_name AS repo_name,
             issues.number,
             issues.is_pull_request,
             issues.milestone_id,
             milestones.milestone,
             issues.state,
             issues.title,
             issues.user_id AS creator_id,
             issues.assignee_id,
             issues.created_at AS created_at,
             issues.updated_at,
             issues.closed_at,
             issues.body,
             issues.comments,
             row_number() OVER (PARTITION BY issues.id ORDER BY issues.updated_at DESC, issues.event_id DESC) AS rank
            FROM (gha_issues issues
              LEFT JOIN current_state.milestones ON issues.milestone_id = milestones.id)
         )
SELECT issue_latest.id,
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
    FROM issue_latest
   WHERE (issue_latest.rank = 1)
   ORDER BY issue_latest.repo_name, issue_latest.number;
