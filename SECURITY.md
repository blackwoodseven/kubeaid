# Security Policy

## Reporting a Vulnerability

Please **do not** open a public GitHub issue for security vulnerabilities.

Report it privately via
[GitHub Security Advisories](https://github.com/Obmondo/KubeAid/security/advisories/new)
for this repository. A maintainer (see [MAINTAINERS.md](MAINTAINERS.md)) will
acknowledge the report, work with you to understand and validate the impact,
and coordinate a fix and disclosure timeline before any public advisory goes
out.

If you'd rather not use GitHub, you can also report security issues directly
to [info@obmondo.com](mailto:info@obmondo.com).

## Supported Versions

KubeAid delivers updates on the `master` branch — clusters are kept current by
pulling the latest state into your mirror; there are no long-term-support
branches. Security fixes for the charts and defaults land on `master` as part
of the regular update cycle — please update your mirror before reporting an
issue that may already be fixed.

## Scope

This policy covers the contents of this repository: the Helm chart wrappers in
`argocd-helm-charts/`, their default values, and the Jsonnet-based monitoring
configuration. Vulnerabilities in the upstream applications packaged by these
charts should be reported to those projects directly — though we track their
releases and ship updated chart versions as part of the regular update cycle.
