create temp table suggested_approvers as
select distinct i.id as issue_id,
  substring(
    c.body from '(?i)META={"approvers":\["([^"]+)"\]}'
  ) as approver,
  i.dup_repo_name as repo_name
from
  gha_comments c,
  gha_payloads pl,
  gha_issues i
where
  i.is_pull_request = true
  and c.event_id = pl.event_id
  and i.event_id = pl.event_id
  and i.created_at >= '{{from}}'
  and i.created_at < '{{to}}'
  and c.dup_actor_login = 'k8s-merge-robot'
  and c.body like '%APPROVALNOTIFIER%'
  and substring(
    c.body from '(?i)META={"approvers":\["([^"]+)"\]}'
  ) is not null
;

create temp table actual_approvers as
select distinct i.id as issue_id,
  c.dup_actor_login as approver
from
  gha_comments c,
  gha_payloads pl,
  gha_issues i
where
  i.is_pull_request = true
  and c.event_id = pl.event_id
  and i.event_id = pl.event_id
  and i.created_at >= '{{from}}'
  and i.created_at < '{{to}}'
  and c.dup_actor_login not in ('googlebot')
  and c.dup_actor_login not like 'k8s-%'
  and c.dup_actor_login not like '%-bot'
  and c.dup_actor_login not like '%-robot'
  and substring(
    c.body from '(?i)(?:^|\n|\r)\s*/approve\s*(?:\n|\r|$)'
  ) is not null
;

select
  'other_approvers;All;all_suggested_approvers,no_approver,other_approver,suggested_approver' as name,
  round(count(distinct sa.issue_id) / {{n}}, 2) as all_suggested_approvers,
  round(count(distinct sa.issue_id) filter (where aa.issue_id is null) / {{n}}, 2) as no_approver,
  round(count(distinct sa.issue_id) filter (where sa.approver != aa.approver) / {{n}}, 2) as other_approver,
  round(count(distinct sa.issue_id) filter (where sa.approver = aa.approver) / {{n}}, 2) as suggested_approver
from
  suggested_approvers sa
left join
  actual_approvers aa
on
  aa.issue_id = sa.issue_id
union select 'other_approvers;' || r.repo_group || ';all_suggested_approvers,no_approver,other_approver,suggested_approver' as name,
  round(count(distinct sa.issue_id) / {{n}}, 2) as all_suggested_approvers,
  round(count(distinct sa.issue_id) filter (where aa.issue_id is null) / {{n}}, 2) as no_approver,
  round(count(distinct sa.issue_id) filter (where sa.approver != aa.approver) / {{n}}, 2) as other_approver,
  round(count(distinct sa.issue_id) filter (where sa.approver = aa.approver) / {{n}}, 2) as suggested_approver
from
  gha_repos r
join
  suggested_approvers sa
on
  sa.repo_name = r.name
  and r.repo_group is not null
left join
  actual_approvers aa
on
  aa.issue_id = sa.issue_id
group by
  repo_group
order by
  all_suggested_approvers desc,
  name asc
;

drop table suggested_approvers;
drop table actual_approvers;

