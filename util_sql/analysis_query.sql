create or replace function pg_temp.array_uniq_stable(anyarray) returns anyarray as
$$
select array_agg(distinct_value ORDER BY first_index)
from (
  select
    value as distinct_value, 
    min(index) as first_index 
  from 
    unnest($1) with ordinality as input(value, index)
  group by
    value
) as unique_input;
$$
language 'sql' immutable strict;

with n as (
  select {{n}} as n
), start_date as (
  select '{{start_date}}' as string,
    '{{start_date}}'::date as date,
    '{{start_date}}'::timestamp as timestamp,
    date_trunc('month', '{{start_date}}'::date) as month_date,
    to_date(date_part('year', '{{start_date}}'::date)::varchar || '-' || ((((date_part('month', '{{start_date}}'::date) - 1)::int / 3) * 3) + 1)::varchar, 'YYYY-MM') as quarter_date
), join_date as (
  select '{{join_date}}' as string,
    '{{join_date}}'::date as date,
    '{{join_date}}'::timestamp as timestamp
), dates as (
  select 1 as ord,
    (select timestamp from start_date) as f,
    (select timestamp from join_date) as t,
    'Before joining CNCF' as rel
  union select 2 as ord,
    (select timestamp from join_date) as f,
    now()::date as t,
    'Since joining CNCF' as rel
  union {{proj_rels}}
  union select generate_series(2001,2001+month_count::int) as ord,
    (select month_date from start_date) + (interval '1' month * generate_series(0,month_count::int)) as f,
    (select month_date from start_date) + (interval '1' month * (1 + generate_series(0,month_count::int))) as t,
    to_char((select month_date from start_date) + (interval '1' month * generate_series(0,month_count::int)), 'MM/YYYY') as rel
  from (
    select (date_part('year', now()) - date_part('year', (select date from start_date))) * 12 + (date_part('month', now()) - date_part('month', (select date from start_date))) as month_count
  ) sub
  union select generate_series(3001,3001+month_count::int, 3) as ord,
    (select quarter_date from start_date) + (interval '1' month * generate_series(0,month_count::int,3)) as f,
    (select quarter_date from start_date) + (interval '1' month * (3 + generate_series(0,month_count::int,3))) as t,
    'Quarter from ' || to_char((select quarter_date from start_date) + (interval '1' month * generate_series(0,month_count::int, 3)), 'MM/YYYY') as rel
  from (
    select (date_part('year', now()) - date_part('year', (select date from start_date))) * 12 + (date_part('month', now()) - date_part('month', (select date from start_date))) as month_count
  ) sub
), top_contributors as (
select sub.date_from,
  sub.date_to,
  sub.release,
  sub.actor,
  sub.company,
  sub.rank,
  sub.events
from (
  select d.f as date_from,
    d.t as date_to,
    d.rel as release,
    e.actor_id as actor,
    af.company_name as company,
    row_number() over actors_by_activity as rank,
    count(distinct e.id) as events
  from
    dates d,
    gha_events e
  left join
    gha_actors_affiliations af
  on
    e.actor_id = af.actor_id
    and af.dt_from <= e.created_at
    and af.dt_to > e.created_at
    and af.company_name != 'Independent'
    and af.company_name != ''
  where
    e.created_at >= d.f
    and e.created_at < d.t
    and (lower(e.dup_actor_login) {{exclude_bots}})
    and e.type in (
      'PushEvent', 'PullRequestEvent', 'IssuesEvent'
    )
  group by
    d.f,
    d.t,
    d.rel,
    e.actor_id,
    af.company_name
  window
    actors_by_activity as (
      partition by
        d.rel
      order by
        count(distinct e.id) desc
    )
  ) sub
where
  sub.rank <= (select n from n)
), top_contributors_companies as (
select sub.date_from,
  sub.date_to,
  sub.release,
  sub.company,
  sub.rank,
  sub.events
from (
  select d.f as date_from,
    d.t as date_to,
    d.rel as release,
    af.company_name as company,
    row_number() over companies_by_activity as rank,
    count(distinct e.id) as events
  from
    dates d,
    gha_events e,
    gha_actors_affiliations af
  where
    e.actor_id = af.actor_id
    and af.dt_from <= e.created_at
    and af.dt_to > e.created_at
    and af.company_name != 'Independent'
    and e.created_at >= d.f
    and e.created_at < d.t
    and (lower(e.dup_actor_login) {{exclude_bots}})
    and e.type in (
      'PushEvent', 'PullRequestEvent', 'IssuesEvent'
    )
    and af.company_name != ''
  group by
    d.f,
    d.t,
    d.rel,
    af.company_name
  window
    companies_by_activity as (
      partition by
        d.rel
      order by
        count(distinct e.id) desc
    )
  ) sub
where
  sub.rank <= (select n from n)
), top_committers as (
select sub.date_from,
  sub.date_to,
  sub.release,
  sub.actor,
  sub.company,
  sub.rank,
  sub.events
from (
  select d.f as date_from,
    d.t as date_to,
    d.rel as release,
    e.actor_id as actor,
    af.company_name as company,
    row_number() over actors_by_activity as rank,
    count(distinct e.id) as events
  from
    dates d,
    gha_events e
  left join
    gha_actors_affiliations af
  on
    e.actor_id = af.actor_id
    and af.dt_from <= e.created_at
    and af.dt_to > e.created_at
    and af.company_name != 'Independent'
    and af.company_name != ''
  where
    e.created_at >= d.f
    and e.created_at < d.t
    and (lower(e.dup_actor_login) {{exclude_bots}})
    and e.type = 'PushEvent'
  group by
    d.f,
    d.t,
    d.rel,
    e.actor_id,
    af.company_name
  window
    actors_by_activity as (
      partition by
        d.rel
      order by
        count(distinct e.id) desc
    )
  ) sub
where
  sub.rank <= (select n from n)
), top_committers_companies as (
select sub.date_from,
  sub.date_to,
  sub.release,
  sub.company,
  sub.rank,
  sub.events
from (
  select d.f as date_from,
    d.t as date_to,
    d.rel as release,
    af.company_name as company,
    row_number() over companies_by_activity as rank,
    count(distinct e.id) as events
  from
    dates d,
    gha_events e,
    gha_actors_affiliations af
  where
    e.actor_id = af.actor_id
    and af.dt_from <= e.created_at
    and af.dt_to > e.created_at
    and af.company_name != 'Independent'
    and e.created_at >= d.f
    and e.created_at < d.t
    and (lower(e.dup_actor_login) {{exclude_bots}})
    and e.type = 'PushEvent'
    and af.company_name != ''
  group by
    d.f,
    d.t,
    d.rel,
    af.company_name
  window
    companies_by_activity as (
      partition by
        d.rel
      order by
        count(distinct e.id) desc
    )
  ) sub
where
  sub.rank <= (select n from n)
), top_issuers as (
select sub.date_from,
  sub.date_to,
  sub.release,
  sub.actor,
  sub.company,
  sub.rank,
  sub.events
from (
  select d.f as date_from,
    d.t as date_to,
    d.rel as release,
    e.actor_id as actor,
    af.company_name as company,
    row_number() over actors_by_activity as rank,
    count(distinct e.id) as events
  from
    dates d,
    gha_events e
  left join
    gha_actors_affiliations af
  on
    e.actor_id = af.actor_id
    and af.dt_from <= e.created_at
    and af.dt_to > e.created_at
    and af.company_name != 'Independent'
    and af.company_name != ''
  where
    e.created_at >= d.f
    and e.created_at < d.t
    and (lower(e.dup_actor_login) {{exclude_bots}})
    and e.type = 'IssuesEvent'
  group by
    d.f,
    d.t,
    d.rel,
    e.actor_id,
    af.company_name
  window
    actors_by_activity as (
      partition by
        d.rel
      order by
        count(distinct e.id) desc
    )
  ) sub
where
  sub.rank <= (select n from n)
), top_issuers_companies as (
select sub.date_from,
  sub.date_to,
  sub.release,
  sub.company,
  sub.rank,
  sub.events
from (
  select d.f as date_from,
    d.t as date_to,
    d.rel as release,
    af.company_name as company,
    row_number() over companies_by_activity as rank,
    count(distinct e.id) as events
  from
    dates d,
    gha_events e,
    gha_actors_affiliations af
  where
    e.actor_id = af.actor_id
    and af.dt_from <= e.created_at
    and af.dt_to > e.created_at
    and af.company_name != 'Independent'
    and e.created_at >= d.f
    and e.created_at < d.t
    and (lower(e.dup_actor_login) {{exclude_bots}})
    and e.type = 'IssuesEvent'
    and af.company_name != ''
  group by
    d.f,
    d.t,
    d.rel,
    af.company_name
  window
    companies_by_activity as (
      partition by
        d.rel
      order by
        count(distinct e.id) desc
    )
  ) sub
where
  sub.rank <= (select n from n)
), top_prs as (
select sub.date_from,
  sub.date_to,
  sub.release,
  sub.actor,
  sub.company,
  sub.rank,
  sub.events
from (
  select d.f as date_from,
    d.t as date_to,
    d.rel as release,
    e.actor_id as actor,
    af.company_name as company,
    row_number() over actors_by_activity as rank,
    count(distinct e.id) as events
  from
    dates d,
    gha_events e
  left join
    gha_actors_affiliations af
  on
    e.actor_id = af.actor_id
    and af.dt_from <= e.created_at
    and af.dt_to > e.created_at
    and af.company_name != 'Independent'
    and af.company_name != ''
  where
    e.created_at >= d.f
    and e.created_at < d.t
    and (lower(e.dup_actor_login) {{exclude_bots}})
    and e.type = 'PullRequestEvent'
  group by
    d.f,
    d.t,
    d.rel,
    e.actor_id,
    af.company_name
  window
    actors_by_activity as (
      partition by
        d.rel
      order by
        count(distinct e.id) desc
    )
  ) sub
where
  sub.rank <= (select n from n)
), top_prs_companies as (
select sub.date_from,
  sub.date_to,
  sub.release,
  sub.company,
  sub.rank,
  sub.events
from (
  select d.f as date_from,
    d.t as date_to,
    d.rel as release,
    af.company_name as company,
    row_number() over companies_by_activity as rank,
    count(distinct e.id) as events
  from
    dates d,
    gha_events e,
    gha_actors_affiliations af
  where
    e.actor_id = af.actor_id
    and af.dt_from <= e.created_at
    and af.dt_to > e.created_at
    and af.company_name != 'Independent'
    and e.created_at >= d.f
    and e.created_at < d.t
    and (lower(e.dup_actor_login) {{exclude_bots}})
    and e.type = 'PullRequestEvent'
    and af.company_name != ''
  group by
    d.f,
    d.t,
    d.rel,
    af.company_name
  window
    companies_by_activity as (
      partition by
        d.rel
      order by
        count(distinct e.id) desc
    )
  ) sub
where
  sub.rank <= (select n from n)
), top_reviewers as (
select sub.date_from,
  sub.date_to,
  sub.release,
  sub.actor,
  sub.company,
  sub.rank,
  sub.events
from (
  select d.f as date_from,
    d.t as date_to,
    d.rel as release,
    e.actor_id as actor,
    af.company_name as company,
    row_number() over actors_by_activity as rank,
    count(distinct e.id) as events
  from
    dates d,
    gha_events e
  left join
    gha_actors_affiliations af
  on
    e.actor_id = af.actor_id
    and af.dt_from <= e.created_at
    and af.dt_to > e.created_at
    and af.company_name != 'Independent'
    and af.company_name != ''
  where
    e.created_at >= d.f
    and e.created_at < d.t
    and (lower(e.dup_actor_login) {{exclude_bots}})
    and e.type = 'PullRequestReviewCommentEvent'
  group by
    d.f,
    d.t,
    d.rel,
    e.actor_id,
    af.company_name
  window
    actors_by_activity as (
      partition by
        d.rel
      order by
        count(distinct e.id) desc
    )
  ) sub
where
  sub.rank <= (select n from n)
), top_reviewers_companies as (
select sub.date_from,
  sub.date_to,
  sub.release,
  sub.company,
  sub.rank,
  sub.events
from (
  select d.f as date_from,
    d.t as date_to,
    d.rel as release,
    af.company_name as company,
    row_number() over companies_by_activity as rank,
    count(distinct e.id) as events
  from
    dates d,
    gha_events e,
    gha_actors_affiliations af
  where
    e.actor_id = af.actor_id
    and af.dt_from <= e.created_at
    and af.dt_to > e.created_at
    and af.company_name != 'Independent'
    and e.created_at >= d.f
    and e.created_at < d.t
    and (lower(e.dup_actor_login) {{exclude_bots}})
    and e.type = 'PullRequestReviewCommentEvent'
    and af.company_name != ''
  group by
    d.f,
    d.t,
    d.rel,
    af.company_name
  window
    companies_by_activity as (
      partition by
        d.rel
      order by
        count(distinct e.id) desc
    )
  ) sub
where
  sub.rank <= (select n from n)
), top_commenters as (
select sub.date_from,
  sub.date_to,
  sub.release,
  sub.actor,
  sub.company,
  sub.rank,
  sub.events
from (
  select d.f as date_from,
    d.t as date_to,
    d.rel as release,
    e.actor_id as actor,
    af.company_name as company,
    row_number() over actors_by_activity as rank,
    count(distinct e.id) as events
  from
    dates d,
    gha_events e
  left join
    gha_actors_affiliations af
  on
    e.actor_id = af.actor_id
    and af.dt_from <= e.created_at
    and af.dt_to > e.created_at
    and af.company_name != 'Independent'
    and af.company_name != ''
  where
    e.created_at >= d.f
    and e.created_at < d.t
    and (lower(e.dup_actor_login) {{exclude_bots}})
    and e.type in ('CommitCommentEvent', 'IssueCommentEvent')
  group by
    d.f,
    d.t,
    d.rel,
    e.actor_id,
    af.company_name
  window
    actors_by_activity as (
      partition by
        d.rel
      order by
        count(distinct e.id) desc
    )
  ) sub
where
  sub.rank <= (select n from n)
), top_commenters_companies as (
select sub.date_from,
  sub.date_to,
  sub.release,
  sub.company,
  sub.rank,
  sub.events
from (
  select d.f as date_from,
    d.t as date_to,
    d.rel as release,
    af.company_name as company,
    row_number() over companies_by_activity as rank,
    count(distinct e.id) as events
  from
    dates d,
    gha_events e,
    gha_actors_affiliations af
  where
    e.actor_id = af.actor_id
    and af.dt_from <= e.created_at
    and af.dt_to > e.created_at
    and af.company_name != 'Independent'
    and e.created_at >= d.f
    and e.created_at < d.t
    and (lower(e.dup_actor_login) {{exclude_bots}})
    and e.type in ('CommitCommentEvent', 'IssueCommentEvent')
    and af.company_name != ''
  group by
    d.f,
    d.t,
    d.rel,
    af.company_name
  window
    companies_by_activity as (
      partition by
        d.rel
      order by
        count(distinct e.id) desc
    )
  ) sub
where
  sub.rank <= (select n from n)
), contributors_summary as (
  select string_agg(a.login, ',' order by tc.rank) as top_actors,
    (select string_agg(c, ',') from unnest(pg_temp.array_uniq_stable(array_agg(tc.company order by tc.rank))) t(c)) as top_companies,
    (select count(*) filter (where c is not null) from unnest(pg_temp.array_uniq_stable(array_agg(tc.company order by tc.rank))) t(c)) as n_top_companies,
    sum(tc.events) as events,
    d.rel as rel
  from
    dates d,
    top_contributors tc,
    gha_actors a
  where
    d.f = tc.date_from
    and d.t = tc.date_to
    and tc.actor = a.id
  group by
    d.rel
), contributors_companies_summary as (
  select string_agg(tcc.company, ',' order by tcc.rank) as top_companies,
    sum(tcc.events) as events,
    d.rel as rel
  from
    dates d,
    top_contributors_companies tcc
  where
    d.f = tcc.date_from
    and d.t = tcc.date_to
  group by
    d.rel
), committers_summary as (
  select string_agg(a.login, ',' order by tc.rank) as top_actors,
    (select string_agg(c, ',') from unnest(pg_temp.array_uniq_stable(array_agg(tc.company order by tc.rank))) t(c)) as top_companies,
    (select count(*) filter (where c is not null) from unnest(pg_temp.array_uniq_stable(array_agg(tc.company order by tc.rank))) t(c)) as n_top_companies,
    sum(tc.events) as events,
    d.rel as rel
  from
    dates d,
    top_committers tc,
    gha_actors a
  where
    d.f = tc.date_from
    and d.t = tc.date_to
    and tc.actor = a.id
  group by
    d.rel
), committers_companies_summary as (
  select string_agg(tcc.company, ',' order by tcc.rank) as top_companies,
    sum(tcc.events) as events,
    d.rel as rel
  from
    dates d,
    top_committers_companies tcc
  where
    d.f = tcc.date_from
    and d.t = tcc.date_to
  group by
    d.rel
), issuers_summary as (
  select string_agg(a.login, ',' order by ti.rank) as top_actors,
    (select string_agg(c, ',') from unnest(pg_temp.array_uniq_stable(array_agg(ti.company order by ti.rank))) t(c)) as top_companies,
    (select count(*) filter (where c is not null) from unnest(pg_temp.array_uniq_stable(array_agg(ti.company order by ti.rank))) t(c)) as n_top_companies,
    sum(ti.events) as events,
    d.rel as rel
  from
    dates d,
    top_issuers ti,
    gha_actors a
  where
    d.f = ti.date_from
    and d.t = ti.date_to
    and ti.actor = a.id
  group by
    d.rel
), issuers_companies_summary as (
  select string_agg(tic.company, ',' order by tic.rank) as top_companies,
    sum(tic.events) as events,
    d.rel as rel
  from
    dates d,
    top_issuers_companies tic
  where
    d.f = tic.date_from
    and d.t = tic.date_to
  group by
    d.rel
), prs_summary as (
  select string_agg(a.login, ',' order by tpr.rank) as top_actors,
    (select string_agg(c, ',') from unnest(pg_temp.array_uniq_stable(array_agg(tpr.company order by tpr.rank))) t(c)) as top_companies,
    (select count(*) filter (where c is not null) from unnest(pg_temp.array_uniq_stable(array_agg(tpr.company order by tpr.rank))) t(c)) as n_top_companies,
    sum(tpr.events) as events,
    d.rel as rel
  from
    dates d,
    top_prs tpr,
    gha_actors a
  where
    d.f = tpr.date_from
    and d.t = tpr.date_to
    and tpr.actor = a.id
  group by
    d.rel
), prs_companies_summary as (
  select string_agg(tpc.company, ',' order by tpc.rank) as top_companies,
    sum(tpc.events) as events,
    d.rel as rel
  from
    dates d,
    top_prs_companies tpc
  where
    d.f = tpc.date_from
    and d.t = tpc.date_to
  group by
    d.rel
), reviewers_summary as (
  select string_agg(a.login, ',' order by tr.rank) as top_actors,
    (select string_agg(c, ',') from unnest(pg_temp.array_uniq_stable(array_agg(tr.company order by tr.rank))) t(c)) as top_companies,
    (select count(*) filter (where c is not null) from unnest(pg_temp.array_uniq_stable(array_agg(tr.company order by tr.rank))) t(c)) as n_top_companies,
    sum(tr.events) as events,
    d.rel as rel
  from
    dates d,
    top_reviewers tr,
    gha_actors a
  where
    d.f = tr.date_from
    and d.t = tr.date_to
    and tr.actor = a.id
  group by
    d.rel
), reviewers_companies_summary as (
  select string_agg(trc.company, ',' order by trc.rank) as top_companies,
    sum(trc.events) as events,
    d.rel as rel
  from
    dates d,
    top_reviewers_companies trc
  where
    d.f = trc.date_from
    and d.t = trc.date_to
  group by
    d.rel
), commenters_summary as (
  select string_agg(a.login, ',' order by tc.rank) as top_actors,
    (select string_agg(c, ',') from unnest(pg_temp.array_uniq_stable(array_agg(tc.company order by tc.rank))) t(c)) as top_companies,
    (select count(*) filter (where c is not null) from unnest(pg_temp.array_uniq_stable(array_agg(tc.company order by tc.rank))) t(c)) as n_top_companies,
    sum(tc.events) as events,
    d.rel as rel
  from
    dates d,
    top_commenters tc,
    gha_actors a
  where
    d.f = tc.date_from
    and d.t = tc.date_to
    and tc.actor = a.id
  group by
    d.rel
), commenters_companies_summary as (
  select string_agg(tcc.company, ',' order by tcc.rank) as top_companies,
    sum(tcc.events) as events,
    d.rel as rel
  from
    dates d,
    top_commenters_companies tcc
  where
    d.f = tcc.date_from
    and d.t = tcc.date_to
  group by
    d.rel
)
select
  sub.*,
  sub.contributions / sub.days as contributions_per_day,
  sub.pushes / sub.days as pushes_per_day,
  sub.issue_evs / sub.days as issue_evs_per_day,
  sub.pr_evs / sub.days as pr_evs_per_day,
  sub.pr_reviews / sub.days as pr_reviews_per_day,
  sub.comment_evs / sub.days as comment_evs_per_day,
  (select top_actors from contributors_summary where rel = sub.release) as top_contributors,
  (select top_companies from contributors_summary where rel = sub.release) as top_contributors_coms,
  (select n_top_companies from contributors_summary where rel = sub.release) as n_top_contributing_coms,
  (select events from contributors_summary where rel = sub.release) as top_contributions,
  (select (100.0 * events) / sub.contributions from contributors_summary where rel = sub.release) as top_contributions_perc,
  (select top_companies from contributors_companies_summary where rel = sub.release) as top_contributing_coms,
  (select events from contributors_companies_summary where rel = sub.release) as top_comp_contributions,
  (select (100.0 * events) / sub.contributions from contributors_companies_summary where rel = sub.release) as top_comp_contributions_perc,
  (select top_actors from committers_summary where rel = sub.release) as top_committers,
  (select top_companies from committers_summary where rel = sub.release) as top_committers_coms,
  (select n_top_companies from committers_summary where rel = sub.release) as n_top_committing_coms,
  (select events from committers_summary where rel = sub.release) as top_commits,
  (select (100.0 * events) / sub.pushes from committers_summary where rel = sub.release) as top_commits_perc,
  (select top_companies from committers_companies_summary where rel = sub.release) as top_committing_coms,
  (select events from committers_companies_summary where rel = sub.release) as top_comp_commits,
  (select (100.0 * events) / sub.pushes from committers_companies_summary where rel = sub.release) as top_comp_commits_perc,
  (select top_actors from issuers_summary where rel = sub.release) as top_issuers,
  (select top_companies from issuers_summary where rel = sub.release) as top_issuers_coms,
  (select n_top_companies from issuers_summary where rel = sub.release) as n_top_issuers_coms,
  (select events from issuers_summary where rel = sub.release) as top_issues,
  (select (100.0 * events) / sub.issue_evs from issuers_summary where rel = sub.release) as top_issues_perc,
  (select top_companies from issuers_companies_summary where rel = sub.release) as top_issuing_coms,
  (select events from issuers_companies_summary where rel = sub.release) as top_comp_issues,
  (select (100.0 * events) / sub.issue_evs from issuers_companies_summary where rel = sub.release) as top_comp_issues_perc,
  (select top_actors from prs_summary where rel = sub.release) as top_pr_creators,
  (select top_companies from prs_summary where rel = sub.release) as top_pr_creators_coms,
  (select n_top_companies from prs_summary where rel = sub.release) as n_top_pr_creators_coms,
  (select events from prs_summary where rel = sub.release) as top_prs,
  (select (100.0 * events) / sub.pr_evs from prs_summary where rel = sub.release) as top_prs_perc,
  (select top_companies from prs_companies_summary where rel = sub.release) as top_pr_creating_coms,
  (select events from prs_companies_summary where rel = sub.release) as top_comp_prs,
  (select (100.0 * events) / sub.pr_evs from prs_companies_summary where rel = sub.release) as top_comp_prs_perc,
  (select top_actors from reviewers_summary where rel = sub.release) as top_reviewers,
  (select top_companies from reviewers_summary where rel = sub.release) as top_reviewers_coms,
  (select n_top_companies from reviewers_summary where rel = sub.release) as n_top_reviewers_coms,
  (select events from reviewers_summary where rel = sub.release) as top_reviews,
  (select (100.0 * events) / sub.pr_reviews from reviewers_summary where rel = sub.release) as top_reviews_perc,
  (select top_companies from reviewers_companies_summary where rel = sub.release) as top_reviewing_coms,
  (select events from reviewers_companies_summary where rel = sub.release) as top_comp_reviews,
  (select (100.0 * events) / sub.pr_reviews from reviewers_companies_summary where rel = sub.release) as top_comp_reviews_perc,
  (select top_actors from commenters_summary where rel = sub.release) as top_commenters,
  (select top_companies from commenters_summary where rel = sub.release) as top_commenters_coms,
  (select n_top_companies from commenters_summary where rel = sub.release) as n_top_commenters_coms,
  (select events from commenters_summary where rel = sub.release) as top_comments,
  (select (100.0 * events) / sub.comment_evs from commenters_summary where rel = sub.release) as top_comments_perc,
  (select top_companies from commenters_companies_summary where rel = sub.release) as top_commenting_coms,
  (select events from commenters_companies_summary where rel = sub.release) as top_comp_comments,
  (select (100.0 * events) / sub.comment_evs from commenters_companies_summary where rel = sub.release) as top_comp_comments_perc
from (
  select
    d.ord as ord,
    d.f as date_from,
    d.t as date_to,
    d.rel as release,
    date_part('day', d.t - d.f) as days,
    count(e.id) filter (where e.type in ('PushEvent', 'PullRequestEvent', 'IssuesEvent')) as contributions,
    count(e.id) filter (where e.type = 'PushEvent') as pushes,
    count(e.id) filter (where e.type = 'IssuesEvent') as issue_evs,
    count(e.id) filter (where e.type = 'PullRequestEvent') as pr_evs,
    count(e.id) filter (where e.type = 'PullRequestReviewCommentEvent') as pr_reviews,
    count(e.id) filter (where e.type in ('CommitCommentEvent', 'IssueCommentEvent')) as comment_evs,
    count(distinct e.actor_id) filter (where e.type in ('PushEvent', 'PullRequestEvent', 'IssuesEvent')) as contributors,
    count(distinct e.actor_id) filter (where e.type = 'PushEvent') as committers,
    count(distinct e.actor_id) filter (where e.type = 'IssuesEvent') as issuers,
    count(distinct e.actor_id) filter (where e.type = 'PullRequestEvent') as pr_creators,
    count(distinct e.actor_id) filter (where e.type = 'PullRequestReviewCommentEvent') as pr_reviewers,
    count(distinct e.actor_id) filter (where e.type in ('CommitCommentEvent', 'IssueCommentEvent')) as commenters,
    count(distinct af.company_name) filter (where e.type in ('PushEvent', 'PullRequestEvent', 'IssuesEvent') and af.company_name is not null) as contributing_coms,
    count(distinct af.company_name) filter (where e.type = 'PushEvent' and af.company_name is not null) as committing_coms,
    count(distinct af.company_name) filter (where e.type = 'IssuesEvent' and af.company_name is not null) as issuers_coms,
    count(distinct af.company_name) filter (where e.type = 'PullRequestEvent' and af.company_name is not null) as pr_creating_coms,
    count(distinct af.company_name) filter (where e.type = 'PullRequestReviewCommentEvent' and af.company_name is not null) as pr_reviewing_coms,
    count(distinct af.company_name) filter (where e.type in ('CommitCommentEvent', 'IssueCommentEvent') and af.company_name is not null) as commenting_coms
  from
    dates d,
    gha_events e
  left join
    gha_actors_affiliations af
  on
    e.actor_id = af.actor_id
    and af.dt_from <= e.created_at
    and af.dt_to > e.created_at
    and af.company_name != 'Independent'
    and af.company_name != ''
  where
    e.created_at >= d.f
    and e.created_at < d.t
    and (lower(e.dup_actor_login) {{exclude_bots}})
    and e.type in (
      'PushEvent', 'PullRequestEvent', 'IssuesEvent',
      'PullRequestReviewCommentEvent',
      'CommitCommentEvent', 'IssueCommentEvent'
    )
  group by
    d.ord,
    d.f,
    d.t,
    d.rel
  ) sub
order by
  sub.ord
;
drop function if exists pg_temp.array_uniq_stable(anyarray);
