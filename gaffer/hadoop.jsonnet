
//
// Definition for Hadoop HDFS resources on Kubernetes.  This creates a Hadoop
// cluster consisting of a master node (running namenode and datanode) and
// slave datanodes.
//

// Import KSonnet library.
local k = import "defs.libsonnet";

local hadoop(config) = {

    name:: "hadoop",
    images:: ["cybermaggedon/hadoop:2.10.0"],

    // Ports used by deployments
    local ports = [
        k.containerPort.newNamed("namenode-http", 50070),
        k.containerPort.newNamed("datanode", 50075),
        k.containerPort.newNamed("namenode-rpc", 9000)
    ],

    // Volume mount points
    local volumeMounts = [
        k.mount.new("data", "/data")
    ],

    local replication = config.gaffer.hadoop_replication,

    // Environment variables
    local envs(id) = [

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

    ],

    // Container definition.
    local containers(id, replication) = [
        k.container.new("hadoop", self.images[0]) +
            k.container.ports(ports) +
            k.container.volumeMounts(volumeMounts) +
            k.container.env(envs(id)) +
            k.container.limits({
                memory: "1G", cpu: "1.0"
            }) +
            k.container.requests({
                memory: "1G", cpu: "0.1"
            })
    ],

    // Volumes - this invokes a pvc
    local volumes(id) = [
        k.volume.new("data") +
            k.volume.pvc("hadoop-%04d" % id)
    ],

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
            k.deployment.volumes(volumes(id)),

    // Ports declared on the service.
    local servicePorts = [
        k.svcPort.newNamed("rpc", 9000, 9000) + k.svcPort.protocol("TCP")
    ],

    local storageClasses = [
        k.storageClass.new("hadoop") +
            k.storageClass.labels({app: "hadoop", component: "gaffer"})
    ],

    local pvcs = [
        k.pvc.new("hadoop-%04d" % id) +
            k.pvc.labels({app: "hadoop", component: "gaffer"}) +
            k.pvc.storageClass("hadoop") +
            k.pvc.size("5G")
            for id in std.range(0, config.gaffer.hadoops - 1)
    ],

    local deployments = [

        // One deployment per Hadoop node.
        deployment(id, config.gaffer.hadoop_replication)
        for id in std.range(0, config.gaffer.hadoops-1)

    ],

    local services = [

        // One service for the first node (name node).
        k.svc.new("hadoop0000") +
            k.svc.labels({app: "hadoop", component: "gaffer"}) +
            k.svc.ports(servicePorts) +
            k.svc.selector({
                instance: "hadoop0000", app: "hadoop", component: "gaffer"
            })

    ],

    // Function which returns resource definitions - deployments and services.
    resources:: deployments + services + storageClasses + pvcs

};

// Return the function which creates resources.
[hadoop]



