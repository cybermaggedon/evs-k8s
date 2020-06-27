
// Import KSonnet library.
local k = import "defs.libsonnet";

local analytics = [
  {n: "evs-geoip", v: "0.2.0"},
  {n: "evs-detector", v: "0.2.1"},
  {n: "evs-elasticsearch", v: "0.2.0"},
  {n: "evs-threatgraph", v: "0.2.1"},
  {n: "evs-riskgraph", v: "0.2.1"},
  {n: "evs-cassandra", v: "0.2.0"}
];

local analytic(config, name, version, replicas) =
    local image = "docker.io/cybermaggedon/" + name + ":" + version;
    k.simple.new(name) +
        k.simple.image(image) +
        k.simple.component("analytics") +
        k.simple.replicas(replicas) +
        k.simple.envs([
            {name: "PULSAR_BROKER", value: "pulsar://exchange:6650"}
        ]) +
        k.simple.limits({
            memory: "256M", cpu: "1.0"
        }) +
        k.simple.requests({
            memory: "256M", cpu: "0.05"
        });


local all(config) = {
    resources:: [
       analytic(config, a.n, a.v, 1)
       for a in analytics
    ]
};

[all]

