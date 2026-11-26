# Cloud-1

*This project has been created as part of the 42 curriculum by bde-la-p and edidier.*

## Description

Automated deployment of a WordPress site on one or more cloud instances (AWS EC2)
with Ansible. Each service runs in its own Docker container:

```
Internet ──443──▶ nginx ──frontend──▶ wordpress  ──backend (internal)──▶ mariadb
                        └─frontend──▶ phpmyadmin ──backend (internal)──┘
```

- HTTPS with Let's Encrypt (self-signed fallback), domain computed from the IP via `sslip.io`
- Secrets encrypted with Ansible Vault, passed to containers as Docker secrets
- Data persisted in named volumes, containers restarted automatically on reboot
- One Ansible role per service, each deployable on its own with tags

## Requirements

- Ansible (with the collections from `requirements.yml`)
- An Ubuntu 22.04 server reachable over SSH, with Python 3
- The Vault password in `.vault_pass` (not versioned)

## Usage

```bash
ansible-galaxy collection install -r requirements.yml   # once
ansible-playbook playbook.yml                           # deploy every host in the inventory
```

The site is then available at `https://<ip-with-dashes>.sslip.io`.

## Essential commands

### Deployment

```bash
ansible all -m ping                                   # check SSH access to every host
ansible-playbook playbook.yml --syntax-check          # check the playbook syntax
ansible-playbook playbook.yml --limit cloud1-1        # deploy a single host
ansible-playbook playbook.yml --tags nginx            # deploy a single part (role)
ansible-playbook playbook.yml --list-tasks --tags wordpress   # show what a tag runs
ansible-playbook playbook.yml --list-tags             # list available tags
```

Add a server: add one line to `inventory/hosts.ini`, then run the playbook.

```ini
cloud1-2 ansible_host=<public IP>
```

### Secrets

```bash
ansible-vault edit group_vars/all/vault.yml           # edit the secrets
ansible all -m debug -a "msg={{ app_db_password | length }}"   # check decryption without printing
```

Never use `ansible-vault decrypt` (leaves the file in clear) and never commit `.vault_pass`.

### Containers (on the server: `ssh -i ~/.ssh/cloud1 ubuntu@<IP>`, then `cd /opt/cloud1`)

```bash
sudo docker compose ps                    # state and health of the containers
sudo docker compose logs -f wordpress     # follow the logs of a service
sudo docker compose restart wordpress     # restart one service
sudo docker compose down                  # remove containers (volumes are kept)
sudo docker compose up -d                 # start everything again
sudo docker volume ls                     # list the data volumes
```

Never run `docker compose down -v`: it deletes the volumes, so all data.

The same commands work from the control machine with Ansible, for example:

```bash
ansible all -b -a "docker compose -f /opt/cloud1/docker-compose.yml ps"
```

### Checks

```bash
nmap -Pn -p- --min-rate 2000 -T4 <IP>     # only 22, 80 and 443 should be open
curl -sI http://<ip-with-dashes>.sslip.io # 301 redirect to HTTPS
ansible all -b -a "ufw status verbose"    # firewall rules
ansible-lint                              # lint the Ansible code
```

## Running from another workstation

Deploying needs the SSH key of the servers and the Vault password, which are not
in the repository. Never copy the owner's private key: give the other workstation
its own key, then revoke it afterwards.

**1. On the other workstation:** clone the repository, install Ansible and create a dedicated key.

```bash
pipx install ansible-core                  # or: python3 -m pip install --user ansible-core
ansible-galaxy collection install -r requirements.yml
ssh-keygen -t ed25519 -f ~/.ssh/cloud1_eval -N "" -C "cloud1-eval"
cat ~/.ssh/cloud1_eval.pub                 # public key: safe to share, send it to the owner
```

**2. On the owner's workstation:** authorize this public key on every server.

```bash
ansible all -m ansible.posix.authorized_key \
  -a "user=ubuntu state=present key='<content of cloud1_eval.pub>'"
```

**3. On the other workstation:** the owner types the Vault password (nothing is displayed).

```bash
read -rs VP && printf '%s' "$VP" > .vault_pass && chmod 600 .vault_pass; unset VP
```

**4. On the other workstation:** use the dedicated key (`--private-key` overrides `ansible.cfg`).

```bash
ansible all -m ping --private-key ~/.ssh/cloud1_eval
ansible-playbook playbook.yml --private-key ~/.ssh/cloud1_eval
ssh -i ~/.ssh/cloud1_eval ubuntu@<IP>
```

**5. Clean up when done.**

```bash
# on the other workstation
rm -f .vault_pass ~/.ssh/cloud1_eval ~/.ssh/cloud1_eval.pub
# on the owner's workstation: revoke the key
ansible all -m ansible.posix.authorized_key \
  -a "user=ubuntu state=absent key='<content of cloud1_eval.pub>'"
```

## Project layout

| Path | Content |
|---|---|
| `playbook.yml` | Main playbook, one tagged role per part |
| `inventory/hosts.ini` | Target servers |
| `group_vars/all/` | Variables (`vars.yml`) and encrypted secrets (`vault.yml`) |
| `roles/common` | Base packages, swap |
| `roles/docker` | Docker Engine and Compose plugin |
| `roles/firewall` | UFW rules |
| `roles/stack` | Shared `docker-compose.yml` and secret files |
| `roles/mariadb`, `wordpress`, `phpmyadmin`, `nginx` | One role per service |
| `roles/tls` | Let's Encrypt certificate |

