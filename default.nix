{ pkgs ? import <nixpkgs> { } }:

with pkgs;

let

  kindSetup = pkgs.writeShellScriptBin "kind-setup" "./kind-setup.sh";
  telepresence = pkgs.stdenv.mkDerivation {
    pname = "telepresence";
    version = "2.0.1";
    src = pkgs.fetchurl {
      url =
        "https://app.getambassador.io/download/tel2/linux/amd64/2.1.3/telepresence";
      sha256 = "1lzmkfw84v3svyb7qqigbd4zhd58df52p26cdxda3hvbkql3h4pc";
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
    tilt
  ];
}
