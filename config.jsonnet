
// Configuration values for sizing the cluster.
{
      hadoops: 1,		// Number of Hadoop nodes.
      hadoop_replication: 1,	// Data replication level on HDFS.
      zookeepers: 1,		// Number of Zookeepers.
      accumulo_slaves: 1,	// Number of Accumulo slaves.
      wildflys: 1,		// Number of Wildfly replicas.

      elasticsearch: {
          instances: 1
      },

      kibana: {
          instances: 1
      }

}
