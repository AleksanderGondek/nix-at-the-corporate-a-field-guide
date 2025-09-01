{
  localSystem ? builtins.currentSystem,
  ...
}@args:
let
  external_sources = import ./nix/sources.nix;

  nixpkgs_import_args = {
    inherit localSystem;
    config = { };
  };

  nixpkgs = import external_sources.nixpkgs nixpkgs_import_args;

  font-awesome = nixpkgs.fetchzip {
    url = "https://use.fontawesome.com/releases/v7.0.0/fontawesome-free-7.0.0-web.zip";
    hash = "sha256-bA1jw/hfm0vsK2C1OKdrO6d9CD0kOWJhqXp24pXM10I=";
  };

  reveal-js = nixpkgs.fetchFromGitHub {
    owner = "hakimel";
    repo = "reveal.js";
    # release 5.2.1
    rev = "25e52e26af09933a98afb24cfdd3574e9055034d";
    hash = "sha256-f5g09Xj4XF+v6Y6zW13R4PUTWkAt3wwGpa9nSypUV6w=";
  };

  stop = nixpkgs.writeShellScriptBin "stop" ''
    set -euo pipefail
    REPO_ROOT=$(${nixpkgs.git}/bin/git rev-parse --show-toplevel)
    PID_FILE="''${REPO_ROOT}/httplz.pid"
    if [ ! -f "''${PID_FILE}" ]; then
      exit 0;
    fi

    PID=$(<''${PID_FILE})
    kill -9 $PID
    rm ''${PID_FILE}
  '';

  play = nixpkgs.writeShellScriptBin "play" ''
    set -euo pipefail
    REPO_ROOT=$(${nixpkgs.git}/bin/git rev-parse --show-toplevel)
    # Ensure that font-awesome is available
    ${nixpkgs.coreutils}/bin/rm -f ''${REPO_ROOT}/assets/font-awesome
    ${nixpkgs.coreutils}/bin/ln -f -s ${font-awesome} ''${REPO_ROOT}/assets/font-awesome
    # Ensure that reveal-js is available
    ${nixpkgs.coreutils}/bin/rm -f ''${REPO_ROOT}/assets/reveal-js
    ${nixpkgs.coreutils}/bin/ln -f -s ${reveal-js} ''${REPO_ROOT}/assets/reveal-js
    # Spin the httplz in the background
    ${nixpkgs.coreutils}/bin/nohup ${nixpkgs.httplz}/bin/httplz ''${REPO_ROOT} >''${REPO_ROOT}/httplz.stdout.log 2>''${REPO_ROOT}/httplz.stderr.log &
    echo $! >''${REPO_ROOT}/httplz.pid
  '';

  devShellPackages =
    pkgs:
    (with pkgs; [
      bashInteractive
      coreutils
      font-awesome
      git
      helix
      httplz
      niv
      nixfmt-rfc-style
      play
      reveal-js
      statix
      stop
    ]);

  devShell = nixpkgs.mkShell {
    name = "natc-shell";
    packages = devShellPackages nixpkgs;
    shellHook = ''
      echo "[natrc-shell] type 'play' to spin the game up (http://127.0.0.1:8000)"
      echo "[natrc-shell] type 'stop' to shut down the game."
    '';
  };
in
{
  inherit devShell nixpkgs;
}
