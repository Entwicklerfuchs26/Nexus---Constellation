{ config, lib, pkgs, userConfig, ... }:

let
  cfg = userConfig.sftpRemote;

  # Passwort liegt bewusst außerhalb des Git-Repos (/etc/nixos/secrets/),
  # damit es nicht ins öffentliche GitHub-Repo gelangt.
  sshWrapper = pkgs.writeShellScript "sftp-remote-ssh-command" ''
    exec ${pkgs.sshpass}/bin/sshpass -f /etc/nixos/secrets/sftp-yuki.pass \
      ${pkgs.openssh}/bin/ssh -o PubkeyAuthentication=no "$@"
  '';
in
lib.mkIf cfg.enable {
  environment.systemPackages = [ pkgs.sshfs pkgs.sshpass ];

  # Host-Key deklarativ statt StrictHostKeyChecking=no
  programs.ssh.knownHosts."sftp-remote" = {
    hostNames = [ "[${cfg.remoteHost}]:${toString cfg.remotePort}" ];
    publicKey = cfg.hostPublicKey;
  };

  systemd.tmpfiles.rules = [
    "d ${cfg.mountPoint} 0755 root root -"
  ];

  systemd.mounts = [{
    what = "${cfg.remoteUser}@${cfg.remoteHost}:/";
    where = cfg.mountPoint;
    type = "fuse.sshfs";
    options = builtins.concatStringsSep "," [
      "port=${toString cfg.remotePort}"
      "ssh_command=${sshWrapper}"
      "reconnect"
      "ServerAliveInterval=15"
      "allow_other"
      "uid=1000"
      "gid=100"
      "_netdev"
    ];
    mountConfig = {
      LazyUnmount = true;
    };
  }];

  systemd.automounts = [{
    where = cfg.mountPoint;
    wantedBy = [ "multi-user.target" ];
    automountConfig = {
      TimeoutIdleSec = "60";
    };
  }];
}
