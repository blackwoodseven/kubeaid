{{/*
hetzner.clusterAutoscalerLabels

Renders a nodeGroup's `labels` map (an arbitrary key→value mapping)
as the comma-separated `key=value` string that cluster-autoscaler's
capacity.cluster-autoscaler.kubernetes.io/labels annotation expects.

Input: a nodeGroup object (a single entry from .Values.nodeGroups.*).
Output: e.g. `role=worker,zone=fsn1` — or empty string when the
nodeGroup has no labels.

Used in MachineDeployment.yaml to keep the annotation YAML readable
instead of inlining a multi-step range/append/join on one line.
*/}}
{{- define "hetzner.clusterAutoscalerLabels" -}}
{{- $labels := list -}}
{{- range $key, $value := .labels -}}
{{- $labels = append $labels (printf "%s=%s" $key $value) -}}
{{- end -}}
{{- join "," $labels -}}
{{- end -}}

{{/*
hetzner.clusterAutoscalerTaints

Renders a nodeGroup's `taints` list as the comma-separated
`key=value:effect` string that cluster-autoscaler's
capacity.cluster-autoscaler.kubernetes.io/taints annotation expects.

Input: a nodeGroup object whose `.taints` is a list of
  { key: string, value: string, effect: string }
Output: e.g. `dedicated=gpu:NoSchedule,workload=batch:PreferNoSchedule`
— or empty string when there are no taints.
*/}}
{{- define "hetzner.clusterAutoscalerTaints" -}}
{{- $taints := list -}}
{{- range $taint := .taints -}}
{{- $taints = append $taints (printf "%s=%s:%s" $taint.key $taint.value $taint.effect) -}}
{{- end -}}
{{- join "," $taints -}}
{{- end -}}

{{/* Give highest priority to the Network Card / Connection entry in the boot order.
     Otherwise, we cannot boot the servers into rescue mode, and need to reach out to the
     Hetzner support team. */}}
{{- define "hetzner.efiBootOrderScript" -}}
if [ ! -d /sys/firmware/efi ]; then
        echo "legacy BIOS boot — skipping EFI boot-order adjustment"
else
  NETBOOT=$(efibootmgr -v \
    | grep -E "Network (Card|Connection|Device)" \
    | sed 's/Boot\([0-9A-F]*\).*/\1/' \
    | head -n1)
  if [ -z "$NETBOOT" ]; then
    echo "no EFI network boot entry found — skipping boot-order adjustment"
  else
    CURRENT_ORDER=$(efibootmgr | grep "BootOrder:" | cut -d' ' -f2)
    NEW_ORDER=$(echo "$CURRENT_ORDER" | sed "s/$NETBOOT,\?//g" | sed "s/^/$NETBOOT,/" | sed 's/,$//')
    efibootmgr -o "$NEW_ORDER"
  fi
fi
{{- end -}}
