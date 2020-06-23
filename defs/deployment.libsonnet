{

    new(name):: {
        apiVersion: "apps/v1",
        kind: "Deployment",
        metadata: {
          name: name
        },
        spec: {
            replicas: 1
        }
    },

    replicas(n):: {
        spec+: {
            replicas: n
        }
    },

    containers(l):: {
        spec+: { template+: { spec+: {
            containers: l
        }}}
    },

    volumes(v):: {
        spec+: { template+: { spec+: {
            volumes: v
        }}}
    },

    containerLabels(l):: {
        spec+: { template+: { metadata+: { labels: l } } }
    },

    labels(l):: {
        metadata+: {
            labels: l
        }
    },

    selector(l):: {
        spec+: { selector+: {
            matchLabels: l
        }}
    },

    hostname(x): {
        spec+: { template+: { spec+: {
            hostname: x
        }}}
    },
    subdomain(x): {
        spec+: { template+: { spec+: {
            subdomain: x
        }}}
    }

}