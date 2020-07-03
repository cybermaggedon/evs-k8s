
// Import definitions for everything
std.flattenArrays([
    import "namespace.jsonnet",
    import "gaffer/resources.jsonnet",
    import "elasticsearch.jsonnet",
    import "kibana.jsonnet",
    import "cassandra.jsonnet",
    import "pulsar.jsonnet",
    import "pulsar-manager.jsonnet",
    import "grafana.jsonnet",
    import "prometheus.jsonnet",
    import "cybermon.jsonnet",
    import "analytics/analytics.jsonnet",
    import "vouch.jsonnet",
    import "nginx.jsonnet",
    import "keycloak.jsonnet"
])

