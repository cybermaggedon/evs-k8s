
// Import KSonnet library.
local config = import "config.jsonnet";

// Import definitions for Gaffer stack
local specs = import "resources.jsonnet";

[
    spec(config).name for spec in specs
]


