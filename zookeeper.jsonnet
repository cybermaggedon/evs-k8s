
//
// Definition for Zookeeper resources on Kubernetes.  This creates a ZK
// cluster consisting of several Zookeepers.
//

// Import KSonnet library.
local k = import "defs.libsonnet";

// Ports used by deployments
local ports() = [
    k.containerPort.newNamed("internal1", 2888),
    k.containerPort.newNamed("internal2", 3888),
    k.containerPort.newNamed("service", 2181)
];

// Volume mount points
local volumeMounts(id) = [
    k.mount.new("data", "/data")
];

// Environment variables
local envs(id, zks) = [
    k.env.new("ZOOKEEPER_MYID", "%d" % (id + 1)),
    k.env.new("ZOOKEEPERS", zks)
];

// Container definition.
local containers(id, zks) = [
    k.container.new("zookeeper", "cybermaggedon/zookeeper:3.6.1") +
        k.container.ports(ports()) +
        k.container.volumeMounts(volumeMounts(id)) +
	k.container.env(envs(id, zks)) +
	k.container.limits({
	    memory: "256M", cpu: "0.5"
	}) +
	k.container.requests({
	    memory: "256M", cpu: "0.15"
	})
];

// Volumes - this invokes a GCE permanent disk.
local volumes(id) = [
    k.volume.new("data") +
        k.volume.pvc("zookeeper-%04d" % id)
];

// Deployment definition.  id is the node ID, zks is number Zookeepers.
local deployment(id, zks) =
    local name = "zk%d" % (id + 1);
    k.deployment.new(name) +
        k.deployment.containers(containers(id, zks)) +
        k.deployment.labels({
            instance: name, app: "zk", component: "gaffer"
        }) +
        k.deployment.containerLabels({
            instance: name, app: "zk", component: "gaffer"
        }) +
        k.deployment.selector({
            instance: name, app: "zk", component: "gaffer"
        }) +
        k.deployment.hostname("zk%d" % (id + 1)) +
        k.deployment.subdomain("zk") +
        k.deployment.volumes(volumes(id));

// Function, returns a Zookeeper list, comma separated list of ZK IDs.
local zookeeperList(count) =
    std.join(",", std.makeArray(count, function(x) "zk%d.zk" % (x + 1)));

// Ports declared on the ZK service.
local servicePorts = [
    k.svcPort.newNamed("internal1", 2888, 2888) + k.svcPort.protocol("TCP"),
    k.svcPort.newNamed("internal2", 3888, 3888) + k.svcPort.protocol("TCP"),
    k.svcPort.newNamed("service", 2181, 2181) + k.svcPort.protocol("TCP")
];

local storageClasses = [
    k.sc.new("zookeeper")
];

local pvcs(zks) = [
    k.pvc.new("zookeeper-%04d" % id) +
        k.pvc.storageClass("zookeeper") +
        k.pvc.size("1G")
        for id in std.range(0, zks-1)
];

// Function which returns resource definitions - deployments and services.
local resources(config) = [

    // One deployment for each Zookeeper
    deployment(id, zookeeperList(config.zookeepers))
    for id in std.range(0, config.zookeepers-1)

] + [

    // One service for each Zookeeper to allow it to be discovered by
    // Zookeeper name.
    k.svc.new("zk") +
        k.svc.labels({app: "zk", component: "gaffer"}) +
        k.svc.selector({app: "zk"}) +
        k.svc.ports(servicePorts) +
        k.svc.clusterIp("None")
    
] + storageClasses + pvcs(config.zookeepers);

// Return the function which creates resources.
resources

