
// Import KSonnet library.
local k = import "defs.libsonnet";

local cfg = importstr "nginx.conf";

local nginx(config) = {

    // Ports used by deployments
    local ports = [
        k.containerPort.newNamed("https", 443)
    ],

    // Volume mount points
    local volumeMounts = [
        k.mount.new("config", "/etc/nginx/conf.d/"),
        k.mount.new("portal-keys", "/etc/tls/portal/"),
        k.mount.new("login-keys", "/etc/tls/login/")
    ],

    // Environment variables
    local envs = [
    ],

    // Container definition.
    local containers = [
        k.container.new("nginx", "nginx:1.19.0") +
            k.container.ports(ports) +
            k.container.volumeMounts(volumeMounts) +
            k.container.env(envs) +
            k.container.limits({
                memory: "256M", cpu: "1.0"
            }) +
            k.container.requests({
                memory: "256M", cpu: "0.05"
            })
    ],

    local configMaps = [
        k.configMap.new("nginx-config") +
            k.configMap.data({"default.conf": cfg})
    ],

    // Volumes - this invokes a pvc
    local volumes = [
        k.volume.new("config") +
            k.volume.fromConfigMap("nginx-config"),
        k.volume.new("portal-keys") +
            k.volume.fromSecret("portal-keys"),
        k.volume.new("login-keys") +
            k.volume.fromSecret("login-keys")
    ],

    // Deployment definition.  id is the node ID.
    local deployments = [
        k.deployment.new("nginx") +
            k.deployment.labels({
                instance: "nginx",
                app: "nginx",
                component: "nginx"
            }) +
            k.deployment.containerLabels({
                instance: "nginx",
                app: "nginx",
                component: "nginx"
            }) +
            k.deployment.selector({
                instance: "nginx",
                app: "nginx",
                component: "nginx"
            }) +
            k.deployment.containers(containers) +
            k.deployment.volumes(volumes)
    ],

    // Ports declared on the service.
    local servicePorts = [
        k.svcPort.newNamed("https", 443, 443) + k.svcPort.protocol("TCP")
    ],



    local services = [

        // portal...
        k.svc.new("portal") +
            k.svc.labels({app: "nginx", component: "nginx"}) +
            k.svc.ports(servicePorts) +
            k.svc.selector({
                app: "nginx", component: "nginx"
            }) + { spec+: {
                loadBalancerIP: "35.237.4.241",
                type: "LoadBalancer"
            }},

        // login...
        k.svc.new("login") +
            k.svc.labels({app: "nginx", component: "nginx"}) +
            k.svc.ports(servicePorts) +
            k.svc.selector({
                app: "nginx", component: "nginx"
            }) + { spec+: {
                loadBalancerIP: "34.75.229.50",
                type: "LoadBalancer"
            }}

    ],

    // Function which returns resource definitions - deployments and services.
    resources::  deployments + services + configMaps

};

// Return the function which creates resources.
[nginx]

