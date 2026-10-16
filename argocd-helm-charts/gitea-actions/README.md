# Gitea Actions

Runs a Gitea Actions runner using Gitea's official [`actions`](https://gitea.com/gitea/helm-actions) chart:
a StatefulSet with the `gitea/runner` container and a `docker:dind` sidecar that runs the job containers.

Replaces the `gitea-runner` chart, which vendors an unmaintained community chart and the `vegardit`
dind image. That image hardwires `iptables-legacy`, so dockerd does not start on nodes without legacy
`ip_tables` modules (e.g. Ubuntu 26.04, kernel 7.x). The official `docker:dind` image picks the
backend itself.

The upstream chart is vendored unmodified under `charts/actions`; all settings are values.

* Create the runner token

```sh
kubectl create secret generic gitea-runner-token --namespace gitea --dry-run=client --from-literal=act-runner-token='lolmyrunnertoken' -o yaml | kubeseal --controller-namespace system --controller-name sealed-secrets -o yaml
```

## Labels and parallel jobs

Both live in the runner config (`runner.capacity` is the number of parallel jobs):

```yaml
actions:
  giteaRootURL: https://gitea.example.com
  statefulset:
    runner:
      config: |
        log:
          level: info
        runner:
          capacity: 5
          labels:
            - "ubuntu-latest:docker://ghcr.io/catthehacker/ubuntu:act-24.04"
        cache:
          enabled: false
        container:
          require_docker: true
          docker_timeout: 300s
```

`config` replaces the default as a whole, so keep the `container` block.

## Private registry auth for job images

The runner pulls job images through the dind sidecar with the credentials in `DOCKER_CONFIG`. Mount a
`.dockerconfigjson` secret (sealed or normal) into the runner container:

```yaml
actions:
  statefulset:
    extraVolumes:
      - name: registry-auth
        secret:
          secretName: gitea-runner-registry
          items:
            - key: .dockerconfigjson
              path: config.json
    runner:
      extraVolumeMounts:
        - name: registry-auth
          mountPath: /docker-auth
          readOnly: true
      extraEnvs:
        - name: DOCKER_CONFIG
          value: /docker-auth
```

Without it, jobs fail with `pull access denied ... no basic auth credentials`.

## CI deploy access

`runner.nameSpace` and `runner.serviceAccount` create a namespace and a ServiceAccount with an admin Role
in it, plus a long-lived token secret (`<serviceAccount.name>-secret`) for CI jobs that deploy there.
The keys and object names match the `gitea-runner` chart, so moving between the two keeps the token.

```yaml
runner:
  nameSpace:
    create: true
    name: obmondo-gitea-ci
  serviceAccount:
    create: true
    name: obmondo-gitea-ci
```

## Migrating from gitea-runner

* `act_runner.instance` -> `actions.giteaRootURL`
* `act_runner.existingToken` -> `actions.existingSecret` (key `act-runner-token` is the default here)
* `act_runner.labels`, `act_runner.parallel_jobs` -> `runner.labels`, `runner.capacity` in `actions.statefulset.runner.config`
* `act_runner.registrySecretName` -> the registry auth block above
* `act_runner.storage.size` / `storageclass` -> `actions.statefulset.persistence.size` / `actions.global.storageClass`

The runner registers again under a new name; delete the old one in the Gitea UI afterwards. The old
Deployment and its PVC are not adopted by this chart and have to be removed.
