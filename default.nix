{ pkgs ? import <nixpkgs> { } }:

with pkgs;

let

  kindSetup = pkgs.writeShellScriptBin "kind-setup" "./kind-setup.sh";
  telepresence = pkgs.stdenv.mkDerivation {
    pname = "telepresence";
    version = "2.1.5";
    src = pkgs.fetchurl {
      url =
        "https://app.getambassador.io/download/tel2/linux/amd64/2.1.5/telepresence";
      sha256 = "0vg4k18dsifrk58z9axay4bw53q67hcbkk7mcbq9wrdr3ds9dmnv";
    };
    phases = [ "installPhase" "postFixup" ];
    installPhase = ''
      mkdir -p $out/bin
      cp $src $out/bin/telepresence
      chmod a+x $out/bin/telepresence
    '';
    postFixup = ''
      chmod +w $out/bin/telepresence
      patchelf \
        --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
        $out/bin/telepresence
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
