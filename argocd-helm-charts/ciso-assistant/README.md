# CISO Assistant

CISO Assistant is an open source GRC (Governance, Risk, Compliance) platform. 

## Creating a superuser

Find your backend pod, then run `createsuperuser` inside it directly with `kubectl exec`:

```bash
kubectl exec -it <backend-pod-name> -n <namespace> -- poetry run python manage.py createsuperuser
```

It'll prompt you for email and password.

If you ever lose the password later, run `changepassword` the same way:

```bash
kubectl exec -it <backend-pod-name> -n <namespace> -- poetry run python manage.py changepassword <email>
```

## Checking if a superuser already exists

Useful if you're not sure whether someone already set one up, or you're debugging why login isn't working. Open a Django shell the same way, via `kubectl exec`:

```bash
kubectl exec -it <backend-pod-name> -n <namespace> -- poetry run python manage.py shell
```

Then:

```python
from iam.models import User
for u in User.objects.filter(is_superuser=True):
    print(u.email, u.is_active, u.date_joined)
```

This prints out every superuser account, whether it's active, and when it was created.

## Email validation

CISO Assistant sends emails for user invitations and password resets. Without SMTP configured, the app defaults to `smtp.server.local:25` which won't resolve in most clusters, causing invitation emails to silently fail.

To enable email, add the following under the `ciso-assistant:` key in your values file:

```yaml
ciso-assistant:
  backend:
    config:
      smtp:
        host: <smtp-host>       # e.g. mail.system for an in-cluster relay
        port: 587
        useTls: false           # set to true if your relay requires STARTTLS
        defaultFrom: no-reply@your-domain.com
        # Optional — only needed if your relay requires authentication:
        # username: myuser
        # password: mypassword
        # existingSecret: my-smtp-secret   # alternative: pull creds from a K8s secret
```

If you're running the `mail` chart in the same cluster as a postfix relay, the host is typically `mail.<namespace>` (e.g. `mail.system`), port `587`, with no authentication required.

To verify email is working after applying the config, add a user via the UI (**Organization → Users → Add user**) and confirm the invitation email arrives. You can also check backend pod logs for SMTP errors:

```bash
kubectl logs -n <namespace> <backend-pod-name> | grep -i smtp
```

## Adding users

Once you're logged in as admin, you don't need the CLI for this - there's a normal UI flow.

In the app: **Organization → Users → Add user**. Enter their email, assign a role (regular user, admin, etc., depending on what's configured under access control), and save.

The admin "add user" form doesn't ask you to set a password. It creates the account and fires off an invitation email with a link for the user to set their own password.

## Adding admin users

Same flow as adding a normal user, just assign the admin role/group when creating them (or edit an existing user and change their group afterward: Organization → Users → select user → update their role).

## Storing evidence

Evidence in CISO Assistant is what justifies a compliance requirement's status, or proves a control was actually applied. It's attached at the requirement level inside a compliance assessment/audit.

Each piece of evidence supports:

- A **description** - what it shows
- A **file** - upload something directly
- A **link** - point to wherever the actual artifact already lives

If your controls already live somewhere else - a git repo, a wiki, a ticketing system - you don't need to duplicate that content into CISO Assistant. You just link to it and add a short description of what it proves. Keeps a single source of truth instead of two copies that can drift out of sync.
