
// Configuration values for sizing the cluster.
{
    gaffer: {
        hadoops: 1,		// Number of Hadoop nodes.
        hadoop_replication: 1,	// Data replication level on HDFS.
        zookeepers: 1,		// Number of Zookeepers.
        accumulo_slaves: 1,	// Number of Accumulo slaves.
        gaffers: 1,		// Number of Gaffer REST replicas.
    },

    elasticsearch: {
        instances: 1
    },

    kibana: {
        instances: 1
    }

}
