# Adding new charts to argocd-helm-charts

To add an upstream chart :

- create a new folder under kubeaid/argocd-helm-charts/

```bash
  mkdir <chart name>
```

- Add a Chart.yaml inside the folder with version and repo URL of the upstream Helm chart.
  It should be similar to the example argocd chart below.

```yaml
apiVersion: v1
name: argo-cd
version: 2.2.2
dependencies:
  - name: argo-cd
    version: 3.29.5
    repository: https://argoproj.github.io/argo-helm
```

Use [this script](../bin/helm-repo-update.sh)
to get the upstream chart and dependencies

## Usage

### Update a specific chart

```sh
./bin/helm-repo-update.sh --update-helm-chart <name-of-chart>
```

### Update a specific chart to a specific version

```sh
./bin/helm-repo-update.sh --update-helm-chart <name-of-chart> --chart-version <version>
```

### Update all charts

```sh
./bin/helm-repo-update.sh --update-all
```

### Update all charts except certain ones

```sh
./bin/helm-repo-update.sh --update-all --skip-charts 'chart1,chart2,chart3'
```

**Note**: `--skip-charts` must be used with `--update-all` or `--update-helm-chart`

### Get help

```sh
./bin/helm-repo-update.sh --help
```

Note:

- Remove the database dependency charts coming with upstream chart.
- We use `db-operators` to manage the databases.
For example `postgres-operator` for postgres for postgresql database and so on.
<!-- markdownlint-disable -->
- Check
[doc](postgres-operator/README.md) about postgres operator and how that works.
<!-- markdownlint-enable -->
