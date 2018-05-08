select
  concat('rev_per_usr,', dup_actor_login, '`All') as repo_user,
  round(count(id) / {{n}}, 2) as result
from
  gha_events
where
  created_at >= '{{from}}'
  and created_at < '{{to}}'
  and type in ('PullRequestReviewCommentEvent')
  and dup_actor_login in (select reviewers_name from treviewers)
group by
  dup_actor_login
union select 'rev_per_usr,' || concat(dup_actor_login, '`', dup_repo_name) as repo_user,
  round(count(id) / {{n}}, 2) as result
from
  gha_events
where
  type in ('PullRequestReviewCommentEvent')
  and created_at >= '{{from}}'
  and created_at < '{{to}}'
  and dup_actor_login in (select reviewers_name from treviewers)
group by
  repo_user
order by
  result desc,
  repo_user asc
;
