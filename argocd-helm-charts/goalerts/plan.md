# GoAlert – setup plan

Running GoAlert in a GitOps way, for ourselves and for customers.

## Chart source & approach

- **No official/maintained upstream chart exists.** We took the community
  `tokens-studio/goalert` chart (app `v0.32.0`), **flattened it, and now
  maintain it in-tree.** It is NOT a Helm dependency — do not
  `helm dependency update` it. Edit templates here directly.
- **Postgres:** bundled Bitnami PostgreSQL was removed. GoAlert will use a
  **CloudNativePG** cluster provisioned by the `kubeaid-addons` chart, the same
  way the `oncall` chart does (`global.postgresql` → `goalert-pgsql`).

## Done

- [x] Vendored + flattened chart (`Chart.yaml`, `templates/`, `values.yaml`,
      `values.schema.json`) — standalone, no dependencies.
- [x] Removed bundled Bitnami PostgreSQL.
- [x] `postgresql.enabled: false`; DB wired via `goalert.existingSecret`.
- [x] **CNPG database provisioned** via the `kubeaid-addons` subchart:
      symlink `charts/kubeaid-addons -> ../../kubeaid-addons` (like oncall) +
      `global.postgresql` block. Renders Cluster `goalert-pgsql` (db/owner
      `goalert`), which yields service `goalert-pgsql-rw` and CNPG-generated
      secret `goalert-pgsql-app`.
      Note: `helm lint` reports "missing dependency: kubeaid-addons" — expected,
      oncall has the identical benign error (symlinked subchart isn't in
      Chart.yaml deps).
- [x] **Ingress + ArgoCD app (kcm)** wired in kubeaid-config-enableit:
      `k8s/kcm.obmondo.com/argocd-apps/templates/goalerts.yaml` (Application,
      ns `obmondo`) + `values-goalerts.yaml` (ingress `goalerts.kcm.obmondo.com`,
      class `traefik-internal`, issuer `letsencrypt`, TLS). Both sources pinned
      to the `goalerts` branch until merged to master. Full manifest set renders
      clean (Deployment/Service/SA/Ingress/CNPG Cluster/PodMonitor).

## Missing / to add (next steps)

### 0. Sync + seal (immediate)
- Push the `goalerts` branch of both repos, then sync the `goalerts` app in
  ArgoCD on kcm. CNPG provisions `goalert-pgsql` + secret `goalert-pgsql-app`
  (GoAlert pod crash-loops until the secret exists — expected).
- Then create the sealed `goalert` secret (see #2) and re-sync.

### 1. Private DB config (kubeaid-config-enableit)
Cluster-specific `global.postgresql` bits are NOT in KubeAid — set per-cluster in
the config repo's goalert values (mirror oncall's private block):
- `backups` / `logicalbackup` (S3 bucket, endpoint, creds secret, retention),
- `size` override, `env` (AWS checksum flags), `monitoring`, `netpol` clients.

### 2. Secret wiring (org-internal → kubeaid-config-enableit)
GoAlert needs a single Secret (`goalert`) with two keys:
- `GOALERT_DB_URL` – Postgres connection string (from the CNPG creds; remember
  `sslmode`).
- `GOALERT_DATA_ENCRYPTION_KEY` – encrypts data at rest.
Two options (decide):
  - (a) Hand-built sealed Secret combining both keys, OR
  - (b) **Edit the deployment** (we own the chart now) to read `GOALERT_DB_URL`
    straight from the CNPG `goalert-pgsql-app` secret's `uri` key, and the
    encryption key from a separate small secret. Cleaner — avoids duplicating
    the DB password.

### 3. Public URL (GOALERT_PUBLIC_URL)
- Ingress is done. GoAlert still needs its public URL
  (`https://goalerts.kcm.obmondo.com`) via `GOALERT_PUBLIC_URL`. The current
  template does NOT inject it — add an env/extra-env mechanism (auth callbacks
  and generated links break without it).

### 4. Hardening (see concern.md)
- Health probes (`initialDelaySeconds` / proper path) to avoid boot crash-loop.
- `resources` requests/limits.
- `podSecurityContext` / `securityContext` (non-root, drop caps).

### 5. Notification providers (org-internal)
- SMTP / Twilio (SMS/voice) — configured in GoAlert itself; creds in
  kubeaid-config-enableit.

### 6. ArgoCD wiring (kubeaid-config-enableit)
- ArgoCD Application for `argocd-helm-charts/goalerts`, values layered
  (public defaults here + private overrides in the config repo).

### 7. Housekeeping
- Confirm `goalerts` gets picked up by the `kubeaid_apps` list
  (`build/kube-prometheus/lib/default_kubeaid_apps_vars.yaml`).
- Name nit: dir/chart is `goalerts` (plural) vs upstream `goalert`.
