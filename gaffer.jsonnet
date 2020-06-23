
// Import KSonnet library.
local k = import "defs.libsonnet";

// Import definitions for Hadoop, Zookeeper, Accumulo, Wildfly.
local hadoop = import "hadoop.jsonnet";
local zookeeper = import "zookeeper.jsonnet";
local accumulo = import "accumulo.jsonnet";
local wildfly = import "wildfly.jsonnet";

// Configuration values for sizing the cluster.
local config = {
      hadoops: 1,		// Number of Hadoop nodes.
      hadoop_replication: 1,	// Data replication level on HDFS.
      zookeepers: 1,		// Number of Zookeepers.
      accumulo_slaves: 1,	// Number of Accumulo slaves.
      wildflys: 1		// Number of Wildfly replicas.
};

// Compile the resource list.
local resources(config) =
    hadoop(config) +     // Hadoop.
    zookeeper(config) +		      // Zookeeper.
    accumulo(config) +   // Accumulo.
    wildfly(config);	      // Wildfly / REST API.

// Output the resources.
resources

