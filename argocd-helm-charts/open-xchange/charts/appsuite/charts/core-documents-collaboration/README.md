# Helm Chart core-documents-collaboration
This Helm Chart deploys the documents-collaboration service core in a kubernetes cluster.

## Introduction
This Chart includes the following components:

* Documents-collaboration application container to deploy in a kubernetes cluster.

## Requirements
Requires Kubernetes v1.19+

## Dependencies
This section will provide details about specific requirements in addition to this Helm Chart.

## Pushing to registry
From wihtin ${PROJECT_DIR}/helm/core-documents-collaboration directory:

```shell
helm repo add ox-documents-registry https://registry.open-xchange.com/chartrepo/documents
helm repo update
helm push . ox-documents-registry
```

## Test installation
Run a test against a cluster deployment:

```shell
helm repo add ox-documents-registry https://registry.open-xchange.com/chartrepo/documents
helm repo update
helm install --dry-run --debug --generate-name --version [VERSION] ox-documents-registry/core-documents-collaboration
```

## Installing the chart
Install the Chart with the release name 'alice':

```shell
helm repo add ox-documents-registry https://registry.open-xchange.com/chartrepo/documents
helm repo update
helm install alice --version [VERSION] ox-documents-registry/core-documents-collaboration [-f path/to/values_with_credentials.yaml]
```

### Configuration

## Global Configuration
| Parameter                     | Description                            | Default                          |
|-------------------------------|----------------------------------------|----------------------------------|
| `defaultRegistry`             | The image registry                     | `registry.open-xchange.com`      |
| `image.repository`            | The image repository                   | `core-documents-collaboration`   |
| `image.tag`                   | The image tag                          | ``                               |
| `image.pullPolicy`            | The imagePullPolicy for the deployment | `IfNotPresent`                   |
| `dcs.serviceName`             | The service name registered in the DNS to query for available DCS nodes.  | <RELEASE-NAME>-core-documents-collaboration |
| `dcs.ssl.enabled`             | If set to true, the current DCS server is listening to SSL requests only. | `false` |
| `dcs.ssl.useInternalCerts`    | Specifies if a default self-signed certificate should be used for SSL connections. | `false`|
| `env`                         | Configuration properties passed to the service via environment variables  | `[]` |
