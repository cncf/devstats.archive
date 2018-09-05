create materialized view current_state.milestones as
with milestone_latest as (
          select gha_milestones.id,
             gha_milestones.title as milestone,
             gha_milestones.state,
             gha_milestones.created_at,
             gha_milestones.updated_at,
             gha_milestones.closed_at,
             gha_milestones.event_id,
             gha_milestones.dup_repo_id as repo_id,
             gha_milestones.dup_repo_name as repo_name,
             row_number() over (partition by gha_milestones.id order by gha_milestones.updated_at desc, gha_milestones.event_id desc) as rank
            from gha_milestones
         )
select milestone_latest.id,
     milestone_latest.milestone,
     milestone_latest.state,
     milestone_latest.created_at,
     milestone_latest.updated_at,
     milestone_latest.closed_at,
     milestone_latest.repo_id,
     milestone_latest.repo_name
from milestone_latest;
