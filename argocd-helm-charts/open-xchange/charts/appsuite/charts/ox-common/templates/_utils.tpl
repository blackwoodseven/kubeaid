{{/*
To dump any variable or value like:
  {{- $myList := (list "a" 1 "b" (dict "c" nil)) }}
just call the named template anywhere in your template, e.g.
  {{- template "ox-common.utils.dump_var" $myList }}

This will generate the following output:
    The JSON output of the dumped var is:
    [
      "a",
      1,
      "b",
      {
        "c": null
      }
    ]
*/}}
{{- define "ox-common.utils.dump_var" -}}
{{- . | mustToPrettyJson | printf "\nThe JSON output of the dumped var is: \n%s" | fail }}
{{- end -}}

{{/*
This function is designed to convert human-readable representations of data
sizes, such as "10Gi" for 10 gibibytes or "500Mi" for 500 mebibytes, into their
corresponding byte values. It supports both binary (Mi, Gi, Ti) and decimal
(M, G, T) units.

Example Usage:

{{- $size := "10Gi" -}}
{{- $convertedSize := include "ox-common.utils.convertToBytes" $size -}}
{{- printf "Converted size in bytes: %d" $convertedSize -}}

In this example, the function is used to convert the size "10Gi" (gigabytes)
into bytes. It should print "Converted size in bytes: 10737418240".
*/}}
{{- define "ox-common.utils.convertToBytes" -}}
  {{- $value := . -}}
  {{- $unit := 1.0 -}}
  {{- if typeIs "string" . -}}
    {{- $base2 := dict "Mi" 0x1p20 "Gi" 0x1p30 "Ti" 0x1p40 -}}
    {{- $base10 := dict "M" 1e6 "G" 1e9 "T" 1e12 -}}
    {{- range $k, $v := merge $base2 $base10 -}}
      {{- if hasSuffix $k $ -}}
        {{- $value = trimSuffix $k $ -}}
        {{- $unit = $v -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
  {{- mulf (float64 $value) $unit | ceil | int -}}
{{- end -}}

{{/*
This function converts a given number of bytes into a human-readable storage
size format with the specified unit. It supports both binary (powers of 2) and
decimal (powers of 10) units.

Example Usage:

{{- $bytes := 52428800 -}}
{{- $result := include "ox-common.utils.convertBytesToHumanReadable" (dict "bytes" $bytes "unit" "Mi") -}}
{{- printf "Human-readable format: %s" $result -}}

This usage converts 52428800 bytes to a human-readable format with the
specified unit "Mi" (mebibytes).
*/}}
{{- define "ox-common.utils.convertBytesToHumanReadable" -}}
  {{- $input := index . "bytes" -}}
  {{- $desiredUnit := index . "unit" -}}
  {{- $unit := "" -}}
  {{- $base2 := dict "Mi" 0x1p20 "Gi" 0x1p30 "Ti" 0x1p40 -}}
  {{- $base10 := dict "M" 1e6 "G" 1e9 "T" 1e12 -}}
  {{- $baseDict := merge $base2 $base10 -}}
  {{- if hasKey $baseDict $desiredUnit -}}
    {{- range $k, $v := $baseDict -}}
      {{- if eq $desiredUnit $k -}}
        {{- if ge (float64 $input) (float64 $v) -}}
          {{- $value := div $input $v -}}
          {{- printf "%d%s" $value $k -}}
          {{- $unit = $k -}}
          {{- break -}}
        {{- else -}}
          {{- fail "Desired unit is larger than the input value." -}}
        {{- end -}}
      {{- end -}}
    {{- end -}}
  {{- else -}}
    {{- fail (printf "Unsupported unit: %s" $desiredUnit) -}}
  {{- end -}}
{{- end -}}

{{/*
Sets the maximum JVM heap size based on the provided input in megabytes ("M").
*/}}
{{- define "ox-common.utils.setMaxJvmHeapSize" -}}
  {{- $input := . -}}
  {{- $heapRatio := 0.7 -}}
  {{- $bytes := include "ox-common.utils.convertToBytes" $input -}}
  {{- $heapSize := mulf $bytes $heapRatio -}}
  {{- $result := include "ox-common.utils.convertBytesToHumanReadable" (dict "bytes" $heapSize "unit" "M") -}}
  {{- $result -}}
{{- end -}}
