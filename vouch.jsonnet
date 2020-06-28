
// Import KSonnet library.
local k = import "defs.libsonnet";

local vouch(config) = {

    // Ports used by deployments
    local ports = [
        k.containerPort.newNamed("http", 9090)
    ],

    // Environment variables
    local envs = [
        k.env.new("VOUCH_PORT", "9090"),
        k.env.new("VOUCH_LISTEN", "0.0.0.0"),
        k.env.new("VOUCH_DOMAINS", "cyberapocalypse.co.uk"),
        k.env.new("OAUTH_PROVIDER", "google"),
        k.env.new("OAUTH_CLIENT_ID", "749175465304-g21av5qp43daojukj3gcn1igb9ri6r3j.apps.googleusercontent.com"),
        k.env.new("OAUTH_CLIENT_SECRET", "_CqoHoDLuzfwochoZ_LbjlUq"),
        k.env.new("OAUTH_CALLBACK_URL", "https://login.cyberapocalypse.co.uk/auth")
    ],

    // Container definition.
    local containers = [
        k.container.new("vouch", "voucher/vouch-proxy:0.16.2") +
            k.container.ports(ports) +
            k.container.env(envs) +
            k.container.limits({
                memory: "256M", cpu: "1.0"
            }) +
            k.container.requests({
                memory: "256M", cpu: "0.05"
            })
    ],

    // Deployment definition.  id is the node ID.
    local deployments = [
        k.deployment.new("vouch") +
            k.deployment.labels({
                instance: "vouch",
                app: "vouch",
                component: "vouch"
            }) +
            k.deployment.containerLabels({
                instance: "vouch",
                app: "vouch",
                component: "vouch"
            }) +
            k.deployment.selector({
                instance: "vouch",
                app: "vouch",
                component: "vouch"
            }) +
            k.deployment.containers(containers)
    ],

    // Ports declared on the service.
    local servicePorts = [
        k.svcPort.newNamed("http", 9090, 9090) + k.svcPort.protocol("TCP")
    ],

    local services = [

        // One service for the first node (name node).
        k.svc.new("vouch") +
            k.svc.labels({app: "vouch", component: "vouch"}) +
            k.svc.ports(servicePorts) +
            k.svc.selector({
                app: "vouch", component: "vouch"
            })

    ],

    // Function which returns resource definitions - deployments and services.
    resources:: deployments + services

};

// Return the function which creates resources.
[vouch]

