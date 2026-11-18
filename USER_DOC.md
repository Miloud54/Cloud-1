## Services provided ##

- WordPress website: `https://edidier.42.fr` 
- WordPress admin: `https://edidier.42.fr/wp-admin`
- FTP (Filezilla):
	- Host: domain name
	- Username: FTP username (`.env`)
	- Password: FTP password (`secrets/ftp_password.txt`)
	- Port: 21
- Static website: `http://localhost:8080`
- Adminer: `http://localhost:8081`
- cAdvisor `http://localhost:8082`

## Start and stop the project ##

```bash
# Start everything
make

# Stop containers (data is preserved)
make down

# Full cleanup (containers + volumes + images)
make clean
```

## Access the website ##

1. Make sure `127.0.0.1   edidier.42.fr` is added in `/etc/hosts`
2. Open `https://edidier.42.fr` in your browser
3. Accept the self-signed TLS certificate warning

WordPress Admin: 
`https://edidier.42.fr/wp-admin`  
Log in with the admin credentials (`secrets/credentials.txt`)

## Credentials

All sensitive credentials are stored in the `secrets/` folder at the root of the repository and are never committed to git.

- `secrets/db_password.txt`: MariaDB user password
- `secrets/db_root_password.txt`: MariaDB root password
- `secrets/credentials.txt`: WordPress admin username & password
- `secrets/ftp_password.txt`: FTP (Filezilla) password

## Check that services are running ##

```bash
# List running containers and their status
docker ps

# View logs for a specific service
docker logs <container_name>

# Examples
docker logs nginx
docker logs wordpress
docker logs mariadb
```

All containers are configured to restart automatically on crash (`restart: always`).
