select
  *
from
  gha_actors_emails
where
  email in (
    select email
    from gha_actors_emails
    group by email
    having count(actor_id) > 1
  )
order by
  email asc,
  actor_id asc;
