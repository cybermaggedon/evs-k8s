
{

    extensions:: {
        v1beta1:: $.extensions,

        deployment:: {

            new(name, replicas, containers, labels):: {
                apiVersion: "extensions/v1beta1",
                kind: "Deployment",
                metadata: {
                  name: name,
                },
                spec: {
                    replicas: replicas,
                    template: {
                        metadata: {
                            labels: labels
                        },
                        spec: {
                            containers: containers
                        }
                    }
                }
            },
            mixin:: {
                spec:: {
                    template:: {
                        spec:: {
                            containersType:: $.container,
                            volumes(x):: {
                                spec+: {
                                    template+: {
                                        spec+: {
                                            volumes: x
                                        }
                                    }
                                }
                            },
                            volumeMountsType:: {
                                new(vol, mpt):: {
                                     asdspec+: {
                                         volume: vol,
                                         mountPt: mpt
                                     }
                                }
                            },
                            volumesType:: {
                                name(x):: { name: x},
                                mixin:: {
                                    gcePersistentDisk:: {
                                        fsType(t): {
                                            gcePersistentDisk+: {
                                                fsType: t
                                            }
                                        },
                                        pdName(pd): {
                                            gcePersistentDisk+: {
                                                pdName: pd
                                            }
                                        }
                                    }
                                }
                                
                            },
                            hostname(x): {
                                spec+: { template+: { spec+: {
                                    hostname: x
                                }}}
                            },
                            subdomain(x): {
                                spec+: { template+: { spec+: {
                                    subdomain: x
                                }}}
                            }
                        }
                    }
                }
            }

        }

    },

    container:: {

        new(name, image):: {
           name: name,
           image: image
        },

        ports(p):: {
           ports: p
        },

        env(e):: {
           env: e
        },

        envType:: $.env,

        volumeMountsType:: {
            new(v, mp):: {
                mountPath: mp,
                name: v,
                readOnly: false
            }
        },

        volumeMounts(m):: {
            volumeMounts: m
        },
        
        portsType:: {

            newNamed(name, port):: {
                containerPort: port,
                name: name
            }

        },

        command(c):: {
            command: c
        },

        mixin:: {

            resources:: {
               requests(r):: {
                  resources+: {
                    requests: r
                  }
               },
               limits(r):: {
                  resources+: {
                    limits: r
                  }
               }
            },

            spec:: {
                template:: {
                    spec:: {
                        volumesType:: {
                        }
                    }
                }
            },

            gcePersistentDisk:: {
            }

        }

    },

    env:: {

        new(n, v):: { name: n, value: v }

    },

    svcLabels(l):: {
 
    },

    core:: {
        v1:: $.core,
        list:: {
            new(x):: { apiVersion: "v1", items: x, kind: "List"}
        },
        service:: {
            new(n, sel, ports):: {
                apiVersion: "v1",
                kind: "Service",
                metadata: {
                    name: n
                },
                spec: {
                    ports: ports,
                    selector: sel
                }
            },
            mixin:: {
                spec:: {
                    portsType:: {
                        newNamed(name, port, target):: {
                            name: name, port: port, targetPort: target
                        },
                        protocol(p):: {
                            protocol: p
                        }
                    },
                    clusterIp(x): {
                        spec+: {
                            clusterIP: x
                        }
                    }
                },
                metadata:: {
                    labels(l):: {
                         metadata+: {
                             labels: l
                         }                
                    }
                }
            }
        }            
    }

}

