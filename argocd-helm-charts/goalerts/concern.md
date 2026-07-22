# GoAlert chart – concerns

Concerns with the GoAlert chart (app `v0.32.0`, based on `tokens-studio/goalert`
0.0.5, now **flattened and maintained in-tree**). Ordered by impact.

Since the last review the chart was flattened and the **bundled Bitnami
PostgreSQL was removed** (→ CloudNativePG via kubeaid-addons). That resolves the
Bitnami concern and the hardcoded-password concern, but the in-tree + external-DB
approach introduces new ones (see "New concerns").

## Open concerns (still apply)

### 1. Secrets rendered as plaintext env (unless `existingSecret` is used)
When `goalert.existingSecret.name` is empty, the chart injects `GOALERT_DB_URL`
and `GOALERT_DATA_ENCRYPTION_KEY` directly into the Deployment as `value:`, and
`goalert.databaseUrl` bakes the DB **password into the connection string** in the
pod spec. Result: secrets visible in `kubectl get deploy -o yaml`, ArgoCD UI, and
git history if committed.
Status: **mitigated** — our `values.yaml` sets `existingSecret.name: goalert`.
→ Keep it non-empty. Never fall back to the plaintext `environment.*` path.

### 2. `GOALERT_DATA_ENCRYPTION_KEY` is a one-way trap
Empty by default (no at-rest encryption). Once set and data is written,
**losing or rotating it makes that data unrecoverable**. Generate once, store
durably (sealed-secret + backup), never change casually.

### 3. Naive health probes → possible crash-loop on first boot
`liveness` and `readiness` both `httpGet /` on 8081 with **no
`initialDelaySeconds`**. GoAlert runs DB migrations on startup; if `/` isn't
serving 200 quickly (migrations, cold DB), liveness can kill the pod before it's
ready. Tune delays / use a proper health path. (We own the template now — fix
directly.)

### 4. No security context, no resource limits by default
`podSecurityContext` / `securityContext` are `{}` (container may run as root; no
`readOnlyRootFilesystem`, no dropped caps) and `resources: {}` (no
requests/limits). Set these in `values.yaml`.

### 5. Missing public-URL wiring
The template only injects DB URL + encryption key — no `GOALERT_PUBLIC_URL`.
GoAlert needs its public URL for auth callbacks and generated links; some
features silently break without it. No extra-env mechanism exists in the
template — we must add one.

## New concerns (introduced by our approach)

### 6. In-tree chart = our maintenance burden
The chart is no longer a tracked dependency, so **nothing auto-updates it**:
- GoAlert app version is pinned via `appVersion: v0.32.0` + the `image` default;
  security/bug fixes require us to manually bump and test.
- `bin/manage-helm-chart.sh --update-all` will skip it (no dependencies), so it
  won't show up in the automated update PRs — easy to forget.
→ Add a reminder/process to periodically check upstream GoAlert releases.

### 7. External-DB ordering / bootstrap dependency
GoAlert now depends on the `goalert-pgsql` CNPG cluster + its generated secret
existing first. If GoAlert syncs before CNPG provisions the cluster/secret, the
pod crash-loops (missing secret) or fails to connect.
→ Needs ArgoCD sync ordering (waves) or a resilient restart policy.

### 8. DB connection string correctness (sslmode)
`GOALERT_DB_URL` is now hand-assembled from CNPG credentials. CNPG serves TLS;
getting `sslmode` wrong (e.g. `disable` vs `require`/`verify-full`) either fails
to connect or silently drops TLS. Pin the intended `sslmode` explicitly when we
build the URL.

### 9. Stale `values.schema.json`
The schema still describes the removed bundled-Postgres values and the
`goalert.environment.*` plaintext path. Harmless (no hard `required`), but
misleading. Trim it when we next touch the chart.

## Downgraded / resolved

- **Bundled Bitnami PostgreSQL (sunset `charts.bitnami.com/bitnami`)** —
  RESOLVED: subchart removed; using CloudNativePG via kubeaid-addons.
- **Hardcoded default Postgres password `"example"`** — RESOLVED: bundled PG and
  its `auth` block are gone.
- **Unmaintained upstream chart / bus factor** — no longer an external risk (we
  own it in-tree); re-expressed as maintenance burden in #6.

## Not concerns
- No CRDs, no cluster-wide RBAC, no privileged/hostPath/hostNetwork in the
  templates — footprint is small and namespace-scoped.

## Top priority
Encryption-key durability (#2), probe crash-loop (#3), and DB ordering +
sslmode (#7, #8) are the ones that cause real pain later.
