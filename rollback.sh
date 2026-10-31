#!/usr/bin/env bash
set -Eeuo pipefail

DEPLOY_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$DEPLOY_DIR"

exec 9>"$DEPLOY_DIR/.deploy.lock"
if ! flock -n 9; then
    echo "Another deployment or rollback is in progress" >&2
    exit 1
fi

if (($# == 0)); then
    echo "Usage: bash rollback.sh service [service ...]" >&2
    exit 2
fi
if [[ ! -f .env || ! -f .rollback.env ]]; then
    echo "Current deployment or rollback history is missing" >&2
    exit 1
fi

declare -A TAG_VARIABLES=(
    ["product-service"]="PRODUCT_TAG"
    ["catalog-service"]="CATALOG_TAG"
    ["angular-app"]="ANGULAR_TAG"
)
SERVICES=()
for service in "$@"; do
    if [[ -z "${TAG_VARIABLES[$service]+x}" ]]; then
        echo "Unknown service: $service" >&2
        exit 2
    fi
    for existing in "${SERVICES[@]}"; do
        if [[ "$existing" == "$service" ]]; then
            echo "Duplicate service: $service" >&2
            exit 2
        fi
    done
    SERVICES+=("$service")
done

read_env_value() {
    local file=$1 key=$2
    awk -F= -v key="$key" '$1 == key {sub(/^[^=]*=/, ""); value=$0; found=1} END {if (found) print value; else exit 1}' "$file"
}

write_env_value() {
    local file=$1 key=$2 value=$3 temp
    temp=$(mktemp "$DEPLOY_DIR/.env-update.XXXXXX")
    awk -F= -v key="$key" -v value="$value" '
        $1 == key {print key "=" value; found=1; next}
        {print}
        END {if (!found) print key "=" value}
    ' "$file" > "$temp"
    chmod 600 "$temp"
    mv "$temp" "$file"
}

ENV_TEMP=$(mktemp "$DEPLOY_DIR/.env.rollback.XXXXXX")
ROLLBACK_TEMP=$(mktemp "$DEPLOY_DIR/.rollback.env.XXXXXX")
rollback_started=false
cleanup() {
    local status=$?
    if ((status != 0)) && [[ "$rollback_started" == true ]]; then
        echo "Rollback failed; restoring the current image for: ${SERVICES[*]}" >&2
        if docker compose --env-file .env -f compose.yml pull "${SERVICES[@]}" &&
           docker compose --env-file .env -f compose.yml up -d --no-deps --wait "${SERVICES[@]}"; then
            echo "Current image restored" >&2
        else
            echo "Failed to restore the current image" >&2
        fi
    fi
    rm -f -- "$ENV_TEMP" "$ROLLBACK_TEMP"
}
trap cleanup EXIT
cp .env "$ENV_TEMP"
cp .rollback.env "$ROLLBACK_TEMP"
chmod 600 "$ENV_TEMP" "$ROLLBACK_TEMP"

for service in "${SERVICES[@]}"; do
    variable=${TAG_VARIABLES[$service]}
    previous_variable="PREVIOUS_${variable}"
    current_tag=$(read_env_value "$ENV_TEMP" "$variable")
    previous_tag=$(read_env_value "$ROLLBACK_TEMP" "$previous_variable") || {
        echo "No previous image is recorded for $service" >&2
        exit 1
    }
    if [[ ! "$current_tag" =~ ^[a-f0-9]{40}$ || ! "$previous_tag" =~ ^[a-f0-9]{40}$ ]]; then
        echo "Invalid image history for $service" >&2
        exit 1
    fi
    write_env_value "$ENV_TEMP" "$variable" "$previous_tag"
    write_env_value "$ROLLBACK_TEMP" "$previous_variable" "$current_tag"
done

docker compose --env-file "$ENV_TEMP" -f compose.yml pull "${SERVICES[@]}"
rollback_started=true
docker compose --env-file "$ENV_TEMP" -f compose.yml up -d --no-deps --wait "${SERVICES[@]}"

attempt=0
while ((attempt < 30)); do
    if docker compose --env-file "$ENV_TEMP" -f compose.yml exec -T angular-app \
        wget -q -O /dev/null http://localhost:8080/api/products >/dev/null 2>&1 &&
       docker compose --env-file "$ENV_TEMP" -f compose.yml exec -T angular-app \
        wget -q -O /dev/null http://localhost:8080/api/catalog/products >/dev/null 2>&1; then
        break
    fi
    attempt=$((attempt + 1))
    sleep 2
done

if ((attempt == 30)); then
    echo "Rollback health check failed" >&2
    exit 1
fi

mv "$ENV_TEMP" .env
mv "$ROLLBACK_TEMP" .rollback.env
chmod 600 .env .rollback.env
rollback_started=false
echo "Rollback is healthy for: ${SERVICES[*]}"
docker compose --env-file .env -f compose.yml ps "${SERVICES[@]}"
