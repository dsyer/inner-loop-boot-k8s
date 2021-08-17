{ pkgs ? import <nixpkgs> { } }:

with pkgs;

let

  kindSetup = pkgs.writeShellScriptBin "kind-setup" "./kind-setup.sh";

in buildEnv {
  name = "env";
  paths = [
    jdk11
    apacheHttpd
    figlet
    kind
    kubectl
    kustomize
    skaffold
    kindSetup
    telepresence2
    tilt
  ];
}
