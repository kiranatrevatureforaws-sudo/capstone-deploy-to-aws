#!/bin/sh
set -eu

docker compose up -d --build --remove-orphans

attempt=0
while [ "$attempt" -lt 30 ]; do
    if docker compose exec -T angular-app \
        wget -q -O /dev/null http://localhost/api/products >/dev/null 2>&1 &&
       docker compose exec -T angular-app \
        wget -q -O /dev/null http://localhost/api/catalog/products >/dev/null 2>&1; then
        echo "Deployment is healthy"
        docker compose ps
        exit 0
    fi

    attempt=$((attempt + 1))
    sleep 2
done

docker compose logs --tail=100
echo "Deployment health check failed" >&2
exit 1
