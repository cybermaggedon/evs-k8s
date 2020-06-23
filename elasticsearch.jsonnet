
// Import KSonnet library.
local k = import "defs.libsonnet";

// Ports used by deployments
local ports() = [
    k.containerPort.newNamed("elasticsearch", 9200)
];

// Volume mount points
local volumeMounts(id) = [
    k.mount.new("data", "/usr/share/elasticsearch/data")
];

// Environment variables
local envs(id) = [

    k.env.new("discover.type", "single-node")

];

// Container definition.
local containers(id) = [
    k.container.new("elasticsearch", "elasticsearch:7.7.1") +
        k.container.ports(ports()) +
        k.container.volumeMounts(volumeMounts(id)) +
	k.container.env(envs(id)) +
	k.container.limits({
	    memory: "1G", cpu: "1.0"
	}) +
	k.container.requests({
	    memory: "1G", cpu: "0.1"
	})
];

// Volumes - this invokes a pvc
local volumes(id) = [
    k.volume.new("data") +
        k.volume.pvc("elasticsearch-%04d" % id)
];

// Deployment definition.  id is the node ID.
local deployment(id) = 
    k.deployment.new("elasticsearch-%04d" % id) +
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
        k.deployment.volumes(volumes(id));

// Ports declared on the service.
local servicePorts = [
    k.svcPort.newNamed("elasticsearch", 9200, 9200) + k.svcPort.protocol("TCP")
];

local storageClasses = [
    k.sc.new("elasticsearch")
];

local pvcs(instances) = [
    k.pvc.new("elasticsearch-%04d" % id) +
        k.pvc.storageClass("elasticsearch") +
        k.pvc.size("10G")
        for id in std.range(0, instances-1)
];
    
// Function which returns resource definitions - deployments and services.
local resources(config) = [
    
    deployment(id) for id in std.range(0, config.elasticsearch.instances-1)
				
] + [

    // One service for the first node (name node).
    k.svc.new("elasticsearch") +
        k.svc.labels({app: "elasticsearch", component: "elasticsearch"}) +
        k.svc.ports(servicePorts) +
	k.svc.selector({
            app: "elasticsearch", component: "elasticsearch"
        })
    
] + storageClasses + pvcs(config.elasticsearch.instances);

// Return the function which creates resources.
resources

