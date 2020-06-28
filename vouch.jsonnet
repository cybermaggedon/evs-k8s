
// Import KSonnet library.
local k = import "defs.libsonnet";

local vouch(config) = 
    k.simple.new("vouch") +
      k.simple.image("vouch/vouch-proxy:0.16.2") +
      k.simple.ports([
          {name: "vouch", port: 9090, protocol: "TCP"}
      ]) +
      k.simple.envs([
          {name: "VOUCH_DOMAINS", value: "yourdomain.com"},
          {name: "OAUTH_PROVIDER", value: "google"},
          {name: "OAUTH_CLIENT_ID", value: "749175465304-g21av5qp43daojukj3gcn1igb9ri6r3j.apps.googleusercontent.com"},
          {name: "OAUTH_CLIENT_SECRET", value: "_CqoHoDLuzfwochoZ_LbjlUq"},
          {name: "OAUTH_CALLBACK_URL", value: "https://vouch.cyberapocalypse.com/auth"}
      ]) +
      k.simple.limits({
          memory: "128M", cpu: "1.0"
      }) +
      k.simple.requests({
          memory: "128M", cpu: "0.1"
      });

[vouch]

