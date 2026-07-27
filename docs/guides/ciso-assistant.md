# CISO Assistant

[CISO Assistant](https://github.com/intuitem/ciso-assistant-community) is an open-source **GRC
(Governance, Risk, Compliance)** platform included in KubeAid. It helps teams manage compliance
frameworks, risk assessments, and audit evidence in one place.

## What It Does

- Maps controls to compliance frameworks (ISO 27001, SOC 2, NIST, etc.)
- Tracks risk assessments and treatment plans
- Stores audit evidence with descriptions, file uploads, or links to external sources
- Manages user roles and access control for compliance workflows

## Deployment

CISO Assistant is deployed via the `ciso-assistant` Helm chart in ArgoCD. See the
[chart README](../../argocd-helm-charts/ciso-assistant/README.md) for full setup instructions,
including:

- **Superuser creation** - `kubectl exec` into the backend pod to run `createsuperuser`
- **Email / SMTP configuration** - required for user invitations and password resets
- **User management** - add users and assign roles via the web UI
- **Evidence storage** - attach descriptions, files, or links at the requirement level

## Quick Start

After the chart is deployed and synced via ArgoCD:

1. **Create a superuser:**

   ```bash
   kubectl exec -it <backend-pod-name> -n <namespace> -- \
     poetry run python manage.py createsuperuser
   ```

2. **Access the UI** via the configured ingress and log in with the superuser credentials.

3. **Configure email** (optional but recommended for invitations):

   ```yaml
   ciso-assistant:
     backend:
       config:
         smtp:
           host: mail.system        # In-cluster relay, or your SMTP host
           port: 587
           defaultFrom: no-reply@your-domain.com
   ```

4. **Add users** via **Organisation → Users → Add user** in the web UI.

## Evidence Approach

Evidence in CISO Assistant justifies a compliance requirement's status. Each piece of evidence
supports a **description**, a **file upload**, or a **link** to an external source. If your controls
already live in a Git repository, wiki, or ticketing system, link to them rather than duplicating
content.

## See Also

- [Chart README](../../argocd-helm-charts/ciso-assistant/README.md) - full deployment and
  configuration reference
- [Cilium Host-Firewall](./cilium-host-firewall.md) - network-level security hardening
