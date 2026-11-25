# Cloud-1

*This project has been created as part of the 42 curriculum by edidier.*

## Description

Automated deployment of a WordPress site (Inception-like stack) on one or more
cloud instances with Ansible. Each process runs in its own container:
nginx (reverse proxy + TLS), WordPress (php-fpm), phpMyAdmin (php-fpm) and MariaDB.

## Usage

```bash
ansible-galaxy collection install -r requirements.yml
ansible-playbook playbook.yml
```

Requirements: an Ubuntu 22.04 instance reachable over SSH with Python installed,
listed in `inventory/hosts.ini`, and the Vault password in `.vault_pass`.

> Full documentation (architecture, technical choices, tests, AI usage): work in progress.
