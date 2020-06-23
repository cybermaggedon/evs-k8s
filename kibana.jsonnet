
// Import KSonnet library.
local k = import "defs.libsonnet";

// Ports used by deployments
local ports() = [
    k.containerPort.newNamed("kibana", 5601)
];

// Environment variables
local envs() = [

    k.env.new("ELASTICSEARCH_URL", "http://elasticsearch:9200/")

];

// Container definition.
local containers() = [
    k.container.new("kibana", "kibana:7.7.1") +
        k.container.ports(ports()) +
	k.container.env(envs()) +
	k.container.limits({
	    memory: "512M", cpu: "1.0"
	}) +
	k.container.requests({
	    memory: "512M", cpu: "0.1"
	})
];

// Deployment definition.
local deployment(replicas) = 
    k.deployment.new("kibana") +
        k.deployment.replicas(replicas) +
        k.deployment.labels({
            instance: "kibana",
            app: "kibana",
            component: "kibana"
        }) +
        k.deployment.containerLabels({
            instance: "kibana",
            app: "kibana",
            component: "kibana"
        }) +
        k.deployment.selector({
            instance: "kibana",
            app: "kibana",
            component: "kibana"
        }) +
        k.deployment.containers(containers());

// Ports declared on the service.
local servicePorts = [
    k.svcPort.newNamed("kibana", 5601, 5601) + k.svcPort.protocol("TCP")
];
    
// Function which returns resource definitions - deployments and services.
local resources(config) = [

    deployment(config.kibana.instances),

    // One service for the first node (name node).
    k.svc.new("kibana") +
        k.svc.labels({app: "kibana", component: "kibana"}) +
        k.svc.ports(servicePorts) +
	k.svc.selector({
            app: "kibana", component: "kibana"
        })
    
];

// Return the function which creates resources.
resources

