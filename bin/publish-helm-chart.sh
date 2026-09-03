#!/bin/bash

set -eou pipefail

# Packages the first-party charts listed in .helm-charts-publish and pushes
# them to an OCI registry, tagged with each chart's own Chart.yaml version.

declare ARGOCD_CHART_PATH="argocd-helm-charts"
declare PUBLISH_LIST=".helm-charts-publish"
declare REGISTRY="${HELM_OCI_REGISTRY:-oci://ghcr.io/obmondo/charts}"
declare DRY_RUN=false
declare -a CHARTS=()

function usage() {
  cat <<'USAGE'
Usage: ./bin/publish-helm-chart.sh [OPTIONS] [CHART...]

Packages every chart listed in .helm-charts-publish and pushes it to an OCI
registry, using the chart's own Chart.yaml version as the tag. A version that
already exists in the registry is skipped, so a release that did not touch a
chart republishes nothing.

OPTIONS:
  --dry-run     Package only; print the push command instead of running it.
  -h, --help    Display this help message.

ARGUMENTS:
  CHART...      Publish only these charts. Each must appear in
                .helm-charts-publish. Defaults to every listed chart.

ENVIRONMENT:
  HELM_OCI_REGISTRY   Target registry.
                      Default:  oci://ghcr.io/obmondo/charts
                      Gitea CI: oci://harbor.obmondo.com/obmondo/charts

The caller is responsible for `helm registry login` against the target.

EXAMPLES:
  ./bin/publish-helm-chart.sh --dry-run
  ./bin/publish-helm-chart.sh kubeaid-addons
USAGE
}

while [[ $# -gt 0 ]]; do
  arg="$1"
  shift

  case "$arg" in
    --dry-run)
      DRY_RUN=true
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --*)
      echo "Error: unknown argument '$arg'"
      usage
      exit 1
      ;;
    *)
      CHARTS+=("$arg")
      ;;
  esac
done

if ! command -v helm >/dev/null; then
  echo "Error: Required program 'helm' is not installed or not in PATH"
  exit 1
fi

helm_version_full=$(helm version --template="{{.Version}}" | sed 's/^v//')
helm_version=$(echo "$helm_version_full" | awk -F. '{printf "%d%02d%02d", $1, $2, $3}')

if [ "$helm_version" -lt "30800" ]; then
  echo "Error: Helm version must be >= 3.8.0 for OCI support (found: $helm_version_full)"
  exit 1
fi

if [ ! -f "$PUBLISH_LIST" ]; then
  echo "Error: ${PUBLISH_LIST} not found. Run this from the repository root."
  exit 1
fi

# Entries are "<chart>  # reason" - drop comments and blank lines.
mapfile -t ALLOWED < <(sed -e 's/#.*//' -e 's/[[:space:]]*$//' "$PUBLISH_LIST" | grep -v '^$' || true)

if [ "${#ALLOWED[@]}" -eq 0 ]; then
  echo "No charts listed in ${PUBLISH_LIST}, nothing to publish."
  exit 0
fi

if [ "${#CHARTS[@]}" -eq 0 ]; then
  CHARTS=("${ALLOWED[@]}")
else
  for chart in "${CHARTS[@]}"; do
    if ! printf '%s\n' "${ALLOWED[@]}" | grep -qxF "$chart"; then
      echo "Error: '${chart}' is not listed in ${PUBLISH_LIST}."
      echo "Add it there, with a reason, before publishing it."
      exit 1
    fi
  done
fi

WORKDIR="$(mktemp -d)"
# shellcheck disable=SC2064
trap "rm -rf '${WORKDIR}'" EXIT

for chart in "${CHARTS[@]}"; do
  chart_dir="${ARGOCD_CHART_PATH}/${chart}"

  if [ ! -f "${chart_dir}/Chart.yaml" ]; then
    echo "Error: ${chart_dir}/Chart.yaml does not exist."
    exit 1
  fi

  chart_meta="$(helm show chart "$chart_dir")"
  chart_name="$(echo "$chart_meta" | awk '/^name:/ {gsub(/["'\'']/, "", $2); print $2; exit}')"
  chart_version="$(echo "$chart_meta" | awk '/^version:/ {gsub(/["'\'']/, "", $2); print $2; exit}')"

  if [ -z "$chart_name" ] || [ -z "$chart_version" ]; then
    echo "Error: could not read name/version from ${chart_dir}/Chart.yaml"
    exit 1
  fi

  echo "==> packaging ${chart_name} ${chart_version}"

  # No `helm dependency update` here on purpose. First-party charts carry their
  # subcharts under charts/ already - kubeaid-addons vendors them, its consumers
  # symlink it - and there is no repository for a dependency update to resolve
  # them against, so it would fail or discard them.
  helm package "$chart_dir" --destination "$WORKDIR" >/dev/null

  package="${WORKDIR}/${chart_name}-${chart_version}.tgz"

  if [ ! -f "$package" ]; then
    echo "Error: helm package did not produce ${package}"
    exit 1
  fi

  if [ "$DRY_RUN" = true ]; then
    echo "    dry-run: helm push ${package} ${REGISTRY}"
    continue
  fi

  if helm show chart "${REGISTRY}/${chart_name}" --version "$chart_version" >/dev/null 2>&1; then
    echo "    ${chart_name} ${chart_version} already present in ${REGISTRY}, skipping."
    continue
  fi

  echo "==> pushing ${chart_name} ${chart_version} to ${REGISTRY}"
  helm push "$package" "$REGISTRY"
done
