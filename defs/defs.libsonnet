{

    namespace:: {
        new(name):: {
            apiVersion: "v1",
            kind: "Namespace",
            metadata: {
                name: name
            }
        },
        labels(l):: {
            metadata+: { labels: l }
        }
    },

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
        },
        namespace(n):: {
            metadata+: {
                netadatnamespace: n
            }
        },
        labels(l):: {
            metadata+: { labels: l }
        },
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
        namespace(n):: {
            metadata+: {
                namespace: n
            }
        },
        labels(l):: {
            metadata+: { labels: l }
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
        namespace(n):: {
            metadata+: {
                namespace: n
            }
        },
        labels(l):: {
            metadata+: { labels: l }
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
        },
        fromSecret(s):: {
            secret: {
                secretName: s
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

        namespace(n):: {
            metadata+: {
                namespace: n
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
    
    },

    simple:: {
        new(name):: {
            name: name,
            component:: name,
            images:: [],
            envs:: [],
            labels:: local cmp = self.component; {
                instance: name, app: name, component: cmp
            },
            command:: {},
            limits:: {},
            ports:: [],
            requests:: {},
            replicas:: 1,
            containers:: [
                $.container.new(self.name, self.images[0]) +
                    self.command +
                    $.container.ports([
                        $.containerPort.newNamed(p.name, p.port)
                        for p in self.ports
                    ]) +
                    $.container.env(self.envs) +
                    self.limits + self.requests
                ],
            deployments:: [
                $.deployment.new(self.name) +
                    $.deployment.namespace(self.namespace) +
                    $.deployment.replicas(self.replicas) +
                    $.deployment.labels(self.labels) +
                    $.deployment.containerLabels(self.labels) +
                    $.deployment.selector(self.labels) +
                    $.deployment.containers(self.containers)
            ],
            services::
                local n = self.name; local c = self.component;
                if self.ports != [] then
                [
                    $.svc.new(self.name) +
                    $.svc.namespace(self.namespace) +
                    $.svc.labels({app: n, component: c}) +
                    $.svc.ports([
                        $.svcPort.newNamed(p.name, p.port, p.port) +
                            $.svcPort.protocol(p.protocol)
                        for p in self.ports
                    ]) +
                    $.svc.selector(self.labels)
                ] else [],
            resources:: self.deployments + self.services
        },
        namespace(n):: {
            namespace: n
        },
        component(name):: {
            component:: name
        },
        replicas(r):: {
            replicas:: r
        },
        image(img):: {
            images:: [img]
        },
        command(c):: {
            command:: $.container.command(c)
        },
        ports(ports):: {
            ports:: ports
        },
        envs(envs):: {
            envs:: [
                $.env.new(e.name, e.value)
                for e in envs
            ]
        },
        limits(l):: {
            limits:: $.container.limits(l)
        },
        requests(r):: {
            requests: $.container.requests(r)
        },
    }

}

