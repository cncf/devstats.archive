# Variable table

- Data in those tables can change between GitHub events, and `event_id` is a part of this tables primary key.
- They represent different state of a given object at the time of a given GitHub event `event_id`.
- For example PRs/Issues can change labels, be closed/merged/reopened, repositories can have different numbers of stars, forks, watchers etc.
