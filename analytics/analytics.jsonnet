
// Import KSonnet library.
local k = import "defs.libsonnet";

local analytics = [
  {n: "evs-geoip", v: "0.3.0", e: []},
  {n: "evs-detector", v: "0.3.0", e: []},
  {n: "evs-elasticsearch", v: "0.3.0", e: [
      ["ELASTICSEARCH_URL", "http://elasticsearch:9200"]
  ]},
  {n: "evs-threatgraph", v: "0.3.0", e: [
       ["GAFFER_URL", "http://threat-graph:8080/rest/v2"]
  ]},
  {n: "evs-riskgraph", v: "0.3.0", e: [
       ["GAFFER_URL", "http://risk-graph:8080/rest/v2"]
  ]},
  {n: "evs-cassandra", v: "0.3.0", e: [
      ["CASSANDRA_CLUSTER", "cassandra"]
  ]}
];

local analytic(config, name, version, replicas, env) =
    local image = "docker.io/cybermaggedon/" + name + ":" + version;
    k.simple.new(name) +
        k.simple.image(image) +
        k.simple.component("analytics") +
        k.simple.replicas(replicas) +
        k.simple.envs([
            {name: "PULSAR_BROKER", value: "pulsar://exchange:6650"}
        ] + if env != null then [{name: e[0], value: e[1]} for e in env] else []
        ) +
        k.simple.limits({
            memory: "128M", cpu: "1.0"
        }) +
        k.simple.requests({
            memory: "128M", cpu: "0.05"
        });


local all(config) = {
    resources:: std.flattenArrays([
       analytic(config, a.n, a.v, 1, a.e).resources
       for a in analytics
    ])
};

[ all
]

