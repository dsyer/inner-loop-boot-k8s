with import <nixpkgs> { overlays = [(import ./overlay.nix)]; } ;
mkShell {
  name = "env";
  buildInputs = [
    (import ./default.nix { inherit pkgs; })
    figlet
  ];
  shellHook = ''
    figlet ":Inner Loop:"
    kind-setup
    kubectl get all
  '';
}
