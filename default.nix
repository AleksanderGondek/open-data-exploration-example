{ pkgs ? import <nixpkgs> { system = builtins.currentSystem; }, ... }:

let
  name = "open-data-exploration-example";
  create_helm_chart = import ./helm-chart.nix;

  # Elastic helm-charts 7.14.0
  elastic_helm_charts_src = builtins.fetchTarball {
    url =
      "https://github.com/elastic/helm-charts/archive/ac7769262fb47b577bad8085f4749dedd5d1bd18.tar.gz";
    sha256 = "13blcylc4ycq9520a5xmwvjxjsf46x0cp0dg843hlz87jd9s3p1x";
  };

  # https://github.com/elastic/helm-charts/blob/master/elasticsearch/examples/kubernetes-kind/values.yaml
  es_helm_chart_values_yaml = pkgs.writeText "values.yaml"
    (pkgs.lib.generators.toYAML { } {
      antiAffinity = "soft";
      esJavaOpts = "-Xmx128m -Xms128m";
      resources = {
        requests = {
          cpu = "100m";
          memory = "512M";
        };
        limits = {
          cpu = "1000m";
          memory = "512M";
        };
      };
    });

  elasticsearch_helm_chart = create_helm_chart {
    inherit pkgs;
    name = "odee-elasticsearch";
    helm_chart_src = elastic_helm_charts_src;
    namespace = "odee-elasticsearch";
    helm_chart_subpath = "./elasticsearch";
    values_yaml_path = es_helm_chart_values_yaml;
  };

  kibana_helm_chart_values_yaml = pkgs.writeText "values.yaml"
    (pkgs.lib.generators.toYAML { } {
      elasticsearchHosts =
        "http://elasticsearch-master.odee-elasticsearch:9200";
      healthCheckPath = "/odee/app/kibana";
      hostAliases = [ ];
      ingress = {
        enabled = true;
        hosts = [{
          host = "blackwood";
          paths = [{ path = "/odee"; }];
        }];
      };
      kibanaConfig = {
        "kibana.yml" = ''
          server:
              basePath: "/odee"
              host: "odee-kibana-kibana"
              publicBaseUrl: "http://blackwood/odee"
              rewriteBasePath: true
          telemetry:
              enabled: false
        '';
      };
    });

  kibana_helm_chart = create_helm_chart {
    inherit pkgs;
    name = "odee-kibana";
    helm_chart_src = elastic_helm_charts_src;
    namespace = "odee-kibana";
    helm_chart_subpath = "./kibana";
    values_yaml_path = kibana_helm_chart_values_yaml;
  };

  shell = pkgs.mkShell {
    inherit name;

    nativeBuildInputs = [ pkgs.kubectl ];

    shellHook = ''
      echo "Welcome to ${name} development shell!"
      echo "Deployment commands: "
      echo "kubectl apply -f ${elasticsearch_helm_chart}/odee-elasticsearch.yaml"
      echo "kubectl apply -f ${kibana_helm_chart}/odee-kibana.yaml"
    '';
  };
in {
  inherit shell;
  test = elasticsearch_helm_chart;
  test2 = kibana_helm_chart;
}
