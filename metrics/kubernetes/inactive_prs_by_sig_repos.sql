create temp table dtto{{rnd}} as select case '{{to}}'::timestamp > now() when true then now() else '{{to}}'::timestamp end as dtto;
create temp table issues{{rnd}} as
  select sub.issue_id,
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
      gha_issues
    where
      created_at >= '{{to}}'::timestamp - '1 year'::interval
      and created_at < '{{to}}'
      and updated_at < '{{to}}'
      and is_pull_request = true
      and (lower(dup_user_login) {{exclude_bots}})
      and dup_repo_name in (select repo_name from trepos)
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
      sub.closed_at is null;
create index on issues{{rnd}}(issue_id);
create index on issues{{rnd}}(user_id);
create temp table prs{{rnd}} as
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
      gha_pull_requests
    where
      created_at >= '{{to}}'::timestamp - '1 year'::interval
      and created_at < '{{to}}'
      and updated_at < '{{to}}'
      and event_id > 0
      and (lower(dup_user_login) {{exclude_bots}})
      and dup_repo_name in (select repo_name from trepos)
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
    issues{{rnd}} i,
    gha_issues_pull_requests ipr
  where
    ipr.issue_id = i.issue_id
    and ipr.pull_request_id = pr.pr_id
    and pr.closed_at is null
    and pr.merged_at is null;
create index on prs{{rnd}}(issue_id);
create index on prs{{rnd}}(pr_id);
create index on prs{{rnd}}(number);
create index on prs{{rnd}}(repo_name);
create index on prs{{rnd}}(user_id);
create index on prs{{rnd}}(event_id);
create temp table pr_sigs{{rnd}} as
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
        prs{{rnd}} pr
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
  ) sub2;
create index on pr_sigs{{rnd}}(number);
create index on pr_sigs{{rnd}}(repo_name);
create temp table issues_act{{rnd}} as
  select i2.number,
    i2.dup_repo_name as repo_name,
    extract(epoch from i2.updated_at - i.created_at) as diff
  from
    issues{{rnd}} i,
    gha_issues i2
  where
    i.issue_id = i2.id
    and (lower(i2.dup_actor_login) {{exclude_bots}})
    and i2.updated_at < '{{to}}'
    and i2.event_id in (
      select event_id
      from
        gha_issues sub
      where
        sub.dup_actor_id != i.user_id
        and sub.id = i.issue_id
        and i2.updated_at < '{{to}}'
        and sub.updated_at > i.created_at + '30 seconds'::interval
        and sub.dup_type like '%Event'
      order by
        sub.updated_at asc
      limit 1
    );
create index on issues_act{{rnd}}(number);
create index on issues_act{{rnd}}(repo_name);
create temp table prs_act{{rnd}} as
  select pr2.number,
    pr2.dup_repo_name as repo_name,
    extract(epoch from pr2.updated_at - pr.created_at) as diff
  from
    prs{{rnd}} pr,
    gha_pull_requests pr2
  where
    pr.pr_id = pr2.id
    and (lower(pr2.dup_actor_login) {{exclude_bots}})
    and pr2.updated_at < '{{to}}'
    and pr2.event_id in (
      select event_id
      from
        gha_pull_requests sub
      where
        sub.dup_actor_id != pr.user_id
        and sub.id = pr.pr_id
        and pr2.updated_at < '{{to}}'
        and sub.updated_at > pr.created_at + '30 seconds'::interval
        and sub.dup_type like '%Event'
      order by
        sub.updated_at asc
      limit 1
    );
create index on prs_act{{rnd}}(number);
create index on prs_act{{rnd}}(repo_name);
create temp table act_on_issue{{rnd}} as
  select
    p.number,
    p.repo_name,
    p.created_at,
    coalesce(ia.diff, extract(epoch from d.dtto - p.created_at)) as inactive_for
  from
    dtto{{rnd}} d,
    prs{{rnd}} p
  left join
    issues_act{{rnd}} ia
  on
    p.repo_name = ia.repo_name
    and p.number = ia.number;
create index on act_on_issue{{rnd}}(number);
create index on act_on_issue{{rnd}}(repo_name);
create temp table act{{rnd}} as
  select
    aoi.number,
    aoi.repo_name,
    least(aoi.inactive_for, coalesce(pra.diff, extract(epoch from d.dtto - aoi.created_at))) as inactive_for
  from
    dtto{{rnd}} d,
    act_on_issue{{rnd}} aoi
  left join
    prs_act{{rnd}} pra
  on
    aoi.repo_name = pra.repo_name
    and aoi.number = pra.number;
create index on act{{rnd}}(number);
create index on act{{rnd}}(repo_name);
select
  'inactive_prs_by_sig_repos;' || sub.sig || '`' || sub.repo || ';w2,d30,d90' as metric,
  count(distinct sub.pr) filter(where sub.inactive_for > 1209600) as inactive_14,
  count(distinct sub.pr) filter(where sub.inactive_for > 2592000) as inactive_30,
  count(distinct sub.pr) filter(where sub.inactive_for > 7776000) as inactive_90
from
  (
  select s.sig,
    s.repo_name as repo,
    s.repo_name || s.number::text as pr,
    a.inactive_for
  from
    pr_sigs{{rnd}} s,
    act{{rnd}} a
  where
    s.number = a.number
    and s.repo_name = a.repo_name
  ) sub
group by
  sub.sig,
  sub.repo
;
