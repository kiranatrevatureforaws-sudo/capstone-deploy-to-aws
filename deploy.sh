#!/usr/bin/env bash
set -Eeuo pipefail

DEPLOY_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$DEPLOY_DIR"

exec 9>"$DEPLOY_DIR/.deploy.lock"
if ! flock -n 9; then
    echo "Another deployment or rollback is in progress" >&2
    exit 1
fi

if (($# < 2)); then
    echo "Usage: bash deploy.sh RUN_NUMBER DOCKERHUB_USERNAME [service=sha-tag ...]" >&2
    exit 2
fi

RUN_NUMBER=$1
DOCKERHUB_USERNAME=$2
shift 2

if [[ ! "$RUN_NUMBER" =~ ^[0-9]+$ ]]; then
    echo "RUN_NUMBER must be a non-negative integer" >&2
    exit 2
fi
if [[ ! "$DOCKERHUB_USERNAME" =~ ^[A-Za-z0-9._-]+$ ]]; then
    echo "Invalid Docker Hub username" >&2
    exit 2
fi
if [[ ! -f .env ]]; then
    echo "Deployment .env is missing; configure it from .env.example before deploying" >&2
    exit 1
fi

if [[ -f .deploy-state ]]; then
    LAST_SUCCESSFUL_RUN=$(awk -F= '$1 == "LAST_SUCCESSFUL_RUN" {print $2}' .deploy-state)
    if [[ ! "$LAST_SUCCESSFUL_RUN" =~ ^[0-9]+$ ]]; then
        echo "Invalid .deploy-state; refusing deployment" >&2
        exit 1
    fi
    if ((RUN_NUMBER > 0 && RUN_NUMBER <= LAST_SUCCESSFUL_RUN)); then
        echo "Stale deployment run $RUN_NUMBER; run $LAST_SUCCESSFUL_RUN already succeeded" >&2
        exit 1
    fi
elif ((RUN_NUMBER > 0)); then
    for service in product-service catalog-service angular-app; do
        found=false
        for configured_service in "$@"; do
            [[ "${configured_service%%=*}" == "$service" ]] && found=true
        done
        if [[ "$found" != true ]]; then
            echo "Initial deployment requires immutable image tags for all services; run workflow_dispatch on a deployment branch" >&2
            exit 1
        fi
    done
fi

declare -A TAG_VARIABLES=(
    ["product-service"]="PRODUCT_TAG"
    ["catalog-service"]="CATALOG_TAG"
    ["angular-app"]="ANGULAR_TAG"
)
declare -a SERVICES=()
for image in "$@"; do
    if [[ "$image" != *=* ]]; then
        echo "Invalid image specification: expected service=sha-tag" >&2
        exit 2
    fi
    service=${image%%=*}
    tag=${image#*=}
    if [[ -z "${TAG_VARIABLES[$service]+x}" || ! "$tag" =~ ^[a-f0-9]{40}$ ]]; then
        echo "Invalid service or immutable image tag: $image" >&2
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
    if [[ -f "$file" ]]; then
        awk -F= -v key="$key" -v value="$value" '
            $1 == key {print key "=" value; found=1; next}
            {print}
            END {if (!found) print key "=" value}
        ' "$file" > "$temp"
    else
        printf '%s=%s\n' "$key" "$value" > "$temp"
    fi
    chmod 600 "$temp"
    mv "$temp" "$file"
}

ENV_TEMP=$(mktemp "$DEPLOY_DIR/.env.deploy.XXXXXX")
ROLLBACK_TEMP=$(mktemp "$DEPLOY_DIR/.rollback.env.XXXXXX")
deployment_started=false
cleanup() {
    local status=$?
    if ((status != 0)) && [[ "$deployment_started" == true ]] && ((${#SERVICES[@]} > 0)); then
        echo "Deployment failed; restoring the prior image for: ${SERVICES[*]}" >&2
        if docker compose --env-file .env -f compose.yml pull "${SERVICES[@]}" &&
           docker compose --env-file .env -f compose.yml up -d --no-deps --wait "${SERVICES[@]}"; then
            echo "Prior image restored" >&2
        else
            echo "Automatic recovery failed; use rollback.sh after resolving the deployment issue" >&2
        fi
    fi
    rm -f -- "$ENV_TEMP" "$ROLLBACK_TEMP"
}
trap cleanup EXIT
cp .env "$ENV_TEMP"
chmod 600 "$ENV_TEMP"
if [[ -f .rollback.env ]]; then
    cp .rollback.env "$ROLLBACK_TEMP"
fi
chmod 600 "$ROLLBACK_TEMP"

write_env_value "$ENV_TEMP" DOCKERHUB_USERNAME "$DOCKERHUB_USERNAME"
for image in "$@"; do
    service=${image%%=*}
    tag=${image#*=}
    variable=${TAG_VARIABLES[$service]}
    previous_tag=""
    if previous_tag=$(read_env_value "$ENV_TEMP" "$variable") && [[ "$previous_tag" =~ ^[a-f0-9]{40}$ ]]; then
        write_env_value "$ROLLBACK_TEMP" "PREVIOUS_${variable}" "$previous_tag"
    fi
    write_env_value "$ENV_TEMP" "$variable" "$tag"
done

if ((${#SERVICES[@]} > 0)); then
    docker compose --env-file "$ENV_TEMP" -f compose.yml pull "${SERVICES[@]}"
    deployment_started=true
    docker compose --env-file "$ENV_TEMP" -f compose.yml up -d --no-deps --wait "${SERVICES[@]}"
else
    docker compose --env-file "$ENV_TEMP" -f compose.yml up -d --wait
fi

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
    docker compose --env-file "$ENV_TEMP" -f compose.yml logs --tail=100 >&2 || true
    echo "Deployment health check failed" >&2
    exit 1
fi

mv "$ENV_TEMP" .env
mv "$ROLLBACK_TEMP" .rollback.env
chmod 600 .env .rollback.env
deployment_started=false
if ((RUN_NUMBER > 0)); then
    STATE_TEMP=$(mktemp "$DEPLOY_DIR/.deploy-state.XXXXXX")
    printf 'LAST_SUCCESSFUL_RUN=%s\n' "$RUN_NUMBER" > "$STATE_TEMP"
    chmod 600 "$STATE_TEMP"
    mv "$STATE_TEMP" .deploy-state
fi

echo "Deployment is healthy"
docker compose --env-file .env -f compose.yml ps
