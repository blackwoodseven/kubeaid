{
  blackboxOauthModule(tokenUrl, clientId, mountPath, scopes=['openid']):: {
    prober: 'http',
    http: {
      preferred_ip_protocol: 'ip4',
      headers: { Accept: 'text/html' },
      oauth2: {
        client_id: clientId,
        client_secret_file: mountPath + '/client_secret',
        token_url: tokenUrl,
        scopes: scopes,
      },
    },
  },

  ingress(name, namespace, rules, tls, annotations):: {
    apiVersion: 'networking.k8s.io/v1',
    kind: 'Ingress',
    metadata: {
      name: name,
      namespace: namespace,
      annotations: annotations,
    },
    spec: {
      rules: rules,
      [if tls != null then 'tls']: tls,
    },
  },

}
