
//
// Definition for Gaffer HTTP API / Wildfly on Kubernetes.  This creates a set
// of Wildfly replicas.
//

// Import KSonnet library.
local k = import "defs.libsonnet";

// Ports used by deployments
local ports() = [
    k.containerPort.newNamed("rest", 8080)
];

// Constructs a list of Zookeeper hostnames, comma separated.
local zookeeperList(count) =
    std.join(",", std.makeArray(count, function(x) "zk%d.zk" % (x + 1)));

// Environment variables
local envs(zookeepers) = [

    // List of Zookeepers.
    k.env.new("ZOOKEEPERS", zookeeperList(zookeepers))
    
];

// Container definition.
local containers(zookeepers) = [
    k.container.new("wildfly", "cybermaggedon/wildfly-gaffer:1.12.0b") +
        k.container.ports(ports()) +
        k.container.env(envs(zookeepers)) +
	k.container.limits({
	    memory: "1G", cpu: "1.5"
	}) +
	k.container.requests({
	    memory: "1G", cpu: "0.1"
	})
];

// Deployment definition.  id is the node ID.
local deployment(gaffers, zookeepers) =
      k.deployment.new("wildfly") +
      k.deployment.replicas(gaffers) +
      k.deployment.labels({
          instance: "wildfly", app: "wildfly", component: "gaffer"
      }) +
      k.deployment.containerLabels({
          instance: "wildfly", app: "wildfly", component: "gaffer"
      }) +
      k.deployment.selector({
          instance: "wildfly", app: "wildfly", component: "gaffer"
      }) +
      k.deployment.containers(containers(zookeepers));

// Ports declared on the service.
local servicePorts = [
    k.svcPort.newNamed("rest", 8080, 8080) + k.svcPort.protocol("TCP")
];

// Function which returns resource definitions - deployments and services.
local resources(c) = [

    // One deployment, with a set of replicas.
    deployment(c.gaffer.gaffers, c.gaffer.zookeepers)

] + [

    // One service load-balanced across the replicas
    k.svc.new("gaffer") + k.svc.labels({app: "wildfly", component: "gaffer"}) +
        k.svc.ports(servicePorts) +
        k.svc.selector({app: "wildfly", component: "gaffer"})

];

// Return the function which creates resources.
resources

