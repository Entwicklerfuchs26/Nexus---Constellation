{ config, pkgs, ... }:

let
  mountPoint = "/mnt/yuki";
  remoteUser = "7qv2faveayb97l9m.92c918a7";
  remoteHost = "yuki.n.u0.eu";
  remotePort = 2022;

  # Passwort liegt bewusst außerhalb des Git-Repos (/etc/nixos/secrets/),
  # damit es nicht ins öffentliche GitHub-Repo gelangt.
  sshWrapper = pkgs.writeShellScript "sftp-yuki-ssh-command" ''
    exec ${pkgs.sshpass}/bin/sshpass -f /etc/nixos/secrets/sftp-yuki.pass \
      ${pkgs.openssh}/bin/ssh -o PubkeyAuthentication=no "$@"
  '';
in
{
  environment.systemPackages = [ pkgs.sshfs pkgs.sshpass ];

  # Host-Key deklarativ statt StrictHostKeyChecking=no
  programs.ssh.knownHosts."yuki-n-u0-eu" = {
    hostNames = [ "[${remoteHost}]:${toString remotePort}" ];
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHOQOKnPbavG+ug8nfBeGsa5mV/NJAeu3A03Xcc2XW4+";
  };

  systemd.tmpfiles.rules = [
    "d ${mountPoint} 0755 root root -"
  ];

  systemd.mounts = [{
    what = "${remoteUser}@${remoteHost}:/";
    where = mountPoint;
    type = "fuse.sshfs";
    options = builtins.concatStringsSep "," [
      "port=${toString remotePort}"
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
    where = mountPoint;
    wantedBy = [ "multi-user.target" ];
    automountConfig = {
      TimeoutIdleSec = "60";
    };
  }];
}
