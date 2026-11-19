#!/usr/bin/env bash
# End-to-end smoke test for the lab.
#
# Starts an isolated copy of the stack (own Compose project, containers,
# volume and port 18080) and checks:
#   web + database OK -> backup -> data loss -> restore -> data back
#   -> containers recreated -> data still there.
#
# The isolated copy and its volume are removed at the end.
# Set KEEP_SMOKE=1 to leave it running for inspection.

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

export COMPOSE_PROJECT_NAME=dlsl-smoke
export COMPOSE_FILE=compose.yaml:tests/compose.smoke.yaml
URL="http://127.0.0.1:18080"
MARKER="smoke-test marker $$"

CREATED_ENV=0
BACKUP_FILE=""

step() { printf '\n==> %s\n' "$*"; }
fail() { echo "FAIL: $*" >&2; exit 1; }

cleanup() {
    local status=$?
    if [[ $status -ne 0 ]]; then
        docker compose ps || true
        docker compose logs --no-color --tail=50 || true
    fi
    if [[ "${KEEP_SMOKE:-0}" != 1 ]]; then
        docker compose down -v --remove-orphans >/dev/null 2>&1 || true
    fi
    if [[ -n "$BACKUP_FILE" ]]; then
        rm -f -- "$BACKUP_FILE"
    fi
    if [[ $CREATED_ENV -eq 1 ]]; then
        rm -f .env
    fi
    exit "$status"
}
trap cleanup EXIT

# Query as the application user; the password stays inside the container.
db_query() {
    # shellcheck disable=SC2016  # variables must expand inside the container
    docker compose exec -T db sh -c \
        'MYSQL_PWD="$MARIADB_PASSWORD" exec mariadb -N -B -u "$MARIADB_USER" "$MARIADB_DATABASE"' \
        <<< "$1"
}

row_count() {
    db_query "SELECT COUNT(*) FROM demo_messages;"
}

expect_count() {
    local actual
    actual="$(row_count)"
    [[ "$actual" == "$1" ]] || fail "expected $1 rows, found $actual"
    echo "rows in demo_messages: $actual"
}

fetch_page() {
    local attempt
    for attempt in $(seq 1 30); do
        if curl -fsS "$URL"; then
            return 0
        fi
        sleep 2
    done
    fail "web service did not answer at $URL (attempts: $attempt)"
}

if [[ ! -f .env ]]; then
    cp .env.example .env
    CREATED_ENV=1
fi

step "Start isolated stack ($COMPOSE_PROJECT_NAME)"
docker compose up -d --build --wait --wait-timeout 180
docker compose ps

step "Web service reaches the database"
page="$(fetch_page)"
echo "$page"
grep -q "Database connection: OK" <<< "$page" || fail "database connection not OK"
expect_count 1

step "Insert a marker row"
db_query "INSERT INTO demo_messages (message) VALUES ('$MARKER');"
expect_count 2

step "Create a backup"
backup_output="$(./scripts/backup-db.sh)"
echo "$backup_output"
BACKUP_FILE="$(tail -n 1 <<< "$backup_output")"
[[ -s "$BACKUP_FILE" ]] || fail "backup file missing or empty: $BACKUP_FILE"
grep -q "$MARKER" "$BACKUP_FILE" || fail "marker row not found in backup"

step "Simulate data loss"
db_query "DELETE FROM demo_messages;"
expect_count 0

step "Restore without --yes in non-interactive mode is refused"
if ./scripts/restore-db.sh "$BACKUP_FILE" < /dev/null; then
    fail "restore ran without confirmation"
fi
expect_count 0

step "Restore the backup"
./scripts/restore-db.sh --yes "$BACKUP_FILE"
expect_count 2
page="$(fetch_page)"
grep -q "$MARKER" <<< "$page" || fail "restored marker not served by the web app"
echo "web app shows: $(grep 'Database message' <<< "$page")"

step "Recreate containers and check persistence"
docker compose down
docker compose up -d --wait --wait-timeout 180
expect_count 2

step "Smoke test passed"
