with matching as (
  select distinct event_id
  from
    gha_texts
  where
    created_at >= '{{from}}'
    and created_at < '{{to}}'
    and substring(body from '(?i)(?:^|\n|\r)\s*/(?:lgtm|approve)\s*(?:\n|\r|$)') is not null
    and (lower(actor_login) {{exclude_bots}})
), reviews as (
  select distinct id as event_id
  from
    gha_events
  where
    created_at >= '{{from}}'
    and created_at < '{{to}}'
    and type in ('PullRequestReviewCommentEvent')
    and (lower(dup_actor_login) {{exclude_bots}})
)
select 'cs;reviews_All_All_All;evs,acts' as metric,
  round(count(distinct e.id) / {{n}}, 2) as evs,
  count(distinct e.dup_actor_login) as acts
from
  gha_events e
where
  e.id in (
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
union all select 'cs;reviews_' || sub.repo || '_All_All;evs,acts' as metric,
  round(count(distinct sub.id) / {{n}}, 2) as evs,
  count(distinct sub.actor) as acts
from (
  select e.dup_repo_name as repo,
    e.dup_actor_login as actor,
    e.id
  from
    gha_events e
  where
    e.id in (
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
    and e.dup_repo_name in (select repo_name from trepos)
  ) sub
group by
  sub.repo
union all select 'cs;reviews_' || sub.repo || '_' || sub.country || '_All;evs,acts' as metric,
  round(count(distinct sub.id) / {{n}}, 2) as evs,
  count(distinct sub.actor) as acts
from (
  select e.dup_repo_name as repo,
    a.country_name as country,
    a.login as actor,
    e.id
  from
    gha_actors a,
    gha_events e
  where
    (e.actor_id = a.id or e.dup_actor_login = a.login)
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
    and e.dup_repo_name in (select repo_name from trepos)
  ) sub
where
  sub.country is not null
group by
  sub.country,
  sub.repo
union all select 'cs;reviews_All_' || a.country_name || '_All;evs,acts' as metric,
  round(count(distinct e.id) / {{n}}, 2) as evs,
  count(distinct e.dup_actor_login) as acts
from
  gha_actors a,
  gha_events e
where
  (e.actor_id = a.id or e.dup_actor_login = a.login)
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
  and a.country_name is not null
group by
  a.country_name
union all select 'cs;reviews_All_All_' || aa.company_name || ';evs,acts' as metric,
  round(count(distinct e.id) / {{n}}, 2) as evs,
  count(distinct e.dup_actor_login) as acts
from
  gha_events e,
  gha_actors_affiliations aa
where
  aa.actor_id = e.actor_id
  and aa.dt_from <= e.created_at
  and aa.dt_to > e.created_at
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
  and aa.company_name in (select companies_name from tcompanies)
group by
  aa.company_name
union all select 'cs;reviews_' || sub.repo || '_All_' || sub.company || ';evs,acts' as metric ,
  round(count(distinct sub.id) / {{n}}, 2) as evs,
  count(distinct sub.actor) as acts
from (
  select e.dup_repo_name as repo,
    e.dup_actor_login as actor,
    aa.company_name as company,
    e.id
  from
    gha_actors_affiliations aa,
    gha_events e
  where
    aa.actor_id = e.actor_id
    and aa.dt_from <= e.created_at
    and aa.dt_to > e.created_at
    and aa.company_name in (select companies_name from tcompanies)
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
    and e.dup_repo_name in (select repo_name from trepos)
  ) sub
group by
  sub.repo,
  sub.company
union all select 'cs;reviews_' || sub.repo || '_' || sub.country || '_' || sub.company || ';evs,acts' as metric,
  round(count(distinct sub.id) / {{n}}, 2) as evs,
  count(distinct sub.actor) as acts
from (
  select e.dup_repo_name as repo,
    a.country_name as country,
    a.login as actor,
    aa.company_name as company,
    e.id
  from
    gha_actors a,
    gha_actors_affiliations aa,
    gha_events e
  where
    aa.actor_id = e.actor_id
    and aa.dt_from <= e.created_at
    and aa.dt_to > e.created_at
    and (e.actor_id = a.id or e.dup_actor_login = a.login)
    and aa.company_name in (select companies_name from tcompanies)
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
    and e.dup_repo_name in (select repo_name from trepos)
  ) sub
where
  sub.country is not null
group by
  sub.country,
  sub.repo,
  sub.company
union all select 'cs;reviews_All_' || a.country_name || '_' || aa.company_name || ';evs,acts' as metric,
  round(count(distinct e.id) / {{n}}, 2) as evs,
  count(distinct e.dup_actor_login) as acts
from
  gha_actors a,
  gha_events e,
  gha_actors_affiliations aa
where
  aa.actor_id = e.actor_id
  and aa.dt_from <= e.created_at
  and aa.dt_to > e.created_at
  and (e.actor_id = a.id or e.dup_actor_login = a.login)
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
  and a.country_name is not null
  and aa.company_name in (select companies_name from tcompanies)
group by
  a.country_name,
  aa.company_name
/*
order by
  acts desc,
  evs desc
*/
;
