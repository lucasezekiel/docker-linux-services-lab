# Docker Linux Services Lab

A small hands-on systems administration lab built with Docker Compose.

The project deploys an Apache/PHP web service connected to a MariaDB database and demonstrates container networking, persistent storage, service health checks, database initialization, backup and recovery, and basic troubleshooting.

## Architecture

```text
CachyOS Linux Host
        |
        v
   Docker Compose
        |
        +---------------------+
        |                     |
        v                     v
  Apache + PHP             MariaDB
     web                     db
        |                     |
        +---- Docker network--+
                              |
                              v
                     Persistent volume
```

The web container communicates with MariaDB using the internal Docker network. The database is not exposed directly to the host.

## Technologies

- GNU/Linux
- Docker
- Docker Compose
- Apache
- PHP
- MariaDB
- Bash
- SQL
- Git
- ShellCheck

## Features

- Custom PHP/Apache Docker image
- Multi-container deployment with Docker Compose
- Internal Docker network
- Persistent MariaDB storage using a named volume
- MariaDB health check
- Automatic database initialization
- Environment-based configuration
- Database backup automation with Bash
- Database restore automation with Bash
- Shell scripts validated with ShellCheck
- Functional persistence and recovery tests

## Project Structure

```text
.
├── app/
│   ├── Dockerfile
│   └── index.php
├── backups/
│   └── .gitkeep
├── db/
│   └── init.sql
├── scripts/
│   ├── backup-db.sh
│   └── restore-db.sh
├── .env.example
├── .gitignore
├── compose.yaml
└── README.md
```

## Requirements

Docker and Docker Compose must be installed and running.

Check the installation with:

```bash
docker --version
docker compose version
docker info
```

## Configuration

Create the local environment file from the provided example:

```bash
cp .env.example .env
```

The `.env` file contains local database credentials and is intentionally excluded from Git.

## Running the Lab

Validate the Compose configuration:

```bash
docker compose config -q
```

Build and start the services:

```bash
docker compose up -d --build
```

Check their status:

```bash
docker compose ps
```

Test the web service:

```bash
curl http://localhost:8080
```

Expected output:

```text
Docker Linux Services Lab
=========================
Web service: OK
Database connection: OK
```

## Persistent Storage Test

A second database record was manually inserted and the containers were then removed:

```bash
docker compose down
```

The services were recreated:

```bash
docker compose up -d
```

The database record remained available because MariaDB stores its data in a named Docker volume.

This demonstrates that container lifecycle and data lifecycle are independent.

The volume can be inspected with:

```bash
docker volume ls
docker volume inspect docker-linux-services-lab_db_data
```

## Database Backup

Create a database dump with:

```bash
./scripts/backup-db.sh
```

Backups are stored locally under:

```text
backups/
```

SQL dump files are excluded from Git.

## Database Recovery

Restore a database dump with:

```bash
./scripts/restore-db.sh backups/<backup-file>.sql
```

The recovery procedure was tested by:

```text
creating a valid backup
        |
        v
deleting all rows from the test table
        |
        v
verifying the data loss
        |
        v
restoring the SQL dump
        |
        v
verifying the recovered data
```

Both direct SQL queries and the PHP application confirmed successful recovery.

## Troubleshooting

During the first deployment, MariaDB required additional time to initialize its database files before becoming healthy.

The issue was investigated using:

```bash
docker compose ps
docker compose logs db
docker inspect sysadmin-lab-db
```

The logs confirmed that MariaDB successfully initialized the database, created the application user, executed the initialization script, and eventually reported itself ready for connections.

This demonstrated the importance of distinguishing between a container that is running and a service that is actually ready to accept requests.

## Useful Commands

Check running services:

```bash
docker compose ps
```

View logs:

```bash
docker compose logs
docker compose logs db
docker compose logs web
```

Stop and remove containers while preserving the database volume:

```bash
docker compose down
```

Remove containers **and the persistent volume**:

```bash
docker compose down -v
```

> Warning: using `-v` removes the database volume and its stored data.

## Learning Objectives

This lab was created to practice concepts related to Linux systems administration and infrastructure:

- containerized service deployment
- service dependencies and health monitoring
- Docker networking
- persistent storage
- SQL database initialization
- backup and disaster recovery
- Bash automation
- log analysis
- troubleshooting
- Git-based project management

## Status

Lab completed and tested on a GNU/Linux host running Docker Engine and Docker Compose.
