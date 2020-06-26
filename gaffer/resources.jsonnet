
// Import KSonnet library.
local k = import "defs.libsonnet";

// Import definitions for Hadoop, Zookeeper, Accumulo, Wildfly.
local hadoop = import "hadoop.jsonnet";
local zookeeper = import "zookeeper.jsonnet";
local accumulo = import "accumulo.jsonnet";
local gaffer = import "gaffer.jsonnet";

local risk_graph_schema = importstr "riskgraph-schema.json";
local risk_graph = gaffer("risk", "riskgraph", risk_graph_schema);

local threat_graph_schema = importstr "threatgraph-schema.json";
local threat_graph = gaffer("threat", "threatgraph", threat_graph_schema);

// Compile the resource list.
local resources(config) = [
//    hadoop(config) +     // Hadoop.
//    zookeeper(config) +		      // Zookeeper.
//    accumulo(config) +   // Accumulo.
    risk_graph(config)];	      // Wildfly / REST API.

// Output the resources.
//risk_graph
hadoop + zookeeper + accumulo + risk_graph + threat_graph

