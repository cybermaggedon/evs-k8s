
// Import KSonnet library.
local k = import "defs.libsonnet";

local elasticsearch(config) = {

    name:: "elasticsearch",
    images:: ["elasticsearch:7.7.1"],

    // Ports used by deployments
    local ports() = [
        k.containerPort.newNamed("elasticsearch", 9200)
    ],

    // Volume mount points
    local volumeMounts(id) = [
        k.mount.new("data", "/usr/share/elasticsearch/data")
    ],

    // Environment variables
    local envs(id) = [

        k.env.new("discovery.type", "single-node"),

        // Memory usage low
        k.env.new("ES_JAVA_OPTS", "-Xms128M -Xmx256M")

    ],

    // Container definition.
    local containers(id) = [
        k.container.new("elasticsearch", self.images[0]) +
            k.container.command(["bash", "-c",
            "sysctl -w vm.max_map_count=262144; chown -R elasticsearch:elasticsearch /usr/share/elasticsearch/data; /usr/local/bin/docker-entrypoint.sh"]) +
            k.container.ports(ports()) +
            k.container.volumeMounts(volumeMounts(id)) +
            k.container.env(envs(id)) +
            k.container.limits({
                memory: "512M", cpu: "1.0"
            }) +
            k.container.requests({
                memory: "512M", cpu: "0.1"
            })
    ],

    // Volumes - this invokes a pvc
    local volumes(id) = [
        k.volume.new("data") +
            k.volume.pvc("elasticsearch-%04d" % id)
    ],

    // Deployment definition.  id is the node ID.
    local deployment(id) = 
        k.deployment.new("elasticsearch-%04d" % id) +
            k.deployment.namespace(config.namespace) +
            k.deployment.labels({
                instance: "elasticsearch-%04d" % id,
                app: "elasticsearch",
                component: "elasticsearch"
            }) +
            k.deployment.containerLabels({
                instance: "elasticsearch-%04d" % id,
                app: "elasticsearch",
                component: "elasticsearch"
            }) +
            k.deployment.selector({
                instance: "elasticsearch-%04d" % id,
                app: "elasticsearch",
                component: "elasticsearch"
            }) +
            k.deployment.containers(containers(id)) +
            k.deployment.volumes(volumes(id)),

    // Ports declared on the service.
    local servicePorts = [
        k.svcPort.newNamed("elasticsearch", 9200, 9200) + k.svcPort.protocol("TCP")
    ],

    local storageClasses = [
        k.storageClass.new("elasticsearch") +
            k.storageClass.labels({app: "elasticsearch", component: "elasticsearch"})
    ],

    local pvcs = [
        k.pvc.new("elasticsearch-%04d" % id) +
            k.pvc.namespace(config.namespace) +
            k.pvc.labels({app: "elasticsearch", component: "elasticsearch"}) +
            k.pvc.storageClass("elasticsearch") +
            k.pvc.size("10G")
            for id in std.range(0, config.elasticsearch.instances - 1)
    ],

    local deployments = [

        deployment(id) for id in std.range(0, config.elasticsearch.instances-1)

    ],

    local services = [

        // One service for the first node (name node).
        k.svc.new("elasticsearch") +
            k.svc.namespace(config.namespace) +
            k.svc.labels({app: "elasticsearch", component: "elasticsearch"}) +
            k.svc.ports(servicePorts) +
            k.svc.selector({
                app: "elasticsearch", component: "elasticsearch"
            })

    ],

    // Function which returns resource definitions - deployments and services.
    resources:: deployments + services + storageClasses + pvcs

};

// Return the function which creates resources.
[elasticsearch]

