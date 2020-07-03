
// Import KSonnet library.
local k = import "defs.libsonnet";

local pulsar_manager(config) = {

    name:: "pulsar-manager",
    images:: ["apachepulsar/pulsar-manager:v0.1.0"],

    // Ports used by deployments
    local ports = [
        k.containerPort.newNamed("ui", 9527)
    ],

    // Volume mount points
    local volumeMounts = [
        k.mount.new("data", "/data")
    ],

    // Environment variables
    local envs = [
        k.env.new("DRIVER_CLASS_NAME", "org.postgresql.Driver"),
        k.env.new("URL", "jdbc:postgresql://127.0.0.1:5432/pulsar_manager"),
        k.env.new("USERNAME", "pulsar"),
        k.env.new("PASSWORD", "pulsar"),
        k.env.new("LOG_LEVEL", "DEBUG"),
        k.env.new("REDIRECT_HOST", "http://127.0.0.1"),
        k.env.new("REDIRECT_PORT", "8080")
    ],

    // Container definition.
    local containers = [
        k.container.new("pulsar-manager", self.images[0]) +
            k.container.ports(ports) +
            k.container.volumeMounts(volumeMounts) +
            k.container.env(envs) +
            k.container.limits({
                memory: "512M", cpu: "1.0"
            }) +
            k.container.requests({
                memory: "512M", cpu: "0.1"
            })
    ],

    // Volumes - this invokes a pvc
    local volumes = [
        k.volume.new("data") +
            k.volume.pvc("pulsar-manager")
    ],

    // Deployment definition.  id is the node ID.
    local deployments = [
        k.deployment.new("pulsar-manager") +
            k.deployment.namespace(config.namespace) +
            k.deployment.labels({
                instance: "pulsar-manager",
                app: "pulsar-manager",
                component: "pulsar"
            }) +
            k.deployment.containerLabels({
                instance: "pulsar-manager",
                app: "pulsar-manager",
                component: "pulsar"
            }) +
            k.deployment.selector({
                instance: "pulsar-manager",
                app: "pulsar-manager",
                component: "pulsar"
            }) +
            k.deployment.containers(containers) +
            k.deployment.volumes(volumes)
    ],

    // Ports declared on the service.
    local servicePorts = [
        k.svcPort.newNamed("ui", 9527, 9527) + k.svcPort.protocol("TCP")
    ],

    local storageClasses = [
        k.storageClass.new("pulsar-manager") +
            k.storageClass.labels({app: "pulsar-manager", component: "pulsar"})
    ],

    local pvcs = [
        k.pvc.new("pulsar-manager") +
            k.pvc.namespace(config.namespace) +
            k.pvc.labels({app: "pulsar-manager", component: "pulsar"}) +
            k.pvc.storageClass("pulsar-manager") +
            k.pvc.size("10G")
    ],

    local services = [
        k.svc.new("pulsar-manager") +
            k.svc.namespace(config.namespace) +
            k.svc.labels({app: "pulsar-manager", component: "pulsar"}) +
            k.svc.ports(servicePorts) +
            k.svc.selector({
                app: "pulsar-manager", component: "pulsar"
            })
    ],

    // Function which returns resource definitions - deployments and services.
    resources:: deployments + services + storageClasses + pvcs

};

// Return the function which creates resources.
[pulsar_manager]

