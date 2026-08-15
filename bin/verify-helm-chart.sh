#!/usr/bin/env bash
#
# Discover every top-level Helm chart under argocd-helm-charts/ and run
# `helm template` against it to catch rendering errors before they
# reach a PR reviewer. Subcharts unpacked into a chart's own charts/
# directory (e.g. argocd-helm-charts/example-chart/charts/subchart)
# are skipped, since `helm template` on the parent chart already
# renders its subcharts.
#
# Runs every chart even if earlier ones fail, then reports a summary
# and exits non-zero if any chart failed.
#
# Usage:
#   scripts/verify-helm-charts.sh                       # verify every chart under argocd-helm-charts/
#   scripts/verify-helm-charts.sh ./argocd-helm-charts/foo  # verify a single chart
#
# Requires: helm (any Helm 3 release). Install locally with:
#   macOS:   brew install helm
#   Ubuntu:  see https://helm.sh/docs/intro/install/
#   Other:   https://helm.sh/docs/intro/install/

set -uo pipefail

cd "$(git rev-parse --show-toplevel)" || exit

CHARTS_ROOT="argocd-helm-charts"

if ! command -v helm >/dev/null 2>&1; then
  echo "error: helm is not installed or not on PATH." >&2
  echo "  See: https://helm.sh/docs/intro/install/" >&2
  exit 127
fi

if [ "$#" -gt 0 ]; then
  charts=("$@")
else
  # Find every Chart.yaml under CHARTS_ROOT, then drop any whose path
  # contains a /charts/ segment -- those are subcharts unpacked by
  # `helm dependency update` under a parent chart, not top-level
  # charts to verify independently.
  mapfile -d '' charts < <(
    find "$CHARTS_ROOT" -type f -name 'Chart.yaml' -print0 \
      | xargs -0 -n1 dirname \
      | grep -v '/charts/' \
      | tr '\n' '\0'
  )
fi

if [ "${#charts[@]}" -eq 0 ]; then
  echo "No Helm charts found under ${CHARTS_ROOT}."
  exit 0
fi

# Charts listed in .helm-template-skip (one name per line, comments with #)
# cannot render with default values alone and are skipped loudly. Every
# entry must carry a reason in the file.
SKIP_FILE=".helm-template-skip"
skip_list=()
if [ -f "$SKIP_FILE" ]; then
  mapfile -t skip_list < <(sed 's/#.*//' "$SKIP_FILE" | awk 'NF {print $1}')
fi

is_skipped() {
  local name="$1" s
  for s in "${skip_list[@]}"; do
    [ "$s" = "$name" ] && return 0
  done
  return 1
}

failed=()
skipped=()

for chart in "${charts[@]}"; do
  chart_name="$(basename "$chart")"
  if is_skipped "$chart_name"; then
    skipped+=("$chart")
    echo "==> SKIPPED ${chart} (listed in ${SKIP_FILE} — cannot template with default values)"
    continue
  fi
  echo "==> Templating ${chart}"
  if ! helm template "$chart" --api-versions="monitoring.coreos.com/v1" >/dev/null; then
    failed+=("$chart")
  fi
done

if [ "${#skipped[@]}" -gt 0 ]; then
  echo
  echo "NOTE: ${#skipped[@]} chart(s) were skipped via ${SKIP_FILE} and are NOT verified."
fi

echo
if [ "${#failed[@]}" -eq 0 ]; then
  echo "All ${#charts[@]} chart(s) templated successfully."
  exit 0
fi

echo "The following ${#failed[@]} chart(s) failed to template:" >&2
for chart in "${failed[@]}"; do
  echo "  - ${chart}" >&2
done

exit 1