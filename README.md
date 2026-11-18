# Inception #

*This project has been created as part of the 42 curriculum by edidier.*

## Description ##

The goal of Inception is to set up a complete and secure cloud infrastructure using Docker Compose.

All services have dedicated containers under Debian Bookworm, ensuring a microservice architecture that is reproductible and scalable.

Services:
	- NGINX: web server
	- WordPress + php-fpm: CMS
	- MariaDB: database

Bonus services:
	- Redis: Wordpress object cache
	- FTP: allow access to Wordpress files
	- Adminer: database web UI
	- cAdvisor: containe resource monitoring

All containers communicate through a dedicated Docker network.

### Technical choices and comparisons ###

#### VMs VS Docker ####

VMs emulate full hardware and run a complete OS (heavy but fully isolated). 

Docker containers share the host kernel and are lightweight, fast to start and ideal for running isolated services.

#### Secrets vs Environment Variables ####

Environment variables (.env) store non-sensitive config like domain names. 

Docker secrets store sensitive data (passwords, keys) as files mounted inside containers, never exposed in docker inspect or image layers.

#### Docker Volumes vs Bind Mounts ####

Bind mounts link a host path directly to a container path. It's simple but host-dependent. 

Named volumes are managed by Docker, portable and are the recommended way to persist data in production.

## Instruction ##

### Prerequisites ###

- VM running under Debian
- Docker and Docker Compose installed
- Sudo privileges to modify system files

### Run ###

```bash
make        # build and start all containers
make down   # stop and remove containers
make clean  # remove containers, volumes, and built images
make re     # full rebuild
```

The website is accessible at `https://edidier.42.fr`

## Resources ##

- Docker: 
	- `https://docs.docker.com/`
	- `https://blog.stephane-robert.info/docs/conteneurs/moteurs-conteneurs/docker/`

- Docker Compose: 
	- `https://docs.docker.com/compose/`

- NGINX:
	- `https://nginx.org/en/docs/http/configuring_https_servers.html`
	- `https://grafikart.fr/tutoriels/nginx-692`

- WordPress: 
	- `https://wp-cli.org/`
	- `https://oscar-black.com/blog/wordpress/docker-wordpress/`

- MariaDB:
	- `https://mariadb.com/kb/en/installing-and-using-mariadb-via-docker/`
	- `https://www.bytebase.com/reference/mariadb/how-to/how-to-install-mariadb-using-docker/`

- Redis:
	- `https://wordpress.org/plugins/redis-cache/`
	- `https://www.ionos.fr/digitalguide/serveur/know-how/redis-dans-des-conteneurs-docker/`

- FTP:
	- `https://tinztwinshub.com/software-engineering/set-up-an-ftp-server-with-docker/`
	- `https://debian-facile.org/doc:reseau:filezilla`

- cAdvisor:
	- `https://github.com/google/cadvisor`
	- `https://www.webhi.com/how-to/fr/surveillance-docker-prometheus-cadvisor-node-exporter-grafana/`

- AI usage: AI was used for troubleshooting Dockerfile build errors, generating Nginx configuration templates, and structuring documentation. It helped clarify the interaction between PHP-FPM and Nginx.