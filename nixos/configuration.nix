{ config, pkgs, ... }:

let nixpkgs-unstable = import (fetchTarball
  https://github.com/NixOS/nixpkgs-channels/archive/nixos-unstable.tar.gz
) {}; in
{
  imports = [ ./hardware-configuration.nix ];

  environment.systemPackages = with pkgs; [
    vim git
  ];

  security.sudo.enable = true;
  security.pam.enableSSHAgentAuth = true;
  security.pam.services.sudo.sshAgentAuth = true;

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 80 ];
  };

  networking.nat = {
    enable = true;
    internalInterfaces = ["ve-+"];
    externalInterface = "ens33";
  };

  services.openssh.enable = true;

  users.extraUsers.johnw = {
    uid = 1000;
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDD2KwW9WdmzpN5vkl18s2QOmojTHeNNdMsC/jO8YRvtjS9IL3A4O0TRs/cFHC0lvSg4Rgwenpfzw781/HuWRZTir7SUX6wGvR1MCt+6fDWO+g9aFaQv+/hDpZZrVbJffxYV3QcoTIZBGRGkVQWk3cFmB5RiTL2OrsKsHV1gFtVMGXkxzOMOoVFSxT1hPQF58d7eGuY2u5AQmj4ktZ3GZ9jjq0yrt79rd1WafSHzJDx68cvgXIThefMo/aA4UV2G3oKJlTootLp6yvFgzs0DRti3Lyr65dVweAz01f7ECknUKSBz1MFYs9BMFKYAaMkEXyWM33d8m98ppJiz8zpvLvr johnw@local"
    ];
  };

  containers.bugzilla = {
    autoStart = true;

    privateNetwork = false;
    forwardPorts = [
      { protocol = "tcp";
        hostPort = 80;
      }
    ];

    config = { config, pkgs, ... }: {
      users.extraUsers.bugs = {
        uid = 2000;
        isNormalUser = true;
      };

      networking.firewall = {
        enable = true;
        allowedTCPPorts = [ 80 ];
      };

      services.mysql = {
        package = pkgs.mysql;
        enable = true;
        ensureUsers = [
          { name = "bugs";
            ensurePermissions = {
              "bugs.*" = "ALL PRIVILEGES";
            };
          }
        ];
      };

      services.httpd = {
        enable = true;
        enableSSL = false;
        enablePerl = true;

        adminAddr = "johnw@newartisans.com";

        virtualHosts = [
          {
            hostName = "bugs.ledger-cli.org";
            documentRoot = "${pkgs.bugzilla_5_0_3}";
            extraConfig = ''
              PerlPassEnv PERL5LIB
              PerlSwitches -w -T
              PerlConfigRequire ${pkgs.bugzilla_5_0_3}/perl5lib.pl
              PerlConfigRequire ${pkgs.bugzilla_5_0_3}/mod_perl.pl

              <Directory "${pkgs.bugzilla_5_0_3}">
                Options +Indexes +ExecCGI
                DirectoryIndex index.cgi

                AddHandler perl-script .cgi
                PerlResponseHandler ModPerl::Registry
                PerlOptions +ParseHeaders

                AllowOverride all
                Order allow,deny
                Allow from all
              </Directory>
            '';
          }
        ];
      };

      nixpkgs.config = {
        packageOverrides = pkgs: {
          DataStructureUtil = nixpkgs-unstable.perlPackages.DataStructureUtil;
        };
        allowBroken = true;
      };
      nixpkgs.overlays =
        let path = /home/johnw/.config/nixpkgs/overlays; in with builtins;
        map (n: import (path + ("/" + n)))
            (filter (n: match ".*\\.nix" n != null ||
                        pathExists (path + ("/" + n + "/default.nix")))
                    (attrNames (readDir path)));
    };
  };

  # ------------------------------------------------------------------------

  networking.hostName = "nixos"; # Define your hostname.
  time.timeZone = "America/Los_Angeles";

  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
  boot.loader.grub.device = "/dev/sda"; # or "nodev" for efi only

  nixpkgs.overlays =
    let path = /home/johnw/.config/nixpkgs/overlays; in with builtins;
    map (n: import (path + ("/" + n)))
        (filter (n: match ".*\\.nix" n != null ||
                    pathExists (path + ("/" + n + "/default.nix")))
                (attrNames (readDir path)));

  system.stateVersion = "17.09"; # Did you read the comment?
}
