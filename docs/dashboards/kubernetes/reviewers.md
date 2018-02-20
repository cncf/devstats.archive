# Kubernetes reviewers dashboard

Links:
- Postgres SQL file: [reviewers.sql](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/reviewers.sql).
- InfluxDB series definition: [metrics.yaml](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/metrics.yaml#L157-L162).
- Grafana dashboard JSON: [reviewers.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/reviewers.json)
- Production version: [view](https://k8s.devstats.cncf.io/d/000000030/reviewers?orgId=1).
- Test version: [view](https://k8s.cncftest.io/d/000000030/reviewers?orgId=1).

# Description

- We're quering `gha_texts` table. It contains all 'texts' from all Kubernetes repositories.
- For more information about `gha_texts` table please check: [docs/tables/gha_texts.md](https://github.com/cncf/devstats/blob/master/docs/tables/gha_texts.md).

create temp table matching as
select event_id
from gha_texts
where
  created_at >= '{{from}}' and created_at < '{{to}}'
  and substring(body from '(?i)(?:^|\n|\r)\s*/(?:lgtm|approve)\s*(?:\n|\r|$)') is not null;

create temp table reviews as
select id as event_id
from
  gha_events
where
  created_at >= '{{from}}' and created_at < '{{to}}'
  and type in ('PullRequestReviewCommentEvent');

select
  'reviewers,All' as repo_group,
  count(distinct dup_actor_login) as result
from
  gha_events
where
  (dup_actor_login {{exclude_bots}})
  and id in (
    select min(event_id)
    from
      gha_issues_events_labels
    where
      created_at >= '{{from}}'
      and created_at < '{{to}}'
      and label_name in ('lgtm', 'approved')
    group by
      issue_id
    union select event_id from matching
    union select event_id from reviews
  )
union select sub.repo_group,
  count(distinct sub.actor) as result
from (
  select 'reviewers,' || coalesce(ecf.repo_group, r.repo_group) as repo_group,
    e.dup_actor_login as actor
  from
    gha_repos r,
    gha_events e
  left join
    gha_events_commits_files ecf
  on
    ecf.event_id = e.id
  where
    e.repo_id = r.id
    and (e.dup_actor_login {{exclude_bots}})
    and e.id in (
      select min(event_id)
      from
        gha_issues_events_labels
      where
        created_at >= '{{from}}'
        and created_at < '{{to}}'
        and label_name in ('lgtm', 'approved')
      group by
        issue_id
      union select event_id from matching
      union select event_id from reviews
    )
  ) sub
where
  sub.repo_group is not null
group by
  sub.repo_group
order by
  result desc,
  repo_group asc
;

drop table reviews;
drop table matching;
