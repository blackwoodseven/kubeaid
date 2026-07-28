# Customization & Extensions

This document covers customizing the Keycloak login page theme and installing custom plugins, such as the Webhook event streaming plugin.

---

## Table of Contents
- [Keycloak Custom Login Page](#keycloak-custom-login-page)
- [Adding a Webhook Event Plugin to Keycloak](#adding-a-webhook-event-plugin-to-keycloak)

---

## Keycloak Custom Login Page

* Create a new folder named `login` inside the `themes/custom` directory. To keep things simple, copy all contents of the [themes/keycloak/login](https://github.com/keycloak/keycloak/tree/main/themes/src/main/resources/theme/keycloak/login) directory.
* Change `login/resources/img/keycloak-logo-text.png` to your custom logo.
* For more theme customization details, refer to the [Keycloak Theme Guide](https://www.keycloak.org/docs/latest/server_development/index.html#creating-a-theme).
* Build and push the image to your container registry.
* In your Helm chart `values.yaml`, add the following:

  ```yaml
  extraInitContainers: |
    - name: custom-theme-provider
      image: <image>
      imagePullPolicy: IfNotPresent
      command:
        - sh
      args:
        - -c
        - |
          echo "Copying theme..."
          cp -R /custom/* /theme
      volumeMounts:
        - name: theme
          mountPath: /theme
  extraVolumeMounts: |
    - name: theme
      mountPath: /opt/keycloak/themes/bw7
  extraVolumes: |
    - name: theme
      emptyDir: {}
  ```

* Apply the changes to view the custom login page.

---

## Adding a Webhook Event Plugin to Keycloak

This guide explains how to extend Keycloak with a webhook plugin to stream login and authentication events to a remote HTTP endpoint.

### 1) Choose the webhook plugin

We use the open-source Keycloak webhook plugin:
- [vymalo/keycloak-webhook](https://github.com/vymalo/keycloak-webhook)

### 2) Download the webhook plugin using an init container

Add an init container in `values.yaml` to download the Keycloak webhook plugin JAR files before Keycloak starts:

```yaml
extraInitContainers: |
  - name: download-webhook-plugin
    image: curlimages/curl:8.5.0
    command:
      - sh
      - -c
      - |
        set -e
        mkdir -p /providers
        VERSION=0.10.0-rc.1
        curl -L -o /providers/keycloak-webhook-core.jar \
          https://github.com/vymalo/keycloak-webhook/releases/download/v${VERSION}/keycloak-webhook-provider-core-${VERSION}-all.jar
        curl -L -o /providers/keycloak-webhook-http.jar \
          https://github.com/vymalo/keycloak-webhook/releases/download/v${VERSION}/keycloak-webhook-provider-http-${VERSION}-all.jar
    volumeMounts:
      - name: providers
        mountPath: /providers
```

### 3) Mount the plugin directory into Keycloak

Add an `emptyDir` volume and mount it into Keycloak’s `providers` directory:

```yaml
extraVolumes: |
  - name: providers
    emptyDir: {}

extraVolumeMounts: |
  - name: providers
    mountPath: /opt/keycloak/providers
```

### 4) Configure webhook environment variables

Add environment variables for target endpoint and event types:

> **Important Notes:**
> * If these variables are missing, the event listener cannot be added in the Keycloak UI.
> * Ensure `extraEnv` does **not overwrite existing environment variables** when syncing via ArgoCD.

```yaml
extraEnv: |
  - name: WEBHOOK_HTTP_BASE_PATH
    value: "http://webhook-test:9000"
  - name: WEBHOOK_EVENTS_TAKEN
    value: "LOGIN,LOGIN_ERROR"
```

### 5) Enable events in Keycloak

1. Log in to the **Keycloak Admin Console**
2. Select the target **realm** (⚠️ Do **not** use the `master` realm)
3. Navigate to **Realm Settings → Events**
4. Under **Event Listeners**, add **`webhook-http`**
5. Click **Save**

### 6) Deploy a test webhook receiver

Create a lightweight test pod to verify incoming webhook events:

```sh
kubectl run webhook-test \
  --image=busybox \
  --restart=Never \
  -- sh -c "while true; do nc -l -p 9000 -v; done"
kubectl expose pod webhook-test --port=9000
```

### 7) Authentication note

> *Note*: Only basic auth is supported for headers currently.
