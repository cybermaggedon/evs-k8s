
// Import KSonnet library.
local k = import "defs.libsonnet";

// Prometheus config
local cfg = importstr "prometheus-config.yml";

local prometheus(config) = {

    name:: "prometheus",
    images:: ["prom/prometheus:v2.19.1"],

    // Ports used by deployments
    local ports = [
        k.containerPort.newNamed("prometheus", 9090)
    ],

    // Volume mount points
    local volumeMounts = [
        k.mount.new("config", "/etc/prometheus") +
            k.mount.readOnly(true)
    ],

    // Environment variables
    local envs = [
    ],

    // Container definition.
    local containers = [
        k.container.new("prometheus", self.images[0]) +
            k.container.args([
                "--web.external-url=%s/prometheus/" % config.portal_url,
                "--web.route-prefix=/",
                "--config.file=/etc/prometheus/prometheus.yml",
                "--storage.tsdb.path=/prometheus",
                "--web.console.libraries=/usr/share/prometheus/console_libraries",
                "--web.console.templates=/usr/share/prometheus/consoles"
            ]) +
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

    // Volumes - this invokes a pvc
    local volumes = [
        k.volume.new("config") +
            k.volume.fromConfigMap("prometheus-config")
    ],

    local configMaps = [
        k.configMap.new("prometheus-config") +
            k.configMap.namespace(config.namespace) +
            k.configMap.labels({app: "prometheus", component: "prometheus"}) +
            k.configMap.data({"prometheus.yml": cfg % config.namespace})
    ],

    // Deployment definition.  id is the node ID.
    local deployments = [
        k.deployment.new("prometheus") +
            k.deployment.namespace(config.namespace) +
            k.deployment.labels({
                instance: "prometheus",
                app: "prometheus",
                component: "prometheus"
            }) +
            k.deployment.containerLabels({
                instance: "prometheus",
                app: "prometheus",
                component: "prometheus"
            }) +
            k.deployment.selector({
                instance: "prometheus",
                app: "prometheus",
                component: "prometheus"
            }) +
            k.deployment.containers(containers) +
            k.deployment.volumes(volumes) +
            { spec+: { template+: { spec+: {
                serviceAccountName: "prometheus"
            }}}}
    ],

    // Ports declared on the service.
    local servicePorts = [
        k.svcPort.newNamed("prometheus", 9090, 9090) + k.svcPort.protocol("TCP")
    ],

    local services = [

        // One service for the first node (name node).
        k.svc.new("prometheus") +
            k.svc.namespace(config.namespace) +
            k.svc.labels({app: "prometheus", component: "prometheus"}) +
            k.svc.ports(servicePorts) +
            k.svc.selector({
                app: "prometheus", component: "prometheus"
            })

    ],

    local clusterRoles = [{
        apiVersion: "rbac.authorization.k8s.io/v1beta1",
        kind: "ClusterRole",
        metadata: {
            name: "prometheus",
            namespace: config.namespace
        },
        rules: [
            {
                apiGroups: [""],
                resources: [
                    "nodes", "nodes/proxy", "services", "endpoints", "pods"
                ],
                "verbs": [ "get", "list", "watch" ]
            },
            {
                "apiGroups": [ "extensions" ],
                "resources": [ "ingresses" ],
                "verbs": [ "get", "list", "watch" ]
            },
            {
                "nonResourceURLs": [ "/metrics" ],
                "verbs": [ "get" ]
            }
        ]
    }],

    local serviceAccounts = [{
        apiVersion: "v1",
        kind: "ServiceAccount",
        metadata: {
            name: "prometheus",
            namespace: config.namespace
        }
    }],

    local roleBindings = [{
        apiVersion: "rbac.authorization.k8s.io/v1beta1",
        kind: "ClusterRoleBinding",
        metadata: {
            name: "prometheus",
            namespace: config.namespace
        },
        roleRef: {
            apiGroup: "rbac.authorization.k8s.io",
            kind: "ClusterRole",
            name: "prometheus"
        },
        subjects: [
            {
                kind: "ServiceAccount",
                name: "prometheus",
                namespace: config.namespace
            }
        ]
    }],

    // Function which returns resource definitions - deployments and services.
    resources:: deployments + services + configMaps + clusterRoles + 
        serviceAccounts + roleBindings

};

// Return the function which creates resources.
[prometheus]









