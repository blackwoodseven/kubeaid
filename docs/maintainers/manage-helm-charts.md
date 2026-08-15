# Adding/Updating new charts to argocd-helm-charts

## Usage

### Add a new chart

```sh
./bin/manage-helm-chart.sh --add-helm-chart <chart-name> <chart-url> <chart-version>
```

### Update a specific chart

```sh
./bin/manage-helm-chart.sh --update-helm-chart <name-of-chart>
```

### Update a specific chart to a specific version

```sh
./bin/manage-helm-chart.sh --update-helm-chart <name-of-chart> --chart-version <version>
```

### Update all charts

```sh
./bin/manage-helm-chart.sh --update-all
```

### Update all charts except certain ones

```sh
./bin/manage-helm-chart.sh --update-all --skip-charts 'chart1,chart2,chart3'
```

**Note**: `--skip-charts` must be used with `--update-all` or `--update-helm-chart`

### Get help

```sh
./bin/manage-helm-chart.sh --help
```

Note:

- Remove the database dependency charts coming with upstream chart.
- We use `db-operators` to manage the databases.
For example `postgres-operator` for postgres for postgresql database and so on.
<!-- markdownlint-disable -->
- Check
[doc](../../argocd-helm-charts/postgres-operator/README.md) about postgres operator and how that works.
<!-- markdownlint-enable -->

## See also

- [Helm Umbrella Pattern](../kubeaid/helm-umbrella-pattern.md) - how these charts fit into the umbrella chart
