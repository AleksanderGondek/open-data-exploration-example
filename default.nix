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

  elasticsearch_helm_chart = import ./es.nix {
    inherit pkgs elastic_helm_charts_src create_helm_chart;
    name = "odee-elasticsearch";
    namespace = "odee-elasticsearch";
  };

  kibana_helm_chart = import ./kibana.nix {
    inherit pkgs elastic_helm_charts_src create_helm_chart;
    name = "odee-kibana";
    namespace = "odee-kibana";
    ingress_host = "blackwood";
    ingress_path = "/odee";
    elasticsearch_hosts = "http://elasticsearch-master.odee-elasticsearch:9200";
  };

  odee = pkgs.symlinkJoin {
    inherit name;
    paths = [ elasticsearch_helm_chart kibana_helm_chart ];
  };

  shell = pkgs.mkShell {
    inherit name;

    nativeBuildInputs = [ pkgs.kubectl ];

    shellHook = ''
      echo "Welcome to ${name} development shell!"
      echo "Deployment bundle avaiable under path: ${odee}"
    '';
  };
in { inherit odee shell; }
