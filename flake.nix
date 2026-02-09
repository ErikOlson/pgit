{
  description = "pgit — git multiplexer for process & product separation";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in {
      packages = forAllSystems (system:
        let pkgs = nixpkgs.legacyPackages.${system};
        in {
          default = pkgs.stdenvNoCC.mkDerivation {
            pname = "pgit";
            version = "0.3.0";
            src = ./.;

            nativeBuildInputs = [ pkgs.installShellFiles ];

            installPhase = ''
              # Preserve relative structure pgit expects (bin/../lib, bin/../completions)
              mkdir -p $out/bin $out/lib $out/completions

              install -m 755 bin/pgit $out/bin/pgit
              install -m 755 bin/pnp $out/bin/pnp
              install -m 644 lib/pgit-*.sh $out/lib/
              install -m 644 completions/* $out/completions/

              # Standard locations for shell auto-discovery
              installShellCompletion --bash --name pgit completions/pgit.bash
              installShellCompletion --zsh completions/_pgit
              installShellCompletion --fish completions/pgit.fish
            '';

            meta = {
              description = "Git multiplexer for process & product separation";
              license = pkgs.lib.licenses.mit;
              platforms = pkgs.lib.platforms.unix;
            };
          };
        });
    };
}
