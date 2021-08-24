{ pkgs ? import <nixpkgs> { system = builtins.currentSystem; }
, elastic_helm_charts_src, create_helm_chart, name, namespace }:

let
  # https://github.com/elastic/helm-charts/blob/master/elasticsearch/examples/kubernetes-kind/values.yaml
  es_helm_chart_values_yaml = pkgs.writeText "values.yaml"
    (pkgs.lib.generators.toYAML { } {
      antiAffinity = "soft";
      esJavaOpts = "-Xmx128m -Xms128m";
      roles = [
        "master"
        "data"
      ];
      resources = {
        requests = {
          cpu = "100m";
          memory = "512M";
        };
        limits = {
          cpu = "1000m";
          memory = "1Gi";
        };
      };
    });
in create_helm_chart {
  inherit pkgs;
  name = name;
  helm_chart_src = elastic_helm_charts_src;
  namespace = namespace;
  helm_chart_subpath = "./elasticsearch";
  values_yaml_path = es_helm_chart_values_yaml;
}
