
//
// Definition for Hadoop HDFS resources on Kubernetes.  This creates a Hadoop
// cluster consisting of a master node (running namenode and datanode) and
// slave datanodes.
//

// Import KSonnet library.
local k = import "defs.libsonnet";

// Ports used by deployments
local ports() = [
    k.containerPort.newNamed("namenode-http", 50070),
    k.containerPort.newNamed("datanode", 50075),
    k.containerPort.newNamed("namenode-rpc", 9000)
];

// Volume mount points
local volumeMounts(id) = [
    k.mount.new("data", "/data")
];

// Environment variables
local envs(id, replication) = [

    // Set Hadoop data replication to 3.
    k.env.new("DFS_REPLICATION", std.toString(replication))

] + if id == 0 then
[

    // The first node runs namenode and secondarynamenode
    k.env.new("DAEMONS", "namenode,secondarynamenode,datanode"),

] else [

    // Everything else just runs a datanode, and needs to know the
    // namenode's URI.
    k.env.new("DAEMONS", "datanode"),
    k.env.new("NAMENODE_URI", "hdfs://hadoop0000:9000")
    
];

// Container definition.
local containers(id, replication) = [
    k.container.new("hadoop", "cybermaggedon/hadoop:2.10.0") +
        k.container.ports(ports()) +
        k.container.volumeMounts(volumeMounts(id)) +
	k.container.env(envs(id, replication)) +
	k.container.limits({
	    memory: "256M", cpu: "1.0"
	}) +
	k.container.requests({
	    memory: "256M", cpu: "0.2"
	})
];

// Volumes - this invokes a GCE permanent disk.
local volumes(id) = [
    k.volume.new("data") +
        k.gceDisk.fsType("ext4") +
	k.gceDisk.pdName("hadoop-%04d" % id)
];

// Deployment definition.  id is the node ID.
local deployment(id, replication) = 
    k.deployment.new("hadoop%04d" % id) +
        k.deployment.labels({
            instance: "hadoop%04d" % id,
            app: "hadoop",
            component: "gaffer"
        }) +
        k.deployment.containerLabels({
            instance: "hadoop%04d" % id,
            app: "hadoop",
            component: "gaffer"
        }) +
        k.deployment.selector({
            instance: "hadoop%04d" % id,
            app: "hadoop",
            component: "gaffer"
        }) +
        k.deployment.containers(containers(id, replication)) +
        k.deployment.volumes(volumes(id));

// Ports declared on the service.
local servicePorts = [
    k.svcPort.newNamed("rpc", 9000, 9000) + k.svcPort.protocol("TCP")
];

// Function which returns resource definitions - deployments and services.
local resources(config) = [
    
    // One deployment per Hadoop node.
    deployment(id, config.hadoop_replication) for id in std.range(0, config.hadoops-1)
				
] + [

    // One service for the first node (name node).
    k.svc.new("hadoop0000") +
        k.svc.labels({app: "hadoop", component: "gaffer"}) +
        k.svc.ports(servicePorts) +
	k.svc.selector({
            instance: "hadoop0000", app: "hadoop", component: "gaffer"
        })
    
];

// Return the function which creates resources.
resources

