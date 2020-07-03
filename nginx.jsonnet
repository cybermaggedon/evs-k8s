
// Import KSonnet library.
local k = import "defs.libsonnet";

local tmpl = importstr "nginx.conf";
local amend(str, config) =
    str % [config.portal_host, config.portal_host, config.portal_host,
        config.accounts_host];

local page_index = importstr "index.html";
local page_50x = importstr "50x.html";

local nginx(config) = {

    name:: "nginx",
    images:: ["nginx:1.19.0"],

    // Ports used by deployments
    local ports = [
        k.containerPort.newNamed("https", 443)
    ],

    // Volume mount points
    local volumeMounts = [
        k.mount.new("config", "/etc/nginx/conf.d/"),
        k.mount.new("portal-keys", "/etc/tls/portal/"),
        k.mount.new("pages", "/usr/share/nginx/html/")
    ],

    // Environment variables
    local envs = [
    ],

    // Container definition.
    local containers = [
        k.container.new("nginx", self.images[0]) +
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
            k.configMap.namespace(config.namespace) +
            k.configMap.labels({app: "nginx", component: "nginx"}) +
            k.configMap.data({"default.conf": amend(tmpl, config)}),
        k.configMap.new("web-pages") +
            k.configMap.namespace(config.namespace) +
            k.configMap.labels({app: "nginx", component: "nginx"}) +
            k.configMap.data({
                "index.html": page_index,
                "50x.html": page_50x
            })
    ],

    // Volumes - this invokes a pvc
    local volumes = [
        k.volume.new("config") +
            k.volume.fromConfigMap("nginx-config"),
        k.volume.new("portal-keys") +
            k.volume.fromSecret("portal-keys"),
        k.volume.new("pages") +
            k.volume.fromConfigMap("web-pages"),
    ],

    // Deployment definition.  id is the node ID.
    local deployments = [
        k.deployment.new("nginx") +
            k.deployment.namespace(config.namespace) +
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
            k.svc.namespace(config.namespace) +
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

