{ pkgs ? import <nixpkgs> {} }:

with pkgs;

let

  kindSetup = pkgs.writeShellScriptBin "kind-setup" "./kind-setup.sh";
  telepresence = pkgs.stdenv.mkDerivation {
    pname = "telepresence2";
    version = "2.0.1";
    src = pkgs.fetchurl {
      url = "https://app.getambassador.io/download/tel2/linux/amd64/latest/telepresence";
      sha256 = "1ip77gfrx3ilqzksmvgphdhx9l0y2jl1xrfhx8zs3py7wn63986s";
    };
    phases = [ "installPhase" "patchPhase" ];
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
    kind
    kubectl
    kustomize
    skaffold
    kindSetup
    telepresence
  ];
}