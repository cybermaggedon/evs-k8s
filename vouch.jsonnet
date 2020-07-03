
// Import KSonnet library.
local k = import "defs.libsonnet";

local vouch(config) = {

    name:: "vouch",
    images:: ["voucher/vouch-proxy:0.16.2"],

    // Ports used by deployments
    local ports = [
        k.containerPort.newNamed("http", 9090)
    ],

    // Environment variables
    local envs = [
        k.env.new("VOUCH_PORT", "9090"),
        k.env.new("VOUCH_LISTEN", "0.0.0.0"),
        k.env.new("VOUCH_COOKIE_DOMAIN", config.auth_domain),
        k.env.new("VOUCH_ALLOWALLUSERS", config.allow_all_users),
        k.env.new("OAUTH_PROVIDER", config.oauth.provider),
        k.env.new("OAUTH_CLIENT_ID", config.oauth.client_id),
        k.env.new("OAUTH_CLIENT_SECRET", config.oauth.client_secret),
        k.env.new("OAUTH_CALLBACK_URL", config.oauth.callback_url),
        k.env.new("OAUTH_AUTH_URL", config.oauth.auth_url),
        k.env.new("OAUTH_TOKEN_URL", config.oauth.token_url),
        k.env.new("OAUTH_USER_INFO_URL", config.oauth.userinfo_url),
        k.env.new("OAUTH_SCOPES", config.oauth.scopes),
        k.env.new("VOUCH_JWT_SECRET", config.oauth.vouch_jwt_secret)
    ],

    // Container definition.
    local containers = [
        k.container.new("vouch", self.images[0]) +
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

