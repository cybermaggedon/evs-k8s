
// Import KSonnet library.
local k = import "defs.libsonnet";

local tmpl = importstr "nginx.conf";
local amend(str, config) =
    str % [config.auth_host, config.portal_host, config.auth_host,
        config.auth_host];

local nginx(config) = {

    // Ports used by deployments
    local ports = [
        k.containerPort.newNamed("https", 443)
    ],

    // Volume mount points
    local volumeMounts = [
        k.mount.new("config", "/etc/nginx/conf.d/"),
        k.mount.new("portal-keys", "/etc/tls/portal/")
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
            k.configMap.data({"default.conf": amend(tmpl, config)})
    ],

    // Volumes - this invokes a pvc
    local volumes = [
        k.volume.new("config") +
            k.volume.fromConfigMap("nginx-config"),
        k.volume.new("portal-keys") +
            k.volume.fromSecret("portal-keys")
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
                loadBalancerIP: config.externalIps.portal,
                type: "LoadBalancer"
            }}

    ],

    // Function which returns resource definitions - deployments and services.
    resources::  deployments + services + configMaps

};

// Return the function which creates resources.
[nginx]

