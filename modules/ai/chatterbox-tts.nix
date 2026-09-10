# Chatterbox TTS — Sprachausgabe für Sojus (Voice Layer).
# Der eigentliche Dienst (venv, Modell, Lazy-Load/Idle-Unload) läuft als
# systemd --user-Service, siehe home/chatterbox-tts.nix — dort auch die
# ausführliche Begründung, warum das hier kein reines Nix-Package ist
# (chatterbox-tts pinnt torch/transformers/diffusers exakt auf Versionen,
# die es in nixpkgs so nicht gibt). Dieses Modul deckt nur den System-Scope
# ab, den home-manager nicht selbst setzen kann.
{ ... }:
{
  networking.firewall.allowedTCPPorts = [ 8004 ];
}
