# Relate

[RELATE](https://relate.readthedocs.io/) is an open-source e-learning platform (courses, exams, flow-based
content). This chart runs it with a `cloudnative-pg`-backed PostgreSQL instance (see `values.yaml`
`global.postgresql`) and an nginx sidecar for static/media assets.

## Why it's in KubeAid

Self-hosted courses/exams (`relate.obmondo.com`) without depending on a SaaS LMS, with backups and network
policy already wired through `kubeaid-addons` (the `global.postgresql.cnpg`/`netpol` blocks in `values.yaml`).

## Flow for giving user a course and exam

1. create user under admin->users - be sure to set user to "active" (under continue editing).
   The password you give the user is irrelevant as they will never know it.
   Do NOT enter the users email! (only set active and confirm name)
   **OR** if you have social auth like keycloak etc configured it will create a user for you when they login.
2. browse to the course you want enroll the new user in, and select "staff->impersonsate" - and impersonate the user. i
   Then click "Enroll" on the course page. **OR** you can configure course to be auto enrolled by users in course settings.
3. provided you already HAVE an exam setup for the course - go to "staff->issue exam tickets"
   and issue ticket - and share a text like this:

```url
Please go to https://relate.obmondo.com/exam-check-in/ and login with username: <username-given> and code: <code>
```
