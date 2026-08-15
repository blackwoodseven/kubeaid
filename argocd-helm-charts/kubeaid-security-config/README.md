## Overview

This chart provides a centralised way to manage resource and security-related configurations for your kubernetes cluster.

Today the only thing it renders is `ResourceQuota` objects, one per namespace, from `values.yaml`.

## Why it's in KubeAid

Namespace-level abuse (e.g. a runaway CronJob spawning unbounded Jobs) is capped declaratively per cluster,
instead of every app team having to remember to set their own quotas.

## Key values

`resourceQuota.namespaces.<namespace>` is a map of namespace name to a `ResourceQuota` spec's `hard` limits
(any valid `ResourceQuota` key, e.g. `count/jobs.batch`). Each entry renders a `ResourceQuota` named
`resource-quota` in that namespace (`templates/resource-quota.yaml`). Empty/omitted `resourceQuota` renders
nothing.

Example value files can be found [here](./example/).
