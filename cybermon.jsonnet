
// Import KSonnet library.
local k = import "defs.libsonnet";

local cybermon(config) = {

    // Ports used by deployments
    local ports = [
        k.containerPort.newNamed("etsi", 9000)
    ],

    // Environment variables
    local envs = [
        k.env.new("PULSAR_BROKER", "ws://exchange:8080")
    ],

    // Container definition.
    local containers = [
        k.container.new("cybermon",
            "docker.io/cybermaggedon/cyberprobe:2.5.1") +
            k.container.command(["cybermon", "-p", "9000", "-c",
                 "/etc/cyberprobe/pulsar.lua"]) +
            k.container.ports(ports) +
            k.container.env(envs) +
            k.container.limits({
                memory: "256M", cpu: "1.0"
            }) +
            k.container.requests({
                memory: "256M", cpu: "0.1"
            })
    ],

    // Deployment definition.  id is the node ID.
    local deployments = [
        k.deployment.new("cybermon") +
            k.deployment.replicas(config.cybermon.instances) +
            k.deployment.labels({
                instance: "cybermon",
                app: "cybermon",
                component: "cybermon"
            }) +
            k.deployment.containerLabels({
                instance: "cybermon",
                app: "cybermon",
                component: "cybermon"
            }) +
            k.deployment.selector({
                instance: "cybermon",
                app: "cybermon",
                component: "cybermon"
            }) +
            k.deployment.containers(containers)
    ],

    // Ports declared on the service.
    local servicePorts = [
        k.svcPort.newNamed("etsi", 9000, 9000) + k.svcPort.protocol("TCP")
    ],

    local services = [

        k.svc.new("cybermon") +
            k.svc.labels({app: "cybermon", component: "cybermon"}) +
            k.svc.ports(servicePorts) +
            k.svc.selector({
                app: "cybermon", component: "cybermon"
            })

    ],

    // Function which returns resource definitions - deployments and services.
    resources:: deployments + services

};

// Return the function which creates resources.
[cybermon]

