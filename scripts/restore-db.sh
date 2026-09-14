#!/usr/bin/env bash

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$PROJECT_DIR/.env"

if [[ ! -f "$ENV_FILE" ]]; then
    echo "Error: .env file not found."
    exit 1
fi

# shellcheck disable=SC1090,SC1091
source "$ENV_FILE"

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <backup.sql>"
    exit 1
fi

BACKUP_FILE="$1"

if [[ ! -f "$BACKUP_FILE" ]]; then
    echo "Error: backup file not found: $BACKUP_FILE"
    exit 1
fi

echo "Restoring database '$DB_NAME' from:"
echo "$BACKUP_FILE"

docker compose \
    -f "$PROJECT_DIR/compose.yaml" \
    exec -T db \
    mariadb \
    -u root \
    -p"$DB_ROOT_PASSWORD" \
    "$DB_NAME" < "$BACKUP_FILE"

echo "Database restored successfully."
