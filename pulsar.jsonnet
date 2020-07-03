
// Import KSonnet library.
local k = import "defs.libsonnet";

local pulsar(config) = {

    name::  "pulsar",
    images:: ["apachepulsar/pulsar:2.5.1"],

    // Ports used by deployments
    local ports() = [
        k.containerPort.newNamed("pulsar", 6650),
        k.containerPort.newNamed("websocket", 8080)
    ],

    // Volume mount points
    local volumeMounts(id) = [
        k.mount.new("data", "/pulsar/data")
    ],

    // Environment variables
    local envs = [
        k.env.new("PULSAR_MEM", "-Xms128M -Xmx300M")
    ],

    // Container definition.
    local containers(id) = [
        k.container.new("pulsar", self.images[0]) +
            k.container.command(["bin/pulsar", "standalone"]) +
            k.container.ports(ports()) +
            k.container.volumeMounts(volumeMounts(id)) +
            k.container.env(envs) +
            k.container.limits({
                memory: "700M", cpu: "1.0"
            }) +
            k.container.requests({
                memory: "700M", cpu: "0.1"
            })
    ],

    // Volumes - this invokes a pvc
    local volumes(id) = [
        k.volume.new("data") +
            k.volume.pvc("pulsar-%04d" % id)
    ],

    // Deployment definition.  id is the node ID.
    local deployment(id) = 
        k.deployment.new("pulsar-%04d" % id) +
            k.deployment.namespace(config.namespace) +
            k.deployment.labels({
                instance: "pulsar-%04d" % id,
                app: "pulsar",
                component: "pulsar"
            }) +
            k.deployment.containerLabels({
                instance: "pulsar-%04d" % id,
                app: "pulsar",
                component: "pulsar"
            }) +
            k.deployment.selector({
                instance: "pulsar-%04d" % id,
                app: "pulsar",
                component: "pulsar"
            }) +
            k.deployment.containers(containers(id)) +
            k.deployment.volumes(volumes(id)),

    // Ports declared on the service.
    local servicePorts = [
        k.svcPort.newNamed("pulsar", 6650, 6650) + k.svcPort.protocol("TCP"),
        k.svcPort.newNamed("websocket", 8080, 8080) + k.svcPort.protocol("TCP")
    ],

    local storageClasses = [
        k.storageClass.new("pulsar") +
            k.storageClass.labels({app: "pulsar", component: "pulsar"})
    ],

    local pvcs = [
        k.pvc.new("pulsar-%04d" % id) +
            k.pvc.namespace(config.namespace) +
            k.pvc.labels({app: "pulsar", component: "pulsar"}) +
            k.pvc.storageClass("pulsar") +
            k.pvc.size("10G")
            for id in std.range(0, config.pulsar.instances -  1)
    ],

    local deployments = [
        deployment(id) for id in std.range(0, config.pulsar.instances-1)
    ],

    local services = [
        k.svc.new("exchange") +
            k.svc.namespace(config.namespace) +
            k.svc.labels({app: "pulsar", component: "pulsar"}) +
            k.svc.ports(servicePorts) +
            k.svc.selector({
                app: "pulsar", component: "pulsar"
            })
    ],

    // Function which returns resource definitions - deployments and services.
    resources:: deployments + services + storageClasses + pvcs

};

// Return the function which creates resources.
[pulsar]

