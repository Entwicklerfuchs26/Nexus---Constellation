# llama-swap (Multi-Modell-Proxy für llama.cpp, Vulkan/RADV) auf nous.
#
# Ersetzt den vorherigen fest-verdrahteten Ein-Modell-Server (llama-cpp-vulkan.nix).
# Modelle liegen als .gguf-Dateien in /var/lib/llama-cpp/models/ — die config.yaml wird
# bei jedem Service-Start automatisch aus allen dort vorhandenen Dateien neu generiert
# (ein Modell-Eintrag pro Datei, Dateiname ohne .gguf = Modell-ID/API-Name). llama-swap
# selbst lauscht auf Port 8090 (OpenAI-kompatibel) und fährt die passende llama-server-
# Instanz on-demand hoch (localhost-only, ttl 600s bis zum automatischen Unload).
#
# Neues Modell installieren (als fuchs, kein Nix-Rebuild nötig):
#   llama-pull <gguf-url> [name]
#
# Serving-Binary ist ein Vulkan-Build mit -march=native (Zen5, GGML_NATIVE=ON) statt dem
# generischen nixpkgs-Default (der GGML_NATIVE bewusst auf false lässt, für reproduzierbare
# Binary-Cache-Hits über alle x86_64-Hosts hinweg). Kostet einen lokalen Rebuild auf nous
# statt Cache-Hit, spart dafür CPU-seitige Zyklen (Tokenizer/Sampling/Prompt-Preprocessing;
# nixpkgs' GGML_CPU_ALL_VARIANTS=true deckt bereits AVX2/AVX-512-Dispatch pauschal ab, native
# holt zusätzlich Zen5-spezifische Instruktionen raus).
#
# ROCm als Alternativ-Backend zu Vulkan liegt als eigenes Binary (llama-server-rocm) daneben,
# NICHT im aktiven Serving-Pfad — gfx1151 (Strix Halo) ist inoffiziell/nicht in AMDs Support-
# Matrix, aber seit 2026 in nixpkgs' Standard-ROCm-Targets enthalten und über cache.nixos.org
# vorgebaut (kein stundenlanger lokaler ROCm-Kompilierjob). Erst nach Benchmark-Vergleich
# (llama-bench, ebenfalls hier bereitgestellt) ggf. im genConfigScript auf ROCm umstellen.
{ config, pkgs, lib, ... }:

let
  modelDir = "/var/lib/llama-cpp/models";

  llamaCppNative = pkgs.llama-cpp-vulkan.overrideAttrs (old: {
    cmakeFlags = old.cmakeFlags ++ [ "-DGGML_NATIVE=ON" ];
  });
  llamaServerBin = "${llamaCppNative}/bin/llama-server";

  # Vergleichsbinary für ROCm-Benchmarks, s. Kommentar oben. Nicht im genConfigScript verdrahtet.
  llamaServerRocmBin = pkgs.writeShellScriptBin "llama-server-rocm"
    "exec ${pkgs.llama-cpp-rocm}/bin/llama-server \"$@\"";
  llamaBench = pkgs.writeShellScriptBin "llama-bench-vulkan"
    "exec ${llamaCppNative}/bin/llama-bench \"$@\"";
  llamaBenchRocm = pkgs.writeShellScriptBin "llama-bench-rocm"
    "exec ${pkgs.llama-cpp-rocm}/bin/llama-bench \"$@\"";

  # KV-Cache Q8_0 (statt F16) halbiert den Speicherbedarf des Kontexts bei minimalem
  # Qualitätsverlust, braucht --flash-attn (bereits an). Batch/Ubatch explizit gesetzt
  # (Werte = llama.cpp-Defaults) als Ausgangspunkt für empirisches Tuning auf der Unified-
  # Memory-Bandbreite von nous — noch nicht durchgemessen.
  commonFlags = "-ngl 99 --flash-attn on --ctx-size 32768 --parallel 2 --cache-type-k q8_0 --cache-type-v q8_0 --batch-size 2048 --ubatch-size 512";

  genConfigScript = pkgs.writeShellScript "llama-swap-gen-config" ''
    set -e
    out="${modelDir}/config.yaml"
    {
      echo "startPort: 9100"
      echo "models:"
      shopt -s nullglob
      for f in ${modelDir}/*.gguf; do
        name=$(basename "$f" .gguf)
        echo "  $name:"
        echo "    cmd: ${llamaServerBin} --host 127.0.0.1 --port \''${PORT} --model $f ${commonFlags}"
        echo "    ttl: 600"
      done
    } > "$out"
  '';

  llamaPull = pkgs.writeShellScriptBin "llama-pull" ''
    set -e
    if [ -z "$1" ]; then
      echo "Usage: llama-pull <gguf-url> [name]" >&2
      exit 1
    fi
    url="$1"
    name="''${2:-$(basename "$url" .gguf)}"
    dest="${modelDir}/$name.gguf"
    echo "Lade $name nach $dest..."
    ${pkgs.curl}/bin/curl -fL -C - -o "$dest.tmp" "$url"
    mv "$dest.tmp" "$dest"
    echo "Download fertig, starte llama-swap neu..."
    sudo systemctl restart llama-swap.service
    echo "Modell '$name' ist jetzt unter http://192.168.1.25:8090/v1 verfügbar (model=\"$name\")."
  '';
in
{
  networking.firewall.allowedTCPPorts = [ 8090 ];

  users.groups.llama-cpp = { };
  users.users.llama-cpp = {
    isSystemUser = true;
    group = "llama-cpp";
  };
  users.users.fuchs.extraGroups = [ "llama-cpp" ];

  systemd.tmpfiles.rules = [
    "Z /var/lib/llama-cpp 0755 llama-cpp llama-cpp -"
    "Z ${modelDir} 2775 llama-cpp llama-cpp -"
  ];

  environment.systemPackages = [ llamaPull llamaServerRocmBin llamaBench llamaBenchRocm ];

  security.sudo.extraRules = [{
    users = [ "fuchs" ];
    commands = [{
      command = "/run/current-system/sw/bin/systemctl restart llama-swap.service";
      options = [ "NOPASSWD" ];
    }];
  }];

  systemd.services.llama-swap = {
    description = "llama-swap (Multi-Modell-Proxy für llama.cpp, Vulkan/RADV)";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];

    serviceConfig = {
      Type = "simple";
      User = "llama-cpp";
      Group = "llama-cpp";
      Restart = "on-failure";
      RestartSec = "5s";
      ExecStartPre = genConfigScript;
      ExecStart = "${pkgs.llama-swap}/bin/llama-swap --config ${modelDir}/config.yaml --listen 0.0.0.0:8090";
    };
  };
}
