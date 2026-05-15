function(etcdMetrics)
  local labels = {
    'app.kubernetes.io/name': etcdMetrics.serviceName,
    'app.kubernetes.io/managed-by': 'kubeaid',
  };

  {
    service: {
      apiVersion: 'v1',
      kind: 'Service',
      metadata: {
        name: etcdMetrics.serviceName,
        namespace: etcdMetrics.namespace,
        labels: labels,
      },
      spec: {
        clusterIP: 'None',
        ports: [{
          name: 'metrics',
          port: etcdMetrics.port,
          targetPort: etcdMetrics.port,
          protocol: 'TCP',
        }],
      },
    },

    endpointSlice: {
      apiVersion: 'discovery.k8s.io/v1',
      kind: 'EndpointSlice',
      metadata: {
        name: etcdMetrics.serviceName,
        namespace: etcdMetrics.namespace,
        labels: labels {
          'kubernetes.io/service-name': etcdMetrics.serviceName,
        },
      },
      addressType: etcdMetrics.addressType,
      endpoints: [
        {
          addresses: [endpoint],
        }
        for endpoint in etcdMetrics.endpoints
      ],
      ports: [{
        name: 'metrics',
        port: etcdMetrics.port,
        protocol: 'TCP',
      }],
    },

    serviceMonitor: {
      apiVersion: 'monitoring.coreos.com/v1',
      kind: 'ServiceMonitor',
      metadata: {
        name: etcdMetrics.serviceName,
        namespace: etcdMetrics.serviceMonitorNamespace,
        labels: labels,
      },
      spec: {
        jobLabel: 'app.kubernetes.io/name',
        namespaceSelector: {
          matchNames: [etcdMetrics.namespace],
        },
        selector: {
          matchLabels: labels,
        },
        endpoints: [{
          port: 'metrics',
          interval: etcdMetrics.interval,
          scheme: etcdMetrics.scheme,
          path: etcdMetrics.path,
        }],
      },
    },
  }
