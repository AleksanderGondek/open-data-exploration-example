{ pkgs ? import <nixpkgs> { system = builtins.currentSystem; }, name
, helm_chart_src, namespace ? name, helm_chart_subpath ? "./"
, values_yaml_path ? null, force_create_ns ? true, yaml_extra_defs ? null
, ... }:
let
  namespace_definition = pkgs.writeText "${namespace}.yaml" ''
    ---
    apiVersion: "v1"
    kind: "Namespace"
    metadata:
      name: "${namespace}"
  '';
  kustomization = pkgs.writeText "kustomization.yaml" ''
    apiVersion: kustomize.config.k8s.io/v1beta1
    kind: Kustomization

    namespace: "${namespace}"

    resources:
    - "${name}.tmp.yaml"
  '';
in pkgs.stdenv.mkDerivation {
  inherit name;
  src = helm_chart_src;

  nativeBuildInputs = with pkgs; [ kubernetes-helm kustomize ];

  phases = [ "unpackPhase" "configurePhase" "buildPhase" "installPhase" ];
  configurePhase = ''
    echo -n "Ensuring helm bullshit does not leak... "

    mkdir -p ./.helm/cache
    mkdir -p ./.helm/config
    mkdir -p ./.helm/data
    mkdir -p ./.helm/repository-cache

    export HELM_CACHE_HOME=$(pwd)/.helm/cache
    export HELM_CONFIG_HOME=$(pwd)/.helm/config
    export HELM_DATA_HOME=$(pwd)/.helm/data
    export HELM_REPOSITORY_CACHE=$(pwd)/.helm/repository-cache
    echo "done."

    echo -n "Copying kustomization.yaml..."
    cp ${kustomization} ./kustomization.yaml
    echo "done."
  '';

  buildPhase = ''
     ${
       if force_create_ns then
         "cat " + namespace_definition + " >> ${name}.tmp.yaml"
       else
         ""
     }

    echo -n "Templating the chart... "
    helm template \
     --create-namespace \
     --include-crds \
     ${
       if !(builtins.isNull values_yaml_path) then
         "-f " + values_yaml_path + "\\"
       else
         "\\"
     }
     -n ${namespace} \
     ${name} \
     ${helm_chart_subpath} \
     >> ${name}.tmp.yaml
    echo "done."

    echo -n "Kustomize the result... "
    kustomize build > ${name}.tmp2.yaml
    echo "done."
    
    ${
      if !(builtins.isNull yaml_extra_defs) then
        "cat " + yaml_extra_defs + " >> ${name}.yaml"
      else
        ""
    }
    cat ${name}.tmp2.yaml >> ${name}.yaml
  '';

  installPhase = ''
    mkdir $out
    mv ./${name}.yaml $out/
  '';
}
