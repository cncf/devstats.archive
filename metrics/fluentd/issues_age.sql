create temp table issues as
select i.id,
  r.repo_group,
  i.created_at,
  i.closed_at as closed_at
from
  gha_repos r,
  gha_issues i
where
  i.is_pull_request = false
  and i.closed_at is not null
  and r.name = i.dup_repo_name
  and i.created_at >= '{{from}}'
  and i.created_at < '{{to}}'
  and i.event_id = (
    select n.event_id from gha_issues n where n.id = i.id order by n.updated_at desc limit 1
  );

create temp table tdiffs as
select id, repo_group, extract(epoch from closed_at - created_at) / 3600 as age
from
  issues;

select
  'issues_age;All;number,median' as name,
  round(count(distinct t.id) / {{n}}, 2) as num,
  percentile_disc(0.5) within group (order by t.age asc) as age_median
from
  tdiffs t
union select 'issues_age;' || t.repo_group || ';number,median' as name,
  round(count(distinct t.id) / {{n}}, 2) as num,
  percentile_disc(0.5) within group (order by t.age asc) as age_median
from
  tdiffs t
where
  t.repo_group is not null
group by
  t.repo_group
order by
  age_median asc,
  name asc
;

drop table tdiffs;
drop table issues;
