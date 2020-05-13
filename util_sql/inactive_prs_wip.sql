with dtfrom as (
  select '{{to}}'::timestamp - '3 months'::interval as dtfrom
), dtto as (
  select case '{{to}}'::timestamp > now() when true then now() else '{{to}}'::timestamp end as dtto
), issues as (
  select distinct sub.issue_id,
    sub.user_id,
    sub.created_at,
    sub.event_id
  from (
    select distinct
      id as issue_id,
      last_value(event_id) over issues_ordered_by_update as event_id,
      first_value(user_id) over issues_ordered_by_update as user_id,
      first_value(created_at) over issues_ordered_by_update as created_at,
      last_value(closed_at) over issues_ordered_by_update as closed_at
    from
      gha_issues,
      dtfrom
    where
      created_at >= dtfrom
      and created_at < '{{to}}'
      and updated_at < '{{to}}'
      and is_pull_request = true
      and (lower(dup_user_login) {{exclude_bots}})
    window
      issues_ordered_by_update as (
        partition by id
        order by
          updated_at asc,
          event_id asc
        range between current row
        and unbounded following
      )
    ) sub
    where
      sub.closed_at is null
), prs as (
  select distinct i.issue_id,
    ipr.pull_request_id as pr_id,
    ipr.number,
    ipr.repo_name,
    pr.created_at,
    pr.user_id,
    i.event_id
  from (
    select distinct id as pr_id,
      first_value(user_id) over prs_ordered_by_update as user_id,
      first_value(created_at) over prs_ordered_by_update as created_at,
      last_value(closed_at) over prs_ordered_by_update as closed_at,
      last_value(merged_at) over prs_ordered_by_update as merged_at
    from
      gha_pull_requests,
      dtfrom
    where
      created_at >= dtfrom
      and created_at < '{{to}}'
      and updated_at < '{{to}}'
      and event_id > 0
      and (lower(dup_user_login) {{exclude_bots}})
    window
      prs_ordered_by_update as (
        partition by id
        order by
          updated_at asc,
          event_id asc
        range between current row
        and unbounded following
      )
    ) pr,
    issues i,
    gha_issues_pull_requests ipr
  where
    ipr.issue_id = i.issue_id
    and ipr.pull_request_id = pr.pr_id
    and pr.closed_at is null
    and pr.merged_at is null
), pr_sigs as (
  select sub2.issue_id,
    sub2.pr_id,
    sub2.event_id,
    sub2.number,
    sub2.repo_name,
    case sub2.sig
      when 'aws' then 'cloud-provider'
      when 'azure' then 'cloud-provider'
      when 'batchd' then 'cloud-provider'
      when 'cloud-provider-aws' then 'cloud-provider'
      when 'gcp' then 'cloud-provider'
      when 'ibmcloud' then 'cloud-provider'
      when 'openstack' then 'cloud-provider'
      when 'vmware' then 'cloud-provider'
      else sub2.sig
    end as sig
  from (
    select sub.issue_id,
      sub.pr_id,
      sub.event_id,
      sub.number,
      sub.repo_name,
      sub.sig
    from (
      select pr.issue_id,
        pr.pr_id,
        pr.event_id,
        pr.number,
        pr.repo_name,
        lower(substring(il.dup_label_name from '(?i)sig/(.*)')) as sig
      from
        gha_issues_labels il,
        prs pr
      where
        il.issue_id = pr.issue_id
        and il.event_id = pr.event_id
      ) sub
    where
      sub.sig is not null
      and sub.sig not in (
        'apimachinery', 'api-machiner', 'cloude-provider', 'nework',
        'scalability-proprosals', 'storge', 'ui-preview-reviewes',
        'cluster-fifecycle', 'rktnetes'
      )
      and sub.sig not like '%use-only-as-a-last-resort'
      and sub.sig in (select sig_mentions_labels_name from tsig_mentions_labels)
  ) sub2
), issues_act as (
  select i2.number,
    i2.dup_repo_name as repo_name,
    extract(epoch from i2.updated_at - i.created_at) as diff
  from
    issues i,
    gha_issues i2
    -- dtfrom
  where
    i.issue_id = i2.id
    and (lower(i2.dup_actor_login) {{exclude_bots}})
    -- and i2.created_at >= dtfrom
    -- and i2.created_at < '{{to}}'
    -- and i2.is_pull_request = true
    and i2.updated_at < '{{to}}'
    and i2.event_id in (
      select event_id
      from
        gha_issues sub
      where
        sub.dup_actor_id != i.user_id
        and sub.id = i.issue_id
        -- and sub.created_at >= dtfrom
        -- and sub.created_at < '{{to}}'
        and i2.updated_at < '{{to}}'
        and sub.updated_at > i.created_at + '30 seconds'::interval
        and sub.dup_type like '%Event'
      order by
        sub.updated_at asc
      limit 1
    )
), prs_act as (
  select pr2.number,
    pr2.dup_repo_name as repo_name,
    extract(epoch from pr2.updated_at - pr.created_at) as diff
  from
    prs pr,
    gha_pull_requests pr2
    -- dtfrom
  where
    pr.pr_id = pr2.id
    and (lower(pr2.dup_actor_login) {{exclude_bots}})
    -- and pr2.created_at >= dtfrom
    -- and pr2.created_at < '{{to}}'
    and pr2.updated_at < '{{to}}'
    and pr2.event_id in (
      select event_id
      from
        gha_pull_requests sub
      where
        sub.dup_actor_id != pr.user_id
        and sub.id = pr.pr_id
        -- and sub.created_at >= dtfrom
        -- and sub.created_at < '{{to}}'
        and pr2.updated_at < '{{to}}'
        and sub.updated_at > pr.created_at + '30 seconds'::interval
        and sub.dup_type like '%Event'
      order by
        sub.updated_at asc
      limit 1
    )
), act_on_issue as (
  select
    p.number,
    p.repo_name,
    p.created_at,
    coalesce(ia.diff, extract(epoch from d.dtto - p.created_at)) as inactive_for
  from
    dtto d,
    prs p
  left join
    issues_act ia
  on
    p.repo_name = ia.repo_name
    and p.number = ia.number
), act as (
  select
    aoi.number,
    aoi.repo_name,
    -- aoi.inactive_for as issue_inactrive_for,
    -- pra.diff as pr_inactive_for,
    -- extract(epoch from d.dtto - aoi.created_at) as elapsed_time,
    least(aoi.inactive_for, coalesce(pra.diff, extract(epoch from d.dtto - aoi.created_at))) as final_inactive_for
  from
    dtto d,
    act_on_issue aoi
  left join
    prs_act pra
  on
    aoi.repo_name = pra.repo_name
    and aoi.number = pra.number
)
--select dtfrom, dtto from dtfrom, dtto;
--select * from issues;
--select * from prs;
--select * from pr_sigs;
--select * from issues_act;
--select * from prs_act;
--select * from act_on_issue;
--select * from act_on_pr;
select * from act;
