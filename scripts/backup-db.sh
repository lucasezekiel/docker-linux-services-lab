#!/usr/bin/env bash

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$PROJECT_DIR/.env"
BACKUP_DIR="$PROJECT_DIR/backups"

if [[ ! -f "$ENV_FILE" ]]; then
    echo "Error: .env file not found."
    exit 1
fi

# Load environment variables
# shellcheck disable=SC1090,SC1091
source "$ENV_FILE"

mkdir -p "$BACKUP_DIR"

TIMESTAMP="$(date '+%Y-%m-%d_%H-%M-%S')"
BACKUP_FILE="$BACKUP_DIR/${DB_NAME}_${TIMESTAMP}.sql"

echo "Creating backup of database '$DB_NAME'..."

docker compose \
    -f "$PROJECT_DIR/compose.yaml" \
    exec -T db \
    mariadb-dump \
    -u root \
    -p"$DB_ROOT_PASSWORD" \
    "$DB_NAME" > "$BACKUP_FILE"

echo "Backup created successfully:"
echo "$BACKUP_FILE"
