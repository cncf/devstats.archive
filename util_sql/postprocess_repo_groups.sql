-- 'Cluster lifecycle': include `cmd/kubeadm` and `cluster` in `kubernetes/kubernetes`.
update
  gha_events_commits_files
set
  repo_group = 'Cluster lifecycle'
where
  repo_group is null
  and (
    path like 'kubernetes/kubernetes/cmd/kubeadm/%'
    or path like 'kubernetes/kubernetes/cluster/%'
  )
;

update
  gha_events_commits_files
set
  repo_group = 'Cluster lifecycle'
where
  repo_group is null
  and event_id in (
    select
      event_id
    from
      gha_comments
    where
      dup_repo_name = 'kubernetes/kubernetes'
      and (
        path like 'cmd/kubeadm/%'
        or path like 'cluster/%'
      )
  )
;
