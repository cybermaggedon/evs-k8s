
// Configuration values for sizing the cluster.
{

    // Gaffer sizing
    gaffer: {
        hadoops: 1,		// Number of Hadoop nodes.
        hadoop_replication: 1,	// Data replication level on HDFS.
        zookeepers: 1,		// Number of Zookeepers.
        accumulo_slaves: 1,	// Number of Accumulo slaves.
        gaffers: 1,		// Number of Gaffer REST replicas.
    },

    // Other sizing.  Most of this stuff won't work properly, the cluster
    // support isn't switched on in Cassandra, for instance.
    elasticsearch: { instances: 1 },
    kibana: { instances: 1 },
    cassandra: { instances: 1 },
    pulsar: { instances: 1 },
    cybermon: { instances: 1 },

    // For auth purposes.  This specifies the domain which is associated with
    // the auth cookie.  It means anything from this domain is authorized to
    // read the cookie.
    auth_domain: "cyberapocalypse.co.uk",

    // This says that anyone with a keycloak account can login.
    allow_all_users: "true",

    base_domain: "cyberapocalypse.co.uk",

    client_id: "cyberapocalypse",
    realm: "cyberapocalypse",

    id: "portal",
    domain: self.id + "." + self.base_domain,

    portal_host: "portal." + self.domain,
    accounts_host: "accounts." + self.domain,

    // No trailing slash.
    portal_url: "https://" + self.portal_host,
    accounts_url: "https://" + self.accounts_host,

    local callback_url = "https://%s/auth/auth" % self.portal_host,

    local keycloak_local = "keycloak:8080",

    local auth_url =
        "https://%s/auth/realms/%s/protocol/openid-connect/auth" % [
            self.accounts_host, self.realm
        ],

    local token_url =
        "http://%s/auth/realms/%s/protocol/openid-connect/token" %
        [keycloak_local, self.realm],

    local userinfo_url =
        "http://%s/auth/realms/%s/protocol/openid-connect/userinfo" %
        [keycloak_local, self.realm],
    
    local client_id = self.client_id,

    oauth: {
        provider:  "oidc",
        client_id: client_id,
        client_secret: "x",
        callback_url: callback_url,
        auth_url: auth_url,

        // Would prefer to use public DNS https:... addresses, but the
        // certificate won't be recognised by vouch, so we're going direct
        // to the keycloak service.
        token_url: token_url,
        userinfo_url: userinfo_url,
        scopes: "openid,email,profile",

        // Don't use these secrets
        // dd bs=50 count=1 if=/dev/urandom | base64
        vouch_jwt_secret: "asdklajsldjaslkdjalskdjad",

        // Used to initialise initial admin account, password should be
        // changed.
        keycloak_admin_password: "sldkfjlsdfjsdlfjsldfjlsdkfjdslk"
    },

    externalIps: {
        portal: "35.196.5.207",
    }
    
}

