-- Add repository groups

update gha_repos set repo_group = 'Kubernetes' where name in (
  'kubernetes/kubernetes',
  'GoogleCloudPlatform/kubernetes',
  'kubernetes',
  'kubernetes/'
);

update gha_repos set repo_group = 'SIG API Machinery' where name in (
  'kubernetes-client/csharp',
  'kubernetes-client/gen',
  'kubernetes-client/go',
  'kubernetes-client/go-base',
  'kubernetes-client/haskell',
  'kubernetes-client/java',
  'kubernetes-client/javascript',
  'kubernetes-client/perl',
  'kubernetes-client/python-base',
  'kubernetes-client/ruby',
  'kubernetes-incubator/apiserver-builder-alpha',
  'kubernetes-incubator/client-python',
  'kubernetes-sigs/controller-runtime',
  'kubernetes-sigs/controller-tools',
  'kubernetes-sigs/kube-storage-version-migrator',
  'kubernetes-sigs/kubebuilder',
  'kubernetes-sigs/kubebuilder-declarative-pattern',
  'kubernetes-sigs/legacyflag',
  'kubernetes-sigs/structured-merge-diff',
  'kubernetes-sigs/yaml',
  'kubernetes/gengo',
  'kubernetes/kube-openapi'
);

update gha_repos set repo_group = 'SIG Apps' where name in (
  'kubernetes-sigs/application',
  'kubernetes/examples',
  'kubernetes/kompose'
);

update gha_repos set repo_group = 'SIG Architecture' where name in (
  'kubernetes/klog',
  'kubernetes/utils'
);

update gha_repos set repo_group = 'SIG Auth' where name in (
  'kubernetes-sigs/multi-tenancy'
);

update gha_repos set repo_group = 'SIG Autoscaling' where name in (
  'kubernetes-incubator/cluster-proportional-autoscaler',
  'kubernetes-incubator/cluster-proportional-vertical-autoscaler',
  'kubernetes/autoscaler'
);

update gha_repos set repo_group = 'SIG AWS' where name in (
  'kubernetes-sigs/aws-alb-ingress-controller',
  'kubernetes-sigs/aws-ebs-csi-driver',
  'kubernetes-sigs/aws-efs-csi-driver',
  'kubernetes-sigs/aws-encryption-provider',
  'kubernetes-sigs/aws-fsx-csi-driver',
  'kubernetes-sigs/aws-iam-authenticator',
  'kubernetes/cloud-provider-aws'
);

update gha_repos set repo_group = 'SIG Azure' where name in (
  'kubernetes-sigs/azuredisk-csi-driver',
  'kubernetes-sigs/azurefile-csi-driver',
  'kubernetes-sigs/cluster-api-provider-azure',
  'kubernetes/cloud-provider-azure'
);

update gha_repos set repo_group = 'SIG CLI' where name in (
  'kubernetes-sigs/cli-experimental',
  'kubernetes-sigs/krew',
  'kubernetes-sigs/krew-index',
  'kubernetes-sigs/kustomize',
  'kubernetes/kubectl'
);

update gha_repos set repo_group = 'SIG Cloud Provider' where name in (
  'kubernetes-sigs/apiserver-network-proxy',
  'kubernetes/cloud-provider-alibaba-cloud',
  'kubernetes/cloud-provider-gcp',
  'kubernetes/cloud-provider-openstack',
  'kubernetes/cloud-provider-sample',
  'kubernetes/cloud-provider-vsphere',
  'kubernetes/legacy-cloud-providers'
);

update gha_repos set repo_group = 'SIG Cluster Lifecycle' where name in (
  'kubernetes-incubator/bootkube',
  'kubernetes-incubator/kube-aws',
  'kubernetes-sigs/addon-operators',
  'kubernetes-sigs/cluster-api',
  'kubernetes-sigs/cluster-api-provider-aws',
  'kubernetes-sigs/cluster-api-provider-digitalocean',
  'kubernetes-sigs/cluster-api-provider-gcp',
  'kubernetes-sigs/cluster-api-provider-openstack',
  'kubernetes-sigs/etcdadm',
  'kubernetes-sigs/kubeadm-dind-cluster',
  'kubernetes-sigs/kubespray',
  'kubernetes/kops',
  'kubernetes/kube-deploy',
  'kubernetes/kubeadm',
  'kubernetes/kubernetes-anywhere',
  'kubernetes/minikube'
);

update gha_repos set repo_group = 'SIG Contributor Experience' where name in (
  'kubernetes-sigs/contributor-playground',
  'kubernetes-sigs/contributor-site',
  'kubernetes-sigs/slack-infra',
  'kubernetes/community',
  'kubernetes/k8s.io',
  'kubernetes/org',
  'kubernetes/repo-infra'
);

update gha_repos set repo_group = 'SIG Docs' where name in (
  'kubernetes-incubator/reference-docs',
  'kubernetes/website'
);

update gha_repos set repo_group = 'SIG GCP' where name in (
  'kubernetes-sigs/gcp-compute-persistent-disk-csi-driver',
  'kubernetes-sigs/gcp-filestore-csi-driver'
);

update gha_repos set repo_group = 'SIG Instrumentation' where name in (
  'kubernetes-incubator/custom-metrics-apiserver',
  'kubernetes-incubator/metrics-server',
  'kubernetes-sigs/mutating-trace-admission-controller',
  'kubernetes/heapster',
  'kubernetes/kube-state-metrics'
);

update gha_repos set repo_group = 'SIG Multicluster' where name in (
  'GoogleCloudPlatform/k8s-multicluster-ingress',
  'kubernetes-sigs/federation-v2',
  'kubernetes/cluster-registry',
  'kubernetes/federation'
);

update gha_repos set repo_group = 'SIG Network' where name in (
  'kubernetes-incubator/external-dns',
  'kubernetes-incubator/ip-masq-agent',
  'kubernetes/dns',
  'kubernetes/ingress-gce',
  'kubernetes/ingress-nginx'
);

update gha_repos set repo_group = 'SIG Node' where name in (
  'kubernetes-incubator/rktlet',
  'kubernetes-sigs/cri-o',
  'kubernetes-sigs/cri-tools',
  'kubernetes-sigs/node-feature-discovery',
  'kubernetes/frakti',
  'kubernetes/node-problem-detector'
);

update gha_repos set repo_group = 'SIG PM' where name in (
  'kubernetes/enhancements'
);

update gha_repos set repo_group = 'SIG Release' where name in (
  'kubernetes-sigs/k8s-container-image-promoter',
  'kubernetes/publishing-bot',
  'kubernetes/release',
  'kubernetes/sig-release'
);

update gha_repos set repo_group = 'SIG Scalability' where name in (
  'kubernetes/perf-tests'
);

update gha_repos set repo_group = 'SIG Scheduling' where name in (
  'kubernetes-incubator/cluster-capacity',
  'kubernetes-incubator/descheduler',
  'kubernetes-sigs/kube-batch',
  'kubernetes-sigs/poseidon'
);

update gha_repos set repo_group = 'SIG Service Catalog' where name in (
  'kubernetes-incubator/service-catalog'
);

update gha_repos set repo_group = 'SIG Storage' where name in (
  'kubernetes-csi/cluster-driver-registrar',
  'kubernetes-csi/csi-driver-flex',
  'kubernetes-csi/csi-driver-host-path',
  'kubernetes-csi/csi-driver-image-populator',
  'kubernetes-csi/csi-driver-iscsi',
  'kubernetes-csi/csi-driver-nfs',
  'kubernetes-csi/csi-lib-fc',
  'kubernetes-csi/csi-lib-iscsi',
  'kubernetes-csi/csi-lib-utils',
  'kubernetes-csi/csi-release-tools',
  'kubernetes-csi/csi-test',
  'kubernetes-csi/docs',
  'kubernetes-csi/driver-registrar',
  'kubernetes-csi/drivers',
  'kubernetes-csi/external-attacher',
  'kubernetes-csi/external-provisioner',
  'kubernetes-csi/external-resizer',
  'kubernetes-csi/external-snapshotter',
  'kubernetes-csi/kubernetes-csi.github.io',
  'kubernetes-csi/livenessprobe',
  'kubernetes-csi/node-driver-registrar',
  'kubernetes-incubator/external-storage',
  'kubernetes-incubator/nfs-provisioner',
  'kubernetes-sigs/sig-storage-lib-external-provisioner',
  'kubernetes-sigs/sig-storage-local-static-provisioner',
  'kubernetes/git-sync'
);

update gha_repos set repo_group = 'SIG Testing' where name in (
  'kubernetes-sigs/kind',
  'kubernetes-sigs/testing_frameworks',
  'kubernetes/test-infra'
);

update gha_repos set repo_group = 'SIG UI' where name in (
  'kubernetes-sigs/dashboard-metrics-scraper',
  'kubernetes/dashboard'
);

update gha_repos set repo_group = 'SIG VMware' where name in (
  'kubernetes-sigs/cluster-api-provider-vsphere',
  'kubernetes-sigs/vsphere-csi-driver'
);

update gha_repos set repo_group = 'SIG Windows' where name in (
  'kubernetes-sigs/windows-gmsa',
  'kubernetes-sigs/windows-testing'
);

-- All other unknown repositories should have 'Other' repository group
-- update gha_repos set repo_group = 'Other' where repo_group is null;

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

