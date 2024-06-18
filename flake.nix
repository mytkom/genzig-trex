{
  description = "Nix project environment with zig";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
  };

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f system);
    in
    {
      devShells = forAllSystems
        (system:
          let
            pkgs = import nixpkgs {
              inherit system;
              config.allowUnfree = true;
            };
          in
          {
            default = with pkgs; mkShell.override { stdenv = gcc12Stdenv; }
              {
                shellHook = ''
                  zellij
                '';
                packages = [
                  zig_0_12
                ];
                buildInputs = [
                  libGL
                  xorg.libX11.dev
                  xorg.libXcursor.dev
                  xorg.libXrandr.dev
                  xorg.libXinerama.dev
                  xorg.libXi.dev
                ];
              };
          }
        );
    };
}
