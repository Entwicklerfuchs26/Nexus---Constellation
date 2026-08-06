#!/usr/bin/env bash

if [ $# -eq 0 ]; then
    echo "Verwendung: DL <url> [<url2> <url3> ...]"
    exit 1
fi

ZIEL_BASIS="$HOME/Videos/Downloads"
DOWNLOADED_TITLES=()

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

    local TITLE
    TITLE=$(yt-dlp --print "%(title)s" --no-warnings --skip-download "$URL" 2>/dev/null | head -n1)
    [ -z "$TITLE" ] && TITLE="$URL"

    local LOG_FILE OUTPUT_FILE RC
    LOG_FILE=$(mktemp)

    yt-dlp \
        -f "bv*[vcodec^=avc1]+ba/bv*+ba/b" \
        --merge-output-format mp4 \
        -o "$ZIEL_BASIS/%(uploader)s/%(title)s.%(ext)s" \
        --embed-thumbnail --embed-metadata \
        --no-playlist \
        --print "after_move:filepath" \
        "$URL" < /dev/null | tee "$LOG_FILE"
    RC=${PIPESTATUS[0]}

    OUTPUT_FILE=$(grep -m1 -F "$ZIEL_BASIS" "$LOG_FILE")
    rm -f "$LOG_FILE"

    if [ $RC -eq 0 ] && [ -n "$OUTPUT_FILE" ] && [ -f "$OUTPUT_FILE" ]; then
        local VCODEC
        VCODEC=$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of csv=p=0 "$OUTPUT_FILE" 2>/dev/null)
        if [ -n "$VCODEC" ] && [ "$VCODEC" != "h264" ]; then
            echo "  Codec '$VCODEC' erkannt (schwarzes Bild auf dieser GPU) – transcodiere zu H.264 (NVENC)..."
            local TMP_FILE="${OUTPUT_FILE%.*}.h264.mp4"
            if ffmpeg -y -v error -i "$OUTPUT_FILE" -c:v h264_nvenc -preset p5 -cq 20 -c:a copy "$TMP_FILE" < /dev/null; then
                mv -f "$TMP_FILE" "$OUTPUT_FILE"
                echo "  Transcode fertig."
            else
                echo "  Transcode fehlgeschlagen, Original ($VCODEC) bleibt erhalten."
                rm -f "$TMP_FILE"
            fi
        fi
    fi

    if [ $RC -eq 0 ]; then
        echo "==> Fertig: $TITLE"
        ntfy_send "Download fertig ✓" "$TITLE" "white_check_mark"
        DOWNLOADED_TITLES+=("$TITLE")
    else
        echo "==> Fehlgeschlagen: $TITLE"
        ntfy_send "Download fehlgeschlagen ✗" "$TITLE" "x"
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

if [ ${#DOWNLOADED_TITLES[@]} -gt 1 ]; then
    ntfy_send "Alle Downloads fertig ✓" "${DOWNLOADED_TITLES[*]}" "sparkles"
fi
