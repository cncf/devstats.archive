create temp table prs_latest as 
  select sub.*
  from (
    select id,
      event_id,
      created_at,
      merged_at,
      dup_repo_id,
      dup_repo_name,
      row_number() over (partition by id order by updated_at desc, event_id desc) as rank
    from
      gha_pull_requests
    where
      created_at >= '{{from}}'
      and created_at < '{{to}}'
      and merged_at is not null
  ) sub
  where
    sub.rank = 1;
create index prs_latest_id_idx on prs_latest(id);
create index prs_latest_event_id_idx on prs_latest(event_id);
create index prs_latest_dup_repo_id_idx on prs_latest(dup_repo_id);

