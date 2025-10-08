# Neovim derivation built with a nix-flake for elite portability
**Heavily inspired** by https://github.com/nix-community/kickstart-nix.nvim

## Usage ##
Try it out!
```bash
nix run "github:nilsblix/neovim.nix"
```

Or use it in a flake
```nix
nvim = {
    url = "github:nilsblix/neovim.nix"
}
...
pkgs = import nixpkgs {
    overlays = [ inputs.nvim.overlays.default ]
}
... in configuration.nix
environment.systemPackages = with pkgs; [nvim-pkg];
