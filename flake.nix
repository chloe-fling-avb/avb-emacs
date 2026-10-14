{
  description = "Emacs config (works as a normal ~/.config/emacs, or as a wrapped flake package)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    wrappers.url = "github:BirdeeHub/nix-wrapper-modules";
  };

  outputs =
    {
      self,
      nixpkgs,
      ...
    }@inputs:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems =
        f: nixpkgs.lib.genAttrs supportedSystems (system: f (import nixpkgs { inherit system; }));

      # mirrors the eglot-ensure hooks in lisp/options.el
      lspAndTools =
        pkgs:
        with pkgs;
        [
          typescript-language-server
          lemminx
          svelte-language-server
          lua-language-server
          ccls
          pyright
          rust-analyzer
          nil
          git
        ]
        # terminal clipboard glue
        ++ lib.optional stdenv.isLinux wl-clipboard;

      wrapEmacs =
        pkgs:
        inputs.wrappers.wrappers.emacs.wrap {
          inherit pkgs;
          configFile = ''(load "${./.}/init.el" nil t)'';
          # isolate elpa/custom.el from a plain `emacs` using this same directory
          userDirectory = "~/.local/share/emacs-flake/";
          # computed before userDirectory is applied, so it would point into the store
          earlyConfigFile = ''
            (setq package-user-dir (locate-user-emacs-file "elpa")
                  package-quickstart-file (locate-user-emacs-file "package-quickstart.el"))
          '';
          runtimePkgs = lspAndTools pkgs;
        };
    in
    {
      packages = forAllSystems (pkgs: {
        default = wrapEmacs pkgs;
        emacs = wrapEmacs pkgs;
      });
    };
}
