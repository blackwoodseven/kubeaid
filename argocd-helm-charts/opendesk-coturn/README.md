# Coturn Helm Chart

This chart installs a STUN/TURN relay server, which is a specialized piece of networking infrastructure used to make audio and video calls work reliably. Used in Opendesk for Jitsi, Element etc.

## Why it's in KubeAid

[openDesk](https://opendesk.eu/) (the German government's sovereign digital-workplace suite) needs a
STUN/TURN relay for its Jitsi (video) and Element (Matrix) apps to punch through NAT — this chart supplies it
when running openDesk on a KubeAid cluster.

## Status

`Chart.yaml` marks the direct `coturn` dependency as commented out, with a note that this chart is ~2 years
old and should be replaced with a plain upstream coturn chart. A vendored copy still lives under
`charts/coturn` (pinned in `Chart.lock`); there's no wrapper `values.yaml` at this chart's root today, so
overrides go directly against `charts/coturn/values.yaml`'s keys.