{ config, pkgs, ... }:

{
  services.ollama = {
    enable = true;
    package = pkgs.ollama-cuda;

    # Im Heimnetz erreichbar (Port 11434)
    # #197 (26.09.2026): Ollama nur lokal — vorher host 0.0.0.0 + openFirewall
    # = unauthentifizierte LLM-API im ganzen Heimnetz. Falls ein LAN-Gerät die
    # nexus-Ollama braucht: statt 127.0.0.1 an die LAN-IP binden, openFirewall=false lassen.
    host = "127.0.0.1";
    port = 11434;
    openFirewall = false;

    # Ressourcen-Begrenzung: 1 Modell im Speicher, 1 parallele Anfrage
    environmentVariables = {
      OLLAMA_MAX_LOADED_MODELS = "1";
      OLLAMA_NUM_PARALLEL      = "1";
      OLLAMA_FLASH_ATTENTION   = "1";
    };
  };
}
