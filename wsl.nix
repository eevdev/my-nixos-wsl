{
  # CONFIG: uncomment the next line if you want to reference your GitHub/GitLab access tokens and other secrets
  # secrets,
  username,
  hostname,
  pkgs,
  inputs,
  ...
}: {
  # CONFIG: timezone (`timedatectl list-timezones`)
  time.timeZone = "Europe/Oslo";

  networking.hostName = "${hostname}";

  # CONFIG: shell
  programs.fish.enable = true;
  environment.pathsToLink = ["/share/fish"];
  environment.shells = [pkgs.fish];

  environment.enableAllTerminfo = true;

  security.sudo.wheelNeedsPassword = false;

  # CONFIG: openssh
  # services.openssh.enable = true;

  users.users.${username} = {
    isNormalUser = true;
    # CONFIG: shell
    shell = pkgs.fish;
    extraGroups = [
      "wheel"
      # CONFIG: for using docker without sudo
      # "docker"
    ];
    # CONFIG: hashed password
    # hashedPassword = "";
    # CONFIG: ssh public key
    # openssh.authorizedKeys.keys = [
    #   "ssh-rsa ..."
    # ];
  };

  home-manager.users.${username} = {
    imports = [
      ./home.nix
    ];
  };

  system.stateVersion = "22.05";

  wsl = {
    enable = true;
    wslConf.automount.root = "/mnt";
    wslConf.interop.appendWindowsPath = false;
    wslConf.network.generateHosts = false;
    defaultUser = username;
    startMenuLaunchers = true;

    # CONFIG: Docker Desktop integration (must be installed on host machine)
    docker-desktop.enable = false;
  };

  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    autoPrune.enable = true;
  };

  # nix-ld is needed for connecting VS Code on the Windows host machine to WSL NixOS
  # See: https://nix-community.github.io/NixOS-WSL/how-to/vscode.html
  # FIXME: it seems like nix-ld-rs has been merged into nix-ld as version 2.0.0, which is not yet released on stable channels.
  #        Once that happens, the following small block should be replaced by this: `programs.nix-ld.enable = true;`
  #        (ie. remove `package = pkgs.nix-ld-rs;`)
  programs.nix-ld = {
    enable = true;
    package = pkgs.nix-ld-rs;
  };

  nix = {
    settings = {
      trusted-users = [username];
      # CONFIG: access tokens for building your NixOS (or at least that's what I assume this is for)
      # access-tokens = [
      #   "github.com=${secrets.github_token}"
      #   "gitlab.com=OAuth2:${secrets.gitlab_token}"
      # ];

      accept-flake-config = true;
      auto-optimise-store = true;
    };

    registry = {
      nixpkgs = {
        flake = inputs.nixpkgs;
      };
    };

    nixPath = [
      "nixpkgs=${inputs.nixpkgs.outPath}"
      "nixos-config=/etc/nixos/configuration.nix"
      "/nix/var/nix/profiles/per-user/root/channels"
    ];

    package = pkgs.nixFlakes;
    extraOptions = ''experimental-features = nix-command flakes'';

    gc = {
      automatic = true;
      options = "--delete-older-than 7d";
    };
  };
}
