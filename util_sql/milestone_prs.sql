select
  state,
  count(*) as count
from
  current_state.prs
where
  milestone='{{milestone}}'
  and repo_name = 'kubernetes/kubernetes'
group by
  state
order by
  state
;
