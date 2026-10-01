{
  platform: 'kubeadm',
  certname: 'prod.acmecorp',
  connect_obmondo: true,
  'blackbox-exporter': false,
  kube_prometheus_version: 'v0.17.0',
  loki: {
    enable: true,
    tenants: ['prod', 'staging'],
  },
}
