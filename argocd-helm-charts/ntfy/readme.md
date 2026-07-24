# ntfy

ntfy - simple HTTP-based pub-sub notification service.

## 1. How to setup

ntfy keeps its message cache and user DB on disk, so enable persistence. By default ntfy is fully open (anyone can read/publish) - lock it down with `deny-all` + login. Minimal values:

```yaml
ntfy:
  persistence:
    enabled: true          # PVC for cache + user DB
  ntfy:
    baseURL: "https://ntfy.example.com"
    behindProxy: true      # TLS terminated at the ingress
    cache:
      file: /data/cache.db # keep cached messages across restarts
    auth:
      file: /data/user.db  # user DB on the PVC
      defaultAccess: deny-all
    enableLogin: true      # allow web/app login
    enableSignup: false    # no self-registration
```

## 2. Users & tokens

Under `deny-all` nobody has access until you create accounts. There is **no admin
UI** for this - use the CLI inside the pod (stored in the user DB on the PVC):

```bash
NS=ntfy

# admin (read+write to every topic):
kubectl -n "$NS" exec -it deploy/ntfy -- ntfy user add --role=admin admin

# regular user + grant read on a topic (users have no access until granted):
kubectl -n "$NS" exec -it deploy/ntfy -- ntfy user add alice
kubectl -n "$NS" exec -it deploy/ntfy -- ntfy access alice mytopic read

# a machine publisher: a user + write grant + a token (machines can't log in):
kubectl -n "$NS" exec -it deploy/ntfy -- ntfy user add bot
kubectl -n "$NS" exec -it deploy/ntfy -- ntfy access bot mytopic write
kubectl -n "$NS" exec    deploy/ntfy -- ntfy token add bot   # -> tk_...
```

Humans log in with username + password (web/app). Machines that can't set headers
(e.g. a webhook) pass the token in the URL:

```bash
echo -n "Bearer tk_xxxx" | base64 | tr '+/' '-_' | tr -d '='
# -> https://ntfy.example.com/mytopic?auth=<encoded>
```

## Configuration

| Value | Default | Notes |
|---|---|---|
| `ntfy.ntfy.baseURL` | - | Public URL ntfy serves on |
| `ntfy.ntfy.auth.defaultAccess` | `read-write` | Set `deny-all` to lock it down |
| `ntfy.ntfy.auth.file` | - | User DB path; needs persistence (`/data/user.db`) |
| `ntfy.ntfy.enableLogin` | `false` | `true` to allow web/app login |
| `ntfy.persistence.enabled` | `false` | `true` to persist cache + users |
| `ntfy.networkPolicy.enabled` | `false` | Off by default |
| `ntfy.ingress.enabled` | `false` | Set host/class/TLS to expose |

Upstream chart: https://codeberg.org/wrenix/helm-charts (ntfy)
