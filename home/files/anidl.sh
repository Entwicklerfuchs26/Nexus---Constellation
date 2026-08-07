#!/usr/bin/env bash

if [ $# -eq 0 ]; then
    echo "Verwendung: AniDL <url> [<url2> <url3> ...]"
    exit 1
fi

ZIEL_BASIS="$HOME/Videos/Animes"
DOWNLOADED_SHOWS=()

ntfy_send() {
    curl -s -X POST "https://ntfy.sh/Nexus-NixOS_fuchs" \
        -H "Title: $1" \
        -H "Tags: $3" \
        -d "$2" > /dev/null
}

download_one() {
    local URL="$1"
    mkdir -p "$ZIEL_BASIS"

    echo "==> $URL"
    echo "    Ziel: $ZIEL_BASIS"

    local LOGFILE RC TITLE LABEL
    LOGFILE=$(mktemp)

    aniworld-dl --url "$URL" --output "$ZIEL_BASIS" --language "German Dub" < /dev/null | tee "$LOGFILE"
    RC=${PIPESTATUS[0]}

    TITLE=$(grep -oP 'ANIDL_TITLE::\K.*' "$LOGFILE" | tail -1)
    rm -f "$LOGFILE"

    LABEL="${TITLE:-$URL}"

    if [ "$RC" -eq 0 ] && [ -n "$TITLE" ]; then
        echo "==> Fertig!"
        ntfy_send "Download fertig ✓" "$LABEL" "white_check_mark"
        DOWNLOADED_SHOWS+=("$TITLE")
    else
        echo "==> Fehlgeschlagen!"
        ntfy_send "Download fehlgeschlagen ✗" "$LABEL" "x"
    fi
}

GESAMT=$#
INDEX=0
for URL in "$@"; do
    INDEX=$(( INDEX + 1 ))
    echo ""
    echo "======== [$INDEX/$GESAMT] ========"
    download_one "$URL"
done

echo ""
echo "======== Alle $GESAMT Downloads abgeschlossen ========"

# Metadaten für alle erfolgreich heruntergeladenen Serien holen
if [ ${#DOWNLOADED_SHOWS[@]} -gt 0 ] && command -v AniO &>/dev/null; then
    echo ""
    echo "======== Metadaten & Jellyfin-Struktur ========"
    declare -A SEEN
    for SHOW in "${DOWNLOADED_SHOWS[@]}"; do
        if [ -z "${SEEN[$SHOW]+x}" ]; then
            SEEN[$SHOW]=1
            echo "  Organisiere: $SHOW"
            AniO "$ZIEL_BASIS" --show "$SHOW" --auto
        fi
    done
    ntfy_send "Metadaten fertig ✓" "${DOWNLOADED_SHOWS[*]}" "sparkles"
fi
