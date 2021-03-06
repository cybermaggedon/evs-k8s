
// Import KSonnet library.
local k = import "defs.libsonnet";
local config = import "config.jsonnet";

// Import definitions for Gaffer stack
local imports = import "resources.jsonnet";

// Compile the resource list.
local resources = [
    imp(config).resources for imp in imports
];

// Output the resources.
k.list.new(std.flattenArrays(resources))

