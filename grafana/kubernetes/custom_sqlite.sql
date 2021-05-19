delete from dashboard_tag where dashboard_id = (select id from dashboard where slug = 'dashboards');

insert into dashboard_tag(dashboard_id, term) values((select id from dashboard where slug = 'dashboards'), 'home');
insert into dashboard_tag(dashboard_id, term) values((select id from dashboard where slug = 'dashboards'), 'all');
insert into dashboard_tag(dashboard_id, term) values((select id from dashboard where slug = 'dashboards'), 'kubernetes');

update dashboard set id = 1001 where slug = 'community-sizing-and-health-assessment';
update dashboard set id = 1002 where slug = 'contributor-statistics';
update dashboard set id = 1003 where slug = 'issue-velocity';
update dashboard set id = 1004 where slug = 'pr-velocity';
update dashboard set id = 1005 where slug = 'other';

update
  dashboard
set
  is_folder = 1
where
  slug in (
    'pr-velocity',
    'community-sizing-and-health-assessment',
    'issue-velocity',
    'contributor-statistics',
    'other'
  )
;

update
  dashboard
set
  folder_id = (
    select
      id
    from
      dashboard
    where
      slug = 'community-sizing-and-health-assessment'
  )
where
  slug in (
    'companies-contributing-in-repository-groups',
    'companies-table',
    'company-statistics-by-repository-group',
    'countries-stats',
    'github-stats-by-repository',
    'github-stats-by-repository-group',
    'overall-project-statistics',
    'stars-and-forks-by-repository',
    'timezones-stats'
  )
;

update
  dashboard
set
  folder_id = (
    select
      id
    from
      dashboard
    where
      slug = 'contributor-statistics'
  )
where
  slug in (
    'bot-commands-repository-groups',
    'company-prs-in-repository-groups',
    'developer-activity-counts-by-repository-group',
    'developer-activity-counts-by-companies',
    'new-and-episodic-pr-contributors',
    'new-contributors',
    'pr-reviews-by-contributor',
    'prs-authors-repository-groups',
    'sig-mentions',
    'contributions-chart'
  )
;

update
  dashboard
set
  folder_id = (
    select
      id
    from
      dashboard
    where
      slug = 'issue-velocity'
  )
where
  slug in (
    'issues-age-by-sig-and-repository-groups',
    'issues-opened-closed-by-sig',
    'new-and-episodic-issue-creators',
    'inactive-issues-by-sig',
    'inactive-issues-by-sig-and-repository'
  )
;

update
  dashboard
set
  folder_id = (
    select
      id
    from
      dashboard
    where
      slug = 'pr-velocity'
  )
where
  slug in (
    'blocked-prs-repository-groups',
    'open-issues-prs-by-milestone-and-repository',
    'open-pr-age-by-repository-group',
    'pr-comments',
    'pr-time-to-approve-and-merge',
    'pr-time-to-engagement',
    'pr-workload-per-sig-chart',
    'pr-workload-per-sig-table',
    'pr-workload-per-sig-and-repository-chart',
    'prs-approval-repository-groups',
    'prs-labels-repository-groups',
    'prs-labels-repositories',
    'prs-opened-by-sig',
    'awaiting-prs-by-sig',
    'awaiting-prs-by-sig-and-repository',
    'prs-labels-by-sig',
    'inactive-prs-by-sig',
    'inactive-prs-by-sig-and-repository'
  )
;

update
  dashboard
set
  folder_id = (
    select
      id
    from
      dashboard
    where
      slug = 'other'
  )
where
  slug in (
    'repository-groups',
    'licenses-and-programming-languages'
  )
;

select id, uid, folder_id, is_folder, slug, title from dashboard;
