-- 'Cluster lifecycle': include `cmd/kubeadm` and `cluster` in `kubernetes/kubernetes`.

-- Update by commit files
update
  gha_events_commits_files
set
  repo_group = 'SIG Cluster Lifecycle'
where
  repo_group is null
  and (
    path like 'kubernetes/kubernetes/cmd/kubeadm/%'
    or path like 'kubernetes/kubernetes/cluster/%'
  )
;

-- Next update by PR review files
update
  gha_events_commits_files
set
  repo_group = 'SIG Cluster Lifecycle'
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
