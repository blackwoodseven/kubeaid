// Keycloak failed login alert, plus the upstream Keycloak dashboards.
// Login events need KC_EVENT_METRICS_USER_ENABLED=true (Keycloak 26+) and
// KC_EVENT_METRICS_USER_TAGS=realm,clientId for the realm/client_id labels.
{
  _config+:: {
    keycloakLoginWindow: '10m',
    // Share of login attempts that failed.
    keycloakFailedLoginRatio: '0.3',
    // Ignore clients with only a handful of failures (e.g. one user mistyping).
    keycloakMinFailedLogins: 20,

    // Upstream dashboards hardcode container="keycloak"; change it here if yours differs.
    dashboardContainer: 'keycloak',
    dashboardTags: ['keycloak'],
    dashboardRefresh: '1m',
    datasourceVar: 'datasource',
    datasourceRegex: '',
    // Original upstream UIDs are kept so existing links keep working.
    dashboardUids: {
      troubleshooting: 'Mh1Ly1ZNz',
      capacityPlanning: 'dtvmgcVNk',
    },
  },

  prometheusAlerts+:: {
    groups+: [
      {
        name: 'keycloak',
        rules: [
          {
            // Failed logins have a non-empty `error` label, successful ones have error="".
            alert: 'KeycloakFailedLoginsHigh',
            expr: |||
              sum by (namespace, realm, client_id) (increase(keycloak_user_events_total{event="login", error!=""}[%(keycloakLoginWindow)s]))
                /
              sum by (namespace, realm, client_id) (increase(keycloak_user_events_total{event="login"}[%(keycloakLoginWindow)s]))
                > %(keycloakFailedLoginRatio)s
              and
              sum by (namespace, realm, client_id) (increase(keycloak_user_events_total{event="login", error!=""}[%(keycloakLoginWindow)s]))
                >= %(keycloakMinFailedLogins)s
            ||| % $._config,
            'for': '10m',
            labels: {
              severity: 'warning',
            },
            annotations: {
              summary: 'Many failed keycloak logins in last %(keycloakLoginWindow)s.' % $._config,
              description: '{{ $value | humanizePercentage }} of logins failed for client {{ $labels.client_id }} in realm {{ $labels.realm }} ({{ $labels.namespace }}). Break it down by cause with sum by (error) (increase(keycloak_user_events_total{event="login", error!="", realm="{{ $labels.realm }}"}[10m])).',
            },
          },
        ],
      },
    ],
  },
} +
(import 'dashboards/dashboards.libsonnet')
