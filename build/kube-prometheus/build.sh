#!/usr/bin/env bash
#

# This script requires path to cluster folder in clone of customers
# kubernetes-config repo in arg $1. The folder should contain a
# <cluster-name>-vars.jsonnet file. With CAPI, the folder name can be
# different from the cluster name (e.g., folder: staging.local.example.com,
# cluster name: staging, jsonnet file: staging-vars.jsonnet).
# The manifests will be put in the cluster folder in a kube-prometheus subdir.
# And it must be run from the root of the argocd-apps repo. Example:
# ./build/kube-prometheus/build.sh ../kubeaid-config/k8s/<cluster-name>

set -euo pipefail

declare -i debug=0 \
  commit=0 \
  show_versions=0

declare cluster_dir='' \
  kubeaid_repo='' \
  kubeaid_repo_root='' \
  build_worktree=''

function realpath() {
  [[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#./}"
}

basedir="$(dirname "$(realpath "${0}")")"

function _exit() {
  if [ -n "${build_worktree}" ] && [ -d "${build_worktree}" ]; then
    git -C "${kubeaid_repo_root}" worktree remove --force "${build_worktree}" 2>/dev/null ||
      { rm -rf "${build_worktree}" && git -C "${kubeaid_repo_root}" worktree prune; }
  fi
  if ! ((debug)); then
    if [ -n "${tmpdir+x}" ] && [ -d "${tmpdir}" ]; then
      rm -rf "${tmpdir}"
    fi
  fi
}

trap _exit EXIT

function usage() {
  cat <<EOF
${0} [-d|--debug] [--commit] [--kubeaid-repo <path>] [--versions] <CLUSTER>

Compile kube-prometheus manifests from jsonnet template.

The manifests are built from a temporary git worktree at the kubeaid
version named by the kubeaid.io/version label on the cluster's
kube-prometheus ArgoCD Application. Without that label (or Application)
the current commit of this checkout is used, with a warning. This
checkout is left untouched either way.

Arguments:
  -d|--debug
    Leave temporary output folder when exiting.
  --commit
    Commit the generated manifests in the kubeaid-config repo.
  --kubeaid-repo <path>
    Build from this local kubeaid checkout as-is, skipping the label lookup.
    For testing.
  --versions
    Show the kube-prometheus / Kubernetes compatibility table and exit.
EOF
}

function show_compatibility_table() {
  echo ""
  echo "Kubernetes Compatibility Matrix"
  echo ""
  {
    echo "kube-prometheus|k8s 1.26|k8s 1.27|k8s 1.28|k8s 1.32|k8s 1.33|k8s 1.34|k8s 1.35|k8s 1.36|k8s 1.37"
    echo "──────────────|───────|───────|───────|───────|───────|───────|───────|───────|───────"
    echo "v0.13.0|✓|✓|✓|✗|✗|✗|✗|✗|✗"
    echo "v0.16.0|✗|✗|✗|✓|✓|✓|✗|✗|✗"
    echo "v0.17.0|✗|✗|✗|✗|✓|✓|✓|✗|✗"
    echo "v0.18.0|✗|✗|✗|✗|✓|✓|✓|✓|✗"
    echo "v0.19.0|✗|✗|✗|✗|✗|✗|✓|✓|✓"
  } | column -t -s '|'
  echo ""
  echo "Note: In CI we test only the last two releases on a regular basis."
}

# Resolve the kubeaid commit a cluster's manifests are built from.
#
# The kubeaid.io/version label on the cluster's kube-prometheus ArgoCD
# Application (written by kubeaid-cli from forkURLs.kubeaid.version) names the
# tag or branch to build from. spec.source.targetRevision is deliberately not
# consulted: it points ArgoCD at the kubeaid-config repo, which is never
# tagged, so it is always HEAD. Without an Application or label the current
# commit of the checkout is used, with a warning on stderr.
#
# $1: kubeaid checkout, $2: path to the Application file.
# Prints "<sha> <label>" (or "<sha> HEAD" for the fallback) on stdout.
function kubeaid_build_commit() {
  local repo_root="${1}" app_file="${2}" label='' sha=''

  if [[ -f "${app_file}" ]]; then
    label=$(gojsontoyaml -yamltojson <"${app_file}" 2>/dev/null |
      jq -r '.metadata.labels["kubeaid.io/version"] // "" | tostring' 2>/dev/null || true)
  fi

  if [[ -z "${label}" ]]; then
    sha=$(git -C "${repo_root}" rev-parse --verify 'HEAD^{commit}')
    if [[ -f "${app_file}" ]]; then
      echo "WARNING: no kubeaid.io/version label on ${app_file}; building from the current commit of ${repo_root} (${sha:0:8})" >&2
    else
      echo "WARNING: no kube-prometheus Application at ${app_file}; building from the current commit of ${repo_root} (${sha:0:8})" >&2
    fi
    echo "${sha} HEAD"
    return 0
  fi

  if ! sha=$(git -C "${repo_root}" rev-parse --verify "${label}^{commit}" 2>/dev/null); then
    echo "ERROR: kubeaid ref '${label}' (kubeaid.io/version label in ${app_file}) not found in ${repo_root}; run 'git -C ${repo_root} fetch --tags origin'" >&2
    return 2
  fi
  echo "${sha} ${label}"
}

while (($# > 0)); do
  case "${1}" in
  -d | --debug)
    debug=1
    ;;
  --commit)
    commit=1
    ;;
  --versions)
    show_versions=1
    ;;
  --kubeaid-repo)
    if ! [ -d "${2:-}" ]; then
      echo "--kubeaid-repo needs a path to a kubeaid checkout"
      exit 2
    fi
    kubeaid_repo="${2}"
    shift
    ;;
  -h | --help)
    usage
    exit 0
    ;;
  *)
    if ! [ -d "${1}" ]; then
      echo "Invalid argument ${1}"
      exit 2
    fi
    cluster_dir="${1}"
    ;;
  esac
  shift
done

if ((show_versions)); then
  show_compatibility_table
  exit 0
fi

if ! [[ "${cluster_dir}" ]]; then
  echo "Missing argument cluster_dir"
  exit 2
fi

# Find the vars.jsonnet file in the cluster directory
# With CAPI, folder name can differ from cluster name
cluster_jsonnet=$(find "${cluster_dir}" -maxdepth 1 -name "*-vars.jsonnet" -type f | head -n 1)

if [ -z "${cluster_jsonnet}" ]; then
  echo "No vars.jsonnet file found in ${cluster_dir}"
  echo "Expected a file named <cluster-name>-vars.jsonnet"
  exit 2
fi

# Sanity checks for jsonnet version
if ! tmp=$(jsonnet --version 2>&1); then
  echo "Missing the program 'jsonnet'"
  exit 2
fi
if ! [[ "${tmp}" =~ v([0-9]+)\.([0-9]+)\.([0-9]+) ]]; then
  echo "Unable to parse jsonnet version ('${tmp}')"
  exit 2
fi

declare -i _version=$(((BASH_REMATCH[1] * 10 ** 6) + (BASH_REMATCH[2] * 10 ** 3) + BASH_REMATCH[3]))
if ((_version < 18000)); then
  echo "jsonnet version too old; aborting"
  exit 2
fi

# Pick the kubeaid checkout to build from. With --kubeaid-repo that checkout
# is used as-is; otherwise a temporary worktree at the commit named by the
# kubeaid.io/version label on the cluster's kube-prometheus ArgoCD Application
# (see kubeaid_build_commit), so this checkout and any local changes in it are
# left alone.
if [[ -n "${kubeaid_repo}" ]]; then
  basedir="$(realpath "${kubeaid_repo%/}")/build/kube-prometheus"
  if ! [[ -f "${basedir}/common-template.jsonnet" ]]; then
    echo "ERROR: ${kubeaid_repo} is not a kubeaid checkout (no build/kube-prometheus/common-template.jsonnet)"
    exit 2
  fi
  echo "Building from kubeaid checkout ${kubeaid_repo} as-is"
else
  kubeaid_repo_root=$(cd "${basedir}/../.." && pwd)
  argocd_app_file="${cluster_dir%/}/argocd-apps/templates/kube-prometheus.yaml"
  if ! build_commit=$(kubeaid_build_commit "${kubeaid_repo_root}" "${argocd_app_file}"); then
    exit 2
  fi
  pinned_sha="${build_commit%% *}"
  pinned_version="${build_commit#* }"

  build_worktree=$(mktemp -d -t kubeaid-build.XXXXXX)
  git -C "${kubeaid_repo_root}" worktree add -q --detach "${build_worktree}" "${pinned_sha}"
  basedir="${build_worktree}/build/kube-prometheus"
  echo "Building from kubeaid ${pinned_version} (${pinned_sha:0:8}) in a temporary worktree"
fi

# Make sure to use project tooling
outdir="${cluster_dir%/}/kube-prometheus"

# A customer values file ($cluster_jsonnet) can pin 'kube_prometheus_version' to build a specific
# version. When it doesn't, fall back to the default declared in lib/default_vars.libsonnet, so the
# documented default and the version actually built cannot drift apart. (The previous fallback was
# 'main', for which no vendored library exists, so an unpinned cluster failed instead of defaulting.)
kube_prometheus_default=$(jsonnet -S -e "(import '${basedir}/lib/default_vars.libsonnet').kube_prometheus_version")
kube_prometheus_release=$(jsonnet "${cluster_jsonnet}" |
  jq -e -r --arg default "${kube_prometheus_default}" '.kube_prometheus_version // $default')
if [[ -z "${kube_prometheus_release}" ]]; then
  echo "Unable to parse kube-prometheus version, please verify '${cluster_jsonnet}'"
  exit 3
fi

jsonnet_lib_path="${basedir}/libraries/${kube_prometheus_release}/vendor"

if ! [ -e "${jsonnet_lib_path}" ]; then
  echo "Libraries not found for ${kube_prometheus_release} at ${jsonnet_lib_path}"
  echo "Run:  ./build/kube-prometheus/setup-version.sh ${kube_prometheus_release}"
  echo "(run with --versions to see the full compatibility table)"
  exit 2
fi

CLUSTER_VARS_FILE="${cluster_jsonnet}" bash "${basedir}/tests/lint_vars_access.sh"

cluster_name=$(basename "${cluster_dir%/}")

if ((commit)); then
  _original_branch=$(git -C "${cluster_dir}" rev-parse --abbrev-ref HEAD)
  _new_branch="kube-prometheus-${cluster_name}-${kube_prometheus_release}-$(date +%Y%m%d%H%M%S)"
  git -C "${cluster_dir}" checkout -q -b "${_new_branch}"
fi

build_start=$(date +%s)

# Use a temporary directory
tmpdir=$(mktemp -d)
mkdir "${tmpdir}/setup"

# Compile jsonnet files
# shellcheck disable=SC2016
jsonnet -J \
  "${jsonnet_lib_path}" \
  --ext-code-file vars="${cluster_jsonnet}" \
  -m "${tmpdir}" \
  "${basedir}/common-template.jsonnet" |
  while read -r f; do
    gojsontoyaml <"${f}" >"${f}.yaml"
    rm "${f}"
  done

rm -rf "${outdir}"
mv "${tmpdir}" "${outdir}"

build_end=$(date +%s)
kubeaid_version_desc=$(git -C "${basedir}" describe --tags --always 2>/dev/null || echo "unknown")
kubeaid_short_sha=$(git -C "${basedir}" rev-parse --short=8 HEAD 2>/dev/null || echo "")
echo "kubeaid=${kubeaid_version_desc} (${kubeaid_short_sha})  kube-prometheus=${kube_prometheus_release}  cluster=${cluster_name}  elapsed=$((build_end - build_start))s"
echo "  👉 ${outdir}"

if ((commit)); then
  if git -C "${cluster_dir}" diff --quiet -- kube-prometheus/ && git -C "${cluster_dir}" diff --cached --quiet -- kube-prometheus/; then
    echo "Nothing to commit in ${cluster_dir}/kube-prometheus"
    git -C "${cluster_dir}" checkout -q "${_original_branch}"
    git -C "${cluster_dir}" branch -q -d "${_new_branch}"
  else
    git -C "${cluster_dir}" add kube-prometheus/
    echo ""
    git -C "${cluster_dir}" diff --cached --stat
    echo ""

    if command -v gpg >/dev/null 2>&1 && gpg --card-status >/dev/null 2>&1; then
      echo "  >>> Touch your YubiKey to sign the commit <<<"
      echo ""
    fi

    if ! git -C "${cluster_dir}" commit -m "kube-prometheus: rebuild manifests for ${cluster_name} (${kube_prometheus_release})" 2>/dev/null; then
      echo "ERROR: GPG signing failed — YubiKey not touched in time or cancelled"
      echo ""
      echo "  Branch: ${_new_branch}"
      echo "  Retry:  git -C '${cluster_dir}' checkout '${_new_branch}' && git commit"
      git -C "${cluster_dir}" checkout -q "${_original_branch}"
      exit 1
    fi

    git -C "${cluster_dir}" checkout -q "${_original_branch}"

    echo ""
    read -rp "Push branch '${_new_branch}' or rebase into '${_original_branch}'? [push/rebase] " _action
    case "${_action}" in
    push)
      git -C "${cluster_dir}" push origin "${_new_branch}"
      ;;
    rebase)
      git -C "${cluster_dir}" rebase "${_new_branch}"
      git -C "${cluster_dir}" branch -d "${_new_branch}"
      ;;
    *)
      echo "Unknown action '${_action}', branch '${_new_branch}' left as-is"
      ;;
    esac
  fi
fi
