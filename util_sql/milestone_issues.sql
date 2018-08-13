select
  state,
  count(*) as count 
from
  current_state.issues
where
  milestone='{{milestone}}'
  and is_pull_request = false
  and repo_name = 'kubernetes/kubernetes'
group by
  state
order by
  state
;

