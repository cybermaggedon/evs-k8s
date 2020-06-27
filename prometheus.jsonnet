
// Import KSonnet library.
local k = import "defs.libsonnet";

local prometheus(config) = 
    k.simple.new("prometheus") +
      k.simple.image("prom/prometheus:v2.19.1") +
      k.simple.ports([
          {name: "prometheus", port: 9090, protocol: "TCP"}
      ]) +
      k.simple.limits({
          memory: "256M", cpu: "1.0"
      }) +
      k.simple.requests({
          memory: "256M", cpu: "0.05"
      });

[prometheus]

