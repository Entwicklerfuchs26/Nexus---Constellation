# Baut das lokale Render-Bundle für ComponentBubble.qml: React/ReactDOM/
# Recharts/Babel-Standalone als gepinnte UMD-Bundles (kein Internetzugriff zur
# Laufzeit nötig, nur beim einmaligen Nix-Fetch — danach aus dem Store bzw.
# per Binary-Cache). QtWebEngine lädt die zusammengebaute index.html per
# file://, siehe ComponentBubble.qml.
{ pkgs }:

let
  react = pkgs.fetchurl {
    url = "https://unpkg.com/react@18/umd/react.production.min.js";
    hash = "sha256-2Unxw2h67a3O2shSYYZfKbF80nOZfn9rK/xTsvnUxN0=";
  };
  reactDom = pkgs.fetchurl {
    url = "https://unpkg.com/react-dom@18/umd/react-dom.production.min.js";
    hash = "sha256-NfT5dPSyvNRNpzljNH+JUuNB+DkJ5EmCJ9Tia5j2bw0=";
  };
  propTypes = pkgs.fetchurl {
    url = "https://unpkg.com/prop-types@15/prop-types.min.js";
    hash = "sha256-5lNHGrqCR4au5dzhvLWobtMMhRjTRtKs4EYKVjOpy9s=";
  };
  recharts = pkgs.fetchurl {
    url = "https://unpkg.com/recharts@2/umd/Recharts.js";
    hash = "sha256-fq+MZbuk07aEe9AAEcNZYFtSi1yxLhP84JGAv6e9RW8=";
  };
  babelStandalone = pkgs.fetchurl {
    url = "https://unpkg.com/@babel/standalone@7/babel.min.js";
    hash = "sha256-Uz5cVUGr+CLVlzpU4Io/A49RH6/Wt0gLwhSNwsPVT5Q=";
  };
in
pkgs.runCommand "sojus-component-renderer" { } ''
  mkdir -p "$out"
  cp ${./index.html} "$out/index.html"
  cp ${react} "$out/react.production.min.js"
  cp ${reactDom} "$out/react-dom.production.min.js"
  cp ${propTypes} "$out/prop-types.min.js"
  cp ${recharts} "$out/recharts.umd.js"
  cp ${babelStandalone} "$out/babel.min.js"
''
