{ pkgs ? import <nixpkgs> { } }:

with pkgs;

let

  kindSetup = pkgs.writeShellScriptBin "kind-setup" "./kind-setup.sh";

  tilt = pkgs.stdenv.mkDerivation {
    pname = "tilt";
    version = "0.22.5";
    src = pkgs.fetchurl {
      url =
        "https://github.com/tilt-dev/tilt/releases/download/v0.22.5/tilt.0.22.5.linux.x86_64.tar.gz";
      sha256 = "044kyc3ip0ysaqprydh5c5s38grj9kc0kngmlz67kzybbs3wdjpw";
    };
    phases = [ "installPhase" ];
    installPhase = ''
      mkdir -p $out/bin
      (cd $out/bin; tar -zxf $src tilt)
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
    telepresence2
    tilt
  ];
}
