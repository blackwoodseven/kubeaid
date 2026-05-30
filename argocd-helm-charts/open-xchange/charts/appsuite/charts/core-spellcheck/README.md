# Helm Chart core-spellcheck
This Helm Chart deploys SpellCheck service core in a kubernetes cluster.

## Introduction
This Chart includes the following components:

* Spellcheck application container to deploy in a kubernetes cluster.

## Requirements
Requires Kubernetes v1.19+

## Dependencies
This section will provide details about specific requirements in addition to this Helm Chart.
## Pushing to registry
From wihtin ${PROJECT_DIR}/helm/core-spellcheck directory:

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
helm install --dry-run --debug --generate-name --version [VERSION] ox-documents-registry/core-spellcheck
```

## Installing the chart
Install the Chart with the release name 'alice':

```shell
helm repo add ox-documents-registry https://registry.open-xchange.com/chartrepo/documents
helm repo update
helm install alice --version [VERSION] ox-documents-registry/core-spellcheck [-f path/to/values_with_credentials.yaml]
```

### Configuration

## Global Configuration
| Parameter                     | Description                                                                               | Default                     |
|-------------------------------|-------------------------------------------------------------------------------------------|-----------------------------|
| `defaultRegistry`             | The image registry                                                                        | `registry.open-xchange.com` |
| `image.repository`            | The image repository                                                                      | `core-spellcheck`           |
| `image.tag`                   | The image tag                                                                             | ``                          |
| `image.pullPolicy`            | The imagePullPolicy for the deployment                                                    | `IfNotPresent`              |
| `imagePullSecrets`            | List of references to secrets for image registries                                        | `[]`                        |
| `ingress.enabled`             | Make SpellCheck service reachable from outside of cluster                                 | `false`                     |
| `ingress.controller`          | The type of controller to use, possible values are `nginx` and `traefik`                  | `nginx`                     |
| `ingress.hosts`               | The list of hosts the service can be reached from. Set to empty to allow from everywhere. | `[]`                        |
| `ingress.hosts.host`          | The host the service can be reached from                                                  | `chart-example.local`       |
| `env`                         | Configuration properties passed to the service via environment variables                  | `[]`                        |
