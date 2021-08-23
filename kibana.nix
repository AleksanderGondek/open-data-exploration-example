{ pkgs ? import <nixpkgs> { system = builtins.currentSystem; }
, elastic_helm_charts_src, create_helm_chart, name, namespace, ingress_host
, ingress_path, elasticsearch_hosts }:

let
  kibana_helm_chart_values_yaml = pkgs.writeText "values.yaml"
    (pkgs.lib.generators.toYAML { } {
      elasticsearchHosts = elasticsearch_hosts;
      healthCheckPath = "${ingress_path}/app/kibana";
      hostAliases = [ ];
      ingress = {
        enabled = true;
        hosts = [{
          host = "${ingress_host}";
          paths = [{ path = "${ingress_path}"; }];
        }];
      };
      kibanaConfig = {
        "kibana.yml" = ''
          server:
              basePath: "${ingress_path}"
              publicBaseUrl: "http://${ingress_host}${ingress_path}"
              rewriteBasePath: true
          telemetry:
              enabled: false
        '';
      };
    });
in create_helm_chart {
  inherit pkgs;
  name = name;
  helm_chart_src = elastic_helm_charts_src;
  namespace = namespace;
  helm_chart_subpath = "./kibana";
  values_yaml_path = kibana_helm_chart_values_yaml;
}
