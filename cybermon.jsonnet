
// Import KSonnet library.
local k = import "defs.libsonnet";

local cfg = importstr "protostream.lua";

local pulsar(config) = {

    // Ports used by deployments
    local ports() = [
        k.containerPort.newNamed("etsi", 9000),
        k.containerPort.newNamed("metrics", 8088)
    ],

    // Volume mount points
    local volumeMounts = [
        k.mount.new("config", "/usr/local/share/cyberprobe")
    ],

    // Environment variables
    local envs = [
          {name: "PULSAR_BROKER", value: "ws://exchange:8080"}
    ],

    local lua_cfg = "/usr/local/share/cyberprobe/protostream.lua",

    // Container definition.
    local containers = [
        k.container.new("cybermon",
                        "docker.io/cybermaggedon/cyberprobe:2.5.1") +
            k.container.command(["cybermon", "-p", "9000", "-c",  lua_cfg]) +
            k.container.ports(ports()) +
            k.container.volumeMounts(volumeMounts) +
            k.container.env(envs) +
            k.container.limits({
                memory: "256M", cpu: "1.0"
            }) +
            k.container.requests({
                memory: "256M", cpu: "0.1"
            }),
        k.container.new("evs-input",
                        "docker.io/cybermaggedon/evs-input:0.4.2") +
            k.container.limits({
                memory: "128M", cpu: "1.0"
            }) +
            k.container.requests({
                memory: "128M", cpu: "0.1"
            })
    ],

    local configMaps = [
        k.configMap.new("cybermon-config") +
            k.configMap.labels({app: "cybermon", component: "cybermon"}) +
            k.configMap.data({"protostream.lua": cfg})
    ],

    // Volumes - this invokes a pvc
    local volumes = [
        k.volume.new("config") +
            k.volume.fromConfigMap("cybermon-config")
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
            k.deployment.containers(containers) +
            k.deployment.volumes(volumes)
    ],

    // Ports declared on the service.
    local servicePorts = [
        k.svcPort.newNamed("etsi", 9000,  9000) + k.svcPort.protocol("TCP"),
        k.svcPort.newNamed("metrics", 8088,  8088) + k.svcPort.protocol("TCP")
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
    resources:: deployments + services  + configMaps

};

// Return the function which creates resources.
[pulsar]

