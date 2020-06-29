
// Import KSonnet library.
local k = import "defs.libsonnet";

local keycloak(config) = {

    // Ports used by deployments
    local ports = [
        k.containerPort.newNamed("http", 8080)
    ],

    // Environment variables
    local envs = [
        k.env.new("KEYCLOAK_USER", "admin"),
        // FIXNE: Not good.
        k.env.new("KEYCLOAK_PASSWORD", "FIXMEthisisbad"),
        k.env.new("JAVA_OPTS", "-Xms128m -Xmx256m"),
        k.env.new("KEYCLOAK_FRONTEND_URL", config.accounts_url + "/auth"),
        k.env.new("PROXY_ADDRESS_FORWARDING", "true")
    ],

    // Container definition.
    local containers = [
        k.container.new("keycloak", "quay.io/keycloak/keycloak:10.0.2") +
            k.container.ports(ports) +
            k.container.env(envs) +
            k.container.limits({
                memory: "512M", cpu: "1.0"
            }) +
            k.container.requests({
                memory: "512M", cpu: "0.05"
            })
    ],

    // Deployment definition.  id is the node ID.
    local deployments = [
        k.deployment.new("keycloak") +
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
            k.deployment.containers(containers)
    ],

    // Ports declared on the service.
    local servicePorts = [
        k.svcPort.newNamed("http", 8080, 8080) + k.svcPort.protocol("TCP")
    ],

    local services = [

        // One service for the first node (name node).
        k.svc.new("keycloak") +
            k.svc.labels({app: "keycloak", component: "keycloak"}) +
            k.svc.ports(servicePorts) +
            k.svc.selector({
                app: "keycloak", component: "keycloak"
            })

    ],

    // Function which returns resource definitions - deployments and services.
    resources:: deployments + services

};

// Return the function which creates resources.
[keycloak]
