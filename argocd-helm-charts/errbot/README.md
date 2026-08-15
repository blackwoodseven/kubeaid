# ErrBot Helm Chart

Errbot is a chatbot, a daemon that connects to your favorite chat service and bring your tools and some
fun into the conversation.

## Why it's in KubeAid

ChatOps in Mattermost (see the `BOT_SCHEME`/`BOT_SERVER`/`BOT_PORT` defaults in `values.yaml`, which point at
a Mattermost instance) — runs and manages an errbot instance so plugins/commands are reachable from chat
instead of the CLI. Obmondo builds its own image (`harbor.obmondo.com/obmondo/errbot`) with the backends and
plugins it needs.

You should use/build your own container image with the backends and plugins you need. You can use our
reference errbot image which allows you to configure errbot with environment variables instead of python.

Example:

```yaml
env:
  - name: BOT_SERVER
    value: "chat.example.com"
  - name: BOT_PORT
    value: "443"
  - name: BOT_SCHEME
    value: "https"
  - name: BOT_TEAM
    value: "test-team"
  - name: BOT_ADMINS
    value: "@admin,@anotheradmin"
  - name: BOT_TOKEN
    valueFrom:
      secretKeyRef:
      name: errbot-secrets
      key: bot-token
```

If you want to run plugins that require webhooks, then you can add an ingress in `values.yaml`.

If you want to execute a command in an initcontainer, ex: to change volume mount permissions then set:

```yaml
initContainerCmd: "chown -R 1000:1000 /home/errbot/data"
```

Look at `values.yaml` for other configurable options like resources, image, etc.
