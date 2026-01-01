{ lib, config, ... }:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.lajp.services.nginx;
in
{
  options.lajp.services.nginx.enable = mkEnableOption "Enable nginx";

  config = mkIf cfg.enable {
    services.nginx = {
      enable = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      statusPage = true;

      commonHttpConfig = ''
        log_format json_analytics escape=json '{'
          '"msec": "$msec", '
          '"connection": "$connection", '
          '"connection_requests": "$connection_requests", '
          '"pid": "$pid", '
          '"request_id": "$request_id", '
          '"request_length": "$request_length", '
          '"remote_addr": "$remote_addr", '
          '"remote_user": "$remote_user", '
          '"remote_port": "$remote_port", '
          '"time_local": "$time_local", '
          '"time_iso8601": "$time_iso8601", '
          '"request": "$request", '
          '"request_uri": "$request_uri", '
          '"args": "$args", '
          '"status": "$status", '
          '"body_bytes_sent": "$body_bytes_sent", '
          '"bytes_sent": "$bytes_sent", '
          '"http_referer": "$http_referer", '
          '"http_user_agent": "$http_user_agent", '
          '"http_x_forwarded_for": "$http_x_forwarded_for", '
          '"http_host": "$http_host", '
          '"server_name": "$server_name", '
          '"request_time": "$request_time", '
          '"upstream": "$upstream_addr", '
          '"upstream_connect_time": "$upstream_connect_time", '
          '"upstream_header_time": "$upstream_header_time", '
          '"upstream_response_time": "$upstream_response_time", '
          '"upstream_response_length": "$upstream_response_length", '
          '"upstream_cache_status": "$upstream_cache_status", '
          '"ssl_protocol": "$ssl_protocol", '
          '"ssl_cipher": "$ssl_cipher", '
          '"scheme": "$scheme", '
          '"request_method": "$request_method", '
          '"server_protocol": "$server_protocol", '
          '"pipe": "$pipe", '
          '"gzip_ratio": "$gzip_ratio", '
          '"http_cf_ray": "$http_cf_ray"'
        '}';

        access_log /var/log/nginx/json_access.log json_analytics;
      '';
    };

    services.prometheus.exporters.nginx.enable = true;
    services.prometheus.exporters.nginxlog = {
      enable = true;
      group = "nginx";
      settings = {
        namespaces = [
          {
            name = "nginx";
            source.files = [ "/var/log/nginx/json_access.log" ];
            format = ''{"msec": "$msec", "connection": "$connection", "connection_requests": "$connection_requests", "pid": "$pid", "request_id": "$request_id", "request_length": "$request_length", "remote_addr": "$remote_addr", "remote_user": "$remote_user", "remote_port": "$remote_port", "time_local": "$time_local", "time_iso8601": "$time_iso8601", "request": "$request", "request_uri": "$request_uri", "args": "$args", "status": "$status", "body_bytes_sent": "$body_bytes_sent", "bytes_sent": "$bytes_sent", "http_referer": "$http_referer", "http_user_agent": "$http_user_agent", "http_x_forwarded_for": "$http_x_forwarded_for", "http_host": "$http_host", "server_name": "$server_name", "request_time": "$request_time", "upstream": "$upstream_addr", "upstream_connect_time": "$upstream_connect_time", "upstream_header_time": "$upstream_header_time", "upstream_response_time": "$upstream_response_time", "upstream_response_length": "$upstream_response_length", "upstream_cache_status": "$upstream_cache_status", "ssl_protocol": "$ssl_protocol", "ssl_cipher": "$ssl_cipher", "scheme": "$scheme", "request_method": "$request_method", "server_protocol": "$server_protocol", "pipe": "$pipe", "gzip_ratio": "$gzip_ratio", "http_cf_ray": "$http_cf_ray"}'';
            histogram_buckets = [ 0.005 0.01 0.025 0.05 0.1 0.25 0.5 1 2.5 5 10 ];
            relabel_configs = [
              { target_label = "vhost"; from = "server_name"; }
              { target_label = "method"; from = "request_method"; }
              { target_label = "status"; from = "status"; }
            ];
          }
        ];
      };
    };

    networking.firewall.interfaces."tailscale0".allowedTCPPorts = [
      config.services.prometheus.exporters.nginx.port
      config.services.prometheus.exporters.nginxlog.port
    ];

    networking.firewall.allowedTCPPorts = [
      80
      443
    ];

    security.acme = {
      acceptTerms = true;
      defaults.email = "lajp" + "@iki.fi";
    };
  };
}
