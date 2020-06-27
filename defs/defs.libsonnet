{

    deployment:: import "deployment.libsonnet",

    container:: import "container.libsonnet",

    list:: {
        new(x):: { apiVersion: "v1", items: x, kind: "List"}
    },

    env:: {
        new(n, v):: { name: n, value: v }
    },

    mount:: {
        new(vol, mpt):: {
            name: vol,
            mountPath: mpt,
            readOnly: false
        },
        readOnly(v):: {
            readOnly: v
        }
    },

    storageClass:: {
        new(name):: {
            apiVersion: "storage.k8s.io/v1",
            kind: "StorageClass",
            metadata: {
                name: name
            },
            parameters: {
                type: "pd-ssd"
            },
            provisioner: "kubernetes.io/gce-pd",
            reclaimPolicy: "Retain"
        }
    },

    pvc:: {
        new(name):: {
            apiVersion: "v1",
            kind: "PersistentVolumeClaim",
            metadata: {
                name: name
            },
            spec: {
                accessModes: ["ReadWriteOnce"],
                volumeMode: "Filesystem"
            }
        },
        storageClass(sc):: {
            spec+: {
                storageClassName: sc
            }
        },
        size(s):: {
            spec+: {
                resources+: {
                    requests: {
                        storage: s
                    }
                }
            }
        }
    },

    configMap:: {
        new(name):  {
            apiVersion: "v1",
            kind: "ConfigMap",
            metadata+: {
                name: name
            }
        },
        data(m): {
            data+: m
        }
    },

    volume:: {
        new(n):: {
            name: n
        },
        pvc(n):: {
            persistentVolumeClaim: {
                claimName: n
            }
        },
        fromConfigMap(cm):: {
            configMap: {
                name: cm
            }
        }
    },

    gceDisk:: {
        fsType(f):: { gcePersistentDisk+: { fsType: f } },
        pdName(d):: { gcePersistentDisk+: { pdName: d } }
    },

    svcPort:: {
        newNamed(name, port, target):: {
            name: name, port: port, targetPort: target
        },
        protocol(p):: {
            protocol: p
        }
    },

    svc:: {

        new(n):: {
            apiVersion: "v1",
            kind: "Service",
            metadata+: {
                name: n
            }
        },

        labels(l):: {
            metadata+: { labels: l }
        },

        ports(p):: {
            spec+: { ports: p }
        },

        selector(s):: {
            spec+: { selector: s }
        },

        clusterIp(x):: {
            spec+: {
                clusterIP: x
            }
        }

    },

    containerPort:: {

        newNamed(name, port):: {
            containerPort: port,
            name: name
        }
    
    }

}

