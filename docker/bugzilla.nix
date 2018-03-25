{ pkgs ? import <nixpkgs> {} }:

with pkgs;
dockerTools.buildImage {
  name = "bugzilla-5.0.3";
  runAsRoot = ''
    #!${stdenv.shell}
    ${dockerTools.shadowSetup}
    groupadd -r redis
    useradd -r -g redis -d /data -M redis
    mkdir /data
    chown redis:redis /data
  '';

  config = {
    Cmd = [ "${goPackages.gosu.bin}/bin/gosu" "redis" "${redis}/bin/redis-server" ];
    ExposedPorts = {
      "6379/tcp" = {};
    };
    WorkingDir = "/data";
    Volumes = {
      "/data" = {};
    };
  };
}
