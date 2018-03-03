select
  proj,
  prog,
  dt,
  msg
from
  gha_logs
order by
  dt desc
limit
  {{lim}};
