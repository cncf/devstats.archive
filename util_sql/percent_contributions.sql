select
  i.company,
  i.contributions
from (
  select
    coalesce(af.company_name, 'Unknown') as company,
    count(distinct e.id) as contributions,
    count(distinct a.id) as contributors
  from
    gha_actors a,
    gha_events e
  left join
    gha_actors_affiliations af
  on
    e.actor_id = af.actor_id
    and af.dt_from <= e.created_at
    and af.dt_to > e.created_at
  where
    e.actor_id = a.id
    and (lower(a.login) {{exclude_bots}})
    and e.type in ('IssuesEvent', 'PullRequestEvent', 'PushEvent', 'CommitCommentEvent', 'IssueCommentEvent', 'PullRequestReviewCommentEvent')
  group by
    coalesce(af.company_name, 'Unknown')
) i
order by
  i.contributions desc,
  i.company asc
;
