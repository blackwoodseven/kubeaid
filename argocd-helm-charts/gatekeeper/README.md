# Gatekeeper

[OPA Gatekeeper](https://open-policy-agent.github.io/gatekeeper/website/) is an admission
controller/policy engine for Kubernetes. It enforces (or dry-run reports on) custom policies,
written in [Rego](https://www.openpolicyagent.org/docs/latest/policy-language/), against incoming
API requests via `ConstraintTemplate`/Constraint CRDs.

This wrapper (chart version 3.11.0) pins the upstream `gatekeeper/gatekeeper` chart (currently
`3.23.0`, from `https://open-policy-agent.github.io/gatekeeper/charts`) and ships two
KubeAid-authored policies plus a network policy.

## Why it's in KubeAid

Gatekeeper is KubeAid's admission-time policy engine — it can block or flag Kubernetes objects that
don't meet cluster rules before they're created, as opposed to Kyverno's chart in this repo, which
in KubeAid is scoped specifically to mutating image references for Harbor proxy-cache (see
[../kyverno/README.md](../kyverno/README.md)) rather than general admission policy.

## Prerequisites

- The [OPA CLI](https://github.com/open-policy-agent/opa/releases) to run policy unit tests locally
  (`make test`, see below).

## Key values / KubeAid-specific configuration

- `networkPolicy: true` (default) — renders `templates/networkpolicy.yaml`, a Calico-flavored
  `NetworkPolicy` (`crd.projectcalico.org/v1`) restricting the Gatekeeper pod's egress to the
  apiserver on 443.
- `policy.RequireRequestCpuMemAndLimitMem: true` (default) — enables
  `templates/K8sRequiredResources.yaml`, a `ConstraintTemplate`/`K8sRequiredResources` constraint
  (backed by `policies/K8sRequiredResources.rego`) requiring every Pod to set CPU+memory requests
  and a memory limit.
- `policy.CronJobForbidConcurrency` — enables `templates/CronJobForbidConcurrency.yaml`, intended to
  require CronJobs to set `concurrencyPolicy: Forbid`.
- `policy.ExcludedNamespaces` — list of namespaces excluded from both constraints above.
- `policy.EnforcementAction` (default `dryrun` when unset) — passed straight through to each
  constraint's `enforcementAction`; set to `deny` to actually block non-conforming objects instead
  of just reporting violations.
- `gatekeeper.revisionHistoryLimit: 0`.

## Operational notes

- `templates/CronJobForbidConcurrency.yaml` loads its Rego body via
  `.Files.Get "policies/CronJobsPolicy.rego"`, but the file actually shipped under `policies/` is
  named `CronJobForbidConcurrency.rego`. `.Files.Get` silently returns an empty string for a missing
  path, so as currently wired this `ConstraintTemplate` renders with no policy logic — worth fixing
  or confirming intentional before relying on `policy.CronJobForbidConcurrency`.
- Policies live under `policies/*.rego` with matching `*_test.rego` files, and are unit-tested with
  `make test` (wraps `opa test -v ./policies`) — see `argocd-helm-charts/gatekeeper/policies` and
  `Makefile`.
- Because ArgoCD renders everything from `helm template` in one pass, make sure `ConstraintTemplate`s
  sync before their corresponding Constraint CRs — Gatekeeper generates the CRD for each policy from
  the template, so a Constraint applied first will fail.
- If Gatekeeper pods CrashLoopBackOff on bare-metal clusters after enabling the network policy,
  that's usually the readiness/liveness probes failing under the policy; set `networkPolicy: false`
  as a workaround.
- If `kubectl describe <ConstraintKind>` shows a violation count higher than the violations listed,
  raise `constraintViolationsLimit` in the upstream Gatekeeper values.
- Check violations for the shipped policies with `kubectl describe K8sRequiredResources` /
  `kubectl describe CronJobForbidConcurrency`.

### Adding a new policy

- Write a `.rego` file describing the policy (Constraint Framework) under
  `argocd-helm-charts/gatekeeper/policies`.
- Add a `ConstraintTemplate` that imports the policy, and a `Constraint` describing which Kubernetes objects it
  applies to; combine both into a single manifest under `argocd-helm-charts/gatekeeper/templates`.
- Test locally with the OPA CLI:

  ```sh
  cd argocd-helm-charts/gatekeeper
  make test
  ```

- Verify the rendered objects with `helm template` before pushing.

## Docs links

- Upstream chart: <https://github.com/open-policy-agent/gatekeeper/tree/master/charts/gatekeeper>
- Gatekeeper docs: <https://open-policy-agent.github.io/gatekeeper/website/docs/howto>
- Policy library: <https://github.com/open-policy-agent/gatekeeper-library>
- Rego: <https://www.openpolicyagent.org/docs/latest/policy-language/>
- Constraint Framework: <https://github.com/open-policy-agent/frameworks/tree/master/constraint>
