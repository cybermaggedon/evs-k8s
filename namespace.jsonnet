
// Import KSonnet library.
local k = import "defs.libsonnet";

local ns(config) = {

    name:: "namespace",
    images:: [],

    // Function which returns resource definitions - deployments and services.
    resources:: [k.namespace.new(config.namespace)]

};

// Return the function which creates resources.
[ns]

