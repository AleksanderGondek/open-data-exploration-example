{ pkgs ? import <nixpkgs> { system = builtins.currentSystem; }
, create_helm_chart, name, namespace, host }:

let
  # Argo Workflows release 0.4.2
  argo_wf_helm_chart_src = builtins.fetchTarball {
    url =
      "https://github.com/argoproj/argo-helm/archive/11ec82596b5a62ba9d7c974c1a25aede739437b2.zip";
    sha256 = "0afnxk21kj4by6zxnz70qxjzqlh091jjasm5rw81yk13hfjcldg3";
  };

  manual_yaml_definitions = pkgs.writeText "${name}-manual-defs.yaml" ''
    ---
    ${builtins.readFile (argo_wf_helm_chart_src + "/charts/argo-workflows/crds/argoproj.io_clusterworkflowtemplates.yaml")}
    ---
    ${builtins.readFile (argo_wf_helm_chart_src + "/charts/argo-workflows/crds/argoproj.io_cronworkflows.yaml")}
    ---
    ${builtins.readFile (argo_wf_helm_chart_src + "/charts/argo-workflows/crds/argoproj.io_workfloweventbindings.yaml")}
    ---
    ${builtins.readFile (argo_wf_helm_chart_src + "/charts/argo-workflows/crds/argoproj.io_workflows.yaml")}
    ---
    ${builtins.readFile (argo_wf_helm_chart_src + "/charts/argo-workflows/crds/argoproj.io_workflowtemplates.yaml")}
    ---
    apiVersion: "v1"
    kind: "Namespace"
    metadata:
      name: "${namespace}"
    ---
    apiVersion: rbac.authorization.k8s.io/v1
    kind: Role
    metadata:
      name: argo-workflow-role
      namespace: ${namespace}
    rules:
    - apiGroups:
      - ""
      resources:
      - pods
      verbs:
      - get
      - watch
      - patch
    - apiGroups:
      - ""
      resources:
      - pods/log
      verbs:
      - get
      - watch
    ---
    kind: RoleBinding
    apiVersion: rbac.authorization.k8s.io/v1
    metadata:
      name: argo-workflow-rolebinding
      namespace: ${namespace}
    subjects:
    - kind: ServiceAccount
      name: default
      namespace: ${namespace}
    roleRef:
      kind: Role
      name: argo-workflow-role
      apiGroup: rbac.authorization.k8s.io
    ---
    apiVersion: v1
    kind: Secret
    metadata:
      name: odee-minio
      namespace: ${namespace}
    type: Opaque
    data:
      accesskey: "bWluaW8xMjIz"
      secretkey: "bWluaW8xMjIz"
    ---
    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
      annotations:
        nginx.ingress.kubernetes.io/rewrite-target: /$2
      name: argo-ingress
      namespace: ${namespace}
    spec:
      rules:
      - host: "${host}"
        http:
          paths:
          - backend:
              service:
                name: odee-argo-workflows-server
                port: 
                  number: 2746
            path: /argo(/|$)(.*)
            pathType: "ImplementationSpecific"
    ---
  '';

  argo_wf_helm_chart_values_yaml = pkgs.writeText "values.yaml"
    (pkgs.lib.generators.toYAML { } {
      installCRD = false;
      artifactRepository = {
        archiveLogs = true;
        s3 = {
          accessKeySecret = {
            name = "odee-minio";
            key = "accesskey";
          };
          secretKeySecret = {
            name = "odee-minio";
            key = "secretkey";
          };
          insecure = true;
          bucket = "argo-artifacts";
          endpoint = "odee-minio.odee-minio.svc.cluster.local:9000";
        };
      };
      controller = {
        containerRuntimeExecutor = "k8sapi";
      };
      createAggregateRoles = true;
      singleNamespace = true;
      server = {
        enabled = true;
        baseHref = "/argo/";
        ingress = {
          enabled = false;
        };
        clusterWorkflowTemplates = {
          enableEditing = true;
        };
        extraArgs = [
          "--auth-mode=server"
        ];
      };
      useStaticCredentials = true;
      useDefaultArtifactRepo = true;
      minio = {
        install = false;
      };
    });
in create_helm_chart {
  inherit pkgs name;
  helm_chart_src = argo_wf_helm_chart_src;
  namespace = namespace;
  helm_chart_subpath = "./charts/argo-workflows";
  values_yaml_path = argo_wf_helm_chart_values_yaml;
  force_create_ns = false;
  yaml_extra_defs = manual_yaml_definitions;
}
