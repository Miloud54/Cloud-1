## Prerequisites ##

- VM running under Debian
- Docker Engine and Docker Compose installed
- Basic commands installed (make)
- Docker and Docker Compose installed
- Sudo privileges to modify system files
- Add the following line to `/etc/hosts`: 
> 127.0.0.1   edidier.42.fr

## Project structure ##

```
.
├── Makefile
├── README.md        
├── USER_DOC.md      
├── DEV_DOC.md       
├── secrets/
│   ├── credentials.txt       
│   ├── db_password.txt  
│   ├── db_root_password.txt     
│   └── ftp_password.txt  
└── srcs/
    ├── .env                 
    ├── docker-compose.yml
    └── requirements/
        ├── nginx/
        ├── wordpress/
        ├── mariadb/
        └── bonus/
            ├── redis/
            ├── ftp/
            ├── adminer/
            ├── static/
            └── cadvisor/
```

## Configuration ##

### .env file (`srcs/.env`) ###

Contains non-sensitive variables.

### secrets files ###

Create these files manually (git-ignored):

```bash
echo "your_wp_admin_password" > secrets/credentials.txt
echo "your_db_password"       > secrets/db_password.txt
echo "your_db_root_password"  > secrets/db_root_password.txt
```

Passwords must never appear in Dockerfiles or the .env file.

## Build and launch ##

```bash
make        # build and start all containers
make down   # stop and remove containers
make clean  # remove containers, volumes, and built images
make re     # full rebuild
```

The Makefile also ensures `/home/edidier/data/wordpress` and `/home/edidier/data/mariadb` exist before starting.

## Useful Docker commands ##

```bash
# See all running containers
docker ps

# Inspect a container
docker inspect <container_name>

# Open a shell inside a container
docker exec -it <container_name> bash

# View real-time logs
docker logs -f <container_name>

# List volumes
docker volume ls

# Remove a specific volume
docker volume rm <volume_name>
```

## Data persistence ##

Named volumes are stored at:

- `/home/edidier/data/wordpress` 
- `/home/edidier/data/mariadb` 

These paths are defined in docker-compose.yml under the volumes section and are created by the Makefile before startup. Data survives make down but is wiped by make clean.