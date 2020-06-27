
// Import KSonnet library.
local k = import "defs.libsonnet";

local cybermon(config) = 
    k.simple.new("cybermon") +
      k.simple.image("docker.io/cybermaggedon/cyberprobe:2.5.1") +
      k.simple.command(["cybermon", "-p", "9000", "-c",
           "/etc/cyberprobe/pulsar.lua"]) +
      k.simple.replicas(config.cybermon.instances) +
      k.simple.ports([
          {name: "etsi", port: 9000, protocol: "TCP"}
      ]) +
      k.simple.envs([
          {name: "PULSAR_BROKER", value: "ws://exchange:8080"}
      ]) +
      k.simple.limits({
          memory: "256M", cpu: "1.0"
      }) +
      k.simple.requests({
          memory: "256M", cpu: "0.1"
      });

[cybermon]

