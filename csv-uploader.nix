{ pkgs ? import <nixpkgs> { system = builtins.currentSystem; }
, ... }:

# https://covid19-lake.s3.amazonaws.com/index.html
# https://registry.opendata.aws/aws-covid19-lake/
let
  to_be_described = "";
in 
  to_be_described
