
// Import KSonnet library.
local config = import "config.jsonnet";

// Import definitions for Gaffer stack
local specs = import "resources.jsonnet";

// Compile the resource list.
std.flattenArrays([
    spec(config).images for spec in specs
])



