
// Import KSonnet library.
local k = import "defs.libsonnet";
local config = import "config.jsonnet";

// Import definitions for Gaffer stack
local imports = std.flattenArrays([
    import "gaffer/resources.jsonnet",
    import "elasticsearch.jsonnet",
    import "kibana.jsonnet",
    import "cassandra.jsonnet",
    import "pulsar.jsonnet"
]);

// Compile the resource list.
local resources = [
    imp(config).resources for imp in imports
];

// Output the resources.
k.list.new(std.flattenArrays(resources))

