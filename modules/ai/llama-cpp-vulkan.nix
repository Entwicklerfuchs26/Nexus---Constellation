# llama.cpp (Vulkan/RADV) als OpenAI-API-kompatible Alternative zu Ollama auf nous.
#
# Warum zusätzlich zu Ollama: Ollama hat einen offenen, ungefixten Bug im Umgang mit
# gesplitteten Vulkan-Heaps auf Unified-Memory-APUs (ollama/ollama#15302) — meldet auf
# dieser Hardware nur ~64GB statt der vollen ~120GB nutzbaren GTT-Größe. llama.cpp hat
# dieses Problem nicht. Beide laufen parallel auf unterschiedlichen Ports, beide bieten
# eine OpenAI-kompatible REST-API — alles was gegen die Ollama-API redet, redet genauso
# gegen llama-server.
{ config, pkgs, lib, ... }:

let
  modelDir = "/var/lib/llama-cpp";
  modelFile = "Qwen2.5-7B-Instruct-Q4_K_M.gguf";
  modelUrl = "https://huggingface.co/bartowski/Qwen2.5-7B-Instruct-GGUF/resolve/main/${modelFile}";
in
{
  networking.firewall.allowedTCPPorts = [ 8090 ];

  systemd.services.llama-server = {
    description = "llama.cpp Server (Vulkan/RADV, OpenAI-kompatible API)";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];

    serviceConfig = {
      Type = "simple";
      DynamicUser = true;
      StateDirectory = "llama-cpp";
      Restart = "on-failure";
      RestartSec = "5s";
      # Modell-Download (~4-5GB) dauert länger als das systemd-Default-Timeout (90s)
      # für ExecStartPre — sonst killt sich der Service mitten im Download selbst.
      TimeoutStartSec = "1800";

      ExecStartPre = pkgs.writeShellScript "llama-fetch-model" ''
        set -e
        if [ ! -f "${modelDir}/${modelFile}" ]; then
          echo "Lade ${modelFile}..."
          ${pkgs.curl}/bin/curl -fsSL -C - -o "${modelDir}/${modelFile}.tmp" "${modelUrl}"
          mv "${modelDir}/${modelFile}.tmp" "${modelDir}/${modelFile}"
        fi
      '';

      ExecStart = ''
        ${pkgs.llama-cpp-vulkan}/bin/llama-server \
          --model ${modelDir}/${modelFile} \
          --host 0.0.0.0 \
          --port 8090 \
          -ngl 99 \
          --flash-attn on \
          --ctx-size 32768 \
          --parallel 2
      '';
    };
  };
}
