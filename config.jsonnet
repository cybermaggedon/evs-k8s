
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
    },

    cassandra: {
        instances: 1
    },

    pulsar: {
        instances: 1
    },

    cybermon: {
        instances: 1
    },

    domain: "cyberapocalypse.co.uk",

    auth_host: "login." + self.domain,
    portal_host: "portal." + self.domain,

    // No trailing slash.
    portal_url: "https://" + self.portal_host,

    local domain = self.domain,
    oauth: {
        provider:  "google",
        client_id: "749175465304-g21av5qp43daojukj3gcn1igb9ri6r3j.apps.googleusercontent.com",
        client_secret: "_CqoHoDLuzfwochoZ_LbjlUq",
        callback_url: "https://login.%s/auth" % domain
    },

    externalIps: {
        portal: "35.237.4.241",
        auth:  "34.75.229.50"
    }
    
}
