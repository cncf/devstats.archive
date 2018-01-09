-- 'Cluster lifecycle': include `cmd/kubeadm` and `cluster` in `kubernetes/kubernetes`.
update
  gha_events_commits_files
set
  repo_group = 'Cluster lifecycle'
where
  path like 'kubernetes/kubernetes/cmd/kubeadm/%'
  or path like 'kubernetes/kubernetes/cluster/%'
;
