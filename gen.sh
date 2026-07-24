#!/usr/bin/env bash
set -Eeuo pipefail

input="${1:-files.tsv}"
google_tts_language="${GOOGLE_TTS_LANGUAGE:-en-US}"
google_tts_voice="${GOOGLE_TTS_VOICE:-en-US-Chirp3-HD-Charon}"
google_tts_volume_gain_db="16"
google_cloud_project="${GOOGLE_CLOUD_PROJECT:-}"
google_access_token=""

google_tts() {
    local text="$1"
    local destination="$2"
    local request
    local response
    local audio_content
    local temporary_output
    local command_name

    for command_name in gcloud curl node base64; do
        command -v "$command_name" >/dev/null 2>&1 || {
            echo "Required command is not installed: $command_name" >&2
            exit 1
        }
    done

    if [[ -z "$google_cloud_project" ]]; then
        google_cloud_project="$(gcloud config get-value project 2>/dev/null)"
    fi

    if [[ -z "$google_cloud_project" || "$google_cloud_project" == "(unset)" ]]; then
        echo "Set GOOGLE_CLOUD_PROJECT or configure a gcloud project." >&2
        exit 1
    fi

    if [[ -z "$google_access_token" ]]; then
        if ! google_access_token="$(gcloud auth print-access-token 2>/dev/null)"; then
            echo "Google Cloud authentication is required." >&2
            echo "Run: gcloud auth login" >&2
            exit 1
        fi
    fi

    request="$(
        node -e '
            const [text, languageCode, name, volumeGainDb] = process.argv.slice(1);
            process.stdout.write(JSON.stringify({
                input: {text},
                voice: {languageCode, name},
                audioConfig: {
                    audioEncoding: "LINEAR16",
                    volumeGainDb: Number(volumeGainDb)
                }
            }));
        ' "$text" "$google_tts_language" "$google_tts_voice" "$google_tts_volume_gain_db"
    )"

    if ! response="$(
        curl \
            --silent \
            --show-error \
            --fail-with-body \
            --request POST \
            --header "Authorization: Bearer $google_access_token" \
            --header "x-goog-user-project: $google_cloud_project" \
            --header "Content-Type: application/json; charset=utf-8" \
            --data "$request" \
            "https://texttospeech.googleapis.com/v1/text:synthesize"
    )"; then
        echo "Google Cloud TTS request failed:" >&2
        printf '%s\n' "$response" >&2
        exit 1
    fi

    if ! audio_content="$(
        node -e '
            let response = "";
            process.stdin.setEncoding("utf8");
            process.stdin.on("data", chunk => response += chunk);
            process.stdin.on("end", () => {
                const audioContent = JSON.parse(response).audioContent;
                if (typeof audioContent !== "string" || audioContent.length === 0) {
                    process.exit(1);
                }
                process.stdout.write(audioContent);
            });
        ' <<< "$response"
    )"; then
        echo "Google Cloud TTS returned an invalid response:" >&2
        printf '%s\n' "$response" >&2
        exit 1
    fi

    temporary_output="$(mktemp "${destination}.tmp.XXXXXX")"

    if ! printf '%s' "$audio_content" | base64 --decode > "$temporary_output"; then
        rm -f "$temporary_output"
        echo "Could not decode Google Cloud TTS audio." >&2
        exit 1
    fi

    mv "$temporary_output" "$destination"
}

[[ -f "$input" ]] || {
    echo "Config file does not exist: $input" >&2
    exit 1
}

line_number=0
while IFS=$'\t' read -r directory filename type value extra; do
    ((line_number += 1))

    if ((line_number == 1)); then
        if [[ "$directory"$'\t'"$filename"$'\t'"$type"$'\t'"$value" != $'directory\tfilename\ttype\tvalue' ]]; then
            echo "Invalid TSV header in $input" >&2
            exit 1
        fi
        continue
    fi

    [[ -n "$directory$filename$type$value$extra" ]] || continue

    if [[ -z "$directory" || -z "$filename" || -z "$type" || -z "$value" || -n "$extra" ]]; then
        echo "Invalid TSV row $line_number in $input" >&2
        exit 1
    fi

    destination="${directory%/}/$filename"
    mkdir -p "$directory"

    case "$type" in
        tts)
            echo "TTS  -> $destination"
            google_tts "$value" "$destination"

            [[ -s "$destination" ]] || {
                echo "TTS output was not created: $destination" >&2
                exit 1
            }
            ;;

        copy)
            echo "COPY -> $destination"
            cp "$value" "$destination"
            ;;

        *)
            echo "Invalid type on TSV row $line_number: $type" >&2
            exit 1
            ;;
    esac
done < "$input"
