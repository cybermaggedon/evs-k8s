
// Import KSonnet library.
local k = import "defs.libsonnet";

// Grafana config
local source_cfg = importstr "grafana/datasource.yml";
local dash_cfg = importstr "grafana/dashboard.yml";
local dashboard = importstr "grafana/dashboard.json";

local grafana(config) = {

    name:: "grafana",
    images:: ["grafana/grafana:7.0.3"],

    // Ports used by deployments
    local ports = [
        k.containerPort.newNamed("grafana", 3000)
    ],

    // Volume mount points
    local volumeMounts = [
        k.mount.new("datasource-provision",
            "/etc/grafana/provisioning/datasources"),
        k.mount.new("dashboard-provision",
            "/etc/grafana/provisioning/dashboards"),
        k.mount.new("dashboards",
            "/var/lib/grafana/dashboards")
    ],

    // Environment variables
    local envs = [
           k.env.new("GF_SERVER_ROOT_URL",
               config.portal_url + "/grafana"),
           k.env.new("GF_AUTH_ANONYMOUS_ENABLED", "true"),
           k.env.new("GF_ORG_NAME", "cybermaggedon"),
           k.env.new("GF_AUTH_ANONYMOUS_ORG_ROLE", "Admin")
    ],

    // Container definition.
    local containers = [
        k.container.new("grafana", self.images[0]) +
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
        k.configMap.new("grafana-dashboard-prov") +
            k.configMap.labels({app: "grafana", component: "grafana"}) +
            k.configMap.data({"dashboard.yml": dash_cfg}),
        k.configMap.new("grafana-datasource-prov") +
            k.configMap.labels({app: "grafana", component: "grafana"}) +
            k.configMap.data({"datasource.yml": source_cfg}),
        k.configMap.new("grafana-dashboards") +
            k.configMap.labels({app: "grafana", component: "grafana"}) +
            k.configMap.data({"dashboard.json": dashboard}),
    ],

    // Volumes - this invokes a pvc
    local volumes = [
        k.volume.new("dashboard-provision") +
            k.volume.fromConfigMap("grafana-dashboard-prov"),
        k.volume.new("dashboards") +
            k.volume.fromConfigMap("grafana-dashboards"),
        k.volume.new("datasource-provision") +
            k.volume.fromConfigMap("grafana-datasource-prov")
    ],

    // Deployment definition.  id is the node ID.
    local deployments = [
        k.deployment.new("grafana") +
            k.deployment.labels({
                instance: "grafana",
                app: "grafana",
                component: "grafana"
            }) +
            k.deployment.containerLabels({
                instance: "grafana",
                app: "grafana",
                component: "grafana"
            }) +
            k.deployment.selector({
                instance: "grafana",
                app: "grafana",
                component: "grafana"
            }) +
            k.deployment.containers(containers) +
            k.deployment.volumes(volumes)
    ],

    // Ports declared on the service.
    local servicePorts = [
        k.svcPort.newNamed("grafana", 3000, 3000) + k.svcPort.protocol("TCP")
    ],

    local services = [

        // One service for the first node (name node).
        k.svc.new("grafana") +
            k.svc.labels({app: "grafana", component: "grafana"}) +
            k.svc.ports(servicePorts) +
            k.svc.selector({
                app: "grafana", component: "grafana"
            })

    ],

    // Function which returns resource definitions - deployments and services.
    resources::  deployments + services + configMaps

};

// Return the function which creates resources.
[grafana]

