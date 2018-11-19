with projects as (
  select distinct period as project,
    repo,
    last_value(time) over projects_by_time as last_release_date,
    last_value(title) over projects_by_time as last_release_tag,
    last_value(description) over projects_by_time as last_release_desc
  from
    sannotations_shared
  window
    projects_by_time as (
      partition by period
      order by
        time asc
      range between unbounded preceding
      and unbounded following
    )
)
select
  'phealth;' || project || ';ltag,ldate,ldesc' as name,
  'Last release',
  last_release_date,
  0.0,
  last_release_tag,
  'Last release date',
  last_release_date,
  0.0,
  to_char(last_release_date, 'MM/DD/YYYY'),
  'Last release description',
  last_release_date,
  0.0,
  last_release_desc
from
  projects
;
/*
select
  'phealth,' || project || ',ltag' as name,
  'Last release',
  last_release_date,
  0.0,
  last_release_tag
from
  projects
union select
  'phealth,' || project || ',ldate' as name,
  'Last release date',
  last_release_date,
  0.0,
  to_char(last_release_date, 'MM/DD/YYYY')
from
  projects
union select
  'phealth,' || project || ',ldesc' as name,
  'Last release description',
  last_release_date,
  0.0,
  last_release_desc
from
  projects
*/
