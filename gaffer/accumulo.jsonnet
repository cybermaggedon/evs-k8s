
//
// Definition for Accumulo resources on Kubernetes.  This creates an Accumulo
// cluster consisting of:
// - A deployment for 'master'
// - A deployment for 'monitor'
// - A deployment for 'gc'
// - A deployment for 'tracer'
// - One deployment per Accumulo slave.
// - One service for each of the above.
//

// This is quite a complex set of resources - clearly Accumulo is not designed
// for Kubernetes.

// Import KSonnet library.
local k = import "defs.libsonnet";

local accumulo(config) = {

    name:: "accumulo",
    images:: ["cybermaggedon/accumulo-gaffer:1.12.0b"],
    
    // Ports used by deployments
    local ports() = [
        k.containerPort.newNamed("master", 9999),
        k.containerPort.newNamed("tablet-server", 9997),
        k.containerPort.newNamed("gc", 50091),
        k.containerPort.newNamed("monitor", 9995),
        k.containerPort.newNamed("monitor-log", 4560),
        k.containerPort.newNamed("tracer", 12234),
        k.containerPort.newNamed("proxy", 42424),
        k.containerPort.newNamed("slave", 10002),
        k.containerPort.newNamed("replication", 10001)
    ],

    // Function, returns a Zookeeper list, comma separated list of ZK IDs.
    local zookeeperList(count) =
        std.join(",", std.makeArray(count, function(x) "zk%d.zk" % (x + 1))),

    // Returns an Accumulo slave list for the SLAVE_HOSTS environment variable.
    // count is the number of slaves, id is the slave number.  This is arranged
    // so that the slave list has the node name substituted for MY_IP which
    // gets replaced with the nodes IP address by the Accumulo container.
    local slaveList(count, id) =
        std.join(",", std.makeArray(count,
                                    function(x)
                                    "slave%04d.accumulo" % x)),

    // Environment variables
    local envs(slaves, zks, id, proc) = [

        // List of Zookeepers.
        k.env.new("ZOOKEEPERS", zookeeperList(zks)),

        // List of master, gc, monitor, tracer and slave hosts.  This does the
        // thing where MY_IP is used instead of a hostname when the node in
        // question supplies the function.
        k.env.new("MASTER_HOSTS", "master.accumulo"),
        k.env.new("GC_HOSTS", "gc.accumulo"),
        k.env.new("MONITOR_HOSTS", "monitor.accumulo"),
        k.env.new("TRACER_HOSTS", "tracer.accumulo"),

        // Slaves only need to know about the master, don't need to know about
        // all the other slaves.  This is only a deal, because in a big cluster,
        // this would generate a lot of config.
        if id >= 0 then
            k.env.new("SLAVE_HOSTS", "slave%04d.accumulo" % id)
        else		 
            k.env.new("SLAVE_HOSTS", slaveList(slaves, id)),

        // HDFS references.
        k.env.new("HDFS_VOLUMES", "hdfs://hadoop0000:9000/accumulo"),
        k.env.new("NAMENODE_URI", "hdfs://hadoop0000:9000/"),

        // Sizing parameters.
        k.env.new("MEMORY_MAPS_MAX", "300M"),
        k.env.new("CACHE_DATA_SIZE", "30M"),
        k.env.new("CACHE_INDEX_SIZE", "40M"),
        k.env.new("SORT_BUFFER_SIZE", "50M"),
        k.env.new("WALOG_MAX_SIZE", "512M")

    ],

    // Container definition for non-slave containers.
    local containers(proc, slaves, xks) = [
        k.container.new("accumulo", self.images[0]) +
            k.container.ports(ports()) +
            k.container.command(["/start-process", proc]) +
            k.container.env(envs(slaves, xks, -1, proc)) +
            k.container.limits({
                memory: "512M", cpu: "0.5"
            }) +
            k.container.requests({
                memory: "512M", cpu: "0.05"
            })
    ],

    // Container definition for slave containers.
    local slaveContainers(id, slaves, xks) = [
        k.container.new("accumulo", "cybermaggedon/accumulo-gaffer:1.12.0b") +
            k.container.ports(ports()) +
            k.container.command(["/start-process", "tserver"]) +
            k.container.env(envs(slaves, xks, id, "tserver")) +
            k.container.limits({
                memory: "1G", cpu: "1.0"
            }) +
            k.container.requests({
                memory: "1G", cpu: "0.1"
            })
    ],

    local slaves = config.gaffer.accumulo_slaves,
    local zks = config.gaffer.zookeepers,
    
    // Deployment definition for non-slave deployments.  proc is the process to
    // run, slaves is the number of slaves, zks is the number of Zookeepers.
    local deployment(proc) =
        local name = "accumulo-%s" % proc;
        k.deployment.new(name) +
            k.deployment.namespace(config.namespace) +
            k.deployment.containers(containers(proc, slaves, zks)) +
            k.deployment.labels({
                instance: name, app: "accumulo", component: "gaffer"
            }) +
            k.deployment.containerLabels({
                instance: name, app: "accumulo", component: "gaffer"
            }) +
            k.deployment.selector({
                instance: name, app: "accumulo", component: "gaffer"
            }) +
            k.deployment.hostname(proc) +
            k.deployment.subdomain("accumulo"),

    // Deployment definition for non-slave deployments.  id is the slave number
    // slaves is the number of slaves, zks is the number of Zookeepers.
    local slaveDeployment(id) =
        local name = "accumulo-slave%04d" % id;
        k.deployment.new(name) + 
            k.deployment.namespace(config.namespace) +
            k.deployment.containers(slaveContainers(id, slaves, zks)) +
            k.deployment.labels({
                instance: name, app: "accumulo", component: "gaffer"
            }) +
            k.deployment.containerLabels({
                instance: name, app: "accumulo", component: "gaffer"
            }) +
            k.deployment.selector({
                instance: name, app: "accumulo", component: "gaffer"
            }) +
            k.deployment.hostname("slave%04d" % id) +
            k.deployment.subdomain("accumulo"),

    // Ports declared on the other services.
    local servicePorts = [
        k.svcPort.newNamed("master", 9999, 9999) + k.svcPort.protocol("TCP"),
        k.svcPort.newNamed("gc", 50091, 50091) + k.svcPort.protocol("TCP"),
        k.svcPort.newNamed("monitor", 9995, 9995) + k.svcPort.protocol("TCP"),
        k.svcPort.newNamed("tracer", 12234, 12234) + k.svcPort.protocol("TCP"),
        k.svcPort.newNamed("proxy", 42424, 42424) + k.svcPort.protocol("TCP"),
        k.svcPort.newNamed("slave", 10002, 10002) + k.svcPort.protocol("TCP"),
        k.svcPort.newNamed("replication", 10001, 10001) + k.svcPort.protocol("TCP")
    ],

    // Ports declared on the slave services.
    local slavePorts = [
        k.svcPort.newNamed("slave", 9997, 9997) + k.svcPort.protocol("TCP")
    ],

    local deployments = [

        // Deployments for master, gc, tracer, monitor.
        deployment("master"),
        deployment("gc"),
        deployment("tracer"),
        deployment("monitor"),

    ] + [

        // One deployment for each slave
        slaveDeployment(id)
        for id in std.range(0, slaves - 1)

    ],

    local services = [

        // Services for the Accumulo master
        k.svc.new("accumulo") +
            k.svc.namespace(config.namespace) +
            k.svc.ports(servicePorts) +
            k.svc.labels({app: "accumulo", component: "gaffer"}) +
            k.svc.clusterIp("None") +
            k.svc.selector({instance: "accumulo-master", app: "accumulo"})

    ],

    // Function which returns resource definitions - deployments and services.
    resources::  deployments + services

};

// Return the function which creates resources.
[accumulo]

