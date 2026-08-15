# Security Design

KubeAid's operational design aims to deliver on all three aspects of security: Confidentiality, Integrity, and
Availability. In practice this means Cilium NetworkPolicies restricting pod network access, sealed-secrets keeping
credentials encrypted in Git, and a general principle of least privilege applied throughout the stack. The sections
below explain the reasoning behind these choices.

## Confidentiality

KubeAid uses the Cilium CNI and enforces network filtering - on both ingress and egress - which means we work hard to
avoid any pod in the cluster having (or needing) internet access. In this way, should a compromise of a pod happen -
it's harder to get data out, or pull necessary code from the internet to further exploit your systems.

You can disable network filtering for any application - but do so at your own peril - with the above risk in mind.

## Integrity

### Helm chart security

We store EVERY Helm chart from an application upstream inside this repository. This has the following benefits:

- You can always install your application/do recovery - with no internet needed. If an upstream chart repo is down
  this will not affect you (and this happens quite often when you have many sources/charts in use).
- On EVERY upgrade, we review the diff of the chart for any unexpected changes, and this way we HOPE to catch a
  compromised upstream release, before it's included in this repository.
  - At the very least we can see from how other codebases has been found compromised - that this is the structure
    that enabled it to be detected.
- We run a CI job that fetches the same charts we have in our repo from the upstream chart repo, and checks if
  upstream matches OUR copy. If it does not:
  - Upstream updated an existing release - which is a VERY BAD idea.
  - Upstream Helm repo suffered a supply-chain attack.

### Docker image security

We change EVERY docker image, to use the `sha256sum` of the docker image instead of the tag. This means if an
upstream mirror (e.g. Docker Hub) is compromised (and a tag ends up pointing to a different docker image) - we will
still get the original image - or fail.

This repository has a CI job that, on every PR, fetches the docker images used and pushes them to your own docker
registry (GitHub, GitLab, or whatever you prefer), so your Kubernetes cluster doesn't talk to anything on the
Internet to pull the necessary Docker images for operations.

We also compare tag to `sha256sum` to detect any supply chain attacks (which won't affect those using this setup) so
they can be reported upstream.

We scan Docker images used for known vulnerabilities (software in the image with a known CVE, for example) and
report upstream, and if upstream will accept it we will gladly submit fixes to upstream to avoid users of this
repository deploying vulnerable code.

## Availability

Lifecycle operations such as auto-scaling, backup and recovery, and major upgrades via a parallel shadow cluster are
covered in [Basic Operations](../getting-started/basic-operations.md) and the [Cluster Design](../cluster-design.md)
document.
