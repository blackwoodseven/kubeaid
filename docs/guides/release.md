# KubeAid Release

* Update the kubeaid managed helm charts, and raise the PR

```sh
./bin/manage-helm-chart.sh --update-all
Branch 'Helm_Update_20260119_MjA5NDkK' set up to track remote branch 'master' from 'origin'.
Switched to a new branch 'Helm_Update_20260119_MjA5NDkK'
Current KubeAid version: 22.0.0
Helm chart argo-cd is cached and on latest version 9.2.4, locally on the filesystem
Helm chart argocd-image-updater is cached and on latest version 1.0.4, locally on the filesystem
Helm chart aws-ebs-csi-driver is cached and on latest version 2.54.1, locally on the filesystem

...skipping
```

* Once the above PR is merged, release it.

```sh
./bin/release.sh
Generating release notes since 22.0.0..23.0.0
Release notes generated: CHANGELOG.md
[master 22bed5336] chore(doc): Update changelog
 2 files changed, 178 insertions(+), 115 deletions(-)
 rewrite .release-notes.md (97%)
```
