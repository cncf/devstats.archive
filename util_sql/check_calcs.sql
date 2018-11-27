select
  proj,
  dt,
  msg
from
  gha_logs
where
  proj != 'contrib'
  and msg like 'Calculate%, period {{period}}, %'
order by
  dt desc
;
