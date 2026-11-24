# Cloud-1 — Notes de projet

## Plan étape par étape

1. ✅ Théorie
2. ✅ Provider (AWS), compte, alerte budget, clé SSH, instance Ubuntu 22.04 + security group 22/80/443
3. ✅ Ansible en local, inventory, `ansible all -m ping`
4. ✅ Rôle `common` : paquets, swap, mises à jour
5. ✅ Rôle `docker` : Docker Engine + plugin compose, service activé au boot
6. ✅ Rôle `firewall` : UFW (22/80/443)
7. ✅ Secrets et variables : Vault + domaine automatique sslip.io
8. ⏳ Rôles par service : `stack`, `mariadb`, `wordpress` (Dockerfile), `phpmyadmin`, `nginx` (routage `/` et `/phpmyadmin`, auto-signé)
9. TLS : Let's Encrypt quand c'est possible, sinon on reste en auto-signé
10. Tests de la grille : nouvelle machine, idempotence (`changed=0`), reboot (site + données intacts), `nmap`, 2 serveurs en parallèle, `docker volume ls`, `docker compose restart <service>`
11. Doc (README + section « Utilisation de l'IA ») + nettoyage des ressources cloud

---

## Décisions d'architecture

| Sujet | Choix retenu | Pourquoi | Alternatives écartées |
|---|---|---|---|
| **Rôles Ansible** | Un rôle par service : `stack` (dossier, `docker-compose.yml`, `.env`), `mariadb`, `wordpress`, `phpmyadmin`, `nginx`. Un seul `docker-compose.yml` ; chaque rôle démarre uniquement son service (`docker_compose_v2` + `services:`). Tags dans le playbook | Grille « Modular architecture » : *the web server in one role, the database in another role… deploy the parts independently* | Un seul rôle `app` : ne passe pas ce critère de la grille |
| **Images Docker** | Images officielles **Alpine** (`nginx`, `wordpress:fpm-alpine`, `phpmyadmin:fpm-alpine`) + `mariadb` officielle + **un Dockerfile WordPress** (`FROM wordpress:*-fpm-alpine`, dépendances et wp-cli d'abord, script d'installation en dernier) | Images petites et maintenues ; pas de gros build sur le t3.micro. Le Dockerfile démontre l'ordre des couches pour le cache (grille « Containers best practices ») | 100 % images officielles : aucun Dockerfile à montrer. Dockerfiles Inception : build lourd, plus de code |
| **Secrets** | Ansible Vault : `group_vars/all/vault.yml` chiffré en AES256 et versionné. Mot de passe dans `.vault_pass`, ignoré par Git | Le dépôt suffit pour déployer, et rien n'est en clair | Fichiers locaux ignorés : rien n'est chiffré, et le dépôt seul ne suffit pas |
| **Domaine** | **sslip.io uniquement** : domaine calculé depuis l'IP de l'inventory (`13.39.242.63` → `13-39-242-63.sslip.io`) | Gratuit, sans compte, automatique pour N serveurs. Si l'IP change, seul l'inventory change | DuckDNS : sous-domaines créés à la main (5 max), token à gérer, mise à jour d'IP à automatiser |
| **Routage / TLS** | Par chemin : `/` → WordPress, `/phpmyadmin` → phpMyAdmin. Let's Encrypt si possible, sinon certificat auto-signé | Un seul certificat ; le déploiement n'échoue jamais, même sans certificat valide (« TLS when possible ») | Sous-domaines : certificat multi-domaines |

### Interprétations du sujet (discutées avec une camarade)

- **Plusieurs serveurs en parallèle** = N copies indépendantes du même site, chacune avec sa propre base. Pas de base partagée ni de load balancer : le sujet ne le demande pas.
- **Root user** = le compte root du provider cloud (connexion à la console AWS avec l'email root), pas un utilisateur de la VM. La grille le confirme : *connect as root access to the service he will have chosen*.
- **TLS « when possible »** = TLS dès qu'on a un domaine, mais le site doit fonctionner même sans certificat valide.

---

## 7a.1 : Domaine automatique avec sslip.io ✅

Aucune inscription : `<ip-avec-tirets>.sslip.io` résout vers cette IP.

```bash
getent hosts 13-39-242-63.sslip.io    # doit renvoyer 13.39.242.63
```

Le domaine sera calculé par Ansible dans `vars.yml` (voir 7a.4).

## 7a.2 : Le mot de passe du Vault ✅

```bash
openssl rand -hex 32 > .vault_pass
chmod 600 .vault_pass
git check-ignore .vault_pass        # doit afficher ".vault_pass"
```

Ajouter dans la section `[defaults]` de `ansible.cfg` :

```ini
vault_password_file = .vault_pass
```

> ⚠️ **Sauvegarder le contenu de `.vault_pass` ailleurs**, par exemple dans un gestionnaire de mots de passe. Si ce fichier est perdu, le Vault devient illisible.

## 7a.3 : Créer le Vault ✅

> Lire : `ansible-vault view`. Modifier : `ansible-vault edit`. Jamais `decrypt`/`encrypt` (fichier en clair entre les deux) ni `cat` sur le contenu déchiffré.
> Valeurs **entre guillemets** (sinon YAML peut lire un hex comme `12345e678` comme un nombre).

Générer 3 mots de passe. On utilise `-hex` pour éviter `/`, `+` et `=`, qui posent des problèmes d'échappement dans les `.env` :

```bash
openssl rand -hex 20    # à lancer 3 fois
```

Créer le Vault :

```bash
ansible-vault create group_vars/all/vault.yml
```

Contenu à saisir dans l'éditeur qui s'ouvre :

```yaml
---
vault_app_db_root_password: "<mot de passe 1>"
vault_app_db_password: "<mot de passe 2>"
vault_app_wp_admin_password: "<mot de passe 3>"
vault_app_wp_admin_email: "<email>"
```

Vérification :

```bash
head -1 group_vars/all/vault.yml              # $ANSIBLE_VAULT;1.1;AES256
ansible-vault view group_vars/all/vault.yml   # contenu en clair
```

> L'email n'est pas un secret, mais il est dans le Vault pour ne pas publier une donnée personnelle dans un dépôt potentiellement public.

## 7a.4 : Les variables non secrètes ✅

`group_vars/all/vars.yml` :

```yaml
---
app_dir: /opt/cloud1
app_domain: "{{ ansible_host | replace('.', '-') }}.sslip.io"

app_db_name: wordpress
app_db_user: wpuser
app_db_password: "{{ vault_app_db_password }}"
app_db_root_password: "{{ vault_app_db_root_password }}"

app_wp_title: Cloud-1
app_wp_admin_user: <nom d'admin>
app_wp_admin_password: "{{ vault_app_wp_admin_password }}"
app_wp_admin_email: "{{ vault_app_wp_admin_email }}"
```

> **Convention de la double variable** : les secrets s'appellent `vault_*` dans `vault.yml`. Les rôles utilisent des variables `app_*` définies dans `vars.yml`, qui pointent vers les `vault_*`. Un `grep app_db_password` montre ainsi où la variable est définie, sans déchiffrer le Vault.

> **`app_domain`** est calculé pour chaque hôte à partir de son `ansible_host`. Pour lui donner un autre nom, il suffit de définir `app_domain=...` sur la ligne de l'hôte dans l'inventory : une variable d'hôte est prioritaire sur `group_vars`.

## 7a.5 : L'inventory ✅

Rien de plus que l'IP : le domaine est calculé automatiquement.

```ini
[cloud1]
cloud1-1 ansible_host=<IP>
```

## 7a : Vérification

```bash
ansible all -m debug -a "var=app_domain"         # <ip-avec-tirets>.sslip.io
ansible all -m debug -a "var=app_db_user"
ansible all -m debug -a "var=app_db_password"   # en clair = le Vault est bien déchiffré
git status                                       # vault.yml OUI (chiffré), .vault_pass NON
```

> Ne jamais partager la sortie du `debug` sur un mot de passe.
