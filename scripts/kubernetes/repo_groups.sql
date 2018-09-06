-- Add repository groups

update gha_repos set repo_group = 'Kubernetes' where name in (
  'kubernetes/kubernetes',
  'GoogleCloudPlatform/kubernetes',
  'kubernetes'
);

update gha_repos set repo_group = 'CSI' where org_login = 'kubernetes-csi';

update gha_repos set repo_group = 'Contrib' where name in (
  'kubernetes/contrib'
);

update gha_repos set repo_group = 'API machinery' where name in (
  'kubernetes/api',
  'kubernetes/apiextensions-apiserver',
  'kubernetes/apimachinery',
  'kubernetes/apiserver',
  'kubernetes/code-generator',
  'kubernetes/gengo',
  'kubernetes-incubator/apiserver-builder',
  'kubernetes/kube-aggregator',
  'kubernetes/kube-openapi',
  'kubernetes/sample-apiserver'
);

update gha_repos set repo_group = 'Clients' where name in (
  'kubernetes-client',
  'kubernetes-client/community',
  'kubernetes-client/csharp',
  'kubernetes-client/gen',
  'kubernetes-client/go',
  'kubernetes/client-go',
  'kubernetes-client/go-base',
  'kubernetes-client/java',
  'kubernetes-client/javascript',
  'kubernetes-client/python-base',
  'kubernetes-client/ruby',
  'kubernetes-client/typescript',
  'kubernetes-incubator/client-python'
);

update gha_repos set repo_group = 'Apps' where name in (
  'kubernetes/kubectl',
  'kubernetes/application-images',
  'kubernetes/examples',
  'kubernetes-incubator/kompose'
);

update gha_repos set repo_group = 'Autoscaling and monitoring' where name in (
  'kubernetes/autoscaler',
  'kubernetes/horizontal-self-scaler',
  'kubernetes-incubator/cluster-proportional-vertical-autoscaler',
  'kubernetes/heapster',
  'kubernetes-incubator/custom-metrics-apiserver',
  'kubernetes-incubator/metrics-server',
  'kubernetes/kube-state-metrics',
  'kubernetes/metrics'
);

update gha_repos set repo_group = 'Networking' where name in (
  'kubernetes/dns',
  'kubernetes-incubator/external-dns',
  'kubernetes-incubator/ip-masq-agent',
  'kubernetes/ingress'
);

update gha_repos set repo_group = 'Storage' where name in (
  'kubernetes-incubator/external-storage',
  'kubernetes-incubator/nfs-provisioner'
);

update gha_repos set repo_group = 'Multi-cluster' where name in (
  'kubernetes/cluster-registry'
);

update gha_repos set repo_group = 'Project' where name in (
  'kubernetes/community',
  'kubernetes/features',
  'kubernetes/sig-release',
  'kubernetes/steering'
);

update gha_repos set repo_group = 'Node' where name in (
  'kubernetes/frakti',
  'kubernetes-incubator/cri-containerd',
  'kubernetes-incubator/cri-tools',
  'kubernetes-incubator/ocid',
  'kubernetes-incubator/node-feature-discovery',
  'kubernetes/node-problem-detector',
  'kubernetes/ocid',
  'kubernetes/rktlet'
);

update gha_repos set repo_group = 'Cluster lifecycle' where name in (
  'kubernetes-incubator/kargo',
  'kubernetes-incubator/kubespray',
  'kubernetes-incubator/kube-aws',
  'kubernetes-incubator/kube-mesos-framework',
  'kubernetes/kops',
  'kubernetes/kubeadm',
  'kubernetes-incubator/bootkube',
  'kubernetes/kubernetes-anywhere',
  'kubernetes/kube-deploy',
  'kubernetes/minikube'
);

update gha_repos set repo_group = 'Project infra' where name in (
  'kubernetes/k8s.io',
  'kubernetes/kubernetes-template-project',
  'kubernetes/perf-tests',
  'kubernetes/pr-bot',
  'kubernetes/release',
  'kubernetes/repo-infra',
  'kubernetes-incubator/spartakus',
  'kubernetes/test-infra',
  'kubernetes/utils'
);

update gha_repos set repo_group = 'UI' where name in (
  'kubernetes/dashboard',
  'kubernetes/kubedash',
  'kubernetes/kube-ui'
);

update gha_repos set repo_group = 'Misc' where name in (
  'kubernetes-incubator/cluster-capacity',
  'kubernetes-incubator/kube-arbitrator',
  'kubernetes/git-sync',
  'kubernetes/kube2consul'
);

update gha_repos set repo_group = 'Docs' where name in (
  'kubernetes/kubernetes.github.io',
  'kubernetes/kubernetes-docs-cn',
  'kubernetes-incubator/reference-docs',
  'kubernetes/kubernetes-bootcamp',
  'kubernetes/md-format'
);

update gha_repos set repo_group = 'SIG Service Catalog' where name in (
  'kubernetes-incubator/service-catalog'
);

-- By default alias is the newest repo name for given repo ID
update
  gha_repos r
set
  alias = coalesce((
    select e.dup_repo_name
    from
      gha_events e
    where
      e.repo_id = r.id
    order by
      e.created_at desc
    limit 1
  ), name)
;

update gha_repos set alias = 'kubernetes/kubernetes' where name like '%kubernetes' or name = 'kubernetes/';

select
  repo_group,
  count(*) as number_of_repos
from
  gha_repos
where
  repo_group is not null
group by
  repo_group
order by
  number_of_repos desc,
  repo_group asc;

