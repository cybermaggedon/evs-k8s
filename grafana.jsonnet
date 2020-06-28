
// Import KSonnet library.
local k = import "defs.libsonnet";

local grafana(config) = 
    k.simple.new("grafana") +
      k.simple.image("grafana/grafana:7.0.3") +
      k.simple.ports([
          {name: "grafana", port: 3000, protocol: "TCP"}
      ]) +
      k.simple.envs([
           {name: "GF_AUTH_ANONYMOUS_ENABLED", value: "true"},
           {name: "GF_ORG_NAME", value: "cybermaggedon"},
           {name: "GF_AUTH_ANONYMOUS_ORG_ROLE", value: "Admin"}
      ]) +
      k.simple.limits({
          memory: "256M", cpu: "1.0"
      }) +
      k.simple.requests({
          memory: "256M", cpu: "0.05"
      });

[grafana]

