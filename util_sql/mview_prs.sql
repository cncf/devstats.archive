create materialized view current_state.prs as
with pr_latest as (
          select prs.id,
             prs.dup_repo_id as repo_id,
             prs.dup_repo_name as repo_name,
             prs.number,
             prs.milestone_id,
             milestones.milestone,
             prs.state,
             prs.title,
             prs.user_id as creator_id,
             prs.assignee_id,
             prs.created_at as created_at,
             prs.updated_at,
             prs.closed_at,
             prs.merged_at,
             prs.body,
             prs.comments,
             row_number() over (partition by prs.id order by prs.updated_at desc, prs.event_id desc) as rank
            from (gha_pull_requests prs
              left join current_state.milestones on prs.milestone_id = milestones.id)
         )
select pr_latest.id,
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
    from pr_latest
   where (pr_latest.rank = 1)
   order by pr_latest.repo_name, pr_latest.number;
