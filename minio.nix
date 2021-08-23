{ pkgs ? import <nixpkgs> { system = builtins.currentSystem; }
, create_helm_chart, name, namespace, host }:

let
  # Operator demands functional auto-certs signing, crds are badly supported
  # for declarative-only single-file approach
  minio_helm_chart_src = builtins.fetchTarball {
    url =
      "https://github.com/minio/charts/archive/032712dbd3a5cd717dcb524e3fcdf5eb85db8ab4.tar.gz";
    sha256 = "1xx882wgmw6n4r82k5n3lyakr33g4jv52wcsjxv2cj1g6a7vy01c";
  };

  minio_helm_chart_values_yaml = pkgs.writeText "values.yaml"
    (pkgs.lib.generators.toYAML { } {
      buckets = [{
        name = "argo-artifacts";
        policy = "none";
        purge = false;
      }];

      accessKey = "minio1223";
      secretKey = "minio1223";

      persistence = {
        enabled = true;
        storageClass = "kubevirt-hostpath-provisioner";
        accessMode = "ReadWriteOnce";
        size = "10Gi";
      };

      ingress = {
        enabled = true;
        path = "/minio";
        hosts = [ "${host}" ];
        tls = [ ];
      };
    });
in create_helm_chart {
  inherit pkgs name;
  helm_chart_src = minio_helm_chart_src;
  namespace = namespace;
  helm_chart_subpath = "./minio";
  values_yaml_path = minio_helm_chart_values_yaml;
}
