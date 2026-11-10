# Claude Desktop (offizielle Linux-Beta von Anthropic) -- deklarativ auf NixOS.
#
# Hintergrund (01.11.2026): Anthropic liefert Claude Desktop für Linux seit
# 30.06.2026 offiziell, aber nur als .deb für Ubuntu/Debian. Hier packen wir
# genau dieses offizielle .deb selbst in einen Nix-Store-Pfad -- kein Fremd-
# Flake-Input, keine zweite Arbeitskopie, eine Wahrheit im eigenen Repo.
# Die alte Community-Flake (k3d3) repackt noch den WINDOWS-Installer und ist
# damit obsolet, seit es den nativen Linux-Build gibt.
#
# Es ist eine selbst-enthaltene Electron-App (gebündeltes Chromium im
# 229 MB-Binary `claude-desktop`), plus mehrere native Helfer:
#   - resources/app.asar.unpacked/node_modules/node-pty       (Terminal)
#   - resources/app.asar.unpacked/node_modules/@ant/claude-native
#   - resources/app.asar.unpacked/resources/github-mcp/github-mcp-server
#   - resources/{chrome-native-host,claude-ssh-askpass,cowork-linux-helper}
# autoPatchelfHook patcht die alle rekursiv.
#
# Aktualisieren: neue Version aus dem apt-Index holen und version/url/hash
# unten anpassen:
#   curl -fsSL https://downloads.claude.ai/claude-desktop/apt/stable/dists/stable/main/binary-amd64/Packages \
#     | grep -E '^(Version|Filename|SHA256):'
# (jeweils letzter Block = neueste Version). Dann:
#   nix store prefetch-file --name claude-desktop.deb <url>
{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  makeWrapper,
  wrapGAppsHook3,
  # Laufzeit-Bibliotheken (aus dem Depends/Recommends des .deb abgeleitet)
  glib,
  gtk3,
  nss,
  nspr,
  at-spi2-atk,
  at-spi2-core,
  cups,
  dbus,
  expat,
  libdrm,
  libgbm,
  libxkbcommon,
  pango,
  cairo,
  alsa-lib,
  libnotify,
  libsecret,
  libuuid,
  pipewire,
  systemd, # libudev
  libseccomp, # von gebündeltem virtiofsd (Computer-Use-VM) benötigt
  libcap_ng, #  dito
  vulkan-loader,
  fontconfig,
  freetype,
  libx11,
  libxcomposite,
  libxdamage,
  libxext,
  libxfixes,
  libxrandr,
  libxrender,
  libxtst,
  libxscrnsaver,
  libxcb,
  libxshmfence,
  libxi,
  libxcursor,
  # Ozone/Wayland-Startverhalten: "auto" nutzt Wayland, wenn vorhanden
  # (nexus = Hyprland), sonst XWayland. Überschreibbar via NIXOS_OZONE_WL.
  commandLineArgs ? [ ],
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "claude-desktop";
  version = "4.4212.0";

  src = fetchurl {
    url = "https://downloads.claude.ai/claude-desktop/apt/stable/pool/main/c/claude-desktop/claude-desktop_${finalAttrs.version}_amd64.deb";
    hash = "sha256:4fcf658e0fc895390ab82593287281dfbce261b0ec3ea90060e82d8bfbfd7a84";
  };

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    makeWrapper
    wrapGAppsHook3
  ];

  buildInputs = [
    glib
    gtk3
    nss
    nspr
    at-spi2-atk
    at-spi2-core
    cups
    dbus
    expat
    libdrm
    libgbm
    libxkbcommon
    pango
    cairo
    alsa-lib
    libnotify
    libsecret
    libuuid
    pipewire
    systemd
    libseccomp
    libcap_ng
    vulkan-loader
    fontconfig
    freetype
    stdenv.cc.cc.lib
    libx11
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxrandr
    libxrender
    libxtst
    libxscrnsaver
    libxcb
    libxshmfence
    libxi
    libxcursor
  ];

  # autoPatchelf: das gebündelte Swiftshader/Vulkan laden Electron intern
  # dynamisch; keine fehlenden-lib-Fehler erzwingen, die nicht real sind.
  autoPatchelfIgnoreMissingDeps = [
    "libvulkan.so.1"
  ];

  unpackPhase = ''
    runHook preUnpack
    # --no-same-permissions: verhindert, dass tar das setuid-Bit von
    # chrome-sandbox zu setzen versucht (schlägt im Build-Sandbox fehl, und
    # setuid aus /nix/store geht ohnehin nicht -- wir nutzen Namespace-Sandbox).
    dpkg-deb --fsys-tarfile "$src" | tar -x --no-same-permissions --no-same-owner -f -
    runHook postUnpack
  '';

  # wrapGAppsHook soll NICHT selbst wrappen -- wir wrappen den Launcher von
  # Hand (makeWrapper), damit wir Chromium-Flags setzen können.
  dontWrapGApps = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out"
    cp -r usr/lib "$out/lib"
    cp -r usr/share "$out/share"

    # Launcher: gebündeltes Electron-Binary.
    # --disable-setuid-sandbox: Der gebündelte chrome-sandbox-Helfer müsste
    #   setuid-root sein -- unmöglich aus dem /nix/store. Stattdessen nutzt
    #   Chromium den (sicheren) User-Namespace-Sandbox, den NixOS per Default
    #   per unprivilegierten userns erlaubt. NICHT --no-sandbox (unsicher).
    # --ozone-platform-hint=auto: Wayland native auf Hyprland, sonst XWayland.
    makeWrapper "$out/lib/claude-desktop/claude-desktop" "$out/bin/claude-desktop" \
      --add-flags "--disable-setuid-sandbox" \
      --add-flags "--ozone-platform-hint=auto" \
      ${lib.concatMapStringsSep " " (f: "--add-flags ${lib.escapeShellArg f}") commandLineArgs} \
      "''${gappsWrapperArgs[@]}" \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [ vulkan-loader libgbm ]}"

    # .desktop-Datei zeigt auf den gewrappten Launcher im PATH -- passt schon
    # (Exec=claude-desktop). Icons liegen in share/icons/hicolor.

    runHook postInstall
  '';

  meta = {
    description = "Desktop-App für Claude.ai inkl. Claude Code (offizielle Linux-Beta)";
    homepage = "https://claude.ai";
    license = lib.licenses.unfree;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "claude-desktop";
  };
})
