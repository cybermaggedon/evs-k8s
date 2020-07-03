
// Import KSonnet library.
local k = import "defs.libsonnet";

local analytics = [
  {n: "evs-geoip", v: "0.4.2", e: []},
  {n: "evs-detector", v: "0.4.2", e: []},
  {n: "evs-elasticsearch", v: "0.4.4", e: [
      ["ELASTICSEARCH_URL", "http://elasticsearch:9200"]
  ]},
  {n: "evs-threatgraph", v: "0.4.2", e: [
       ["GAFFER_URL", "http://threat-graph:8080/rest/v2"]
  ]},
  {n: "evs-riskgraph", v: "0.4.2", e: [
       ["GAFFER_URL", "http://risk-graph:8080/rest/v2"]
  ]},
  {n: "evs-cassandra", v: "0.4.2", e: [
      ["CASSANDRA_CLUSTER", "cassandra"]
  ]}
];

local an(config, name, version, replicas, env) =
    local image = "docker.io/cybermaggedon/" + name + ":" + version;
    k.simple.new(name) +
        k.simple.image(image) +
        k.simple.ports([
            {name: "metrics", port: 8088, protocol: "TCP"}
        ]) +
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

local analytic(name, version, replicas, env) =
    local h(config) = an(config, name, version, replicas, env); h;

local all = [
    analytic(a.n, a.v, 1, a.e)
    for a in analytics
//  analytic("asd", "def", 1, [])
];

/*
local all(config) = {
    resources:: std.flattenArrays([
       analytic(config, a.n, a.v, 1, a.e).resources
       for a in analytics
    ])
};
*/

//[ all
//]

all


