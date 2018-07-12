create materialized view current_state.prs as
WITH pr_latest AS (
          SELECT prs.id,
             prs.dup_repo_id AS repo_id,
             prs.dup_repo_name AS repo_name,
             prs.number,
             prs.milestone_id,
             milestones.milestone,
             prs.state,
             prs.title,
             prs.user_id AS creator_id,
             prs.assignee_id,
             prs.dup_created_at AS created_at,
             prs.updated_at,
             prs.closed_at,
             prs.merged_at,
             prs.body,
             prs.comments,
             row_number() OVER (PARTITION BY prs.id ORDER BY prs.updated_at DESC, prs.event_id DESC) AS rank
            FROM (gha_pull_requests prs
              LEFT JOIN current_state.milestones ON prs.milestone_id = milestones.id)
         )
SELECT pr_latest.id,
     pr_latest.repo_id,
     pr_latest.repo_name,
     pr_latest.number,
     pr_latest.milestone_id,
     pr_latest.milestone,
     pr_latest.state,
     pr_latest.title,
     pr_latest.creator_id,
     pr_latest.assignee_id,
     pr_latest.created_at,
     pr_latest.updated_at,
     pr_latest.closed_at,
     pr_latest.merged_at,
     pr_latest.body,
     pr_latest.comments
    FROM pr_latest
   WHERE (pr_latest.rank = 1)
   ORDER BY pr_latest.repo_name, pr_latest.number;
