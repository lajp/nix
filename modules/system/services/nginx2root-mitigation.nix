# Temporary mitigation for NGINX2Root (https://nginx2root.com) and the rest of
# nginx 1.30.7's fixes, which aren't in the nixos-26.05 channel yet. Until they
# are, turn off or forbid every affected feature:
#   HTTP/2 (CVE-2026-123007, CVE-2026-123633): NixOS enables it per vhost
#   QUIC/HTTP/3 (CVE-2026-121810)
#   stream module (CVE-2026-120967, CVE-2026-123640)
#   resolver (CVE-2026-123634, together with mirror and a variable proxy_pass)
# The mail proxy (CVE-2026-113425) isn't compiled into nixpkgs' nginx.
#
# Applies to every nginx on every host (proxy-pi doesn't use
# lajp.services.nginx) and lifts itself once the package is >= 1.30.7. Delete
# this file and its import then.
{ lib, config, ... }:
let
  cfg = config.services.nginx;
  vulnerable = lib.versionOlder cfg.package.version "1.30.7";
in
{
  options.services.nginx.virtualHosts = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        config = lib.mkIf vulnerable {
          http2 = lib.mkForce false;
          quic = lib.mkForce false;
          http3 = lib.mkForce false;
          http3_hq = lib.mkForce false;
        };
      }
    );
  };

  config.assertions = lib.mkIf (cfg.enable && vulnerable) [
    {
      assertion = cfg.streamConfig == "";
      message = "nginx < 1.30.7 has stream module CVEs (NGINX2Root); don't set services.nginx.streamConfig until it's updated.";
    }
    {
      assertion = cfg.resolver.addresses == [ ];
      message = "nginx < 1.30.7 has a resolver use-after-free (CVE-2026-123634, NGINX2Root); don't set services.nginx.resolver until it's updated.";
    }
  ];
}
