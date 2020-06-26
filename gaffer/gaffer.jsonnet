
//
// Definition for Gaffer HTTP API / Wildfly on Kubernetes.  This creates a set
// of Wildfly replicas.
//

// Import KSonnet library.
local k = import "defs.libsonnet";

local g(config, id, table, schema) = {

        id:: "gaffer-" + id,
        images:: ["cybermaggedon/wildfly-gaffer:1.12.0b"],

        // Ports used by deployments
        local ports = [
            k.containerPort.newNamed("rest", 8080)
        ],

        // Constructs a list of Zookeeper hostnames, comma separated.
        local zookeeperList =
            std.join(",", std.makeArray(config.gaffer.zookeepers,
                          function(x) "zk%d.zk" % (x + 1))),

        // Environment variables
        local envs = [

            // List of Zookeepers.
            k.env.new("ZOOKEEPERS", zookeeperList)

        ],

        local volumeMounts = [
            k.mount.new("schema", "/usr/local/wildfly/schema") +
                k.mount.readOnly(true)
        ],

        local configMaps = [
            k.configMap.new(id + "-schema") +
                k.configMap.data({"schema.json": schema})
        ],

        // Volumes - this invokes a secret containing the web cert/key
        local volumes = [
            k.volume.new("schema") + 
                k.volume.fromConfigMap(id + "-schema")
        ],

        // Container definition.
        local containers = [
            k.container.new("gaffer", "cybermaggedon/wildfly-gaffer:1.12.0b") +
                k.container.ports(ports) +
                k.container.volumeMounts(volumeMounts) +
                k.container.env(envs) +
                k.container.limits({
                    memory: "1G", cpu: "1.5"
                }) +
                k.container.requests({
                    memory: "1G", cpu: "0.1"
                })
        ],

        local gaffers = config.gaffer.gaffers,
        local zookeepers = config.gaffer.zookeepers,

        // Deployment definition.  id is the node ID.
        local deployments = [
            local instance = "gaffer-" + id;
            k.deployment.new("gaffer-" + id) +
                k.deployment.replicas(gaffers) +
                k.deployment.labels({
                    instance: instance, app: "gaffer", component: "gaffer"
                }) +
                k.deployment.containerLabels({
                    instance: instance, app: "gaffer", component: "gaffer"
                }) +
                k.deployment.selector({
                    instance: instance, app: "gaffer", component: "gaffer"
                }) +
                k.deployment.containers(containers) + 
                k.deployment.volumes(volumes)
      ],

        // Ports declared on the service.
        local servicePorts = [
            k.svcPort.newNamed("rest", 8080, 8080) + k.svcPort.protocol("TCP")
        ],

        local services = [
            // One service load-balanced across the replicas
            k.svc.new("gaffer") +
                k.svc.labels({app: "wildfly", component: "gaffer"}) +
                k.svc.ports(servicePorts) +
                k.svc.selector({app: "wildfly", component: "gaffer"})
        ],

        // Function which returns resource definitions
        resources:: deployments + services + configMaps

    };

local gaffer(id, table, schema) =
    local h(config) = g(config, id, table, schema); [h];

// Return the function which creates resources.
gaffer

