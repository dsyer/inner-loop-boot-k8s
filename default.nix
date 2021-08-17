{ pkgs ? import <nixpkgs> { } }:

with pkgs;

let

  kindSetup = pkgs.writeShellScriptBin "kind-setup" "./kind-setup.sh";
  telepresence = pkgs.stdenv.mkDerivation {
    pname = "telepresence";
    version = "2.4.0";
    src = pkgs.fetchurl {
      url =
        "https://app.getambassador.io/download/tel2/linux/amd64/2.4.0/telepresence";
      sha256 = "0qh6m5xghl9p59shfgm7ydx3psx00f11zbsqbn7xl6sz950ac0d6";
    };
    phases = [ "installPhase" ];
    installPhase = ''
      mkdir -p $out/bin
      cp $src $out/bin/telepresence
      chmod a+x $out/bin/telepresence
    '';
  };

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
    telepresence
    tilt
  ];
}
