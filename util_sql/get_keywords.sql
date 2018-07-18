select
  to_char(dt, 'YYYY-MM-DD HH24:MI:SS.US') as dt,
  to_char(run_dt, 'YYYY-MM-DD HH24:MI:SS.US') as run_dt,
  proj,
  prog,
  msg
from
  gha_logs
where
  lower(msg) like '%{{msg}}%'
order by
  dt desc
;
