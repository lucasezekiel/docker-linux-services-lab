#!/usr/bin/env bash
# Restore the lab database from a SQL dump created by backup-db.sh.

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$PROJECT_DIR/.env"

usage() {
    echo "Usage: $0 [--yes] <backup.sql>" >&2
    exit 1
}

ASSUME_YES=0
if [[ "${1:-}" == "--yes" || "${1:-}" == "-y" ]]; then
    ASSUME_YES=1
    shift
fi

[[ $# -eq 1 ]] || usage

if [[ ! -f "$ENV_FILE" ]]; then
    echo "Error: .env file not found." >&2
    exit 1
fi

# shellcheck disable=SC1090,SC1091
source "$ENV_FILE"
: "${DB_NAME:?DB_NAME is not set in .env}"

if [[ ! -f "$1" ]]; then
    echo "Error: backup file not found: $1" >&2
    exit 1
fi

# Resolve the path before changing directory.
BACKUP_FILE="$(realpath -- "$1")"
cd "$PROJECT_DIR"

if [[ "$ASSUME_YES" -ne 1 ]]; then
    if [[ ! -t 0 ]]; then
        echo "Error: refusing to restore non-interactively without --yes." >&2
        exit 1
    fi
    echo "This replaces the tables in '$DB_NAME' with the contents of:"
    echo "  $BACKUP_FILE"
    read -r -p "Type the database name to continue: " answer
    if [[ "$answer" != "$DB_NAME" ]]; then
        echo "Aborted; nothing was changed."
        exit 1
    fi
fi

echo "Restoring database '$DB_NAME' from:"
echo "$BACKUP_FILE"

# shellcheck disable=SC2016  # variables must expand inside the container
docker compose exec -T db sh -c \
    'MYSQL_PWD="$MARIADB_ROOT_PASSWORD" exec mariadb -u root "$MARIADB_DATABASE"' \
    < "$BACKUP_FILE"

echo "Database restored successfully."
