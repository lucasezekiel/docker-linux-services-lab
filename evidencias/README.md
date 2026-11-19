# Evidencias

Capturas y salidas de una ejecución real del laboratorio. Cada `.png` de terminal tiene al lado un `.txt` con la misma salida en texto plano.

## Entorno (2026-11-19)

| Componente | Versión |
|---|---|
| Host | Debian GNU/Linux 13 (trixie) |
| Docker | Engine y CLI 26.1.5, Docker Compose 2.26.1, storage driver `overlay2` |
| Imágenes | `mariadb:11`, `php:8.3-apache` (imagen web construida localmente) |
| Herramientas | ShellCheck 0.10.0, curl, Chromium headless (captura del navegador) |

- En las salidas, `<proyecto>` reemplaza la ruta absoluta del directorio del repositorio en el equipo de prueba.
- El `.env` usado fue una copia de `.env.example`, solo para la prueba.
- Al terminar se eliminaron contenedores, volúmenes, backups y el `.env` de prueba.

## Capturas

| # | Archivo | Qué demuestra |
|---|---|---|
| 01 | [01-validacion-estatica](01-validacion-estatica.png) | ShellCheck sin advertencias en los tres scripts; `docker compose config` válido |
| 02 | [02-smoke-test](02-smoke-test.png) | `tests/smoke.sh` completo: web ↔ base, backup, pérdida simulada, rechazo sin `--yes`, restauración y persistencia tras recrear los contenedores |
| 03 | [03-servicios-healthy](03-servicios-healthy.png) | MariaDB `healthy`; solo la web publica el puerto 8080 y la base no publica ninguno |
| 04 | [04-curl-aplicacion](04-curl-aplicacion.png) | La aplicación responde y lee el mensaje de la base |
| 05 | [05-navegador-localhost-8080](05-navegador-localhost-8080.png) | La misma respuesta vista desde un navegador |
| 06 | [06-backup-manual](06-backup-manual.png) | Backup manual con permisos `-rw-------` (`umask 077`) |
| 07 | [07-restauracion-con-confirmacion](07-restauracion-con-confirmacion.png) | Con una respuesta incorrecta se cancela; con el nombre de la base se restaura y la web sigue funcionando |

## Observaciones

- La captura 02 omite unas 575 líneas de descarga de imágenes y compilación de `pdo_mysql`; el `.txt` tiene la salida completa.
- La prueba de humo usa su propio proyecto Compose (`dlsl-smoke`), contenedores, volumen y puerto `127.0.0.1:18080`. Al terminar no quedó ningún recurso `dlsl-smoke` y el laboratorio normal no se tocó.
- Para la captura 07 se usó `script` para simular una terminal interactiva, ya que la confirmación solo se pide si la entrada es una TTY.
