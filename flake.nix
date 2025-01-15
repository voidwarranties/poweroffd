{
  description = "Flake for the Space Control poweroffd script";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
  };

  outputs = {
    self,
    nixpkgs,
  } @ inputs: let
    # This list of architectures provides the supported systems to the wrapper function below.
    # It basically defines which architectures can build and run the Backtab application.
    supportedSystems = [
      "aarch64-darwin"
      "x86_64-linux"
    ];

    # This helper function is used to make the flake outputs below more DRY. It looks a bit intimidating but that's
    # mostly because of the functional programming nature of Nix. I recommend reading
    # [Nix language basics](https://nix.dev/tutorials/nix-language.html) and search online for resources about
    # functional programming paradigms.
    #
    # Basically this function makes it so that instead of declaring outputs for every architecture as the flake schema
    # expects, e.g.:
    #
    # packages = {
    #   "x86_64-linux" = {
    #     ...
    #   };
    #   "aarch64-darwin" = {
    #     ...
    #   };
    # };
    #
    # we can define each output below (package, formatter, ...) once for all the architectures / systems.
    #
    # See https://ayats.org/blog/no-flake-utils to learn more.
    #
    forAllSystems = function:
      nixpkgs.lib.genAttrs supportedSystems (system:
        function (import nixpkgs {
          inherit system;
        }));
  in {
    formatter = forAllSystems (pkgs: pkgs.alejandra);

    nixosModules.poweroffd = import ./nixos-module.nix;
  };
}
