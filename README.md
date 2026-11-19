🇪🇸 Español | [🇬🇧 English](README.en.md)

# Docker Linux Services Lab

[![CI](https://github.com/lucasezekiel/docker-linux-services-lab/actions/workflows/ci.yml/badge.svg)](https://github.com/lucasezekiel/docker-linux-services-lab/actions/workflows/ci.yml)

Laboratorio práctico de administración de sistemas GNU/Linux con Docker Compose.

Despliega un servicio web PHP/Apache conectado a una base MariaDB y demuestra:

- redes entre contenedores;
- almacenamiento persistente;
- health checks;
- inicialización de la base;
- backup y recuperación;
- integración continua;
- troubleshooting.

## Arquitectura

```text
Host GNU/Linux
      │
      ▼
Docker Compose
      │
      ├───────────────────────┐
      ▼                       ▼
 Servicio web             Base de datos
 Apache + PHP             MariaDB
      │                       │
      └────── red labnet ─────┤
                              ▼
                   Volumen Docker persistente
```

- El servicio web se comunica con MariaDB por una red interna de Docker.
- Solo el servicio web se publica en el host, en el puerto `8080`.
- MariaDB no expone ningún puerto al host.

## Tecnologías

GNU/Linux · Docker Engine · Docker Compose · Apache · PHP · MariaDB · SQL · Bash · Git · GitHub Actions · ShellCheck

## Funcionalidades

- Despliegue multicontenedor con Docker Compose.
- Imagen propia PHP/Apache.
- Red interna de Docker y almacenamiento persistente para MariaDB.
- Inicialización automática de la base con SQL.
- Health check de MariaDB; el servicio web espera a que la base esté sana.
- Configuración por variables de entorno (`.env`).
- Scripts Bash de backup y restauración, validados con ShellCheck.
- Prueba de humo de punta a punta: backup → pérdida de datos → restauración → persistencia.
- CI con GitHub Actions que ejecuta ShellCheck, la validación de Compose, el build y la prueba de humo.

## Estructura

```text
.
├── .github/workflows/ci.yml
├── app/
│   ├── Dockerfile
│   └── index.php
├── backups/                # dumps SQL (excluidos de Git)
├── db/init.sql
├── evidencias/             # capturas y salidas de ejecuciones reales
├── scripts/
│   ├── backup-db.sh
│   └── restore-db.sh
├── tests/
│   ├── compose.smoke.yaml  # override aislado para la prueba de humo
│   └── smoke.sh
├── .env.example
├── compose.yaml
└── LICENSE
```

Los backups y el archivo `.env` local están excluidos del control de versiones a propósito.

## Requisitos

Docker Engine con el plugin Docker Compose.

```bash
docker --version
docker compose version
docker info
```

## Configuración

```bash
cp .env.example .env
```

Editá `.env` y definí las credenciales de la base. El `.env` local está ignorado por Git y no debe commitearse.

## Levantar el laboratorio

```bash
docker compose config -q        # validar la configuración
docker compose up -d --build    # construir e iniciar
docker compose ps               # MariaDB debería quedar "healthy"
```

## Probar la aplicación

```bash
curl http://localhost:8080
```

```text
Docker Linux Services Lab
=========================
Web service: OK
Database connection: OK

Database message: Persistent storage is working
```

Esto confirma que:

- el contenedor web está corriendo y PHP funciona;
- el DNS de Docker resuelve el servicio `db`;
- la aplicación se conecta a MariaDB y lee los datos iniciales.

## Persistencia

Con los datos cargados, se recrean los contenedores:

```bash
docker compose down
docker compose up -d
```

Los registros siguen disponibles porque MariaDB guarda los datos en un volumen con nombre (`docker volume ls`). Es decir, el ciclo de vida de los datos es independiente del de los contenedores.

> **Cuidado:** `docker compose down` elimina los contenedores pero conserva el volumen. `docker compose down -v` **también borra el volumen** y con él los datos.

## Backup

```bash
./scripts/backup-db.sh
```

El script:

1. carga la configuración local;
2. ejecuta `mariadb-dump` dentro del contenedor y toma la contraseña root del entorno del propio contenedor, así no aparece en ninguna línea de comandos ni en `ps`;
3. escribe en un archivo temporal oculto y lo publica solo si no está vacío;
4. lo guarda en `backups/` con permisos solo para el dueño (`umask 077`), por ejemplo `backups/labdb_2026-09-14_03-13-58.sql`.

## Restauración

```bash
./scripts/restore-db.sh backups/<archivo>.sql
```

Antes de sobrescribir pide escribir el nombre de la base. Para automatizar se usa `--yes`; sin esa opción, una ejecución no interactiva se rechaza.

```text
Base funcionando ─▶ backup ─▶ registros borrados ─▶ pérdida verificada ─▶ restauración ─▶ datos recuperados
```

La recuperación se verificó con consultas SQL directas y a través de la aplicación PHP.

## Pruebas

### Prueba de humo de punta a punta

`tests/smoke.sh` levanta una **copia aislada** del stack: proyecto Compose `dlsl-smoke`, contenedores y volumen propios y puerto `127.0.0.1:18080`. Sobre esa copia comprueba:

1. que la web llega a la base;
2. que una fila marcadora aparece dentro de un backup nuevo;
3. el borrado de todas las filas (pérdida de datos simulada);
4. que una restauración no interactiva sin `--yes` se rechaza;
5. que la restauración devuelve la fila marcadora y la web la muestra;
6. que después de `down` y `up` los datos siguen ahí.

```bash
./tests/smoke.sh
```

Al terminar se elimina la copia aislada con su volumen; un laboratorio normal levantado con `docker compose up` no se toca. Con `KEEP_SMOKE=1` la copia queda en pie para inspeccionarla.

### ShellCheck

```bash
shellcheck scripts/backup-db.sh scripts/restore-db.sh tests/smoke.sh
```

### Integración continua

GitHub Actions corre en cada push y pull request a `main`:

- ShellCheck de los scripts;
- validación de la configuración de Compose;
- build de la imagen web;
- prueba de humo de punta a punta.

## Evidencias

Las capturas y salidas de ejecuciones reales están en [`evidencias/`](evidencias/).

## Health check y troubleshooting

En el primer despliegue MariaDB figuró un tiempo como `unhealthy`. Se investigó con:

```bash
docker compose ps
docker compose logs db
docker inspect sysadmin-lab-db
```

Los logs mostraban que MariaDB seguía con la inicialización inicial, que tardaba más que la ventana de reintentos del health check. Se agregó un período de gracia:

```yaml
start_period: 90s
```

Lección: **contenedor corriendo ≠ aplicación lista.** Un contenedor puede estar en marcha mientras el servicio de adentro todavía se inicializa.

## Comandos útiles

```bash
docker compose ps             # estado
docker compose logs [db|web]  # logs
docker compose restart        # reiniciar
docker compose down           # detener conservando los datos
```

## Seguridad

- Credenciales en un `.env` local, excluido de Git.
- Backups excluidos de Git y con permisos restringidos.
- La contraseña root no se pasa por línea de comandos.
- MariaDB sin puerto publicado; la web usa un usuario de base dedicado.
- Red Docker dedicada para los servicios.

Para producción harían falta, además: gestión de secretos, TLS, privilegios mínimos, cifrado de backups, control de acceso, monitoreo y actualizaciones periódicas.

## Objetivos de aprendizaje

Administración de Linux, contenedores y Compose, redes de servicios, almacenamiento persistente, health checks, administración SQL, backup y recuperación, automatización con Bash, CI, análisis de logs, troubleshooting y Git.

## Licencia

MIT. Ver [LICENSE](LICENSE).

## Estado

Completado y probado en un entorno de laboratorio GNU/Linux. Es un ejercicio práctico de administración de sistemas, no un despliegue de producción.
