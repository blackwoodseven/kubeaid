# KubeAid Project - Software Bill of Materials (SBOM)
**Date:** July 24, 2026

## Summary of Dependencies:

- argo-cd
- argocd-image-updater
- aws-ebs-csi-driver
- aws-efs-csi-driver
- azuredisk-csi-driver
- azure-workload-identity-webhook
- backup-exporter
- calcom
- capi-cluster
- castopod
- ccm-aws
- ccm-azure
- ccm-hetzner
- cerebro
- cert-manager
- cilium
- circleci-runner
- ciso-assistant
- cloudnative-pg
- cluster-api-operator
- cluster-autoscaler
- coredns
- crossplane
- crossplane-compositions
- crossplane-providers-and-functions
- docker-mailserver
- dokuwiki
- erpnext
- errbot
- external-dns
- filebeat
- fluent-bit
- friendica
- garage
- gatekeeper
- gitea
- gitea-runner
- gitlab-runner
- goalerts
- grafana-operator
- graylog
- hami
- haproxy
- harbor
- hcloud-csi-driver
- ingress-nginx
- k8s-event-logger
- keda
- keycloakx
- kube2iam
- kubeaid-addons
- kubeaid-agent
- kubeaid-custom-azure
- kubeaid-security-config
- kubearmor
- kubelet-csr-approver
- kubescape-operator
- kyverno
- localpv-provisioner
- loki-stack
- mail
- mariadb-operator
- matomo
- metal3
- metallb
- metrics-server
- minio
- mongodb-kubernetes
- netbird
- netbird-operator
- ntfy
- obmondo-k8s-agent
- oncall
- opencost
- opendesk-coturn
- openobserve
- opensearch
- opensearch-dashboards
- opensearch-operator
- opentelemetry-operator
- openvox
- opsbridge
- postgres-operator
- prometheus-adapter
- prometheus-linuxaid
- rabbitmq-operator
- redis-operator
- redmine
- relate
- reloader
- rook-ceph
- sealed-secrets
- seaweedfs
- sftpgo
- smartmon-exporter
- snapshot-controller
- sonarqube
- step-ca
- strimzi-kafka-operator
- teleport-cluster
- teleport-kube-agent
- tetragon
- tigera-operator
- traefik
- traefik-forward-auth
- trivy-operator
- velero
- version-checker
- vuls-dictionary
- whoami
- yetibot
- zfs-localpv

## Dependency Details

### argo-cd

* **Images:**
    - ecr-public.aws.com/docker/library/redis:8.2.3-alpine
    - quay.io/argoproj/argocd:v3.4.5

### argocd-image-updater

* **Images:**
    - quay.io/argoprojlabs/argocd-image-updater:v1.2.2

### aws-ebs-csi-driver

* **Images:**
    - public.ecr.aws/csi-components/csi-attacher:v4.12.0-eksbuild.2
    - public.ecr.aws/csi-components/csi-node-driver-registrar:v2.17.0-eksbuild.2
    - public.ecr.aws/csi-components/csi-provisioner:v6.3.0-eksbuild.1
    - public.ecr.aws/csi-components/csi-resizer:v2.2.0-eksbuild.2
    - public.ecr.aws/csi-components/livenessprobe:v2.19.0-eksbuild.2
    - public.ecr.aws/ebs-csi-driver/aws-ebs-csi-driver:v1.62.0
    - us-central1-docker.pkg.dev/k8s-staging-test-infra/images/kubekins-e2e:v20260615-b4199512ce-master

### aws-efs-csi-driver

* **Images:**
    - public.ecr.aws/csi-components/csi-node-driver-registrar:v2.17.0-eksbuild.2
    - public.ecr.aws/csi-components/csi-provisioner:v6.3.0-eksbuild.1
    - public.ecr.aws/csi-components/livenessprobe:v2.19.0-eksbuild.2
    - public.ecr.aws/efs-csi-driver/amazon/aws-efs-csi-driver:v3.4.0

### azuredisk-csi-driver

* **Images:**
    - mcr.microsoft.com/oss/v2/kubernetes-csi/azuredisk-csi:v1.34.4
    - mcr.microsoft.com/oss/v2/kubernetes-csi/azuredisk-csi:v1.34.4-windows-hp
    - mcr.microsoft.com/oss/v2/kubernetes-csi/csi-attacher:v4.11.0
    - mcr.microsoft.com/oss/v2/kubernetes-csi/csi-node-driver-registrar:v2.16.0
    - mcr.microsoft.com/oss/v2/kubernetes-csi/csi-provisioner:v6.2.0
    - mcr.microsoft.com/oss/v2/kubernetes-csi/csi-resizer:v2.1.0
    - mcr.microsoft.com/oss/v2/kubernetes-csi/csi-snapshotter:v8.5.0
    - mcr.microsoft.com/oss/v2/kubernetes-csi/livenessprobe:v2.18.0

### azure-workload-identity-webhook

* **Images:**
    - mcr.microsoft.com/oss/v2/azure/workload-identity/webhook:v1.6.0

### backup-exporter

* **Images:**
    - ghcr.io/obmondo/backup-exporter:v1.0.5

### calcom

* **Images:**
    - busybox
    - harbor.obmondo.com/obmondo/calcom:0.0.6

### castopod

* **Images:**
    - busybox
    - castopod/castopod:1.12.10
    - mariadb:11.6.2-noble
    - quay.io/opstree/redis-exporter:v1.44.0
    - quay.io/opstree/redis:v7.2.6

### ccm-aws

* **Images:**
    - registry.k8s.io/provider-aws/cloud-controller-manager:v1.30.0

### ccm-azure

* **Images:**
    - mcr.microsoft.com/oss/v2/kubernetes/azure-cloud-controller-manager:v1.36.0
    - mcr.microsoft.com/oss/v2/kubernetes/azure-cloud-node-manager:v1.36.0

### ccm-hetzner

* **Images:**
    - docker.io/hetznercloud/hcloud-cloud-controller-manager:v1.34.0 # x-releaser-pleaser-version

### cerebro

* **Images:**
    - lmenezes/cerebro:0.9.4

### cert-manager

* **Images:**
    - quay.io/jetstack/cert-manager-cainjector:v1.21.0
    - quay.io/jetstack/cert-manager-controller:v1.21.0
    - quay.io/jetstack/cert-manager-startupapicheck:v1.21.0
    - quay.io/jetstack/cert-manager-webhook:v1.21.0

### cilium

* **Images:**
    - quay.io/cilium/cilium-envoy:v1.36.9-1782267392-edeb3f2af56c37c407efa1f63f0b32f595399bbc@sha256:767101fb8a5e38f055778cb43b7aa8eed80450b37f8121effac3d9de9e06dc99
    - quay.io/cilium/cilium:v1.19.6@sha256:0df5b2750b64c49843aba1d649e9eaf61467cb0645ad3171db6f6962c095ac92
    - quay.io/cilium/hubble-relay:v1.19.6@sha256:6782a49e3f28eba015701c4410a5ec7fa096fe9a562f879b4372dbecd827ea44
    - quay.io/cilium/hubble-ui-backend:v0.13.5@sha256:fac0c300ae119274edca11fd89b1ad23c788792d8bc4ea2ba631c709e8d3c688
    - quay.io/cilium/hubble-ui:v0.13.5@sha256:f7d514fc54d784ed6df9d58cf0e97648b143f92b766dd1780ed3fc845bd4c516
    - quay.io/cilium/operator-generic:v1.19.6@sha256:0db4ca4e06969d8904ee036617795d0e9c3228cf7b8d902ba74fc2bb98d2d665

### circleci-runner

* **Images:**
    - circleci/runner:launch-agent

### ciso-assistant

* **Images:**
    - ghcr.io/intuitem/ciso-assistant-community/backend:v2.5.4
    - ghcr.io/intuitem/ciso-assistant-community/frontend:v2.5.4

### cloudnative-pg

* **Images:**
    - ghcr.io/cloudnative-pg/cloudnative-pg:1.30.0
    - ghcr.io/cloudnative-pg/plugin-barman-cloud:v0.13.0

### cluster-api-operator

* **Images:**
    - registry.k8s.io/capi-operator/cluster-api-operator:v0.28.0

### crossplane

* **Images:**
    - xpkg.crossplane.io/crossplane/crossplane:v2.3.3

### docker-mailserver

* **Images:**
    - mailserver/docker-mailserver:15.1.0

### dokuwiki

* **Images:**
    - docker.io/bitnami/dokuwiki:20240206.1.0-debian-12-r24

### erpnext

* **Images:**
    - busybox
    - docker.io/valkey/valkey:7.2
    - frappe/erpnext:v16.28.0
    - mariadb:11.6.2-noble
    - quay.io/opstree/redis-exporter:v1.44.0
    - quay.io/opstree/redis:v7.2.6

### errbot

* **Images:**
    - docker.io/alpine:3
    - harbor.obmondo.com/obmondo/errbot:6.1.10

### external-dns

* **Images:**
    - registry.k8s.io/external-dns/external-dns:v0.21.0

### filebeat

* **Images:**
    - docker.elastic.co/beats/filebeat:8.7.1

### fluent-bit

* **Images:**
    - busybox:latest
    - cr.fluentbit.io/fluent/fluent-bit:5.0.9

### friendica

* **Images:**
    - friendica:2024.12
    - mariadb:11.6.2-noble

### garage

* **Images:**
    - dxflrs/garage:v2.3.0

### gatekeeper

* **Images:**
    - curlimages/curl:8.20.0
    - openpolicyagent/gatekeeper-crds:v3.23.0
    - openpolicyagent/gatekeeper:v3.23.0

### gitea

* **Images:**
    - busybox:latest
    - docker.gitea.com/gitea:1.27.0-rootless
    - quay.io/opstree/redis-exporter:v1.44.0
    - quay.io/opstree/redis:v7.2.6

### gitea-runner

* **Images:**
    - vegardit/gitea-act-runner:dind-1.0.6

### gitlab-runner

* **Images:**
    - registry.gitlab.com/gitlab-org/gitlab-runner:alpine-v19.2.0

### goalerts

* **Images:**
    - busybox:1.37
    - goalert/goalert:v0.32.0

### grafana-operator

* **Images:**
    - ghcr.io/grafana/grafana-operator:v5.20.0

### graylog

* **Images:**
    - alpine
    - graylog/graylog:7.1.5

### hami

* **Images:**
    - docker.io/liangjw/kube-webhook-certgen:v1.1.1
    - docker.io/projecthami/hami:v2.9.0
    - registry.cn-hangzhou.aliyuncs.com/google_containers/kube-scheduler:v1.36.0

### haproxy

* **Images:**
    - docker.io/haproxytech/haproxy-alpine:3.3.10

### harbor

* **Images:**
    - docker.io/busybox:latest
    - docker.io/goharbor/harbor-core:v2.15.1
    - docker.io/goharbor/harbor-jobservice:v2.15.1
    - docker.io/goharbor/harbor-portal:v2.15.1
    - docker.io/goharbor/harbor-registryctl:v2.15.1
    - docker.io/goharbor/registry-photon:v2.15.1
    - docker.io/goharbor/trivy-adapter-photon:v2.15.1
    - quay.io/opstree/redis-exporter:v1.48.0
    - quay.io/opstree/redis:v8.0.2

### hcloud-csi-driver

* **Images:**
    - docker.io/hetznercloud/hcloud-csi-driver:v2.22.0 # x-releaser-pleaser-version
    - registry.k8s.io/sig-storage/csi-attacher:v4.11.0
    - registry.k8s.io/sig-storage/csi-node-driver-registrar:v2.16.0
    - registry.k8s.io/sig-storage/csi-provisioner:v6.2.0
    - registry.k8s.io/sig-storage/csi-resizer:v2.1.0
    - registry.k8s.io/sig-storage/livenessprobe:v2.18.0

### ingress-nginx

* **Images:**
    - registry.k8s.io/ingress-nginx/controller:v1.15.1@sha256:594ceea76b01c592858f803f9ff4d2cb40542cae2060410b2c95f75907d659e1
    - registry.k8s.io/ingress-nginx/kube-webhook-certgen:v1.6.9@sha256:01038e7de14b78d702d2849c3aad72fd25903c4765af63cf16aa3398f5d5f2dd

### k8s-event-logger

* **Images:**
    - maxrocketinternet/k8s-event-logger:2.1

### keda

* **Images:**
    - ghcr.io/kedacore/keda:2.20.1
    - ghcr.io/kedacore/keda-admission-webhooks:2.20.1
    - ghcr.io/kedacore/keda-metrics-apiserver:2.20.1

### keycloakx

* **Images:**
    - docker.io/busybox:1.37
    - ghcr.io/obmondo/postgres-logical-backup:3.1.8
    - quay.io/keycloak/keycloak:26.6.4

### kube2iam

* **Images:**
    - jtblin/kube2iam:0.11.1

### kubeaid-agent

* **Images:**
    - ghcr.io/obmondo/kubeaid-agent:v0.4.4

### kubearmor

* **Images:**
    - docker.io/kubearmor/kubearmor-operator:v1.7.4

### kubelet-csr-approver

* **Images:**
    - busybox
    - ghcr.io/postfinance/kubelet-csr-approver:v1.2.14

### kubescape-operator

* **Images:**
    - quay.io/kubescape/http-request:v0.2.19
    - quay.io/kubescape/klamav:1.3.1-34_alpha
    - quay.io/kubescape/kubescape:v4.0.8
    - quay.io/kubescape/kubevuln:v0.3.142
    - quay.io/kubescape/node-agent:v0.3.119
    - quay.io/kubescape/operator:v0.2.142
    - quay.io/kubescape/storage:v0.0.274

### kyverno

* **Images:**
    - ghcr.io/kyverno/readiness-checker:latest
    - ghcr.io/kyverno/readiness-checker:v1.18.2
    - reg.kyverno.io/kyverno/background-controller:v1.18.2
    - reg.kyverno.io/kyverno/cleanup-controller:v1.18.2
    - reg.kyverno.io/kyverno/kyverno-cli:v1.18.2
    - reg.kyverno.io/kyverno/kyvernopre:v1.18.2
    - reg.kyverno.io/kyverno/kyverno:v1.18.2
    - reg.kyverno.io/kyverno/reports-controller:v1.18.2

### localpv-provisioner

* **Images:**
    - docker.io/openebs/provisioner-localpv:4.5.1

### loki-stack

* **Images:**
    - docker.io/grafana/promtail:3.5.1
    - grafana/loki:2.9.15

### mail

* **Images:**
    - boky/postfix:v1.0.0

### mariadb-operator

* **Images:**
    - ghcr.io/mariadb-operator/mariadb-operator:26.6.0

### matomo

* **Images:**
    - docker.io/bitnamilegacy/matomo:5.1.1
    - ghcr.io/obmondo/mariadb-logical-backup:3.1.6
    - ghcr.io/obmondo/mariadb-logical-backup:3.1.8
    - mariadb:latest

### metal3

* **Images:**
    - registry.opensuse.org/isv/suse/edge/containers/images/baremetal-operator:0.9.0
    - registry.opensuse.org/isv/suse/edge/containers/images/ironic:35.0.0.1
    - registry.opensuse.org/isv/suse/edge/containers/images/ironic-ipa-downloader:3.1.2

### metallb

* **Images:**
    - docker.io/bitnami/metallb-controller:0.15.2-debian-12-r7
    - docker.io/bitnami/metallb-speaker:0.15.2-debian-12-r6

### metrics-server

* **Images:**
    - registry.k8s.io/metrics-server/metrics-server:v0.8.1

### minio

* **Images:**
    - quay.io/minio/mc:RELEASE.2024-11-21T17-21-54Z
    - quay.io/minio/minio:RELEASE.2024-12-18T13-15-44Z

### mongodb-kubernetes

* **Images:**
    - quay.io/mongodb/mongodb-kubernetes:1.9.1

### netbird

* **Images:**
    - coturn/coturn:4.14.0
    - ghcr.io/obmondo/postgres-logical-backup:3.1.8
    - mikefarah/yq:latest
    - netbirdio/dashboard:v2.90.4
    - netbirdio/management:0.74.6
    - netbirdio/relay:0.74.6
    - netbirdio/signal:0.74.6

### netbird-operator

* **Images:**
    - ghcr.io/netbirdio/netbird-operator:v0.7.0

### ntfy

* **Images:**
    - binwiederhier/ntfy:v2.26.0
    - busybox

### obmondo-k8s-agent

* **Images:**
    - ghcr.io/obmondo/obmondo-k8s-agent:v1.1.6

### oncall

* **Images:**
    - bitnamilegacy/rabbitmq:3.12.0-debian-11-r0
    - docker.io/bats/bats:v1.4.1
    - docker.io/bitnami/redis:6.2.7-debian-11-r11
    - docker.io/grafana/grafana:11.1.4
    - docker.io/library/busybox:1.31.1
    - grafana/oncall:v1.16.5

### opencost

* **Images:**
    - ghcr.io/opencost/opencost:1.120.4@sha256:5467eaac8d301be69cc4a3f69f063ad5da7d57130d1126a4eb75b0d8f79839e1
    - ghcr.io/opencost/opencost-ui:1.120.4@sha256:a59d77750cda9eaf7a220855c0449a5bf929cbefdb17defa109d576acb545494

### opendesk-coturn

* **Images:**
    - dockeri.io/coturn/coturn:4.6.2-alpine@sha256:cecbd85f5b27ce5bf00901192c9fe565c4be631f285411e5625427372a3a2f8b

### openobserve

* **Images:**
    - ghcr.io/open-telemetry/opentelemetry-collector-releases/opentelemetry-collector-contrib:0.138.0
    - ghcr.io/open-telemetry/opentelemetry-go-instrumentation/autoinstrumentation-go:v0.23.0
    - nats:2.14.2-alpine
    - natsio/nats-box:0.19.7
    - natsio/nats-server-config-reloader:0.23.0
    - natsio/prometheus-nats-exporter:0.20.1
    - o2cr.ai/openobserve/openobserve-enterprise:v0.91.1
    - o2cr.ai/openobserve/report-server:v0.11.2-88574bc
    - openfga/openfga:latest
    - public.ecr.aws/docker/library/busybox:1.36.1
    - registry.k8s.io/kube-state-metrics/kube-state-metrics:v2.15.0

### opensearch

* **Images:**
    - busybox:latest
    - opensearchproject/opensearch:3.7.0

### opensearch-dashboards

* **Images:**
    - opensearchproject/opensearch-dashboards:3.7.0

### opensearch-operator

* **Images:**
    - opensearchproject/opensearch-operator:3.0.0-alpha

### opentelemetry-operator

* **Images:**
    - busybox:latest
    - ghcr.io/open-telemetry/opentelemetry-operator/opentelemetry-operator:0.156.0
    - otel/opentelemetry-collector-k8s:0.156.0

### openvox

* **Images:**
    - camptocamp/prometheus-puppetdb-exporter:1.1.0
    - curlimages/curl:8.11.1
    - docker.io/busybox:1.37
    - ghcr.io/obmondo/gfetch:v1.2.0
    - ghcr.io/obmondo/puppet-agent-exporter:v0.0.1
    - ghcr.io/openvoxproject/openvoxdb:8.11.0-main
    - ghcr.io/openvoxproject/openvoxserver:8.11.0-main
    - ghcr.io/voxpupuli/puppetboard:6.0.1

### opsbridge

* **Images:**
    - harbor.obmondo.com/obmondo/opsbridge:v1.0.0

### postgres-operator

* **Images:**
    - ghcr.io/zalando/postgres-operator/logical-backup:v1.15.1
    - ghcr.io/zalando/postgres-operator:v1.15.1
    - ghcr.io/zalando/spilo-17:4.0-p3
    - registry.opensource.zalan.do/acid/pgbouncer:master-32

### prometheus-adapter

* **Images:**
    - registry.k8s.io/prometheus-adapter/prometheus-adapter:v0.12.0

### prometheus-linuxaid

* **Images:**
    - grafana/grafana:12.2.0

### rabbitmq-operator

* **Images:**
    - docker.io/bitnamilegacy/rabbitmq-cluster-operator:2.16.1-debian-12-r0
    - docker.io/bitnamilegacy/rmq-messaging-topology-operator:1.17.4-debian-12-r0

### redis-operator

* **Images:**
    - quay.io/opstree/redis-operator:v0.25.0

### redmine

* **Images:**
    - docker.io/bitnami/redmine:6.0.6-debian-12-r6

### relate

* **Images:**
    - nginx:latest
    - registry.example.com/obmondo/dockerfiles/relate:latest

### reloader

* **Images:**
    - ghcr.io/stakater/reloader:v1.4.19

### rook-ceph

* **Images:**
    - docker.io/rook/ceph:v1.20.2
    - quay.io/ceph/ceph:v20.2.2
    - quay.io/cephcsi/ceph-csi-operator:v1.0.4

### sealed-secrets

* **Images:**
    - docker.io/bitnami/sealed-secrets-controller:0.37.0

### seaweedfs

* **Images:**
    - chrislusf/seaweedfs:4.40

### sftpgo

* **Images:**
    - ghcr.io/drakkan/sftpgo:v2.6.2

### smartmon-exporter

* **Images:**
    - quay.io/prometheuscommunity/smartctl-exporter:v0.14.0

### snapshot-controller

* **Images:**
    - registry.k8s.io/sig-storage/snapshot-controller:v8.6.0
    - registry.k8s.io/sig-storage/snapshot-conversion-webhook:v8.6.0

### sonarqube

* **Images:**
    - sonarqube:26.5.0.122743-community

### step-ca

* **Images:**
    - alpine/curl:latest
    - busybox:latest
    - cr.smallstep.com/smallstep/step-ca:0.30.2
    - cr.smallstep.com/smallstep/step-ca-bootstrap:latest
    - cr.step.sm/smallstep/step-issuer:0.11.0
    - quay.io/jetstack/trust-manager:v0.24.0
    - quay.io/jetstack/trust-pkg-debian-trixie:20250419.1

### strimzi-kafka-operator

* **Images:**
    - quay.io/strimzi/operator:1.1.0

### teleport-cluster

* **Images:**
    - public.ecr.aws/gravitational/teleport-distroless:18.10.1

### teleport-kube-agent

* **Images:**
    - public.ecr.aws/gravitational/teleport-distroless:18.10.1

### tetragon

* **Images:**
    - quay.io/cilium/hubble-export-stdout:v1.1.1
    - quay.io/cilium/tetragon-operator:v1.7.0
    - quay.io/cilium/tetragon:v1.7.0

### tigera-operator

* **Images:**
    - quay.io/tigera/operator:v1.42.3

### traefik

* **Images:**
    - docker.io/traefik:v3.7.6

### traefik-forward-auth

* **Images:**
    - busybox
    - mesosphere/kubeaddons-addon-initializer:v0.5.1
    - mesosphere/traefik-forward-auth:3.1.0

### trivy-operator

* **Images:**
    - mirror.gcr.io/aquasec/trivy:0.72.0
    - mirror.gcr.io/aquasec/trivy-operator:0.32.0

### velero

* **Images:**
    - docker.io/velero/velero:v1.18.1

### version-checker

* **Images:**
    - quay.io/jetstack/version-checker:v0.11.0

### vuls-dictionary

* **Images:**
    - alpine:3.21
    - ghcr.io/obmondo/vuls:45714b6
    - ghcr.io/oras-project/oras:v1.2.2

### whoami

* **Images:**
    - docker.io/traefik/whoami:v1.11.0
    - ghcr.io/cowboysysop/pytest:1.2.0

### yetibot

* **Images:**
    - busybox
    - docker.io/bitnami/postgresql:15.1.0-debian-11-r12
    - yetibot/yetibot:20260608.145320.8ee84eb

### zfs-localpv

* **Images:**
    - docker.io/openebs/zfs-driver:2.10.1
    - registry.k8s.io/sig-storage/csi-node-driver-registrar:v2.13.0
    - registry.k8s.io/sig-storage/csi-provisioner:v5.2.0
    - registry.k8s.io/sig-storage/csi-resizer:v1.13.2
    - registry.k8s.io/sig-storage/csi-snapshotter:v8.2.0
    - registry.k8s.io/sig-storage/snapshot-controller:v8.2.0

