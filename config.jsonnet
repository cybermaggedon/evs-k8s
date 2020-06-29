
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

    // For auth purposes
    auth_domain: "cyberapocalypse.co.uk",

    base_domain: "cyberapocalypse.co.uk",

    id: "portal",
    domain: self.id + "." + self.base_domain,

    portal_host: "portal." + self.domain,
    accounts_host: "accounts." + self.domain,

    // No trailing slash.
    portal_url: "https://" + self.portal_host,
    accounts_url: "https://" + self.accounts_host,

    local callback_url = "https://%s/auth/auth" % self.portal_host,
    oauth: {
        provider:  "oidc",
        client_id: "cyberapocalypse",
        client_secret: "x",
        callback_url: callback_url,
        auth_url: "https://accounts.portal.cyberapocalypse.co.uk/auth/realms/cyberapocalypse/protocol/openid-connect/auth",

        // Would prefer to use public DNS https:... addresses, but the
        // certificate won't be recognised by vouch, so we're going direct
        // to the keycloak service.
        token_url: "http://keycloak:8080/auth/realms/cyberapocalypse/protocol/openid-connect/token",
        userinfo_url: "http://keycloak:8080/auth/realms/cyberapocalypse/protocol/openid-connect/userinfo",
        scopes: "openid,email,profile",
        // dd bs=50 count=1 if=/dev/urandom | base64
        vouch_jwt_secret: "klthI35b4yvWXpdVrzTajQb6U1D9rKamQ64jcqIcembpP0g5UKOWA68CJUYgpKGt6pA=",

        // Used to initialise
        keycloak_admin_password: "8DM2Tu2X/Vkp5VGKHRtg2U2GBBbZsFdCKd+CMlU3"
    },

    externalIps: {
        portal: "35.196.5.207",
    }
    
}

