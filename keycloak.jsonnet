
// Import KSonnet library.
local k = import "defs.libsonnet";

local keycloak(config) = {

    name:: "keycloak",
    images:: ["quay.io/keycloak/keycloak:10.0.2"],

    // Ports used by deployments
    local ports = [
        k.containerPort.newNamed("http", 8080)
    ],

    // Environment variables
    local envs = [
        k.env.new("KEYCLOAK_USER", "admin"),
        // FIXNE: Not good.
        k.env.new("KEYCLOAK_PASSWORD", config.oauth.keycloak_admin_password),
        k.env.new("JAVA_OPTS", "-Xms128m -Xmx256m"),
        k.env.new("KEYCLOAK_FRONTEND_URL", config.accounts_url + "/auth"),
        k.env.new("PROXY_ADDRESS_FORWARDING", "true")
    ],

    // Volume mount points
    local volumeMounts = [
        k.mount.new("data", "/opt/jboss/keycloak/standalone/data")
    ],

    // Container definition.
    local containers = [
        k.container.new("keycloak", self.images[0]) +
            k.container.ports(ports) +
            k.container.volumeMounts(volumeMounts) +
            k.container.env(envs) +
            k.container.limits({
                memory: "512M", cpu: "1.0"
            }) +
            k.container.requests({
                memory: "512M", cpu: "0.05"
            })
    ],

    // Volumes - this invokes a pvc
    local volumes = [
        k.volume.new("data") +
            k.volume.pvc("keycloak")
    ],

    // Deployment definition.  id is the node ID.
    local deployments = [
        k.deployment.new("keycloak") +
            k.deployment.namespace(config.namespace) +
            k.deployment.labels({
                instance: "keycloak",
                app: "keycloak",
                component: "keycloak"
            }) +
            k.deployment.containerLabels({
                instance: "keycloak",
                app: "keycloak",
                component: "keycloak"
            }) +
            k.deployment.selector({
                instance: "keycloak",
                app: "keycloak",
                component: "keycloak"
            }) +
            k.deployment.containers(containers) +
            k.deployment.volumes(volumes) +
            {
                spec+: { template+: { spec+: {
                    securityContext: {
                        runAsUser: 1000,
                        runAsGroup: 0,
                        fsGroup: 0
                    }
                } } }
            }
    ],

    // Ports declared on the service.
    local servicePorts = [
        k.svcPort.newNamed("http", 8080, 8080) + k.svcPort.protocol("TCP")
    ],

    local services = [

        // One service for the first node (name node).
        k.svc.new("keycloak") +
            k.svc.namespace(config.namespace) +
            k.svc.labels({app: "keycloak", component: "keycloak"}) +
            k.svc.ports(servicePorts) +
            k.svc.selector({
                app: "keycloak", component: "keycloak"
            })

    ],

    local storageClasses = [
        k.storageClass.new("keycloak") +
            k.storageClass.labels({app: "keycloak", component: "keycloak"})
    ],

    local pvcs = [
        k.pvc.new("keycloak") +
            k.pvc.namespace(config.namespace) +
            k.pvc.labels({app: "keycloak", component: "keycloak"}) +
            k.pvc.storageClass("keycloak") +
            k.pvc.size("10G")
    ],

    // Function which returns resource definitions - deployments and services.
    resources:: deployments + services + storageClasses + pvcs

};

// Return the function which creates resources.
[keycloak]

