// based on Prometheus alert by GitHub user raqqun:
// https://github.com/vmware-tanzu/velero/issues/2725#issuecomment-661577500
{
  _config+:: {
    selector: '',
  },

  prometheusAlerts+:: {
    groups+: [
      {
        name: 'velero',
        rules: [
          {
            alert: 'VeleroUnsuccessfulBackup',
            expr: |||
              (
                (
                  (time() - velero_backup_last_successful_timestamp{schedule=~".*6hrly.*"} > (60 * 60 * 6))
                  and on(schedule) (velero_backup_attempt_total{schedule=~".*6hrly.*"} > 0)
                  and on() hour() >= 6
                )
                or
                (
                  time() - max without (schedule) (
                    label_replace(velero_backup_last_successful_timestamp{schedule=~".*(daily|weekly).*"}, "location", "offsite", "schedule", ".*-offsite")
                  ) > (60 * 60 * 24)
                )
              )
            ||| % $._config,
            'for': '60m',
            labels: {
              severity: 'warning',
            },
            annotations: {
              description: 'The newest successful Velero backup{{ with $labels.location }} ({{ . }} copy){{ end }}{{ with $labels.schedule }} for schedule {{ . }}{{ end }} completed {{ $value | humanizeDuration }} ago. The backup that should have replaced it did not complete.',
              summary: 'Velero backup for schedule was unsuccessful.',
            },
          },
          {
            alert: 'VeleroNoFirstSuccessfulBackup',
            expr: |||
              (
                (
                  absent(velero_backup_last_successful_timestamp{schedule=~".*(daily|6hrly|weekly).*"})
                  or
                  velero_backup_last_successful_timestamp{schedule=~".*(daily|6hrly|weekly).*"} == 0
                )
                and on() (up{pod=~".*velero.*"} == 1)
                and on() ((time() - process_start_time_seconds{pod=~".*velero.*"}) > (60 * 60 * 25))
              )
            ||| % $._config,
            'for': '15m',
            labels: {
              severity: 'critical',
              schedule: '{{ $labels.schedule }}',
            },
            annotations: {
              summary: 'Velero backup has not completed once successfully for any schedule.',
              description:
                '{{- with $labels.schedule -}} No successful Velero backups have been detected for schedule: {{ . }} while the Velero pod is running.This likely indicates a configuration or permission issue preventing backups from completing. {{- else -}} Velero backup metrics are missing while the Velero pod is running. This may indicate that the backup metric is not being emitted or there is a configuration/permission issue. {{- end }}',
            },
          },
        ],
      },
    ],
  },
}
