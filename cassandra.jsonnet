
// Import KSonnet library.
local k = import "defs.libsonnet";

local cassandra(config) = {

    name:: "cassandra",
    images:: ["cassandra:3.11.6"],

    // Ports used by deployments
    local ports() = [
        k.containerPort.newNamed("cassandra", 9042)
    ],

    // Volume mount points
    local volumeMounts(id) = [
        k.mount.new("data", "/var/lib/cassandra")
    ],

    // Environment variables
    local envs = [
        // Memory usage low
        k.env.new("JVM_OPTS", "-Xms64M -Xmx256M")
    ],

    // Container definition.
    local containers(id) = [
        k.container.new("cassandra", self.images[0]) +
            k.container.ports(ports()) +
            k.container.volumeMounts(volumeMounts(id)) +
            k.container.env(envs) +
            k.container.limits({
                memory: "512M", cpu: "1.0"
            }) +
            k.container.requests({
                memory: "512M", cpu: "0.1"
            })
    ],

    // Volumes - this invokes a pvc
    local volumes(id) = [
        k.volume.new("data") +
            k.volume.pvc("cassandra-%04d" % id)
    ],

    // Deployment definition.  id is the node ID.
    local deployment(id) = 
        k.deployment.new("cassandra-%04d" % id) +
            k.deployment.labels({
                instance: "cassandra-%04d" % id,
                app: "cassandra",
                component: "cassandra"
            }) +
            k.deployment.containerLabels({
                instance: "cassandra-%04d" % id,
                app: "cassandra",
                component: "cassandra"
            }) +
            k.deployment.selector({
                instance: "cassandra-%04d" % id,
                app: "cassandra",
                component: "cassandra"
            }) +
            k.deployment.containers(containers(id)) +
            k.deployment.volumes(volumes(id)),

    // Ports declared on the service.
    local servicePorts = [
        k.svcPort.newNamed("cassandra", 9042, 9042) + k.svcPort.protocol("TCP")
    ],

    local storageClasses = [
        k.storageClass.new("cassandra") +
            k.storageClass.labels({app: "cassandra", component: "cassandra"})
    ],

    local pvcs = [
        k.pvc.new("cassandra-%04d" % id) +
            k.pvc.labels({app: "cassandra", component: "cassandra"}) +
            k.pvc.storageClass("cassandra") +
            k.pvc.size("10G")
            for id in std.range(0, config.cassandra.instances - 1)
    ],

    local deployments = [

        deployment(id) for id in std.range(0, config.cassandra.instances-1)

    ],

    local services = [

        // One service for the first node (name node).
        k.svc.new("cassandra") +
            k.svc.labels({app: "cassandra", component: "cassandra"}) +
            k.svc.ports(servicePorts) +
            k.svc.selector({
                app: "cassandra", component: "cassandra"
            })

    ],

    // Function which returns resource definitions - deployments and services.
    resources::  deployments + services + storageClasses + pvcs

};

// Return the function which creates resources.
[cassandra]

