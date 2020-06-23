{

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

 }