#!/usr/bin/env bash
# Create a timestamped SQL dump of the lab database under backups/.

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$PROJECT_DIR/.env"
BACKUP_DIR="$PROJECT_DIR/backups"

if [[ ! -f "$ENV_FILE" ]]; then
    echo "Error: .env file not found." >&2
    exit 1
fi

# shellcheck disable=SC1090,SC1091
source "$ENV_FILE"
: "${DB_NAME:?DB_NAME is not set in .env}"

# Run Compose from the project directory so COMPOSE_FILE and
# COMPOSE_PROJECT_NAME from the caller's environment are honored.
cd "$PROJECT_DIR"

# Dumps contain all table data: keep them readable by the owner only.
umask 077
mkdir -p "$BACKUP_DIR"

TIMESTAMP="$(date '+%Y-%m-%d_%H-%M-%S')"
BACKUP_FILE="$BACKUP_DIR/${DB_NAME}_${TIMESTAMP}.sql"

# Write to a hidden temporary file first so a failed dump never looks like
# a valid backup.
TMP_FILE="$(mktemp "$BACKUP_DIR/.${DB_NAME}_${TIMESTAMP}.XXXXXX")"
trap 'rm -f -- "$TMP_FILE"' EXIT

echo "Creating backup of database '$DB_NAME'..."

# The root password is read from the container's own environment, so it never
# appears on a command line (and therefore not in `ps` output).
# shellcheck disable=SC2016  # variables must expand inside the container
docker compose exec -T db sh -c \
    'MYSQL_PWD="$MARIADB_ROOT_PASSWORD" exec mariadb-dump -u root --single-transaction "$MARIADB_DATABASE"' \
    > "$TMP_FILE"

if [[ ! -s "$TMP_FILE" ]]; then
    echo "Error: the dump is empty; no backup was created." >&2
    exit 1
fi

mv -- "$TMP_FILE" "$BACKUP_FILE"
trap - EXIT

echo "Backup created successfully:"
echo "$BACKUP_FILE"
